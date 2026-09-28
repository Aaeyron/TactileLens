package com.tactilelens.app

import android.content.Context
import android.os.SystemClock
import kotlin.math.max
import kotlin.math.min
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Full offline page scan: layout + OCR + formula recognition, merged in
 * reading order.
 *
 * 1. PP-DocLayoutV3 finds regions (text, display/inline formulas, ...)
 *    and their reading order.
 * 2. PP-OCRv6 reads every text line on the page.
 * 3. Each OCR line is assigned to the layout region it sits in. Lines that
 *    fall inside a display formula are dropped (plain OCR garbles math).
 * 4. Each display formula region is read by PP-FormulaNet_plus-S -> LaTeX.
 * 5. SAFETY NET: text blocks that look like math (operators, stacked short
 *    rows, no real words) are also sent to the formula model, because the
 *    layout model sometimes labels equations as text or misses them.
 *    Stacked stray lines are grouped first so fractions stay together.
 * 6. Blocks are returned in reading order, plus Markdown with $$ ... $$.
 */
object OfflineDocumentPipeline {
    private const val DISPLAY_FORMULA = "formula_display"
    private const val INLINE_FORMULA = "formula_inline"

    // A text line below this OCR confidence flags its block for review.
    private const val LOW_CONFIDENCE = 0.80

    // Share of a line's area that must lie inside a region to belong to it.
    private const val LINE_IN_REGION = 0.5

    // Overlapping duplicate layout regions above this IoU are merged.
    private const val DUPLICATE_IOU = 0.8

    // Math fallback only for short blocks (a stacked fraction is 2-3 rows).
    private const val MAX_FALLBACK_LINES = 3

    private val MATH_SYMBOL = Regex("""[=<>≤≥≠±+\-−×÷*/^√]""")
    private val REAL_WORD = Regex("""[A-Za-z]{3,}""")
    private const val MATH_CHARACTERS = "0123456789=<>≤≥≠±+-−×÷*/^√()[]."

    suspend fun scanDocument(
        context: Context,
        imagePath: String,
        threadCount: Int,
        layoutThreshold: Float = 0.5f,
    ): Map<String, Any?> = withContext(Dispatchers.Default) {
        val totalStart = SystemClock.elapsedRealtime()

        // 1. Layout
        val layoutStart = SystemClock.elapsedRealtime()
        val layout = PaddleOnnxLayoutDetector.detectFile(
            context = context,
            imagePath = imagePath,
            threadCount = threadCount,
            threshold = layoutThreshold,
        )
        val layoutMs = SystemClock.elapsedRealtime() - layoutStart

        // 2. OCR
        val ocrStart = SystemClock.elapsedRealtime()
        val ocr = PaddleOnnxOcrEngine.recognizeFile(
            context = context,
            imagePath = imagePath,
            threadCount = threadCount,
        )
        val ocrMs = SystemClock.elapsedRealtime() - ocrStart

        val regions = removeDuplicates(parseRegions(layout["regions"]))
        val lines = parseLines(ocr["blocks"])

        val containers = regions.filter {
            it.category != DISPLAY_FORMULA && it.category != INLINE_FORMULA
        }

        // Inline formulas that are not inside any text region are really
        // equations on their own line: treat them as display formulas.
        val (standaloneInline, embeddedInline) = regions
            .filter { it.category == INLINE_FORMULA }
            .partition { inline ->
                containers.none { container ->
                    container.box.intersection(inline.box) / max(inline.box.area, 1.0) >=
                        LINE_IN_REGION
                }
            }

        val displayFormulas = regions.filter { it.category == DISPLAY_FORMULA } +
            standaloneInline

        // 3. Assign OCR lines to regions
        val linesByRegion = HashMap<Region, MutableList<Line>>()
        val orphanLines = mutableListOf<Line>()
        var droppedFormulaLines = 0

        for (line in lines) {
            if (line.text.isBlank()) {
                continue
            }

            val lineArea = max(line.box.area, 1.0)

            val insideFormula = displayFormulas.any { formula ->
                formula.box.intersection(line.box) / lineArea >= LINE_IN_REGION
            }

            if (insideFormula) {
                droppedFormulaLines++
                continue
            }

            val best = containers.maxByOrNull { region ->
                region.box.intersection(line.box)
            }

            if (best != null && best.box.intersection(line.box) / lineArea >= LINE_IN_REGION) {
                linesByRegion.getOrPut(best) { mutableListOf() }.add(line)
            } else {
                orphanLines.add(line)
            }
        }

        // 4. Build blocks in layout reading order
        val ordered = (containers + displayFormulas).sortedBy { it.order }
        val pending = mutableListOf<PendingBlock>()
        val stats = Stats()

        ordered.forEachIndexed { index, region ->
            if (region.category == DISPLAY_FORMULA || region in standaloneInline) {
                val formulaStart = SystemClock.elapsedRealtime()
                val block = recognizeFormulaBlock(
                    context = context,
                    imagePath = imagePath,
                    threadCount = threadCount,
                    label = region.label,
                    score = region.score,
                    box = region.box,
                )
                stats.formulaMs += SystemClock.elapsedRealtime() - formulaStart
                stats.formulaCount++

                pending += PendingBlock(index.toDouble(), region.box.top, block)
            } else {
                val regionLines = linesByRegion[region].orEmpty()

                if (regionLines.isNotEmpty()) {
                    val inlineCount = embeddedInline.count { inline ->
                        inline.box.intersection(region.box) / max(inline.box.area, 1.0) >=
                            LINE_IN_REGION
                    }

                    pending += PendingBlock(
                        index.toDouble(),
                        region.box.top,
                        textOrFormulaBlock(
                            context = context,
                            imagePath = imagePath,
                            threadCount = threadCount,
                            type = region.category,
                            label = region.label,
                            score = region.score,
                            box = region.box.union(unionOf(regionLines)),
                            lines = regionLines,
                            inlineFormulaCount = inlineCount,
                            stats = stats,
                        ),
                    )
                }
            }
        }

        // Lines the layout model missed: group stacked rows (so a fraction's
        // numerator and denominator stay together), then place each group
        // after the last region that starts above it.
        for (group in groupStackedLines(orphanLines)) {
            val groupBox = unionOf(group)
            val previous = ordered.indexOfLast { region -> region.box.top <= groupBox.top }

            pending += PendingBlock(
                previous + 0.5,
                groupBox.top,
                textOrFormulaBlock(
                    context = context,
                    imagePath = imagePath,
                    threadCount = threadCount,
                    type = "text",
                    label = "unassigned_text",
                    score = 0.0,
                    box = groupBox,
                    lines = group,
                    inlineFormulaCount = 0,
                    stats = stats,
                ),
            )
        }

        // 5. Final ordering + Markdown
        val blocks = pending
            .sortedWith(compareBy({ it.sortKey }, { it.top }))
            .mapIndexed { index, item -> item.block + ("index" to index) }

        val markdown = blocks.joinToString("\n\n") { block ->
            val content = block["content"] as? String ?: ""
            if (block["type"] == "formula") "$$\n$content\n$$" else content
        }

        val needsReviewCount = blocks.count { it["needs_review"] == true }
        val totalMs = SystemClock.elapsedRealtime() - totalStart

        mapOf(
            "success" to true,
            "is_empty" to blocks.isEmpty(),
            "blocks" to blocks,
            "markdown" to markdown,
            "block_count" to blocks.size,
            "formula_count" to stats.formulaCount,
            "fallback_formula_count" to stats.fallbackCount,
            "inline_formula_count" to embeddedInline.size,
            "region_count" to regions.size,
            "ocr_line_count" to lines.size,
            "dropped_formula_line_count" to droppedFormulaLines,
            "unassigned_line_count" to orphanLines.size,
            "needs_review_count" to needsReviewCount,
            "image_width" to layout["image_width"],
            "image_height" to layout["image_height"],
            "layout_time_ms" to layoutMs,
            "ocr_time_ms" to ocrMs,
            "formula_time_ms" to stats.formulaMs,
            "total_time_ms" to totalMs,
            "thread_count" to threadCount,
        )
    }

    // ------------------------------------------------------------------
    // Blocks
    // ------------------------------------------------------------------

    private class PendingBlock(
        val sortKey: Double,
        val top: Double,
        val block: Map<String, Any?>,
    )

    private class Stats {
        var formulaCount = 0
        var fallbackCount = 0
        var formulaMs = 0L
    }

    /**
     * Text block, unless it looks like math: then try the formula model and
     * keep the OCR text as a fallback if recognition fails.
     */
    private suspend fun textOrFormulaBlock(
        context: Context,
        imagePath: String,
        threadCount: Int,
        type: String,
        label: String,
        score: Double,
        box: Box,
        lines: List<Line>,
        inlineFormulaCount: Int,
        stats: Stats,
    ): Map<String, Any?> {
        val text = textBlock(type, label, score, box, lines, inlineFormulaCount)

        if (lines.size > MAX_FALLBACK_LINES || !looksLikeMath(lines)) {
            return text
        }

        val formulaStart = SystemClock.elapsedRealtime()
        val formula = recognizeFormulaBlock(
            context = context,
            imagePath = imagePath,
            threadCount = threadCount,
            label = label,
            score = score,
            box = box,
        )
        stats.formulaMs += SystemClock.elapsedRealtime() - formulaStart

        val latex = formula["latex"] as? String ?: ""

        if (latex.isBlank() || formula["error"] != null || formula["reached_end"] == false) {
            return text
        }

        stats.formulaCount++
        stats.fallbackCount++

        return formula + mapOf(
            "source" to "formula_fallback",
            "ocr_text" to text["content"],
            "needs_review" to true,
        )
    }

    /**
     * Math if it has math symbols (or is a short stack of rows, like a
     * fraction), no real words ("Solve for x" stays text), and mostly
     * digits/operators.
     */
    private fun looksLikeMath(lines: List<Line>): Boolean {
        val text = lines.joinToString(" ") { it.text }.trim()

        if (text.isEmpty()) {
            return false
        }

        if (!MATH_SYMBOL.containsMatchIn(text) && lines.size < 2) {
            return false
        }

        if (REAL_WORD.findAll(text).count() > 1) {
            return false
        }

        val mathCharacters = text.count { it in MATH_CHARACTERS }
        val letters = text.count { it.isLetter() }

        return mathCharacters >= 2 && letters <= mathCharacters * 2
    }

    private suspend fun recognizeFormulaBlock(
        context: Context,
        imagePath: String,
        threadCount: Int,
        label: String,
        score: Double,
        box: Box,
    ): Map<String, Any?> {
        return try {
            val result = PaddleOnnxFormulaRecognizer.recognizeFile(
                context = context,
                imagePath = imagePath,
                threadCount = threadCount,
                box = box.toFloatArray(),
            )

            val latex = result["latex"] as? String ?: ""
            val reachedEnd = result["reached_end"] == true

            mapOf(
                "type" to "formula",
                "label" to label,
                "content" to latex,
                "latex" to latex,
                "score" to score,
                "confidence" to score,
                "box" to box.toMap(),
                "needs_review" to (latex.isBlank() || !reachedEnd),
                "reached_end" to reachedEnd,
                "source" to "formula",
                "token_count" to result["token_count"],
                "time_ms" to result["total_time_ms"],
            )
        } catch (error: Exception) {
            mapOf(
                "type" to "formula",
                "label" to label,
                "content" to "",
                "latex" to "",
                "score" to score,
                "confidence" to 0.0,
                "box" to box.toMap(),
                "needs_review" to true,
                "source" to "formula",
                "error" to (error.message ?: error.javaClass.simpleName),
            )
        }
    }

    private fun textBlock(
        type: String,
        label: String,
        score: Double,
        box: Box,
        lines: List<Line>,
        inlineFormulaCount: Int,
    ): Map<String, Any?> {
        val sorted = lines.sortedWith(compareBy({ it.box.top }, { it.box.left }))
        val averageConfidence = sorted.map { it.confidence }.average()
        val minimumConfidence = sorted.minOf { it.confidence }

        return mapOf(
            "type" to type,
            "label" to label,
            "content" to sorted.joinToString("\n") { it.text },
            "score" to score,
            "confidence" to averageConfidence,
            "min_confidence" to minimumConfidence,
            "line_count" to sorted.size,
            "inline_formula_count" to inlineFormulaCount,
            "box" to box.toMap(),
            "needs_review" to (minimumConfidence < LOW_CONFIDENCE),
            "source" to "ocr",
        )
    }

    /**
     * Groups lines that sit directly above/below each other and overlap
     * horizontally (e.g. a fraction's numerator and denominator).
     */
    private fun groupStackedLines(lines: List<Line>): List<List<Line>> {
        val groups = mutableListOf<MutableList<Line>>()

        for (line in lines.sortedBy { it.box.top }) {
            val lineHeight = max(line.box.bottom - line.box.top, 1.0)

            val target = groups.lastOrNull { group ->
                val groupBox = unionOf(group)
                val horizontalOverlap =
                    min(groupBox.right, line.box.right) - max(groupBox.left, line.box.left)
                val verticalGap = line.box.top - groupBox.bottom

                horizontalOverlap > 0.0 && verticalGap < lineHeight * 1.2
            }

            if (target != null) {
                target.add(line)
            } else {
                groups.add(mutableListOf(line))
            }
        }

        return groups
    }

    private fun unionOf(lines: List<Line>): Box = Box(
        left = lines.minOf { it.box.left },
        top = lines.minOf { it.box.top },
        right = lines.maxOf { it.box.right },
        bottom = lines.maxOf { it.box.bottom },
    )

    // ------------------------------------------------------------------
    // Parsing the engines' result maps
    // ------------------------------------------------------------------

    private class Box(
        val left: Double,
        val top: Double,
        val right: Double,
        val bottom: Double,
    ) {
        val area: Double
            get() = max(0.0, right - left) * max(0.0, bottom - top)

        fun intersection(other: Box): Double {
            val width = min(right, other.right) - max(left, other.left)
            val height = min(bottom, other.bottom) - max(top, other.top)
            return if (width <= 0.0 || height <= 0.0) 0.0 else width * height
        }

        fun iou(other: Box): Double {
            val overlap = intersection(other)
            val union = area + other.area - overlap
            return if (union <= 0.0) 0.0 else overlap / union
        }

        fun union(other: Box): Box = Box(
            left = min(left, other.left),
            top = min(top, other.top),
            right = max(right, other.right),
            bottom = max(bottom, other.bottom),
        )

        fun toMap(): Map<String, Any?> = mapOf(
            "left" to left,
            "top" to top,
            "right" to right,
            "bottom" to bottom,
        )

        fun toFloatArray(): FloatArray = floatArrayOf(
            left.toFloat(),
            top.toFloat(),
            right.toFloat(),
            bottom.toFloat(),
        )
    }

    private class Region(
        val order: Int,
        val label: String,
        val category: String,
        val score: Double,
        val box: Box,
    )

    private class Line(
        val text: String,
        val confidence: Double,
        val box: Box,
    )

    private fun number(value: Any?): Double = (value as? Number)?.toDouble() ?: 0.0

    private fun parseRegions(raw: Any?): List<Region> {
        val list = raw as? List<*> ?: return emptyList()

        return list.mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val box = map["box"] as? Map<*, *> ?: return@mapNotNull null

            Region(
                order = (map["order"] as? Number)?.toInt() ?: 0,
                label = map["label"] as? String ?: "",
                category = map["category"] as? String ?: "text",
                score = number(map["score"]),
                box = Box(
                    left = number(box["left"]),
                    top = number(box["top"]),
                    right = number(box["right"]),
                    bottom = number(box["bottom"]),
                ),
            )
        }
    }

    private fun parseLines(raw: Any?): List<Line> {
        val list = raw as? List<*> ?: return emptyList()

        return list.mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val points = (map["box"] as? List<*>).orEmpty()
                .mapNotNull { it as? Map<*, *> }

            if (points.isEmpty()) {
                return@mapNotNull null
            }

            val xs = points.map { number(it["x"]) }
            val ys = points.map { number(it["y"]) }

            Line(
                text = (map["text"] as? String).orEmpty().trim(),
                confidence = number(map["confidence"]),
                box = Box(
                    left = xs.minOrNull() ?: 0.0,
                    top = ys.minOrNull() ?: 0.0,
                    right = xs.maxOrNull() ?: 0.0,
                    bottom = ys.maxOrNull() ?: 0.0,
                ),
            )
        }
    }

    /** The layout model can report one area twice with different labels. */
    private fun removeDuplicates(regions: List<Region>): List<Region> {
        val kept = mutableListOf<Region>()

        for (region in regions.sortedByDescending { it.score }) {
            val duplicate = kept.any { other -> other.box.iou(region.box) >= DUPLICATE_IOU }

            if (!duplicate) {
                kept += region
            }
        }

        return kept.sortedBy { it.order }
    }
}