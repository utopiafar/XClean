package com.utopiafar.xclean.engine

import rikka.shizuku.Shizuku
import java.io.File

/**
 * File engine that uses Shizuku (ADB privilege) to access restricted paths
 * like /Android/data without root.
 *
 * For MVP this uses Shizuku's process execution to run shell commands.
 */
object ShizukuFileEngine {

    fun isAvailable(): Boolean {
        return try {
            Shizuku.pingBinder()
        } catch (_: Exception) {
            false
        }
    }

    fun listFiles(path: String, recursive: Boolean, pattern: String?): List<Map<String, Any>> {
        if (!isAvailable()) return emptyList()

        val results = mutableListOf<Map<String, Any>>()
        try {
            val findCmd = if (recursive) {
                "find \"$path\" -type f ${pattern?.let { "-name \"$it\"" } ?: ""}"
            } else {
                "find \"$path\" -maxdepth 1 -type f ${pattern?.let { "-name \"$it\"" } ?: ""}"
            }

            val output = execShell(findCmd) ?: return emptyList()
            output.lines().filter { it.isNotBlank() }.forEach { filePath ->
                val statOut = execShell("stat -c \"%s %Y\" \"$filePath\"")?.trim()
                val parts = statOut?.split(" ")
                val size = parts?.getOrNull(0)?.toLongOrNull() ?: 0L
                val mtime = (parts?.getOrNull(1)?.toLongOrNull() ?: 0L) * 1000
                val file = File(filePath)
                results.add(mapOf(
                    "path" to filePath,
                    "name" to file.name,
                    "size" to size,
                    "lastModified" to mtime,
                    "isDirectory" to false
                ))
            }
        } catch (_: Exception) {
            // Fallback
        }
        return results
    }

    fun deleteFiles(paths: List<String>): Map<String, Any> {
        var successCount = 0
        var failCount = 0
        var freedBytes = 0L

        paths.forEach { path ->
            val sizeStr = execShell("du -sb \"$path\"")
            val size = sizeStr?.split("\t")?.firstOrNull()?.toLongOrNull() ?: 0L
            execShell("rm -rf \"$path\"")
            val exists = execShell("test -e \"$path\" && echo yes || echo no")?.trim() == "yes"
            if (!exists) {
                successCount++
                freedBytes += size
            } else {
                failCount++
            }
        }

        return mapOf(
            "successCount" to successCount,
            "failCount" to failCount,
            "freedBytes" to freedBytes
        )
    }

    fun getDirectorySize(path: String): Long {
        return execShell("du -sb \"$path\"")?.split("\t")?.firstOrNull()?.toLongOrNull() ?: 0L
    }

    /**
     * Executes a shell command via Shizuku's process API.
     */
    private fun execShell(command: String): String? {
        return try {
            val process = Shizuku.newProcess(
                arrayOf("sh", "-c", command),
                null,
                null
            )
            process.waitFor()
            val output = process.inputStream.bufferedReader().readText()
            process.destroy()
            output
        } catch (_: Exception) {
            null
        }
    }
}
