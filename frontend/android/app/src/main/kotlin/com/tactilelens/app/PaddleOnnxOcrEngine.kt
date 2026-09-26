package com.tactilelens.app

import android.content.Context
import com.paddle.ocr.EngineConfig
import com.paddle.ocr.PaddleOCR
import com.paddle.ocr.PaddleOCRConfig
import com.paddle.ocr.util.OpenCVUtils
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * Offline full-page OCR engine (PP-OCRv6 detector + recognizer via the
 * official PaddleOCR Android SDK on ONNX Runtime).
 *
 * - The engine is created once and reused between scans.
 * - All public functions are suspend functions and run off the main thread.
 * - A mutex ensures only one load/scan/release runs at a time.
 */
object PaddleOnnxOcrEngine {
    private const val DETECTOR_MODEL_ASSET =
        "paddle_onnx/PP-OCRv6-tiny-det-onnx/inference.onnx"

    private const val RECOGNIZER_MODEL_ASSET =
        "paddle_onnx/PP-OCRv6-small-rec-onnx/inference.onnx"

    private const val RECOGNIZER_CONFIG_ASSET =
        "paddle_onnx/PP-OCRv6-small-rec-onnx/inference.yml"

    private const val MIN_THREADS = 1
    private const val MAX_THREADS = 8

    private val engineLock = Mutex()

    // Guarded by engineLock.
    private var engine: PaddleOCR? = null
    private var loadedThreadCount = 0

    suspend fun initialize(
        context: Context,
        threadCount: Int,
    ): Map<String, Any?> = withContext(Dispatchers.Default) {
        val safeThreadCount = threadCount.coerceIn(MIN_THREADS, MAX_THREADS)

        engineLock.withLock {
            val ocr = getOrCreateEngineLocked(
                context = context,
                threadCount = safeThreadCount,
            )

            mapOf(
                "success" to true,
                "loaded" to true,
                "thread_count" to safeThreadCount,
                "cold_load_time_ms" to ocr.coldLoadTimeMs,
            )
        }
    }

    suspend fun recognizeFile(
        context: Context,
        imagePath: String,
        threadCount: Int,
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
        val imageBytes = imageFile.readBytes()

        engineLock.withLock {
            val ocr = getOrCreateEngineLocked(
                context = context,
                threadCount = safeThreadCount,
            )

            val result = ocr.recognize(imageBytes)

            val blocks = result.results.mapIndexed { index, item ->
                mapOf<String, Any?>(
                    "index" to index,
                    "text" to item.text,
                    "confidence" to item.confidence.toDouble(),
                    "box" to item.box.points.map { point ->
                        mapOf(
                            "x" to point.x.toDouble(),
                            "y" to point.y.toDouble(),
                        )
                    },
                )
            }

            mapOf(
                // success = the scan completed; is_empty = no text was found.
                "success" to true,
                "is_empty" to blocks.isEmpty(),
                "text" to result.results
                    .joinToString("\n") { item -> item.text },
                "blocks" to blocks,
                "line_count" to result.lineCount,
                "detection_time_ms" to result.detectionTimeMs,
                "recognition_time_ms" to result.recognitionTimeMs,
                "total_time_ms" to result.totalTimeMs,
                "cold_load_time_ms" to result.coldLoadTimeMs,
                "thread_count" to safeThreadCount,
            )
        }
    }

    suspend fun release() {
        withContext(Dispatchers.Default) {
            engineLock.withLock {
                engine?.release()
                engine = null
                loadedThreadCount = 0
            }
        }
    }

    /** Must only be called while holding [engineLock]. */
    private suspend fun getOrCreateEngineLocked(
        context: Context,
        threadCount: Int,
    ): PaddleOCR {
        val currentEngine = engine

        if (currentEngine != null && loadedThreadCount == threadCount) {
            return currentEngine
        }

        currentEngine?.release()
        engine = null
        loadedThreadCount = 0

        check(OpenCVUtils.init(context.applicationContext)) {
            "OpenCV could not be initialized."
        }

        val createdEngine = PaddleOCR.create(
            context = context.applicationContext,
            config = PaddleOCRConfig(
                detLimitSideLen = 1280,
                detLimitType = "max",
                detMaxSideLimit = 1280,
                detThresh = 0.3f,
                detBoxThresh = 0.6f,
                detUnclipRatio = 1.5f,
                recScoreThresh = 0.0f,
                recBatchSize = 1,
            ),
            engineConfig = EngineConfig(
                numThreads = threadCount,
            ),
            detModelAssetPath = DETECTOR_MODEL_ASSET,
            recModelAssetPath = RECOGNIZER_MODEL_ASSET,
            recConfigAssetPath = RECOGNIZER_CONFIG_ASSET,
        )

        engine = createdEngine
        loadedThreadCount = threadCount

        return createdEngine
    }
}