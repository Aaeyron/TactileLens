package com.tactilelens.app

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.SystemClock
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONObject

/**
 * Offline math formula recognition with PP-FormulaNet_plus-S (ONNX Runtime).
 *
 * Image of ONE formula -> LaTeX, e.g. "\left(\sqrt{2}\right)^{2}=2".
 *
 * The ONNX graph contains the full autoregressive decode loop, so one
 * session.run() returns every token id. Pre/post-processing follow
 * PaddleX's UniMERNetImgDecode, UniMERNetTestTransform,
 * UniMERNetImageFormat and UniMERNetDecode (verified on the PC:
 * byte-level decode == Hugging Face tokenizer, "RESULT: MATCH").
 */
object PaddleOnnxFormulaRecognizer {
    private const val MODEL_ASSET =
        "paddle_onnx/PP-FormulaNet_plus-S/pp-formulanet_plus-s.onnx"

    private const val VOCAB_ASSET =
        "paddle_onnx/PP-FormulaNet_plus-S/pp-formulanet_vocab.json"

    // Bump the version suffix if the model file ever changes.
    private const val MODEL_CACHE_FILE =
        "paddle_onnx_models/pp-formulanet_plus-s.v1.onnx"

    private const val INPUT_SIZE = 384
    private const val MEAN = 0.7931f
    private const val STD = 0.1738f
    private const val EOS_ID = 2L

    private const val MIN_THREADS = 1
    private const val MAX_THREADS = 8

    private val lock = Mutex()

    // Guarded by lock. The OrtEnvironment is a process-wide singleton
    // shared with other ONNX sessions, so it is never closed here.
    private var environment: OrtEnvironment? = null
    private var sessionOptions: OrtSession.SessionOptions? = null
    private var session: OrtSession? = null
    private var inputName: String = "x"
    private var loadedThreadCount = 0
    private var coldLoadTimeMs = 0L

    private var vocabulary: Array<String>? = null
    private var specialIds: Set<Int> = emptySet()

    private val byteDecoder: Map<Char, Int> by lazy { buildByteDecoder() }

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

    /**
     * Recognizes one formula.
     *
     * @param box optional [left, top, right, bottom] in original-image
     *   pixels (e.g. a display_formula region from the layout detector).
     *   When null, the whole image is treated as one formula.
     */
    suspend fun recognizeFile(
        context: Context,
        imagePath: String,
        threadCount: Int,
        box: FloatArray? = null,
    ): Map<String, Any?> = withContext(Dispatchers.Default) {
        val normalizedPath = imagePath.trim()

        require(normalizedPath.isNotEmpty()) {
            "The image path is required."
        }

        val imageFile = File(normalizedPath)

        require(imageFile.isFile) {
            "The image does not exist: $normalizedPath"
        }

        require(box == null || box.size == 4) {
            "The formula box must be [left, top, right, bottom]."
        }

        val safeThreadCount = threadCount.coerceIn(MIN_THREADS, MAX_THREADS)

        lock.withLock {
            val ortSession = getOrCreateSessionLocked(context, safeThreadCount)
            val env = checkNotNull(environment) {
                "ONNX Runtime environment is not available."
            }

            val preprocessStart = SystemClock.elapsedRealtime()
            val source = decodeImage(imageFile, box)
            val pixels = try {
                preprocess(source)
            } finally {
                source.recycle()
            }
            val preprocessMs = SystemClock.elapsedRealtime() - preprocessStart

            val inferenceStart = SystemClock.elapsedRealtime()
            val tokenIds = OnnxTensor.createTensor(
                env,
                pixels,
                longArrayOf(1, 1, INPUT_SIZE.toLong(), INPUT_SIZE.toLong()),
            ).use { input ->
                ortSession.run(mapOf(inputName to input)).use { outputs ->
                    readTokenIds(outputs)
                }
            }
            val inferenceMs = SystemClock.elapsedRealtime() - inferenceStart

            val decodeStart = SystemClock.elapsedRealtime()
            val decoded = decodeTokens(tokenIds)
            val latex = normalizeLatex(decoded.text)
            val decodeMs = SystemClock.elapsedRealtime() - decodeStart

            mapOf(
                "success" to latex.isNotBlank(),
                "latex" to latex,
                "raw_latex" to decoded.text,
                "token_count" to decoded.tokenCount,
                "reached_end" to decoded.reachedEnd,
                "preprocess_time_ms" to preprocessMs,
                "inference_time_ms" to inferenceMs,
                "decode_time_ms" to decodeMs,
                "total_time_ms" to (preprocessMs + inferenceMs + decodeMs),
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
    // Session + vocabulary management
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

        val appContext = context.applicationContext

        if (vocabulary == null) {
            loadVocabulary(appContext)
        }

        val modelFile = copyModelIfNeeded(appContext)
        val env = environment
            ?: OrtEnvironment.getEnvironment().also { environment = it }

        val options = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(threadCount)
            setOptimizationLevel(
                OrtSession.SessionOptions.OptLevel.ALL_OPT,
            )
        }

        val created = env.createSession(modelFile.absolutePath, options)

        inputName = created.inputNames.firstOrNull() ?: "x"
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

    private fun loadVocabulary(context: Context) {
        val text = context.assets.open(VOCAB_ASSET).use { stream ->
            stream.readBytes().toString(Charsets.UTF_8)
        }

        val json = JSONObject(text)
        val tokens = json.getJSONArray("tokens")
        val special = json.getJSONArray("special_ids")

        vocabulary = Array(tokens.length()) { index -> tokens.getString(index) }
        specialIds = (0 until special.length()).map { index -> special.getInt(index) }.toSet()
    }

    /**
     * Copies the model from APK assets to internal storage once, so ONNX
     * Runtime loads it from a file instead of one huge Java byte array.
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
            "The formula model could not be prepared in internal storage."
        }

        return target
    }

    // ------------------------------------------------------------------
    // Preprocessing (UniMERNetImgDecode + UniMERNetTestTransform)
    // ------------------------------------------------------------------

    /** Decodes the image, optionally cropping to [box] with a small margin. */
    private fun decodeImage(imageFile: File, box: FloatArray?): Bitmap {
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }

        val full = BitmapFactory.decodeFile(imageFile.absolutePath, options)
            ?: throw IllegalArgumentException(
                "Android could not decode the image: ${imageFile.name}",
            )

        if (box == null) {
            return full
        }

        // Layout boxes can be tight; a small margin avoids clipping glyphs.
        // crop_margin() below trims the extra white space again.
        val boxHeight = box[3] - box[1]
        val margin = max(4f, boxHeight * 0.08f)

        val left = (box[0] - margin).toInt().coerceIn(0, full.width - 1)
        val top = (box[1] - margin).toInt().coerceIn(0, full.height - 1)
        val right = (box[2] + margin).roundToInt().coerceIn(left + 1, full.width)
        val bottom = (box[3] + margin).roundToInt().coerceIn(top + 1, full.height)

        val cropped = Bitmap.createBitmap(full, left, top, right - left, bottom - top)

        if (cropped !== full) {
            full.recycle()
        }

        return cropped
    }

        private fun preprocess(source: Bitmap): FloatBuffer {
        // Photos have a gray/textured background; the model expects clean
        // black-on-white. Stretch contrast first, then crop the margins.
        val normalized = normalizeContrast(source)
        val cropped = cropMargin(normalized)

        // PIL: resize short side to 384, then thumbnail into 384x384.
        // Net effect: the long side becomes 384, aspect ratio preserved.
        val scale = INPUT_SIZE.toFloat() / max(cropped.width, cropped.height)
        val newWidth = (cropped.width * scale).roundToInt().coerceIn(1, INPUT_SIZE)
        val newHeight = (cropped.height * scale).roundToInt().coerceIn(1, INPUT_SIZE)

        val scaled = Bitmap.createScaledBitmap(cropped, newWidth, newHeight, true)

        if (cropped !== source && cropped !== scaled) {
            cropped.recycle()
        }

        if (normalized !== source && normalized !== cropped && normalized !== scaled) {
            normalized.recycle()
        }

        // Center on a BLACK 384x384 canvas (PIL ImageOps.expand default fill).
        val canvasBitmap = Bitmap.createBitmap(
            INPUT_SIZE,
            INPUT_SIZE,
            Bitmap.Config.ARGB_8888,
        )
        canvasBitmap.eraseColor(Color.BLACK)

        val offsetX = (INPUT_SIZE - newWidth) / 2
        val offsetY = (INPUT_SIZE - newHeight) / 2

        Canvas(canvasBitmap).drawBitmap(
            scaled,
            offsetX.toFloat(),
            offsetY.toFloat(),
            Paint(Paint.FILTER_BITMAP_FLAG),
        )

        if (scaled !== source) {
            scaled.recycle()
        }

        val planeSize = INPUT_SIZE * INPUT_SIZE
        val argb = IntArray(planeSize)
        canvasBitmap.getPixels(argb, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)
        canvasBitmap.recycle()

        val pixels = ByteBuffer
            .allocateDirect(planeSize * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        // (v/255 - mean) / std on each channel, then grayscale.
        // The grayscale weights sum to 1, so this equals normalizing the
        // grayscale value once.
        for (i in 0 until planeSize) {
            val color = argb[i]
            val red = (color shr 16) and 0xFF
            val green = (color shr 8) and 0xFF
            val blue = color and 0xFF
            val gray = 0.299f * red + 0.587f * green + 0.114f * blue
            pixels.put(i, (gray / 255f - MEAN) / STD)
        }

        pixels.rewind()

        return pixels
    }



         /**
     * Camera photos (of paper or of a screen) have a gray, textured
     * background and low contrast, but the formula model was trained on
     * clean black-on-white images. Stretch the contrast so the background
     * becomes white and the ink black. Clean screenshots are practically
     * unchanged (their background is already white).
     */
    private fun normalizeContrast(source: Bitmap): Bitmap {
        val width = source.width
        val height = source.height
        val argb = IntArray(width * height)
        source.getPixels(argb, 0, width, 0, 0, width, height)

        val gray = IntArray(argb.size)
        val histogram = IntArray(256)

        for (i in argb.indices) {
            val color = argb[i]
            val value = (
                ((color shr 16) and 0xFF) * 299 +
                    ((color shr 8) and 0xFF) * 587 +
                    (color and 0xFF) * 114
                ) / 1000
            gray[i] = value
            histogram[value]++
        }

        // Darkest 1% = ink; the median = background (formulas are mostly
        // white space around thin strokes).
        val blackPoint = percentile(histogram, argb.size, 0.01)
        val whitePoint = percentile(histogram, argb.size, 0.50)

        if (whitePoint - blackPoint < 30) {
            return source
        }

        val range = (whitePoint - blackPoint).toFloat()

        for (i in argb.indices) {
            val value = ((gray[i] - blackPoint) / range * 255f)
                .roundToInt()
                .coerceIn(0, 255)
            argb[i] = (0xFF shl 24) or (value shl 16) or (value shl 8) or value
        }

        val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        output.setPixels(argb, 0, width, 0, 0, width, height)

        return output
    }

    private fun percentile(histogram: IntArray, total: Int, fraction: Double): Int {
        val target = (total * fraction).toLong()
        var count = 0L

        for (value in 0..255) {
            count += histogram[value]

            if (count > target) {
                return value
            }
        }

        return 255
    }

    /**
     * Port of UniMERNetImgDecode.crop_margin(): crops to the bounding box of
     * "ink" pixels (normalized grayscale < 200).
     */

    private fun cropMargin(source: Bitmap): Bitmap {
        val width = source.width
        val height = source.height
        val argb = IntArray(width * height)
        source.getPixels(argb, 0, width, 0, 0, width, height)

        val gray = IntArray(argb.size)
        var low = 255
        var high = 0

        for (i in argb.indices) {
            val color = argb[i]
            // PIL "L" conversion (ITU-R 601-2 luma, fixed point).
            val value = (
                ((color shr 16) and 0xFF) * 19595 +
                    ((color shr 8) and 0xFF) * 38470 +
                    (color and 0xFF) * 7471 +
                    0x8000
                ) shr 16
            gray[i] = value
            low = min(low, value)
            high = max(high, value)
        }

        if (high == low) {
            return source
        }

        val range = (high - low).toFloat()
        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        for (y in 0 until height) {
            val row = y * width
            for (x in 0 until width) {
                val normalized = (gray[row + x] - low) / range * 255f
                if (normalized < 200f) {
                    if (x < minX) minX = x
                    if (x > maxX) maxX = x
                    if (y < minY) minY = y
                    if (y > maxY) maxY = y
                }
            }
        }

        if (maxX < 0) {
            return source
        }

        val cropWidth = maxX - minX + 1
        val cropHeight = maxY - minY + 1

        if (cropWidth == width && cropHeight == height) {
            return source
        }

        return Bitmap.createBitmap(source, minX, minY, cropWidth, cropHeight)
    }

    // ------------------------------------------------------------------
    // Decoding (UniMERNetDecode)
    // ------------------------------------------------------------------

    private class DecodedTokens(
        val text: String,
        val tokenCount: Int,
        val reachedEnd: Boolean,
    )

    private fun readTokenIds(outputs: OrtSession.Result): LongArray {
        val tensor = outputs.get(0) as? OnnxTensor
            ?: throw IllegalStateException("The formula model returned no tensor.")

        val buffer = tensor.longBuffer
            ?: throw IllegalStateException("The formula model output is not int64.")

        val ids = LongArray(buffer.remaining())
        buffer.get(ids)

        // Output shape is [batch, sequence]; batch is always 1 here.
        return ids
    }

    private fun decodeTokens(ids: LongArray): DecodedTokens {
        val tokens = checkNotNull(vocabulary) {
            "The formula vocabulary is not loaded."
        }

        val joined = StringBuilder()
        var count = 0
        var reachedEnd = false

        for (id in ids) {
            count++

            if (id == EOS_ID) {
                reachedEnd = true
                break
            }

            val index = id.toInt()

            if (index in specialIds || index < 0 || index >= tokens.size) {
                continue
            }

            joined.append(tokens[index])
        }

        // Byte-level BPE: every char maps back to one byte, then UTF-8.
        val bytes = ByteArray(joined.length) { position ->
            val char = joined[position]
            (byteDecoder[char] ?: (char.code and 0xFF)).toByte()
        }

        return DecodedTokens(
            text = String(bytes, Charsets.UTF_8).trim(),
            tokenCount = count,
            reachedEnd = reachedEnd,
        )
    }

    /** GPT-2 bytes_to_unicode(), inverted: printable char -> byte. */
    private fun buildByteDecoder(): Map<Char, Int> {
        val bytes = ArrayList<Int>()
        bytes += ('!'.code..'~'.code)
        bytes += (0xA1..0xAC)
        bytes += (0xAE..0xFF)

        val chars = ArrayList<Int>(bytes)
        var extra = 0

        for (byte in 0 until 256) {
            if (byte !in bytes) {
                bytes.add(byte)
                chars.add(256 + extra)
                extra++
            }
        }

        return bytes.indices.associate { index -> chars[index].toChar() to bytes[index] }
    }

    // Port of UniMERNetDecode.normalize(): removes the spaces the tokenizer
    // puts between LaTeX tokens, keeping spaces inside \text{...} etc.
    // Braces are escaped because Java/ICU regex rejects bare '{'.
    private val TEXT_REG =
        Regex("""(\\(operatorname|mathrm|text|mathbf)\s?\*? \{.*?\})""")

    private val COMMAND_BEFORE_WORD =
        Regex("""(\\[a-zA-Z]+)\s(?=\w)|\\[a-zA-Z]+\s(?=\})""")

    private val KEEP_COMMANDS = setOf("\\operatorname", "\\mathrm", "\\text", "\\mathbf")

    private const val LETTER = "[a-zA-Z]"
    private const val NO_LETTER = """[\W_^\d]"""

    private val NO_LETTER_NO_LETTER =
        Regex("""(?!\\ )($NO_LETTER)\s+?($NO_LETTER)""")

    private val NO_LETTER_LETTER =
        Regex("""(?!\\ )($NO_LETTER)\s+?($LETTER)""")

    private val LETTER_NO_LETTER =
        Regex("""($LETTER)\s+?($NO_LETTER)""")

    private fun normalizeLatex(input: String): String {
        // Protect command spaces inside a text-style group locally. The old
        // code saved the entire formula for each match and could duplicate
        // it when replacing just one group, while stripping every space.
        var text = TEXT_REG.replace(input) { match ->
            var protectedGroup = match.value

            for (inner in COMMAND_BEFORE_WORD.findAll(match.value)) {
                val command = inner.groupValues[1]

                if (command.isNotBlank() && command !in KEEP_COMMANDS) {
                    protectedGroup = protectedGroup.replace(
                        "$command ",
                        "${command}XXXXXXX",
                    )
                }
            }

            protectedGroup
        }

        var next = text

        while (true) {
            text = next
            next = NO_LETTER_NO_LETTER.replace(text, "\$1\$2")
            next = NO_LETTER_LETTER.replace(next, "\$1\$2")
            next = LETTER_NO_LETTER.replace(next, "\$1\$2")

            if (next == text) {
                break
            }
        }

        return text.replace("XXXXXXX", " ")
    }
}
