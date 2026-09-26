package com.tactilelens.app

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import java.nio.FloatBuffer
import kotlin.math.ceil
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

object PaddleOnnxTextRecognizer {
    private const val MODEL_DIRECTORY =
        "PP-OCRv6-small-rec-onnx"

    private const val IMAGE_HEIGHT = 48
    private const val IMAGE_WIDTH = 320

    private val environment: OrtEnvironment by lazy {
        OrtEnvironment.getEnvironment()
    }

    fun recognizeAsset(
        context: Context,
        assetPath: String,
        threadCount: Int,
    ): Map<String, Any> {
        val bitmap = context.assets
            .open(assetPath)
            .use { input ->
                BitmapFactory.decodeStream(input)
            }
            ?: error("Unable to decode test image: $assetPath")

        return try {
            recognizeBitmap(
                context = context,
                bitmap = bitmap,
                threadCount = threadCount,
            )
        } finally {
            bitmap.recycle()
        }
    }

    fun recognizeFile(
    context: Context,
    imagePath: String,
    threadCount: Int,
): Map<String, Any> {
    val normalizedPath = imagePath.trim()

    require(normalizedPath.isNotEmpty()) {
        "The recognition image path is missing."
    }

    val imageFile = File(normalizedPath)

    require(imageFile.isFile) {
        "The recognition image does not exist: $normalizedPath"
    }

    val bitmap = BitmapFactory.decodeFile(
        imageFile.absolutePath,
    ) ?: error(
        "Unable to decode recognition image: $normalizedPath",
    )

    return try {
        recognizeBitmap(
            context = context,
            bitmap = bitmap,
            threadCount = threadCount.coerceIn(1, 8),
        )
    } finally {
        bitmap.recycle()
    }
}

    internal fun recognizeBitmap(
        context: Context,
        bitmap: Bitmap,
        threadCount: Int,
    ): Map<String, Any> {
        val modelRoot =
            PaddleOnnxNative.modelDirectory(context)

        val modelDirectory = File(
            modelRoot,
            MODEL_DIRECTORY,
        )

        val modelFile = File(
            modelDirectory,
            "inference.onnx",
        )

        val configurationFile = File(
            modelDirectory,
            "inference.yml",
        )

        require(modelFile.isFile) {
            "The PP-OCRv6 recognition model is missing."
        }

        require(configurationFile.isFile) {
            "The PP-OCRv6 recognition dictionary is missing."
        }

        val characterDictionary =
            readCharacterDictionary(configurationFile)

        val inputTensor = preprocess(bitmap)
        val safeThreadCount = threadCount.coerceIn(1, 8)

        val startedAt = System.nanoTime()

        OrtSession.SessionOptions().use { options ->
            options.setIntraOpNumThreads(safeThreadCount)
            options.setInterOpNumThreads(1)
            options.setOptimizationLevel(
                OrtSession.SessionOptions.OptLevel.ALL_OPT,
            )

            environment
                .createSession(
                    modelFile.absolutePath,
                    options,
                )
                .use { session ->
                    val inputName =
                        session.inputNames.firstOrNull()
                            ?: error(
                                "The recognition model has no input.",
                            )

                    OnnxTensor.createTensor(
                        environment,
                        FloatBuffer.wrap(inputTensor),
                        longArrayOf(
                            1,
                            3,
                            IMAGE_HEIGHT.toLong(),
                            IMAGE_WIDTH.toLong(),
                        ),
                    ).use { tensor ->
                        session.run(
                            mapOf(inputName to tensor),
                        ).use { output ->
                            val elapsedMilliseconds =
                                (
                                    System.nanoTime() - startedAt
                                ) / 1_000_000.0

                            val decoded = decodeOutput(
                                value = output[0].value,
                                dictionary = characterDictionary,
                            )

                            return mapOf(
                                "success" to decoded.text.isNotBlank(),
                                "text" to decoded.text,
                                "confidence" to decoded.confidence,
                                "inference_time_ms" to
                                    elapsedMilliseconds,
                                "dictionary_size" to
                                    characterDictionary.size,
                                "thread_count" to safeThreadCount,
                            )
                        }
                    }
                }
        }
    }

    private fun preprocess(bitmap: Bitmap): FloatArray {
        val sourceWidth = max(bitmap.width, 1)
        val sourceHeight = max(bitmap.height, 1)

        val resizedWidth = min(
            IMAGE_WIDTH,
            max(
                1,
                ceil(
                    sourceWidth *
                        IMAGE_HEIGHT.toDouble() /
                        sourceHeight,
                ).toInt(),
            ),
        )

        val resizedBitmap = Bitmap.createScaledBitmap(
            bitmap,
            resizedWidth,
            IMAGE_HEIGHT,
            true,
        )

        val pixels = IntArray(
            resizedWidth * IMAGE_HEIGHT,
        )

        resizedBitmap.getPixels(
            pixels,
            0,
            resizedWidth,
            0,
            0,
            resizedWidth,
            IMAGE_HEIGHT,
        )

        val planeSize = IMAGE_HEIGHT * IMAGE_WIDTH
        val tensor = FloatArray(3 * planeSize)

        for (y in 0 until IMAGE_HEIGHT) {
            for (x in 0 until resizedWidth) {
                val color = pixels[y * resizedWidth + x]

                val red = (color shr 16) and 0xFF
                val green = (color shr 8) and 0xFF
                val blue = color and 0xFF

                val position = y * IMAGE_WIDTH + x

                tensor[position] =
                    normalizeChannel(blue)

                tensor[planeSize + position] =
                    normalizeChannel(green)

                tensor[(2 * planeSize) + position] =
                    normalizeChannel(red)
            }
        }

        if (resizedBitmap !== bitmap) {
            resizedBitmap.recycle()
        }

        return tensor
    }

    private fun normalizeChannel(value: Int): Float {
        return ((value / 255.0f) - 0.5f) / 0.5f
    }

    private fun readCharacterDictionary(
        configurationFile: File,
    ): List<String> {
        val lines = configurationFile.readLines(
            Charsets.UTF_8,
        )

        val startIndex = lines.indexOfFirst { line ->
            line.trim() == "character_dict:"
        }

        require(startIndex >= 0) {
            "The recognition dictionary was not found."
        }

        val characters = mutableListOf<String>()

        for (index in (startIndex + 1) until lines.size) {
            val trimmed = lines[index].trimStart()

            if (!trimmed.startsWith("- ")) {
                break
            }

            val scalar = trimmed
                .removePrefix("- ")
                .trim()

            characters.add(parseYamlScalar(scalar))
        }

        require(characters.isNotEmpty()) {
            "The recognition dictionary is empty."
        }

        return characters
    }

    private fun parseYamlScalar(value: String): String {
        if (
            value.length >= 2 &&
            value.startsWith("'") &&
            value.endsWith("'")
        ) {
            return value
                .substring(1, value.length - 1)
                .replace("''", "'")
        }

        if (
            value.length >= 2 &&
            value.startsWith("\"") &&
            value.endsWith("\"")
        ) {
            return value.substring(
                1,
                value.length - 1,
            )
        }

        return value
    }

    private fun decodeOutput(
        value: Any?,
        dictionary: List<String>,
    ): DecodedText {
        val batches = value as? Array<*>
            ?: error(
                "The recognition output has an unexpected type.",
            )

        val timeSteps = batches.firstOrNull() as? Array<*>
            ?: error(
                "The recognition output has an unexpected shape.",
            )

        val text = StringBuilder()
        var previousIndex = -1
        var confidenceTotal = 0.0
        var characterCount = 0

        for (timeStep in timeSteps) {
            val probabilities = timeStep as? FloatArray
                ?: error(
                    "The recognition logits have an unexpected type.",
                )

            var bestIndex = 0
            var bestValue = Float.NEGATIVE_INFINITY
            var probabilitySum = 0.0
            var containsNegativeValue = false

            for (index in probabilities.indices) {
                val candidate = probabilities[index]

                if (candidate > bestValue) {
                    bestValue = candidate
                    bestIndex = index
                }

                probabilitySum += candidate

                if (candidate < 0.0f) {
                    containsNegativeValue = true
                }
            }

            if (
                bestIndex != 0 &&
                bestIndex != previousIndex
            ) {
                val dictionaryIndex = bestIndex - 1

                if (dictionaryIndex in dictionary.indices) {
                    text.append(
                        dictionary[dictionaryIndex],
                    )

                    confidenceTotal += if (
                        !containsNegativeValue &&
                        probabilitySum in 0.98..1.02
                    ) {
                        bestValue.toDouble()
                    } else {
                        softmaxProbability(
                        probabilities,
                        bestValue,
                        )
                    }

                    characterCount++
                }
            }

            previousIndex = bestIndex
        }

        return DecodedText(
            text = text.toString(),
            confidence = if (characterCount == 0) {
                0.0
            } else {
                confidenceTotal / characterCount
            },
        )
    }

    private fun softmaxProbability(
    values: FloatArray,
    maximumValue: Float,
): Double {
        var denominator = 0.0

        for (value in values) {
            denominator += exp(
                (value - maximumValue).toDouble(),
            )
        }

        return if (denominator <= 0.0) {
            0.0
        } else {
            1.0 / denominator
        }
    }

    private data class DecodedText(
        val text: String,
        val confidence: Double,
    )
} 