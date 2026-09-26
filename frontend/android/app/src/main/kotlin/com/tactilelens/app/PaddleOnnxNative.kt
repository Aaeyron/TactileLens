package com.tactilelens.app

import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import java.io.File

object PaddleOnnxNative {
    private const val ASSET_ROOT = "paddle_onnx"
    private const val MODEL_CACHE_VERSION = "1"

    private data class ModelDefinition(
        val name: String,
        val directory: String,
    )

    private val models = listOf(
        ModelDefinition(
            name = "layout",
            directory = "PP-DocLayout-S-onnx",
        ),
        ModelDefinition(
            name = "text_detector",
            directory = "PP-OCRv6-tiny-det-onnx",
        ),
        ModelDefinition(
            name = "text_recognizer",
            directory = "PP-OCRv6-small-rec-onnx",
        ),
        ModelDefinition(
            name = "formula_recognizer",
            directory = "PP-FormulaNet-plus-S-onnx",
        ),
    )

    private val environment: OrtEnvironment by lazy {
        OrtEnvironment.getEnvironment()
    }



    fun runtimeInfo(): Map<String, Any> {
        return mapOf(
            "success" to true,
            "version" to environment.version,
            "providers" to OrtEnvironment
                .getAvailableProviders()
                .map { provider -> provider.name },
        )
    }

    fun modelDirectory(context: Context): File {
    return prepareModelFiles(context)
}

    @Synchronized
    fun validateModels(
        context: Context,
        threadCount: Int,
    ): Map<String, Any> {
        val safeThreadCount = threadCount.coerceIn(1, 8)
        val modelRoot = prepareModelFiles(context)
        val validationResults = mutableListOf<Map<String, Any>>()

        var totalBytes = 0L
        val totalStartedAt = System.nanoTime()

        OrtSession.SessionOptions().use { options ->
            options.setIntraOpNumThreads(safeThreadCount)
            options.setInterOpNumThreads(1)
            options.setOptimizationLevel(
                OrtSession.SessionOptions.OptLevel.ALL_OPT,
            )

            for (model in models) {
                val modelFile = File(
                    modelRoot,
                    "${model.directory}/inference.onnx",
                )

                require(modelFile.isFile && modelFile.length() > 0L) {
                    "Missing ONNX model: ${modelFile.absolutePath}"
                }

                totalBytes += modelFile.length()

                val startedAt = System.nanoTime()

                environment
                    .createSession(
                        modelFile.absolutePath,
                        options,
                    )
                    .use { session ->
                        val elapsedMilliseconds =
                            (System.nanoTime() - startedAt) / 1_000_000.0

                        validationResults.add(
                            mapOf(
                                "name" to model.name,
                                "size_bytes" to modelFile.length(),
                                "load_time_ms" to elapsedMilliseconds,
                                "inputs" to session.inputNames.toList(),
                                "outputs" to session.outputNames.toList(),
                            ),
                        )
                    }
            }
        }

        val totalMilliseconds =
            (System.nanoTime() - totalStartedAt) / 1_000_000.0

        return mapOf(
            "success" to true,
            "runtime_version" to environment.version,
            "thread_count" to safeThreadCount,
            "model_directory" to modelRoot.absolutePath,
            "total_model_bytes" to totalBytes,
            "total_validation_ms" to totalMilliseconds,
            "models" to validationResults,
        )
    }

    private fun prepareModelFiles(context: Context): File {
        val modelRoot = File(
            context.noBackupFilesDir,
            ASSET_ROOT,
        )

        val versionFile = File(
            modelRoot,
            ".model-version",
        )

        if (
            versionFile.isFile &&
            versionFile.readText().trim() == MODEL_CACHE_VERSION
        ) {
            return modelRoot
        }

        if (modelRoot.exists()) {
            check(modelRoot.deleteRecursively()) {
                "Unable to clear the previous ONNX model cache."
            }
        }

        check(modelRoot.mkdirs()) {
            "Unable to create the ONNX model directory."
        }

        copyAssetTree(
            context = context,
            assetPath = ASSET_ROOT,
            destination = modelRoot,
        )

        versionFile.writeText(MODEL_CACHE_VERSION)

        return modelRoot
    }

    private fun copyAssetTree(
        context: Context,
        assetPath: String,
        destination: File,
    ) {
        val children =
            context.assets.list(assetPath).orEmpty()

        if (children.isEmpty()) {
            destination.parentFile?.mkdirs()

            val temporaryFile = File(
                destination.parentFile,
                "${destination.name}.temporary",
            )

            context.assets.open(assetPath).use { input ->
                temporaryFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            check(
                temporaryFile.renameTo(destination),
            ) {
                "Unable to install asset $assetPath."
            }

            return
        }

        check(
            destination.exists() || destination.mkdirs(),
        ) {
            "Unable to create ${destination.absolutePath}."
        }

        for (child in children) {
            copyAssetTree(
                context = context,
                assetPath = "$assetPath/$child",
                destination = File(destination, child),
            )
        }
    }
}