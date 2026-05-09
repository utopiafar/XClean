package com.utopiafar.xclean.engine

import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

/**
 * File engine that uses root (su) access to perform file operations.
 */
object RootFileEngine {

    fun isAvailable(): Boolean {
        return try {
            Runtime.getRuntime().exec("su -c echo test").let { process ->
                val output = process.inputStream.bufferedReader().readText().trim()
                process.waitFor()
                output == "test"
            }
        } catch (_: Exception) {
            false
        }
    }

    fun listFiles(path: String, recursive: Boolean, pattern: String?): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        val findCmd = if (recursive) {
            "su -c 'find \"$path\" -type f ${pattern?.let { "-name \"$it\"" } ?: ""}'"
        } else {
            "su -c 'find \"$path\" -maxdepth 1 -type f ${pattern?.let { "-name \"$it\"" } ?: ""}'"
        }

        exec(findCmd)?.lines()?.filter { it.isNotBlank() }?.forEach { filePath ->
            val stat = exec("su -c 'stat -c \"%s %Y\" \"$filePath\"'")
            val parts = stat?.trim()?.split(" ")
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
        return results
    }

    fun deleteFiles(paths: List<String>): Map<String, Any> {
        var successCount = 0
        var failCount = 0
        var freedBytes = 0L
        val deletedPaths = mutableListOf<String>()
        val failedPaths = mutableListOf<String>()

        paths.forEach { path ->
            val sizeStr = exec("su -c 'du -sb \"$path\"'")
            val size = sizeStr?.split("\t")?.firstOrNull()?.toLongOrNull() ?: 0L
            val result = exec("su -c 'rm -rf \"$path\"'")
            val exists = exec("su -c 'test -e \"$path\" && echo yes || echo no'")?.trim() == "yes"
            if (!exists) {
                successCount++
                freedBytes += size
                deletedPaths.add(path)
            } else {
                failCount++
                failedPaths.add(path)
            }
        }

        return mapOf(
            "successCount" to successCount,
            "failCount" to failCount,
            "freedBytes" to freedBytes,
            "deletedPaths" to deletedPaths,
            "failedPaths" to failedPaths
        )
    }

    fun getDirectorySize(path: String): Long {
        return exec("su -c 'du -sb \"$path\"'")?.split("\t")?.firstOrNull()?.toLongOrNull() ?: 0L
    }

    private fun exec(command: String): String? {
        return try {
            val process = Runtime.getRuntime().exec(command)
            val output = process.inputStream.bufferedReader().readText()
            process.waitFor()
            output
        } catch (_: Exception) {
            null
        }
    }
}
