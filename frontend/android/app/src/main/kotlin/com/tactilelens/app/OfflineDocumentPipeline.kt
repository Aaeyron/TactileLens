package com.tactilelens.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.SystemClock
import android.util.Log
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
    private const val TAG = "TactileLensPipeline"
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

    // ...unless every OCR piece is short (numerators, denominators, numbers):
    // an equation with several fractions is read by OCR as many small
    // pieces, e.g. "x-4 | 2 | x | 5 | 1 | 10" for (x-4)/2 - x/5 = 1/10.
    private const val MAX_SHORT_LINE_CHARACTERS = 12
    private const val MAX_SHORT_FALLBACK_LINES = 12

    // Longest OCR piece that may be attached to a formula box ("= 6", "+ 2x").
    private const val MAX_ATTACHED_CHARACTERS = 16

        // Item labels in front of an equation: "a.", "b)", "(c)", "1.", "12)".
        private val LIST_MARKER =
        Regex("""^(\(?[A-Za-z][.)]\s*|\(?\d{1,3}[.)](?:\s+|$))""")

    private val LATEX_COMMAND = Regex("""\\([A-Za-z]+)""")

    private val EDGE_SPACING_START = Regex("""^(?:\\[ ,;:!]|\\q?quad|\s)+""")
    private val EDGE_SPACING_END = Regex("""(?:\\[ ,;:!]|\\q?quad|\s)+$""")

    private val EMPTY_WRAPPER =
        Regex("""\\(?:mathrm|text|mathbf|mathit|operatorname)\s*\{\s*\}""")

    // Real LaTeX commands the formula model uses for algebra. Anything else
    // (e.g. a hallucinated "\lefted{...}") is unwrapped to its content.
    private val KNOWN_LATEX_COMMANDS = setOf(
        "frac", "dfrac", "tfrac", "sqrt", "left", "right",
        "big", "Big", "bigl", "bigr", "Bigl", "Bigr",
        "text", "textrm", "mathrm", "mathbf", "mathit", "operatorname",
        "mathbb", "mathcal", "boldsymbol", "displaystyle", "textstyle",
        "times", "div", "cdot", "cdots", "ldots", "dots", "pm", "mp",
        "leq", "geq", "le", "ge", "neq", "ne", "approx", "equiv", "sim",
        "lt", "gt", "infty", "circ", "degree", "prime", "angle",
        "alpha", "beta", "gamma", "delta", "epsilon", "varepsilon",
        "theta", "lambda", "mu", "pi", "rho", "sigma", "tau", "phi", "omega",
        "Delta", "Sigma", "Pi", "Omega",
        "sum", "prod", "int", "lim", "log", "ln", "exp",
        "sin", "cos", "tan", "sec", "csc", "cot",
        "quad", "qquad", "overline", "underline", "hat", "bar", "vec",
        "in", "notin", "subset", "cup", "cap", "emptyset",
        "to", "rightarrow", "Rightarrow", "leftarrow", "Leftarrow",
        "leftrightarrow", "Leftrightarrow", "mid", "vert", "lvert", "rvert",
        "lbrace", "rbrace", "langle", "rangle",
        "lfloor", "rfloor", "lceil", "rceil",
        "begin", "end", "boxed", "cases", "array",
        "longrightarrow", "Longrightarrow", "implies", "iff",
        "therefore", "because",
    )

    // A formula model stuck in a loop repeats itself: "0000000000..." or
    // "{1}{1}{1}{1}...". Such output is rejected, never shown.
    private val RUNAWAY_OUTPUT = Regex("""(.)\1{15,}|(.{2,8})\2{6,}""")

    
        // Longer than any single printed algebra line should ever be.
    private const val MAX_LATEX_LENGTH = 600

    // Multi-row output: \begin{array}{c} row \\ row \end{array} (also
    // aligned / gathered / cases / split).
    private val MULTI_ROW_ENVIRONMENT = Regex(
        """\\begin\{(array|aligned|gathered|cases|split)\}(\{[^\{\}]*\})?(.*)\\end\{\1\}""",
        RegexOption.DOT_MATCHES_ALL,
    )

    // Command names that lost their backslash mean the model broke down
    // ("mathbf x88rmathrm{...}").
    private val BARE_COMMAND_WORD = Regex(
        """(?<![\\A-Za-z])(displaystyle|mathbf|mathrm|mathit|operatorname|frac|sqrt|pm|mp|bf|begin|end|array|boxed|times|div|cdot|left|right)(?![A-Za-z])""",
    )

    private val DISPLAY_STYLE = Regex("""\\?(?:displaystyle|textstyle)(?![A-Za-z])""")

    private val LEFT_RIGHT = Regex("""\\(left|right)(?![A-Za-z])""")

    private val LEFT_RIGHT_WITHOUT_DELIMITER =
        Regex("""\\(left|right)(?![A-Za-z])(?!\s*[.()\[\]|\\])""")

    private val LEFT_RIGHT_TOKEN = Regex("""\\(?:left|right)(?![A-Za-z])\s*\.?""")

    // Never split one formula box into more rows than this.
    private const val MAX_FORMULA_ROWS = 8

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

        // Diagnostics: view with  adb logcat -d -s TactileLensPipeline
        Log.d(
            TAG,
            "Layout regions: " + regions.joinToString(" | ") { region ->
                "${region.label} ${"%.2f".format(region.score)} ${region.box.describe()}"
            },
        )
        Log.d(
            TAG,
            "OCR lines: " + lines.joinToString(" | ") { line ->
                "\"${line.text}\" ${line.box.describe()}"
            },
        )

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

        // Layout boxes sometimes cover only part of an equation (e.g. just
        // the fraction in "3x/10 = 6"). Grow each formula box over short,
        // math-looking OCR pieces on the same row right next to it.
        val formulaBoxes = HashMap<Region, Box>()

        for (formula in displayFormulas) {
            formulaBoxes[formula] = expandFormulaBox(formula.box, lines)
        }

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
                formulaBoxes.getValue(formula).intersection(line.box) / lineArea >=
                    LINE_IN_REGION
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
                val formulaBlocks = recognizeFormulaBlocks(
                    context = context,
                    imagePath = imagePath,
                    threadCount = threadCount,
                    label = region.label,
                    score = region.score,
                    box = formulaBoxes[region] ?: region.box,
                    lines = lines,
                )
                stats.formulaMs += SystemClock.elapsedRealtime() - formulaStart
                stats.formulaCount += formulaBlocks.count { it["type"] == "formula" }

                // A multi-row derivation becomes one block per row, in order.
                formulaBlocks.forEachIndexed { row, block ->
                    pending += PendingBlock(
                        index + row * 0.01,
                        region.box.top + row,
                        block,
                    )
                }
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

                Log.d(
            TAG,
            "Blocks: " + blocks.joinToString(" | ") { block ->
                "${block["type"]}/${block["source"]}: ${block["content"]}"
            },
        )

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

        val allShortPieces = lines.all { it.text.length <= MAX_SHORT_LINE_CHARACTERS }
        val lineLimit = if (allShortPieces) MAX_SHORT_FALLBACK_LINES else MAX_FALLBACK_LINES

        if (lines.size > lineLimit || !looksLikeMath(lines)) {
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
            lines = lines,
        )
        stats.formulaMs += SystemClock.elapsedRealtime() - formulaStart

        val latex = formula["latex"] as? String ?: ""

             if (latex.isBlank() || !isUsableFormula(formula) || looksBroken(latex)) {
            Log.d(
                TAG,
                "Math fallback rejected (reached_end=${formula["reached_end"]}): " +
                    "${formula["raw_latex"]}",
            )
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

        /**
     * Reads one formula region.
     * - Multi-row output (\begin{array} ... \\ ... \end{array}) is unwrapped
     *   into one equation per row.
     * - If the output failed or looks broken, the region is split into rows
     *   at the blank gaps in the image (fraction bars stay with their
     *   numerator/denominator) and each row is read on its own.
     * - A row that still fails falls back to its OCR text.
     * Garbage is never shown.
     */
    private suspend fun recognizeFormulaBlocks(
        context: Context,
        imagePath: String,
        threadCount: Int,
        label: String,
        score: Double,
        box: Box,
        lines: List<Line>,
    ): List<Map<String, Any?>> {
        val whole = recognizeFormulaBlock(
            context = context,
            imagePath = imagePath,
            threadCount = threadCount,
            label = label,
            score = score,
            box = box,
            lines = lines,
        )

        if (isUsableFormula(whole)) {
            val latex = whole["latex"] as? String ?: ""
            val latexRows = splitLatexRows(latex)

            if (latexRows == null) {
                if (!looksBroken(latex)) {
                    return listOf(whole)
                }
                        } else if (latexRows.isNotEmpty()) {
                if (latexRows.none { looksBroken(it) }) {
                    return latexRows.map { row ->
                        whole + mapOf("content" to row, "latex" to row)
                    }
                }

                // Some rows are good, some broken: keep the good rows exactly
                // as the model read them, and show the OCR text of the
                // matching image row for each broken one.
                val imageRows = splitIntoRows(imagePath, box)

                if (imageRows.size == latexRows.size) {
                    Log.d(TAG, "Formula ${box.describe()}: kept good rows, OCR for broken rows.")

                    return latexRows.mapIndexed { index, row ->
                        val rowBox = imageRows[index]

                        if (!looksBroken(row)) {
                            whole + mapOf(
                                "content" to row,
                                "latex" to row,
                                "box" to rowBox.toMap(),
                            )
                        } else {
                            ocrFallbackBlock(rowBox, lines, label, score)
                                ?: emptyFormula(rowBox, label, score)
                        }
                    }
                }
            }
        }

        val rows = splitIntoRows(imagePath, box)

        Log.d(TAG, "Formula ${box.describe()} unusable; split into ${rows.size} row(s).")

        if (rows.size < 2) {
            return listOf(
                ocrFallbackBlock(box, lines, label, score) ?: emptyFormula(box, label, score),
            )
        }

        return rows.map { row ->
            val rowBlock = recognizeFormulaBlock(
                context = context,
                imagePath = imagePath,
                threadCount = threadCount,
                label = label,
                score = score,
                box = row,
                lines = lines,
            )
            val rowLatex = rowBlock["latex"] as? String ?: ""

            if (isUsableFormula(rowBlock) && !looksBroken(rowLatex)) {
                rowBlock
            } else {
                ocrFallbackBlock(row, lines, label, score) ?: emptyFormula(row, label, score)
            }
        }
    }

    /** True when command names appear without their backslash. */
    private fun looksBroken(latex: String): Boolean =
        BARE_COMMAND_WORD.containsMatchIn(latex)

    /**
     * If [latex] is a multi-row environment, returns its cleaned rows;
     * otherwise null.
     */
    private fun splitLatexRows(latex: String): List<String>? {
        val match = MULTI_ROW_ENVIRONMENT.find(latex) ?: return null

        return splitTopLevelRows(match.groupValues[3])
            .map { row -> cleanRow(row) }
            .filter { row -> row.isNotBlank() }
    }

    /** Splits on "\\" that is not inside braces. */
    private fun splitTopLevelRows(body: String): List<String> {
        val rows = mutableListOf<String>()
        var depth = 0
        var start = 0
        var index = 0

        while (index < body.length) {
            val character = body[index]

            if (character == '\\' && index + 1 < body.length) {
                if (body[index + 1] == '\\' && depth == 0) {
                    rows += body.substring(start, index)
                    index += 2
                    start = index
                    continue
                }

                // Skip the escaped character ("\{", "\frac", ...).
                index += 2
                continue
            }

            when (character) {
                '{' -> depth++
                '}' -> depth--
            }

            index++
        }

        rows += body.substring(start)

        return rows
    }

    /** Removes alignment marks and redundant outer braces, then cleans. */
    private fun cleanRow(input: String): String {
        var row = input.replace("&", "").trim()

        while (row.startsWith("{")) {
            val group = readBracedGroup(row, 0) ?: break

            if (group.second != row.length) {
                break
            }

            row = group.first.trim()
        }

        return cleanLatex(row)
    }

    /** Rejects failed model output: unfinished, looping, or absurdly long. */
    private fun isUsableFormula(block: Map<String, Any?>): Boolean {
        val latex = block["latex"] as? String ?: return false

        return latex.isNotBlank() &&
            block["error"] == null &&
            block["reached_end"] == true &&
            latex.length <= MAX_LATEX_LENGTH &&
            !RUNAWAY_OUTPUT.containsMatchIn(latex)
    }

    /** OCR text of the lines inside [box], used when the formula model fails. */
    private fun ocrFallbackBlock(
        box: Box,
        lines: List<Line>,
        label: String,
        score: Double,
    ): Map<String, Any?>? {
        val inside = lines.filter { line ->
            line.text.isNotBlank() &&
                box.intersection(line.box) / max(line.box.area, 1.0) >= LINE_IN_REGION
        }

        if (inside.isEmpty()) {
            return null
        }

        return textBlock("text", label, score, box, inside, 0) + mapOf(
            "source" to "ocr_fallback",
            "needs_review" to true,
        )
    }

    /** Empty formula block; the Dart side skips blocks without content. */
    private fun emptyFormula(box: Box, label: String, score: Double): Map<String, Any?> =
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
        )

    /**
     * Splits a formula box into rows using the blank horizontal gaps in the
     * image. A thin band (a fraction bar) is merged with the bands above and
     * below it, and bands separated by only a hairline gap are joined, so a
     * fraction always stays in one row.
     */
    private fun splitIntoRows(imagePath: String, box: Box): List<Box> {
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }

        val full = BitmapFactory.decodeFile(imagePath, options) ?: return listOf(box)

        try {
            val left = box.left.toInt().coerceIn(0, full.width - 1)
            val top = box.top.toInt().coerceIn(0, full.height - 1)
            val right = box.right.toInt().coerceIn(left + 1, full.width)
            val bottom = box.bottom.toInt().coerceIn(top + 1, full.height)
            val width = right - left
            val height = bottom - top

            if (width < 8 || height < 16) {
                return listOf(box)
            }

            val pixels = IntArray(width * height)
            full.getPixels(pixels, 0, width, left, top, width, height)

            val gray = IntArray(pixels.size)
            var low = 255
            var high = 0

            for (i in pixels.indices) {
                val color = pixels[i]
                val value = (
                    ((color shr 16) and 0xFF) * 299 +
                        ((color shr 8) and 0xFF) * 587 +
                        (color and 0xFF) * 114
                    ) / 1000
                gray[i] = value
                if (value < low) low = value
                if (value > high) high = value
            }

            if (high - low < 40) {
                return listOf(box)
            }

            val threshold = low + (high - low) * 0.6
            val minimumInk = max(2, width / 300)

            val inkRow = BooleanArray(height) { y ->
                var count = 0
                val rowStart = y * width
                for (x in 0 until width) {
                    if (gray[rowStart + x] < threshold) count++
                }
                count >= minimumInk
            }

            // Continuous runs of ink rows: [start, endExclusive].
            var bands = mutableListOf<IntArray>()
            var y = 0

            while (y < height) {
                if (!inkRow[y]) {
                    y++
                    continue
                }

                val start = y
                while (y < height && inkRow[y]) y++
                bands.add(intArrayOf(start, y))
            }

            if (bands.size < 2) {
                return listOf(box)
            }

            val heights = bands.map { it[1] - it[0] }.filter { it >= 3 }.sorted()

            if (heights.isEmpty()) {
                return listOf(box)
            }

            val median = heights[heights.size / 2].toDouble()
            val hairline = max(2, (median * 0.15).toInt())

            // 1. Join bands separated by only a hairline gap.
            val joined = mutableListOf<IntArray>()

            for (band in bands) {
                val previous = joined.lastOrNull()

                if (previous != null && band[0] - previous[1] < hairline) {
                    previous[1] = band[1]
                } else {
                    joined.add(intArrayOf(band[0], band[1]))
                }
            }

            bands = joined

            // 2. A thin band (fraction bar) joins the bands above and below.
            var changed = true

            while (changed && bands.size > 1) {
                changed = false

                for (i in bands.indices) {
                    if (bands[i][1] - bands[i][0] >= median * 0.35) {
                        continue
                    }

                    val from = if (i > 0) i - 1 else i
                    val to = if (i + 1 < bands.size) i + 1 else i
                    val merged = intArrayOf(bands[from][0], bands[to][1])

                    val rebuilt = mutableListOf<IntArray>()
                    for (k in bands.indices) {
                        when {
                            k == from -> rebuilt.add(merged)
                            k in (from + 1)..to -> Unit
                            else -> rebuilt.add(bands[k])
                        }
                    }

                    bands = rebuilt
                    changed = true
                    break
                }
            }

            val rows = bands.filter { it[1] - it[0] >= median * 0.5 }

            if (rows.size < 2 || rows.size > MAX_FORMULA_ROWS) {
                return listOf(box)
            }

            return rows.map { band ->
                Box(
                    left = box.left,
                    top = (top + band[0] - 2).toDouble(),
                    right = box.right,
                    bottom = (top + band[1] + 2).toDouble(),
                )
            }
        } finally {
            full.recycle()
        }
    }

        private suspend fun recognizeFormulaBlock(
        context: Context,
        imagePath: String,
        threadCount: Int,
        label: String,
        score: Double,
        box: Box,
        lines: List<Line>,
    ): Map<String, Any?> {
        // "b. g(x) = ..." -> read only "g(x) = ..." and keep "b." as text.
        val split = splitListLabel(box, lines)

        return try {
            val result = PaddleOnnxFormulaRecognizer.recognizeFile(
                context = context,
                imagePath = imagePath,
                threadCount = threadCount,
                box = split.box.toFloatArray(),
            )

            val cleaned = cleanLatex(result["latex"] as? String ?: "")
            val latex = if (cleaned.isNotBlank() && split.label != null) {
                "\\text{${split.label}}\\ $cleaned"
            } else {
                cleaned
            }
            val reachedEnd = result["reached_end"] == true

            mapOf(
                "type" to "formula",
                "label" to label,
                "content" to latex,
                "latex" to latex,
                "raw_latex" to result["latex"],
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

    private class LabelledBox(val box: Box, val label: String?)

    /**
     * If the equation row starts with an item label ("b.", "1.", "(c)"),
     * returns a box that starts after the label, plus the label text.
     * The label position is estimated from its share of the OCR line.
     */
    private fun splitListLabel(box: Box, lines: List<Line>): LabelledBox {
        val height = max(box.bottom - box.top, 1.0)

        val first = lines
            .filter { line ->
                val centerY = (line.box.top + line.box.bottom) / 2.0
                line.text.isNotBlank() &&
                    box.intersection(line.box) > 0.0 &&
                    centerY >= box.top && centerY <= box.bottom
            }
            .minByOrNull { it.box.left }
            ?: return LabelledBox(box, null)

        val marker = LIST_MARKER.find(first.text) ?: return LabelledBox(box, null)

        // Only a label if it sits at the left edge of the equation.
        if (first.box.left > box.left + height) {
            return LabelledBox(box, null)
        }

        val lineWidth = first.box.right - first.box.left
        val cut = if (marker.value.length >= first.text.length) {
            first.box.right
        } else {
            first.box.left + lineWidth * marker.value.length / first.text.length
        } + height * 0.15

        // Never cut away (almost) the whole equation.
        if (cut >= box.right - height * 0.5) {
            return LabelledBox(box, null)
        }

        return LabelledBox(
            box = Box(max(box.left, cut), box.top, box.right, box.bottom),
            label = marker.value.trim(),
        )
    }

        /**
     * Makes the model's LaTeX valid and clean enough to draw:
     * unwraps unknown/hallucinated commands, removes display-style
     * commands, fixes unbalanced braces and \left/\right pairs, and removes
     * stray spacing/punctuation at the ends.
     */
    private fun cleanLatex(input: String): String {
        var latex = unwrapUnknownCommands(input.trim())
        latex = DISPLAY_STYLE.replace(latex, "")
        latex = latex.replace("~", " ")
        latex = balanceBraces(latex)
        latex = fixLeftRight(latex)
        latex = EMPTY_WRAPPER.replace(latex, "")
        latex = EDGE_SPACING_START.replace(latex, "")
        latex = EDGE_SPACING_END.replace(latex, "")
        latex = latex.trimEnd('.', ',', ';', ':').trim()
        latex = EDGE_SPACING_END.replace(latex, "")
        return latex.trim()
    }

    /**
     * "\right" with nothing after it becomes "\right." (valid LaTeX).
     * If \left and \right counts still don't match, all of them are removed
     * (the brackets themselves stay), so the formula can always be drawn.
     */
    private fun fixLeftRight(input: String): String {
        var latex = LEFT_RIGHT_WITHOUT_DELIMITER.replace(input) { match ->
            "\\${match.groupValues[1]}."
        }

        val sides = LEFT_RIGHT.findAll(latex).map { it.groupValues[1] }.toList()

        if (sides.count { it == "left" } != sides.count { it == "right" }) {
            latex = LEFT_RIGHT_TOKEN.replace(latex, "")
        }

        return latex
    }

    private fun unwrapUnknownCommands(input: String): String {
        var text = input
        var searchFrom = 0

        while (searchFrom < text.length) {
            val match = LATEX_COMMAND.find(text, searchFrom) ?: break
            val start = match.range.first

            // "\\x" (line break + x) is not a command.
            val escaped = start > 0 && text[start - 1] == '\\'

            if (escaped || match.groupValues[1] in KNOWN_LATEX_COMMANDS) {
                searchFrom = match.range.last + 1
                continue
            }

            var argumentStart = match.range.last + 1

            while (argumentStart < text.length && text[argumentStart] == ' ') {
                argumentStart++
            }

            val argument = readBracedGroup(text, argumentStart)

            text = if (argument != null) {
                text.substring(0, start) + argument.first + text.substring(argument.second)
            } else {
                text.substring(0, start) + text.substring(match.range.last + 1)
            }

            searchFrom = start
        }

        return text
    }

    /** Drops unmatched '}' and closes any '{' left open. */
    private fun balanceBraces(input: String): String {
        val output = StringBuilder()
        var depth = 0
        var index = 0

        while (index < input.length) {
            val character = input[index]

            if (character == '\\' && index + 1 < input.length) {
                output.append(character).append(input[index + 1])
                index += 2
                continue
            }

            when (character) {
                '{' -> {
                    depth++
                    output.append(character)
                }
                '}' -> if (depth > 0) {
                    depth--
                    output.append(character)
                }
                else -> output.append(character)
            }

            index++
        }

        repeat(depth) { output.append('}') }

        return output.toString()
    }

    /** Returns (inner text, index after the closing brace), or null. */
    private fun readBracedGroup(text: String, start: Int): Pair<String, Int>? {
        if (start >= text.length || text[start] != '{') {
            return null
        }

        var depth = 0

        for (index in start until text.length) {
            when (text[index]) {
                '{' -> depth++
                '}' -> {
                    depth--

                    if (depth == 0) {
                        return text.substring(start + 1, index) to (index + 1)
                    }
                }
            }
        }

        return null
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
     * Groups stray OCR lines that belong together: stacked rows (a
     * fraction's numerator/denominator, paragraph lines) and pieces on the
     * same row close together (e.g. "3x/10" and "= 6"). A group with real
     * words is never merged with a group without them, so a sentence is
     * not swallowed into an equation.
     */
    private fun groupStackedLines(lines: List<Line>): List<List<Line>> {
        val groups = lines
            .sortedBy { it.box.top }
            .map { mutableListOf(it) }
            .toMutableList()

        var merged = true

        while (merged) {
            merged = false

            search@ for (i in groups.indices) {
                for (j in i + 1 until groups.size) {
                    val first = groups[i]
                    val second = groups[j]

                    if (isWordy(first) != isWordy(second)) {
                        continue
                    }

                    if (areNeighbors(unionOf(first), unionOf(second))) {
                        first.addAll(second)
                        groups.removeAt(j)
                        merged = true
                        break@search
                    }
                }
            }
        }

        return groups
    }

    private fun isWordy(lines: List<Line>): Boolean =
        REAL_WORD.findAll(lines.joinToString(" ") { it.text }).count() > 1

    private fun areNeighbors(a: Box, b: Box): Boolean {
        val lineHeight = max(min(a.bottom - a.top, b.bottom - b.top), 1.0)
        val horizontalOverlap = min(a.right, b.right) - max(a.left, b.left)
        val verticalOverlap = min(a.bottom, b.bottom) - max(a.top, b.top)
        val verticalGap = max(a.top, b.top) - min(a.bottom, b.bottom)
        val horizontalGap = max(a.left, b.left) - min(a.right, b.right)

        // Stacked: numerator over denominator, or consecutive lines.
        if (horizontalOverlap > 0.0 && verticalGap < lineHeight * 1.2) {
            return true
        }

        // Same row, close together: "3x/10" next to "= 6".
        return verticalOverlap > 0.0 && horizontalGap < lineHeight * 1.5
    }

        /**
     * Grows a formula box so it covers the whole equation:
     * - an OCR line on the same row that OVERLAPS the box is absorbed
     *   completely (e.g. layout boxed only "√5" but OCR read the whole
     *   row "b. g(x) = √5x − 12"), unless that line is a sentence;
     * - a short math-looking piece right NEXT to the box is absorbed too
     *   (e.g. "= 6" beside a fraction).
     */
    private fun expandFormulaBox(start: Box, lines: List<Line>): Box {
        var box = start
        var changed = true

        while (changed) {
            changed = false

            for (line in lines) {
                if (line.text.isBlank()) {
                    continue
                }

                // Already fully inside the box.
                if (box.intersection(line.box) >= line.box.area * 0.9) {
                    continue
                }

                // Never pull a sentence into an equation.
                if (REAL_WORD.findAll(line.text).count() > 1) {
                    continue
                }

                val height = max(box.bottom - box.top, 1.0)
                val lineCenterY = (line.box.top + line.box.bottom) / 2.0
                val sameRow = lineCenterY >= box.top - height * 0.25 &&
                    lineCenterY <= box.bottom + height * 0.25

                if (!sameRow) {
                    continue
                }

                val overlaps = box.intersection(line.box) > 0.0

                val attach = if (overlaps) {
                    true
                } else {
                    val gap = max(line.box.left - box.right, box.left - line.box.right)
                    line.text.length <= MAX_ATTACHED_CHARACTERS &&
                        looksLikeMath(listOf(line)) &&
                        gap < height * 1.5
                }

                if (attach) {
                    box = box.union(line.box)
                    changed = true
                }
            }
        }

        return box
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

        fun describe(): String =
            "[${left.toInt()},${top.toInt()},${right.toInt()},${bottom.toInt()}]"

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