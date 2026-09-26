package com.tactilelens.app

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.SystemClock
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.exp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * Offline page-layout detection with PP-DocLayoutV3 (ONNX Runtime).
 *
 * Finds text, display formulas, inline formulas, tables, figures, etc.,
 * and returns them in the model's predicted reading order.
 *
 * Pre/post-processing is ported from the reference
 * pp_doclayout_v3_onnx.py (PPDocLayoutV3ImageProcessor):
 * - RGB, resized to 800x800, scaled to [0, 1], no mean/std
 * - sigmoid scores, top-300 over (query, class), threshold
 * - cxcywh (normalized) -> xyxy in original-image pixels
 * - reading order from order_logits "votes"
 */
object PaddleOnnxLayoutDetector {
    private const val MODEL_ASSET =
        "paddle_onnx/PP-DocLayoutV3/pp_doclayoutv3_nomask.onnx"

    // Bump the version suffix if the model file ever changes,
    // so the cached copy in internal storage is refreshed.
    private const val MODEL_CACHE_FILE =
        "paddle_onnx_models/pp_doclayoutv3_nomask.v1.onnx"

    private const val INPUT_SIZE = 800
    private const val NUM_QUERIES = 300
    private const val NUM_CLASSES = 25
    private const val DEFAULT_THRESHOLD = 0.5f

    private const val MIN_THREADS = 1
    private const val MAX_THREADS = 8

    // PaddleX PP-DocLayoutV3 label list (alphabetical, 25 classes).
    // 5 = display_formula (own line), 15 = inline_formula (inside text).
    private val LABELS = arrayOf(
        "abstract",          // 0
        "algorithm",         // 1
        "aside_text",        // 2
        "chart",             // 3
        "content",           // 4
        "display_formula",   // 5
        "doc_title",         // 6
        "figure_title",      // 7
        "footer",            // 8
        "footer_image",      // 9
        "footnote",          // 10
        "formula_number",    // 11
        "header",            // 12
        "header_image",      // 13
        "image",             // 14
        "inline_formula",    // 15
        "number",            // 16
        "paragraph_title",   // 17
        "reference",         // 18
        "reference_content", // 19
        "seal",              // 20
        "table",             // 21
        "text",              // 22
        "vertical_text",     // 23
        "vision_footnote",   // 24
    )

    private val lock = Mutex()

    // Guarded by lock. The OrtEnvironment is a process-wide singleton
    // shared with other ONNX sessions, so it is never closed here.
    private var environment: OrtEnvironment? = null
    private var sessionOptions: OrtSession.SessionOptions? = null
    private var session: OrtSession? = null
    private var inputName: String = "pixel_values"
    private var loadedThreadCount = 0
    private var coldLoadTimeMs = 0L

    suspend fun initialize(
        context: Context,
        threadCount: Int,
    ): Map<String, Any?> = withContext(Dispatchers.Default) {
        val safeThreadCount = threadCount.coerceIn(MIN_THREADS, MAX_THREADS)

        lock.withLock {
            getOrCreateSessionLocked(context, safeThreadCount)

            mapOf(
                "success" to true,
                "loaded" to true,
                "thread_count" to safeThreadCount,
                "cold_load_time_ms" to coldLoadTimeMs,
            )
        }
    }

    suspend fun detectFile(
        context: Context,
        imagePath: String,
        threadCount: Int,
        threshold: Float = DEFAULT_THRESHOLD,
    ): Map<String, Any?> = withContext(Dispatchers.Default) {
        val normalizedPath = imagePath.trim()

        require(normalizedPath.isNotEmpty()) {
            "The image path is required."
        }

        val imageFile = File(normalizedPath)

        require(imageFile.isFile) {
            "The image does not exist: $normalizedPath"
        }

        val safeThreadCount = threadCount.coerceIn(MIN_THREADS, MAX_THREADS)
        val safeThreshold = threshold.coerceIn(0.05f, 0.95f)

        lock.withLock {
            val ortSession = getOrCreateSessionLocked(context, safeThreadCount)
            val env = checkNotNull(environment) {
                "ONNX Runtime environment is not available."
            }

            val preprocessStart = SystemClock.elapsedRealtime()
            val prepared = prepareInput(imageFile)
            val preprocessMs = SystemClock.elapsedRealtime() - preprocessStart

            val inferenceStart = SystemClock.elapsedRealtime()
            val raw = OnnxTensor.createTensor(
                env,
                prepared.pixels,
                longArrayOf(1, 3, INPUT_SIZE.toLong(), INPUT_SIZE.toLong()),
            ).use { input ->
                ortSession.run(mapOf(inputName to input)).use { outputs ->
                    RawOutputs(
                        logits = readFloats(
                            outputs, "logits", NUM_QUERIES * NUM_CLASSES,
                        ),
                        boxes = readFloats(
                            outputs, "pred_boxes", NUM_QUERIES * 4,
                        ),
                        orderLogits = readFloats(
                            outputs, "order_logits", NUM_QUERIES * NUM_QUERIES,
                        ),
                    )
                }
            }
            val inferenceMs = SystemClock.elapsedRealtime() - inferenceStart

            val postprocessStart = SystemClock.elapsedRealtime()
            val regions = postprocess(
                raw = raw,
                imageWidth = prepared.originalWidth,
                imageHeight = prepared.originalHeight,
                threshold = safeThreshold,
            )
            val postprocessMs = SystemClock.elapsedRealtime() - postprocessStart

            mapOf(
                "success" to true,
                "is_empty" to regions.isEmpty(),
                "regions" to regions.map { region -> region.toMap() },
                "region_count" to regions.size,
                "image_width" to prepared.originalWidth,
                "image_height" to prepared.originalHeight,
                "threshold" to safeThreshold.toDouble(),
                "preprocess_time_ms" to preprocessMs,
                "inference_time_ms" to inferenceMs,
                "postprocess_time_ms" to postprocessMs,
                "total_time_ms" to (preprocessMs + inferenceMs + postprocessMs),
                "cold_load_time_ms" to coldLoadTimeMs,
                "thread_count" to safeThreadCount,
            )
        }
    }

    suspend fun release() {
        withContext(Dispatchers.Default) {
            lock.withLock {
                closeSessionLocked()
            }
        }
    }

    // ------------------------------------------------------------------
    // Session management
    // ------------------------------------------------------------------

    /** Must only be called while holding [lock]. */
    private fun getOrCreateSessionLocked(
        context: Context,
        threadCount: Int,
    ): OrtSession {
        val current = session

        if (current != null && loadedThreadCount == threadCount) {
            return current
        }

        closeSessionLocked()

        val loadStart = SystemClock.elapsedRealtime()

        val modelFile = copyModelIfNeeded(context.applicationContext)
        val env = environment
            ?: OrtEnvironment.getEnvironment().also { environment = it }

        val options = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(threadCount)
            setOptimizationLevel(
                OrtSession.SessionOptions.OptLevel.ALL_OPT,
            )
        }

        val created = env.createSession(modelFile.absolutePath, options)

        inputName = created.inputNames.firstOrNull() ?: "pixel_values"
        sessionOptions = options
        session = created
        loadedThreadCount = threadCount
        coldLoadTimeMs = SystemClock.elapsedRealtime() - loadStart

        return created
    }

    /** Must only be called while holding [lock]. */
    private fun closeSessionLocked() {
        session?.close()
        session = null
        sessionOptions?.close()
        sessionOptions = null
        loadedThreadCount = 0
    }

    /**
     * Copies the model from APK assets to internal storage once, so ONNX
     * Runtime can load it from a file instead of one huge Java byte array
     * (which can cause OutOfMemoryError on phones).
     */
    private fun copyModelIfNeeded(context: Context): File {
        val target = File(context.filesDir, MODEL_CACHE_FILE)

        if (target.isFile && target.length() > 0L) {
            return target
        }

        target.parentFile?.mkdirs()

        val temporary = File(target.parentFile, "${target.name}.tmp")

        context.assets.open(MODEL_ASSET).use { input ->
            FileOutputStream(temporary).use { output ->
                input.copyTo(output, bufferSize = 1 shl 20)
            }
        }

        check(temporary.renameTo(target)) {
            "The layout model could not be prepared in internal storage."
        }

        return target
    }

    // ------------------------------------------------------------------
    // Preprocessing
    // ------------------------------------------------------------------

    private class PreparedInput(
        val pixels: FloatBuffer,
        val originalWidth: Int,
        val originalHeight: Int,
    )

    private fun prepareInput(imageFile: File): PreparedInput {
        val bounds = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(imageFile.absolutePath, bounds)

        val originalWidth = bounds.outWidth
        val originalHeight = bounds.outHeight

        require(originalWidth > 0 && originalHeight > 0) {
            "Android could not read the image size: ${imageFile.name}"
        }

        // Decode at reduced resolution when the photo is much larger than
        // 800x800. Boxes are normalized, so the original size is still used
        // for mapping results back.
        var sampleSize = 1
        while (
            originalWidth / (sampleSize * 2) >= INPUT_SIZE &&
            originalHeight / (sampleSize * 2) >= INPUT_SIZE
        ) {
            sampleSize *= 2
        }

        val decodeOptions = BitmapFactory.Options().apply {
            inSampleSize = sampleSize
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }

        val decoded = BitmapFactory.decodeFile(
            imageFile.absolutePath,
            decodeOptions,
        ) ?: throw IllegalArgumentException(
            "Android could not decode the image: ${imageFile.name}",
        )

        val resized = Bitmap.createScaledBitmap(
            decoded,
            INPUT_SIZE,
            INPUT_SIZE,
            true,
        )

        if (resized !== decoded) {
            decoded.recycle()
        }

        val planeSize = INPUT_SIZE * INPUT_SIZE
        val argb = IntArray(planeSize)
        resized.getPixels(argb, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)
        resized.recycle()

        val pixels = ByteBuffer
            .allocateDirect(3 * planeSize * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        val scale = 1f / 255f

        // NCHW, RGB, [0, 1]
        for (i in 0 until planeSize) {
            val color = argb[i]
            pixels.put(i, ((color shr 16) and 0xFF) * scale)
            pixels.put(planeSize + i, ((color shr 8) and 0xFF) * scale)
            pixels.put(2 * planeSize + i, (color and 0xFF) * scale)
        }

        pixels.rewind()

        return PreparedInput(pixels, originalWidth, originalHeight)
    }

    // ------------------------------------------------------------------
    // Postprocessing
    // ------------------------------------------------------------------

    private class RawOutputs(
        val logits: FloatArray,
        val boxes: FloatArray,
        val orderLogits: FloatArray,
    )

    private class LayoutRegion(
        val order: Int,
        val labelId: Int,
        val label: String,
        val category: String,
        val score: Float,
        val left: Float,
        val top: Float,
        val right: Float,
        val bottom: Float,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "order" to order,
            "label_id" to labelId,
            "label" to label,
            "category" to category,
            "score" to score.toDouble(),
            "box" to mapOf(
                "left" to left.toDouble(),
                "top" to top.toDouble(),
                "right" to right.toDouble(),
                "bottom" to bottom.toDouble(),
            ),
        )
    }

    private fun readFloats(
        outputs: OrtSession.Result,
        name: String,
        expectedSize: Int,
    ): FloatArray {
        val value = outputs.get(name).orElseThrow {
            IllegalStateException("The layout model has no output named '$name'.")
        }

        val tensor = value as? OnnxTensor
            ?: throw IllegalStateException("Layout output '$name' is not a tensor.")

        val buffer = tensor.floatBuffer
        val array = FloatArray(buffer.remaining())
        buffer.get(array)

        check(array.size >= expectedSize) {
            "Layout output '$name' has ${array.size} values; expected $expectedSize."
        }

        return array
    }

    private fun postprocess(
        raw: RawOutputs,
        imageWidth: Int,
        imageHeight: Int,
        threshold: Float,
    ): List<LayoutRegion> {
        val orderRanks = computeOrderRanks(raw.orderLogits)

        val totalScores = NUM_QUERIES * NUM_CLASSES
        val scores = FloatArray(totalScores) { index ->
            sigmoid(raw.logits[index]).toFloat()
        }

        // Equivalent to the reference: top-300 over the flattened
        // (query, class) grid, then keep scores >= threshold.
        val selected = (0 until totalScores)
            .filter { index -> scores[index] >= threshold }
            .sortedByDescending { index -> scores[index] }
            .take(NUM_QUERIES)

        val width = imageWidth.toFloat()
        val height = imageHeight.toFloat()

        return selected
            .map { flatIndex ->
                val query = flatIndex / NUM_CLASSES
                val labelId = flatIndex % NUM_CLASSES

                val centerX = raw.boxes[query * 4]
                val centerY = raw.boxes[query * 4 + 1]
                val boxWidth = raw.boxes[query * 4 + 2]
                val boxHeight = raw.boxes[query * 4 + 3]

                LayoutRegion(
                    order = orderRanks[query],
                    labelId = labelId,
                    label = LABELS.getOrElse(labelId) { labelId.toString() },
                    category = categoryFor(labelId),
                    score = scores[flatIndex],
                    left = ((centerX - boxWidth / 2f) * width).coerceIn(0f, width),
                    top = ((centerY - boxHeight / 2f) * height).coerceIn(0f, height),
                    right = ((centerX + boxWidth / 2f) * width).coerceIn(0f, width),
                    bottom = ((centerY + boxHeight / 2f) * height).coerceIn(0f, height),
                )
            }
            .sortedBy { region -> region.order } // stable, like the reference
    }

    /**
     * Port of get_order_seqs():
     * votes[j] = sum_{i<j} s[i][j] + sum_{i>j} (1 - s[j][i])
     * then rank = position of j when sorted by votes (stable).
     */
    private fun computeOrderRanks(orderLogits: FloatArray): IntArray {
        val n = NUM_QUERIES
        val votes = DoubleArray(n)

        for (i in 0 until n) {
            for (j in 0 until n) {
                if (j > i) {
                    votes[j] += sigmoid(orderLogits[i * n + j])
                } else if (j < i) {
                    votes[j] += 1.0 - sigmoid(orderLogits[j * n + i])
                }
            }
        }

        val pointers = (0 until n).sortedBy { index -> votes[index] }
        val ranks = IntArray(n)

        pointers.forEachIndexed { rank, query ->
            ranks[query] = rank
        }

        return ranks
    }

    private fun categoryFor(labelId: Int): String =
        when (LABELS.getOrNull(labelId)) {
            "display_formula" -> "formula_display"
            "inline_formula" -> "formula_inline"
            "formula_number" -> "formula_number"
            "table" -> "table"
            "image", "chart", "seal", "header_image", "footer_image" -> "figure"
            else -> "text"
        }

    private fun sigmoid(value: Float): Double =
        1.0 / (1.0 + exp(-value.toDouble()))
}
