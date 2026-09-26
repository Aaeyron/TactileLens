package com.tactilelens.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlinx.coroutines.runBlocking

class MainActivity : FlutterActivity() {
    companion object {
        private const val LIBLOUIS_CHANNEL =
            "com.tactilelens.app/liblouis"
        
        private const val PADDLE_ONNX_CHANNEL =
            "com.tactilelens.app/paddle_onnx"

        private const val PADDLEOCR_VL_CHANNEL =
             "com.tactilelens.app/paddleocr_vl"

        private const val PADDLEOCR_VL_MODEL_FILE =
            "PaddleOCR-VL-1.6-GGUF.gguf"

        private const val PADDLEOCR_VL_PROJECTOR_FILE =
             "PaddleOCR-VL-1.6-GGUF-mmproj.gguf"
    }

    private val mainHandler =
        Handler(Looper.getMainLooper())

    private val liblouisExecutor: ExecutorService =
        Executors.newSingleThreadExecutor() 

    private val paddleOnnxExecutor: ExecutorService =
    Executors.newSingleThreadExecutor()
    
    private val paddleOcrVlExecutor: ExecutorService =
    Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine,
    ) {
        super.configureFlutterEngine(flutterEngine)

        configureLiblouisChannel(flutterEngine)
        configurePaddleOnnxChannel(flutterEngine)
        configurePaddleOcrVlChannel(flutterEngine)
    }

    private fun configureLiblouisChannel(
        flutterEngine: FlutterEngine,
    ) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LIBLOUIS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    runLiblouisTask(result) {
                        LiblouisNative.initialize(
                            applicationContext,
                        )

                        mapOf(
                            "success" to true,
                            "version" to
                                LiblouisNative.runtimeVersion(),
                        )
                    }
                }

                "translateBlock" -> {
                    val content =
                        call.argument<String>("content")
                            ?.trim()
                            .orEmpty()

                    val isFormula =
                        call.argument<Boolean>("isFormula")
                            ?: false

                    val isTable =
                        call.argument<Boolean>("isTable")
                            ?: false

                    runLiblouisTask(result) {
                        val translation =
                            LiblouisNative.translateBlock(
                                context = applicationContext,
                                content = content,
                                isFormula = isFormula,
                                isTable = isTable,
                            )

                        mapOf(
                            "success" to translation.success,
                            "code" to translation.code,
                            "content" to translation.content,
                            "error" to translation.error,
                        )
                    }
                }

                "version" -> {
                    runLiblouisTask(result) {
                        mapOf(
                            "version" to
                                LiblouisNative.runtimeVersion(),
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun configurePaddleOnnxChannel(
    flutterEngine: FlutterEngine,
) {
    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        PADDLE_ONNX_CHANNEL,
    ).setMethodCallHandler { call, result ->
        when (call.method) {
            "runtimeInfo" -> {
                runPaddleOnnxTask(result) {
                    PaddleOnnxNative.runtimeInfo()
                }
            }

            "recognizeTestImage" -> {
    val threadCount =
        call.argument<Int>("threadCount") ?: 4

    runPaddleOnnxTask(result) {
        PaddleOnnxTextRecognizer.recognizeAsset(
            context = applicationContext,
            assetPath =
                "paddle_onnx_test/equation-crop.png",
            threadCount = threadCount.coerceIn(1, 8),
        )
    }
}

                        "validateModels" -> {
                val threadCount =
                    call.argument<Int>("threadCount") ?: 4

                runPaddleOnnxTask(result) {
                    PaddleOnnxNative.validateModels(
                        context = applicationContext,
                        threadCount = threadCount.coerceIn(1, 8),
                    )
                }
            }

            // ---- Full-page offline OCR (PaddleOCR SDK + PP-OCRv6) ----

            "initializeOcr" -> {
                val threadCount =
                    call.argument<Int>("threadCount") ?: 4

                runPaddleOnnxTask(result) {
                    runBlocking {
                        PaddleOnnxOcrEngine.initialize(
                            context = applicationContext,
                            threadCount = threadCount,
                        )
                    }
                }
            }

            "recognizeImage" -> {
                val imagePath =
                    call.argument<String>("imagePath")
                        ?.trim()
                        .orEmpty()

                val threadCount =
                    call.argument<Int>("threadCount") ?: 4

                runPaddleOnnxTask(result) {
                    runBlocking {
                        PaddleOnnxOcrEngine.recognizeFile(
                            context = applicationContext,
                            imagePath = imagePath,
                            threadCount = threadCount,
                        )
                    }
                }
            }

            "releaseOcr" -> {
                runPaddleOnnxTask(result) {
                    runBlocking {
                        PaddleOnnxOcrEngine.release()
                    }

                    mapOf(
                        "success" to true,
                        "loaded" to false,
                    )
                }
            }

            else -> result.notImplemented()
        }
    }
}

   private fun configurePaddleOcrVlChannel(
    flutterEngine: FlutterEngine,
) {
    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        PADDLEOCR_VL_CHANNEL,
    ).setMethodCallHandler { call, result ->
        when (call.method) {
            "initialize" -> {
                runPaddleOcrVlTask(result) {
                    val initialized =
                        PaddleOcrVlNative.nativeInitialize()

                    mapOf(
                        "success" to initialized,
                        "version" to
                            PaddleOcrVlNative
                                .nativeRuntimeVersion(),
                        "system_information" to
                            PaddleOcrVlNative
                                .nativeSystemInformation(),
                        "model_directory" to
                            paddleOcrVlModelDirectory()
                                .absolutePath,
                    )
                }
            }

            "modelDirectory" -> {
                runPaddleOcrVlTask(result) {
                    mapOf(
                        "model_directory" to
                            paddleOcrVlModelDirectory()
                                .absolutePath,
                    )
                }
            }

            "loadModels" -> {
                val requestedThreadCount =
                    call.argument<Int>("threadCount")

                runPaddleOcrVlTask(result) {
                    loadPaddleOcrVlModels(
                        requestedThreadCount,
                    )
                }
            }

            "scanImage" -> {
    val imagePath =
        call.argument<String>("imagePath")
            ?.trim()
            .orEmpty()

    val prompt =
        call.argument<String>("prompt")
            ?.trim()
            ?.ifBlank { "OCR:" }
            ?: "OCR:"

    val maximumTokens =
        (
            call.argument<Int>("maximumTokens")
                ?: 256
        ).coerceIn(1, 1024)

    val requestedThreadCount =
        call.argument<Int>("threadCount")

    runPaddleOcrVlTask(result) {
        if (imagePath.isBlank()) {
            mapOf(
                "success" to false,
                "content" to "",
                "scan_time_ms" to 0L,
                "error" to
                    "The scan image path is missing.",
            )
        } else {
            if (
                !PaddleOcrVlNative
                    .nativeModelsLoaded()
            ) {
                loadPaddleOcrVlModels(
                    requestedThreadCount,
                )
            }

            if (
                !PaddleOcrVlNative
                    .nativeModelsLoaded()
            ) {
                mapOf(
                    "success" to false,
                    "content" to "",
                    "scan_time_ms" to 0L,
                    "error" to
                        PaddleOcrVlNative
                            .nativeLastError()
                            .ifBlank {
                                "The PaddleOCR-VL models could not be loaded."
                            },
                )
            } else {
                               // llama.cpp's image loader only supports basic
                // JPEG/PNG. Re-encode through Android so WebP/HEIC
                // and edited gallery images also work.
                val preparedImagePath =
                    prepareImageForPaddleOcrVl(imagePath)

                val content =
                    PaddleOcrVlNative.nativeScanImage(
                        imagePath = preparedImagePath,
                        prompt = prompt,
                        maximumTokens =
                            maximumTokens,
                    )

                val error =
                    PaddleOcrVlNative
                        .nativeLastError()
                        .ifBlank { null }

                mapOf(
                    "success" to (
                        content.isNotBlank() &&
                            error == null
                    ),
                    "content" to content,
                    "scan_time_ms" to
                        PaddleOcrVlNative
                            .nativeScanTimeMs(),
                    "error" to error,
                )
            }
        }
    }
}

            "modelsLoaded" -> {
                runPaddleOcrVlTask(result) {
                    mapOf(
                        "loaded" to
                            PaddleOcrVlNative
                                .nativeModelsLoaded(),
                        "load_time_ms" to
                            PaddleOcrVlNative
                                .nativeModelLoadTimeMs(),
                        "error" to
                            PaddleOcrVlNative
                                .nativeLastError()
                                .ifBlank { null },
                    )
                }
            }

            "unloadModels" -> {
                runPaddleOcrVlTask(result) {
                    val success =
                        PaddleOcrVlNative
                            .nativeUnloadModels()

                    mapOf(
                        "success" to success,
                        "loaded" to
                            PaddleOcrVlNative
                                .nativeModelsLoaded(),
                    )
                }
            }

            "version" -> {
                runPaddleOcrVlTask(result) {
                    mapOf(
                        "version" to
                            PaddleOcrVlNative
                                .nativeRuntimeVersion(),
                    )
                }
            }

            "systemInformation" -> {
                runPaddleOcrVlTask(result) {
                    mapOf(
                        "system_information" to
                            PaddleOcrVlNative
                                .nativeSystemInformation(),
                    )
                }
            }

            else -> result.notImplemented()
        }
    }
}

    /**
     * Decodes any Android-supported image (JPEG, PNG, WebP, HEIC, ...)
     * and writes a plain PNG copy that llama.cpp can read.
     * Runs on the single-thread PaddleOCR-VL executor, so one fixed
     * cache file is safe.
     */
    private fun prepareImageForPaddleOcrVl(
        imagePath: String,
    ): String {
        val source = File(imagePath)

        require(source.isFile) {
            "The scan image does not exist: $imagePath"
        }

        val bitmap =
            BitmapFactory.decodeFile(source.absolutePath)
                ?: throw IllegalArgumentException(
                    "Android could not decode the scan image: " +
                        source.name,
                )

        try {
            val output = File(
                applicationContext.cacheDir,
                "paddleocr_vl_input.png",
            )

            FileOutputStream(output).use { stream ->
                check(
                    bitmap.compress(
                        Bitmap.CompressFormat.PNG,
                        100,
                        stream,
                    ),
                ) {
                    "The scan image could not be converted to PNG."
                }
            }

            return output.absolutePath
        } finally {
            bitmap.recycle()
        }
    }

 private fun paddleOcrVlModelDirectory(): File {
    val directory = File(
        applicationContext.filesDir,
        "models",
    )

    if (!directory.exists() && !directory.mkdirs()) {
        throw IllegalStateException(
            "The PaddleOCR-VL model directory could not be created.",
        )
    }

    return directory
}

private fun loadPaddleOcrVlModels(
    requestedThreadCount: Int?,
): Map<String, Any?> {
    val directory = paddleOcrVlModelDirectory()

    val modelFile = File(
        directory,
        PADDLEOCR_VL_MODEL_FILE,
    )

    val projectorFile = File(
        directory,
        PADDLEOCR_VL_PROJECTOR_FILE,
    )

    if (!modelFile.isFile || !projectorFile.isFile) {
        return mapOf(
            "success" to false,
            "loaded" to false,
            "model_directory" to directory.absolutePath,
            "model_exists" to modelFile.isFile,
            "projector_exists" to projectorFile.isFile,
            "model_path" to modelFile.absolutePath,
            "projector_path" to projectorFile.absolutePath,
            "error" to
                "The PaddleOCR-VL model files are missing.",
        )
    }

    val threadCount =
        (
            requestedThreadCount
                ?: Runtime.getRuntime()
                    .availableProcessors()
                    .coerceAtMost(4)
        ).coerceIn(1, 8)

    val success =
        PaddleOcrVlNative.nativeLoadModels(
            modelPath = modelFile.absolutePath,
            projectorPath = projectorFile.absolutePath,
            threadCount = threadCount,
        )

    return mapOf(
        "success" to success,
        "loaded" to
            PaddleOcrVlNative.nativeModelsLoaded(),
        "thread_count" to threadCount,
        "load_time_ms" to
            PaddleOcrVlNative.nativeModelLoadTimeMs(),
        "model_path" to modelFile.absolutePath,
        "projector_path" to projectorFile.absolutePath,
        "model_size_bytes" to modelFile.length(),
        "projector_size_bytes" to projectorFile.length(),
        "error" to
            PaddleOcrVlNative
                .nativeLastError()
                .ifBlank { null },
    )
}

    private fun runLiblouisTask(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        liblouisExecutor.execute {
            try {
                val value = operation()

                mainHandler.post {
                    result.success(value)
                }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error(
                        "LIBLOUIS_ERROR",
                        error.message
                            ?: "Offline Braille translation failed.",
                        null,
                    )
                }
            }
        }
    }

    private fun runPaddleOcrVlTask(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        paddleOcrVlExecutor.execute {
            try {
                val value = operation()

                mainHandler.post {
                    result.success(value)
                }
            } catch (error: Throwable) {
                mainHandler.post {
                    result.error(
                        "PADDLEOCR_VL_ERROR",
                        error.message
                            ?: "PaddleOCR-VL native runtime failed.",
                        mapOf(
                            "error_type" to
                                error.javaClass.simpleName,
                        ),
                    )
                }
            }
        }
    }

    private fun runPaddleOnnxTask(
    result: MethodChannel.Result,
    operation: () -> Any?,
) {
    paddleOnnxExecutor.execute {
        try {
            val value = operation()

            mainHandler.post {
                result.success(value)
            }
        } catch (error: Throwable) {
            mainHandler.post {
                result.error(
                    "PADDLE_ONNX_ERROR",
                    error.message
                        ?: "The offline ONNX runtime failed.",
                    mapOf(
                        "error_type" to
                            error.javaClass.simpleName,
                    ),
                )
            }
        }
    }
}

        override fun onDestroy() {
        if (isFinishing) {
            // Queue the release behind any running scan so it never
            // frees the engine mid-recognition. shutdown() still lets
            // already-queued tasks finish.
            paddleOnnxExecutor.execute {
                runBlocking {
                    PaddleOnnxOcrEngine.release()
                }
            }
        }

        liblouisExecutor.shutdown()
        paddleOnnxExecutor.shutdown()
        paddleOcrVlExecutor.shutdown()

        super.onDestroy()
    }
}