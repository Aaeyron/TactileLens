package com.tactilelens.app

import android.content.Context
import android.content.res.AssetManager
import java.io.File
import java.io.FileOutputStream

object LiblouisNative {
    private const val LIBLOUIS_VERSION =
        "3.38.0"

    private const val ASSET_TABLES_DIRECTORY =
        "flutter_assets/third_party/liblouis/tables"

    private const val UNICODE_DISPLAY_TABLE =
        "unicode.dis"

    private const val UEB_TABLE =
        "en-ueb-g2.ctb"

    private const val NEMETH_TABLE =
        "en-us-mathtext.ctb"

    private var initialized = false
    private var tablesDirectory: File? = null

    init {
        System.loadLibrary(
            "tactilelens_liblouis",
        )
    }

    @JvmStatic
    private external fun translateNative(
        tableList: String,
        sourceText: String,
    ): String

    @JvmStatic
    private external fun versionNative(): String

    @JvmStatic
    private external fun releaseNative()

    @Synchronized
    fun initialize(context: Context) {
        if (initialized) {
            return
        }

        val applicationContext =
            context.applicationContext

        val runtimeDirectory = File(
            applicationContext.filesDir,
            "liblouis/$LIBLOUIS_VERSION",
        )

        val destinationTablesDirectory = File(
            runtimeDirectory,
            "tables",
        )

        val installationMarker = File(
            runtimeDirectory,
            ".installed",
        )

        val requiredFilesExist =
            File(
                destinationTablesDirectory,
                UNICODE_DISPLAY_TABLE,
            ).isFile &&
                File(
                    destinationTablesDirectory,
                    UEB_TABLE,
                ).isFile &&
                File(
                    destinationTablesDirectory,
                    NEMETH_TABLE,
                ).isFile

        if (
            !installationMarker.isFile ||
            !requiredFilesExist
        ) {
            if (runtimeDirectory.exists()) {
                runtimeDirectory.deleteRecursively()
            }

            if (!destinationTablesDirectory.mkdirs()) {
                throw IllegalStateException(
                    "The Liblouis tables directory " +
                        "could not be created.",
                )
            }

            copyAssetDirectory(
                assetManager =
                    applicationContext.assets,
                assetPath =
                    ASSET_TABLES_DIRECTORY,
                destination =
                    destinationTablesDirectory,
            )

            if (!installationMarker.createNewFile()) {
                throw IllegalStateException(
                    "The Liblouis installation " +
                        "could not be completed.",
                )
            }
        }

        validateRequiredTable(
            destinationTablesDirectory,
            UNICODE_DISPLAY_TABLE,
        )

        validateRequiredTable(
            destinationTablesDirectory,
            UEB_TABLE,
        )

        validateRequiredTable(
            destinationTablesDirectory,
            NEMETH_TABLE,
        )

        tablesDirectory =
            destinationTablesDirectory

        initialized = true
    }

    fun translateText(
        context: Context,
        content: String,
    ): String {
        return translate(
            context = context,
            content = content,
            translationTable = UEB_TABLE,
        )
    }

    fun translateFormula(
        context: Context,
        content: String,
    ): String {
        return translate(
            context = context,
            content = content,
            translationTable = NEMETH_TABLE,
        )
    }

    fun translateBlock(
        context: Context,
        content: String,
        isFormula: Boolean,
        isTable: Boolean,
    ): LiblouisTranslationResult {
        val normalizedContent = content.trim()
        val usesNemeth = isFormula || isTable

        val code = if (usesNemeth) {
            "nemeth"
        } else {
            "ueb"
        }

        if (normalizedContent.isEmpty()) {
            return LiblouisTranslationResult(
                success = true,
                code = code,
                content = "",
                error = null,
            )
        }

        return try {
            val translatedContent =
                if (usesNemeth) {
                    translateFormula(
                        context,
                        normalizedContent,
                    )
                } else {
                    translateText(
                        context,
                        normalizedContent,
                    )
                }

            val hasTranslation =
                translatedContent.isNotBlank()

            LiblouisTranslationResult(
                success = hasTranslation,
                code = code,
                content = translatedContent,
                error = if (hasTranslation) {
                    null
                } else {
                    "Liblouis returned an empty translation."
                },
            )
        } catch (error: Exception) {
            LiblouisTranslationResult(
                success = false,
                code = code,
                content = "",
                error =
                    error.message
                        ?: "Braille translation failed.",
            )
        }
    }

    fun runtimeVersion(): String {
        return versionNative()
    }

    @Synchronized
    fun release() {
        if (!initialized) {
            return
        }

        releaseNative()
        initialized = false
        tablesDirectory = null
    }

    private fun translate(
        context: Context,
        content: String,
        translationTable: String,
    ): String {
        val normalizedContent = content.trim()

        if (normalizedContent.isEmpty()) {
            return ""
        }

        initialize(context)

        val directory =
            tablesDirectory
                ?: throw IllegalStateException(
                    "Liblouis has not been initialized.",
                )

        val displayTablePath = File(
            directory,
            UNICODE_DISPLAY_TABLE,
        ).absolutePath

        val translationTablePath = File(
            directory,
            translationTable,
        ).absolutePath

        val tableList = listOf(
            displayTablePath,
            translationTablePath,
        ).joinToString(",")

        return translateNative(
            tableList,
            normalizedContent,
        ).trimEnd('\r', '\n')
    }

    private fun validateRequiredTable(
        directory: File,
        fileName: String,
    ) {
        val tableFile = File(
            directory,
            fileName,
        )

        if (!tableFile.isFile) {
            throw IllegalStateException(
                "Required Liblouis table is missing: " +
                    fileName,
            )
        }
    }

    private fun copyAssetDirectory(
        assetManager: AssetManager,
        assetPath: String,
        destination: File,
    ) {
        val children =
            assetManager.list(assetPath)
                ?: emptyArray()

        if (children.isEmpty()) {
            copyAssetFile(
                assetManager = assetManager,
                assetPath = assetPath,
                destination = destination,
            )

            return
        }

        if (
            !destination.exists() &&
            !destination.mkdirs()
        ) {
            throw IllegalStateException(
                "Could not create directory: " +
                    destination.absolutePath,
            )
        }

        for (child in children) {
            val childAssetPath =
                "$assetPath/$child"

            val childDestination = File(
                destination,
                child,
            )

            val grandChildren =
                assetManager.list(childAssetPath)
                    ?: emptyArray()

            if (grandChildren.isEmpty()) {
                copyAssetFile(
                    assetManager = assetManager,
                    assetPath = childAssetPath,
                    destination = childDestination,
                )
            } else {
                copyAssetDirectory(
                    assetManager = assetManager,
                    assetPath = childAssetPath,
                    destination = childDestination,
                )
            }
        }
    }

    private fun copyAssetFile(
        assetManager: AssetManager,
        assetPath: String,
        destination: File,
    ) {
        destination.parentFile?.let {
            parentDirectory ->

            if (
                !parentDirectory.exists() &&
                !parentDirectory.mkdirs()
            ) {
                throw IllegalStateException(
                    "Could not create directory: " +
                        parentDirectory.absolutePath,
                )
            }
        }

        assetManager.open(assetPath).use {
            inputStream ->

            FileOutputStream(destination).use {
                outputStream ->

                inputStream.copyTo(outputStream)
            }
        }
    }
}

data class LiblouisTranslationResult(
    val success: Boolean,
    val code: String,
    val content: String,
    val error: String?,
)