package com.tactilelens.app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val LIBLOUIS_CHANNEL =
            "com.tactilelens.app/liblouis"

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

    private val paddleOcrVlExecutor: ExecutorService =
        Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine,
    ) {
        super.configureFlutterEngine(flutterEngine)

        configureLiblouisChannel(flutterEngine)
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
                val content =
                    PaddleOcrVlNative.nativeScanImage(
                        imagePath = imagePath,
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

    override fun onDestroy() {
        liblouisExecutor.shutdown()
        paddleOcrVlExecutor.shutdown()

        super.onDestroy()
    }
}