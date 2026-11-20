package com.tactilelens.app

import android.content.Context
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest

/**
 * A model problem the teacher can act on. [code] goes to Dart as the
 * PlatformException code; [message] is already written for a teacher.
 */
class OfflineModelException(
    val code: String,
    override val message: String,
    cause: Throwable? = null,
) : Exception(message, cause)

/**
 * The four on-device models: expected size and SHA-256 of each, a quick
 * check when the Scan screen opens, and a verified copy into internal
 * storage for the two models ONNX Runtime loads from a file.
 *
 * - check(): presence in the APK and size of the installed copies. No
 *   hashing, so it is fast enough to run every time the Scan screen opens.
 * - installedFile(): copies a model out of the APK once, hashing it while
 *   it copies; a wrong size or hash is never kept. It checks free space
 *   first and never leaves a partial file behind.
 * - verifyAsset(): size and hash of a model read straight from the APK
 *   (the text models, which the PaddleOCR SDK loads from assets).
 * - discardInstalled(): drops an installed copy that ONNX Runtime could not
 *   load, so the next attempt copies it again instead of failing forever.
 *
 * The sizes and hashes below are the bundled model files. If a model is
 * ever replaced, update its entry (and the cache file name) here.
 */
object OfflineModelFiles {
    const val MODEL_MISSING = "model_missing"
    const val MODEL_DAMAGED = "model_damaged"
    const val STORAGE_FULL = "storage_full"

    class Model(
        /** How the model is named to a teacher. */
        val name: String,
        val asset: String,
        val size: Long,
        val sha256: String,
        /** Path under filesDir, or null when it is loaded from the APK. */
        val installedPath: String?,
    )

    val LAYOUT = Model(
        name = "page layout",
        asset = "paddle_onnx/PP-DocLayoutV3/pp_doclayoutv3_nomask.onnx",
        size = 134_056_969L,
        sha256 = "e45dc58f7896e049d58f89c4b515e184998efce4acacac2781f30afff60806b8",
        installedPath = "paddle_onnx_models/pp_doclayoutv3_nomask.v1.onnx",
    )

    val FORMULA = Model(
        name = "formula",
        asset = "paddle_onnx/PP-FormulaNet_plus-S/pp-formulanet_plus-s.onnx",
        size = 231_878_904L,
        sha256 = "449d205c8fb2fe0a9b134a5e4a0f2421c2e7812fd902ea67dfda4e9ef4588978",
        installedPath = "paddle_onnx_models/pp-formulanet_plus-s.v1.onnx",
    )

    val TEXT_DETECTION = Model(
        name = "text detection",
        asset = "paddle_onnx/PP-OCRv6-tiny-det-onnx/inference.onnx",
        size = 1_829_618L,
        sha256 = "b21286914016977b96c00d1724a53cbb4e6350f82aba6f001955ce858bfe8e02",
        installedPath = null,
    )

    val TEXT_RECOGNITION = Model(
        name = "text recognition",
        asset = "paddle_onnx/PP-OCRv6-small-rec-onnx/inference.onnx",
        size = 21_154_056L,
        sha256 = "dfa6c7c5bf4908348b90f7aec54e0e0ae95f73f838d237bb958f5cc763dad15a",
        installedPath = null,
    )

    val ALL = listOf(LAYOUT, FORMULA, TEXT_DETECTION, TEXT_RECOGNITION)

    /** Small files the models need next to them (vocabulary, configs). */
    private val SUPPORT_ASSETS = listOf(
        "paddle_onnx/PP-FormulaNet_plus-S/pp-formulanet_vocab.json",
        "paddle_onnx/PP-OCRv6-small-rec-onnx/inference.yml",
    )

    /** Free space kept on top of a copy, so the phone is not left full. */
    private const val SPACE_MARGIN_BYTES = 50L * 1024 * 1024

    /** Copy of every model that an earlier build kept (no longer used). */
    private const val LEGACY_COPY_DIRECTORY = "paddle_onnx"

    private const val BUFFER_SIZE = 1 shl 20

    // Text models verified in this process (they are read from the APK).
    private val verifiedAssets = HashSet<String>()

    /**
     * Quick check for the Scan screen. Returns:
     * - ok: every model is in the app and no installed copy is damaged.
     * - needs_install / install_megabytes: the first on-device scan will
     *   first copy this much (shown as "first time" note).
     * - problems: one map per missing or damaged model, with a message.
     */
    fun check(context: Context): Map<String, Any?> {
        val appContext = context.applicationContext

        removeLegacyCopy(appContext)

        val problems = mutableListOf<Map<String, Any?>>()
        var installBytes = 0L

        for (model in ALL) {
            if (!assetExists(appContext, model.asset)) {
                problems += problem(model, MODEL_MISSING, missingMessage(model))
                continue
            }

            val installedPath = model.installedPath ?: continue
            val installed = File(appContext.filesDir, installedPath)

            when {
                !installed.isFile -> installBytes += model.size
                installed.length() != model.size -> {
                    // A copy with the wrong size can never load: remove it,
                    // and the next scan copies it again.
                    installed.delete()
                    installBytes += model.size
                }
            }
        }

        for (asset in SUPPORT_ASSETS) {
            if (!assetExists(appContext, asset)) {
                val model = if (asset.contains("FormulaNet")) FORMULA else TEXT_RECOGNITION
                problems += problem(model, MODEL_MISSING, missingMessage(model))
            }
        }

        return mapOf(
            "ok" to problems.isEmpty(),
            "needs_install" to (installBytes > 0L),
            "install_megabytes" to megabytes(installBytes),
            "problems" to problems,
        )
    }

    /**
     * The installed copy of [model], copied and verified first if needed.
     * Throws [OfflineModelException] with a teacher-facing message.
     */
    fun installedFile(context: Context, model: Model): File {
        val installedPath = requireNotNull(model.installedPath) {
            "${model.name} is loaded from the app package."
        }
        val appContext = context.applicationContext
        val target = File(appContext.filesDir, installedPath)

        if (target.isFile && target.length() == model.size) {
            return target
        }

        target.delete()
        target.parentFile?.mkdirs()

        val directory = target.parentFile ?: appContext.filesDir
        val needed = model.size + SPACE_MARGIN_BYTES

        if (directory.usableSpace < needed) {
            throw OfflineModelException(
                STORAGE_FULL,
                "There is not enough free storage to set up on-device " +
                    "scanning. Free up about ${megabytes(needed)} MB on this " +
                    "phone and try again.",
            )
        }

        val temporary = File(directory, "${target.name}.tmp")

        try {
            val (bytes, hash) = openAsset(appContext, model).use { input ->
                FileOutputStream(temporary).use { output ->
                    copyAndHash(input, output)
                }
            }

            if (bytes != model.size || hash != model.sha256) {
                throw OfflineModelException(MODEL_DAMAGED, damagedMessage(model))
            }

            if (!temporary.renameTo(target)) {
                throw IOException("Could not move ${temporary.name} into place.")
            }

            return target
        } catch (error: OfflineModelException) {
            throw error
        } catch (error: IOException) {
            // Most often the storage filled up during the copy.
            if (directory.usableSpace < SPACE_MARGIN_BYTES) {
                throw OfflineModelException(
                    STORAGE_FULL,
                    "There is not enough free storage to set up on-device " +
                        "scanning. Free up about ${megabytes(needed)} MB on " +
                        "this phone and try again.",
                    error,
                )
            }

            throw OfflineModelException(MODEL_DAMAGED, damagedMessage(model), error)
        } finally {
            // Never leave a partial copy taking up space.
            temporary.delete()
        }
    }

    /**
     * Checks a model that is read straight from the APK (size and hash),
     * once per process.
     */
    @Synchronized
    fun verifyAsset(context: Context, model: Model) {
        if (model.asset in verifiedAssets) {
            return
        }

        val (bytes, hash) = openAsset(context.applicationContext, model).use { input ->
            copyAndHash(input, null)
        }

        if (bytes != model.size || hash != model.sha256) {
            throw OfflineModelException(MODEL_DAMAGED, damagedMessage(model))
        }

        verifiedAssets += model.asset
    }

    /** Removes an installed copy that could not be loaded. */
    fun discardInstalled(context: Context, model: Model) {
        val installedPath = model.installedPath ?: return
        File(context.applicationContext.filesDir, installedPath).delete()
    }

    /** The error for a model ONNX Runtime could not open. */
    fun loadFailed(model: Model, cause: Throwable): OfflineModelException =
        OfflineModelException(MODEL_DAMAGED, damagedMessage(model), cause)

    fun missingMessage(model: Model): String =
        "On-device scanning can't start: the ${model.name} model is missing " +
            "from this copy of TactileLens. Reinstall the app to fix this."

    fun damagedMessage(model: Model): String =
        "On-device scanning can't start: the ${model.name} model file is " +
            "damaged. Try again; if this keeps happening, reinstall TactileLens."

    private fun problem(model: Model, code: String, message: String): Map<String, Any?> =
        mapOf("model" to model.name, "code" to code, "message" to message)

    private fun openAsset(context: Context, model: Model) =
        try {
            context.assets.open(model.asset)
        } catch (error: FileNotFoundException) {
            throw OfflineModelException(MODEL_MISSING, missingMessage(model), error)
        }

    private fun assetExists(context: Context, asset: String): Boolean {
        val directory = asset.substringBeforeLast('/')
        val name = asset.substringAfterLast('/')

        return try {
            context.assets.list(directory).orEmpty().contains(name)
        } catch (error: IOException) {
            false
        }
    }

    /** Copies [input] to [output] (if any); returns (bytes, SHA-256 hex). */
    private fun copyAndHash(
        input: java.io.InputStream,
        output: java.io.OutputStream?,
    ): Pair<Long, String> {
        val digest = MessageDigest.getInstance("SHA-256")
        val buffer = ByteArray(BUFFER_SIZE)
        var total = 0L

        while (true) {
            val read = input.read(buffer)

            if (read < 0) {
                break
            }

            digest.update(buffer, 0, read)
            output?.write(buffer, 0, read)
            total += read
        }

        val hex = digest.digest().joinToString("") { byte -> "%02x".format(byte) }
        return total to hex
    }

    private fun removeLegacyCopy(context: Context) {
        // Earlier builds copied every model to no_backup/paddle_onnx for a
        // benchmark screen that no longer exists (about 370 MB).
        val legacy = File(context.noBackupFilesDir, LEGACY_COPY_DIRECTORY)

        if (legacy.exists()) {
            legacy.deleteRecursively()
        }
    }

    private fun megabytes(bytes: Long): Long = (bytes + 1024 * 1024 - 1) / (1024 * 1024)
}
