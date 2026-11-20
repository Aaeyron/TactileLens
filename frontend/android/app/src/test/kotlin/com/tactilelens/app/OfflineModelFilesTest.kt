package com.tactilelens.app

import java.io.File
import java.security.MessageDigest
import org.junit.Assert.assertEquals
import org.junit.Assume.assumeTrue
import org.junit.Test

/**
 * The sizes and hashes in OfflineModelFiles must be those of the models
 * bundled in src/main/assets/paddle_onnx. The models are not in git, so
 * each check is skipped where a model file is absent.
 */
class OfflineModelFilesTest {
    private val assetRoot = File("src/main/assets")

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(1 shl 20)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    @Test
    fun everyModelMatchesTheBundledFile() {
        var checked = 0

        for (model in OfflineModelFiles.ALL) {
            val file = File(assetRoot, model.asset)
            if (!file.isFile) continue

            assertEquals(model.name, model.size, file.length())
            assertEquals(model.name, model.sha256, sha256(file))
            checked++
        }

        assumeTrue("No bundled models in this checkout", checked > 0)
    }

    @Test
    fun theFourModelsAreDistinctAndTheCopiedOnesHaveAPath() {
        assertEquals(4, OfflineModelFiles.ALL.map { it.asset }.toSet().size)
        assertEquals(
            listOf("page layout", "formula"),
            OfflineModelFiles.ALL.filter { it.installedPath != null }.map { it.name },
        )
    }
}
