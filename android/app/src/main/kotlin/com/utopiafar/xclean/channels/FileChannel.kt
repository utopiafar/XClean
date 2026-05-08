package com.utopiafar.xclean.channels

import android.os.Environment
import android.os.StatFs
import com.utopiafar.xclean.engine.RootFileEngine
import com.utopiafar.xclean.engine.ShizukuFileEngine
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

/**
 * MethodChannel + EventChannel handler for file-system operations.
 *
 * Channels:
 *   MethodChannel  -> com.utopiafar.xclean/file
 *   EventChannel   -> com.utopiafar.xclean/file_events
 *
 * Supported engines: "normal" (standard java.io.File API).
 */
class FileChannel(
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val CHANNEL_NAME = "com.utopiafar.xclean/file"
        const val EVENT_CHANNEL_NAME = "com.utopiafar.xclean/file_events"
        private const val ENGINE_NORMAL = "normal"
        private const val ENGINE_SHIZUKU = "shizuku"
        private const val ENGINE_ROOT = "root"
    }

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    private val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME)

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var streamJob: Job? = null
    private val isStreamCancelled = AtomicBoolean(false)

    /**
     * Arguments cached by [startScanStream] so that the [EventChannel.StreamHandler]
     * can pick them up once Flutter calls [onListen].
     */
    @Volatile
    private var pendingStreamArgs: ScanArgs? = null

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    data class ScanArgs(
        val path: String,
        val pattern: String?,
        val recursive: Boolean,
        val engine: String
    )

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanPath" -> {
                val path = call.argument<String>("path")
                    ?: return result.error("INVALID_ARG", "path is required", null)
                val pattern = call.argument<String>("pattern")
                val recursive = call.argument<Boolean>("recursive") ?: true
                val engine = call.argument<String>("engine") ?: "auto"

                scope.launch(Dispatchers.IO) {
                    try {
                        val files = scanPathInternal(path, pattern, recursive, engine)
                        withContext(Dispatchers.Main) { result.success(files) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("SCAN_ERROR", e.message, null)
                        }
                    }
                }
            }

            "startScanStream" -> {
                val path = call.argument<String>("path")
                    ?: return result.error("INVALID_ARG", "path is required", null)
                val pattern = call.argument<String>("pattern")
                val recursive = call.argument<Boolean>("recursive") ?: true
                val engine = call.argument<String>("engine") ?: "auto"

                pendingStreamArgs = ScanArgs(path, pattern, recursive, engine)
                result.success(true)
            }

            "deleteFiles" -> {
                val paths = call.argument<List<String>>("paths")
                    ?: return result.error("INVALID_ARG", "paths is required", null)
                val engine = call.argument<String>("engine") ?: "auto"

                scope.launch(Dispatchers.IO) {
                    try {
                        val deleteResult = deleteFilesInternal(paths, engine)
                        withContext(Dispatchers.Main) { result.success(deleteResult) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("DELETE_ERROR", e.message, null)
                        }
                    }
                }
            }

            "getStorageInfo" -> {
                scope.launch(Dispatchers.IO) {
                    try {
                        val info = getStorageInfoInternal()
                        withContext(Dispatchers.Main) { result.success(info) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("STORAGE_ERROR", e.message, null)
                        }
                    }
                }
            }

            "getDirectorySize" -> {
                val path = call.argument<String>("path")
                    ?: return result.error("INVALID_ARG", "path is required", null)
                val engine = call.argument<String>("engine") ?: "auto"

                scope.launch(Dispatchers.IO) {
                    try {
                        val size = getDirectorySizeInternal(path, engine)
                        withContext(Dispatchers.Main) { result.success(size) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("SIZE_ERROR", e.message, null)
                        }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    /* ------------------------------------------------------------------ */
    /*  EventChannel.StreamHandler                                         */
    /* ------------------------------------------------------------------ */

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        isStreamCancelled.set(false)
        val args = pendingStreamArgs
        pendingStreamArgs = null

        if (args == null || events == null) {
            events?.error(
                "NO_ARGS",
                "No scan arguments provided. Call startScanStream first.",
                null
            )
            return
        }

        streamJob = scope.launch(Dispatchers.IO) {
            try {
                scanPathStreamInternal(args.path, args.pattern, args.recursive, args.engine, events)
                if (!isStreamCancelled.get()) {
                    withContext(Dispatchers.Main) { events.endOfStream() }
                }
            } catch (e: Exception) {
                if (!isStreamCancelled.get()) {
                    withContext(Dispatchers.Main) {
                        events.error("STREAM_ERROR", e.message, null)
                    }
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        isStreamCancelled.set(true)
        streamJob?.cancel()
        streamJob = null
    }

    /* ------------------------------------------------------------------ */
    /*  Internal implementations                                           */
    /* ------------------------------------------------------------------ */

    private fun scanPathInternal(
        path: String,
        pattern: String?,
        recursive: Boolean,
        engine: String
    ): List<Map<String, Any>> {
        return when (resolveEngine(engine)) {
            ENGINE_ROOT -> RootFileEngine.listFiles(path, recursive, pattern)
            ENGINE_SHIZUKU -> ShizukuFileEngine.listFiles(path, recursive, pattern)
            else -> {
                val results = mutableListOf<Map<String, Any>>()
                val root = File(path)
                if (!root.exists()) return results

                val matcher = pattern?.let { createPatternMatcher(it) }
                val files = if (recursive) {
                    root.walkTopDown().filter { it.isFile }
                } else {
                    // When not recursive, return all children (files + directories)
                    // This supports directory browsing use cases
                    root.listFiles()?.asSequence() ?: emptySequence()
                }

                files.forEach { file ->
                    if (matcher != null && !matcher(file.name)) return@forEach
                    results.add(fileToMap(file))
                }
                results
            }
        }
    }

    private suspend fun scanPathStreamInternal(
        path: String,
        pattern: String?,
        recursive: Boolean,
        engine: String,
        events: EventChannel.EventSink
    ) {
        val root = File(path)
        if (!root.exists()) return

        val matcher = pattern?.let { createPatternMatcher(it) }
        val files = if (recursive) {
            root.walkTopDown().filter { it.isFile }
        } else {
            root.listFiles { file -> file.isFile }?.asSequence() ?: emptySequence()
        }

        files.forEach { file ->
            if (isStreamCancelled.get()) return
            if (matcher != null && !matcher(file.name)) return@forEach

            withContext(Dispatchers.Main) {
                events.success(fileToMap(file))
            }
            yield() // Cooperate with cancellation
        }
    }

    private fun deleteFilesInternal(paths: List<String>, engine: String): Map<String, Any> {
        return when (resolveEngine(engine)) {
            ENGINE_ROOT -> RootFileEngine.deleteFiles(paths)
            ENGINE_SHIZUKU -> ShizukuFileEngine.deleteFiles(paths)
            else -> {
                var successCount = 0
                var failCount = 0
                var freedBytes = 0L

                paths.forEach { path ->
                    val file = File(path)
                    val size = when {
                        file.isFile -> file.length()
                        file.isDirectory -> getDirectorySizeInternal(path, engine)
                        else -> 0L
                    }

                    val deleted = file.deleteRecursively()
                    if (deleted) {
                        successCount++
                        freedBytes += size
                    } else {
                        failCount++
                    }
                }

                mapOf(
                    "successCount" to successCount,
                    "failCount" to failCount,
                    "freedBytes" to freedBytes
                )
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun getStorageInfoInternal(): Map<String, Long> {
        // Use the primary external storage path for a user-facing overview.
        val path = Environment.getExternalStorageDirectory()?.absolutePath
            ?: Environment.getDataDirectory().path
        val stat = StatFs(path)
        val totalBytes = stat.totalBytes
        val freeBytes = stat.availableBytes

        return mapOf(
            "totalBytes" to totalBytes,
            "freeBytes" to freeBytes,
            "usedBytes" to (totalBytes - freeBytes)
        )
    }

    private fun getDirectorySizeInternal(path: String, engine: String): Long {
        return when (resolveEngine(engine)) {
            ENGINE_ROOT -> RootFileEngine.getDirectorySize(path)
            ENGINE_SHIZUKU -> ShizukuFileEngine.getDirectorySize(path)
            else -> {
                val dir = File(path)
                if (!dir.exists() || !dir.isDirectory) return 0L

                dir.walkTopDown()
                    .filter { it.isFile }
                    .sumOf { it.length() }
            }
        }
    }

    private fun resolveEngine(requested: String): String {
        return when (requested) {
            "auto" -> {
                when {
                    RootFileEngine.isAvailable() -> ENGINE_ROOT
                    ShizukuFileEngine.isAvailable() -> ENGINE_SHIZUKU
                    else -> ENGINE_NORMAL
                }
            }
            ENGINE_ROOT -> if (RootFileEngine.isAvailable()) ENGINE_ROOT else ENGINE_NORMAL
            ENGINE_SHIZUKU -> if (ShizukuFileEngine.isAvailable()) ENGINE_SHIZUKU else ENGINE_NORMAL
            else -> ENGINE_NORMAL
        }
    }

    /* ------------------------------------------------------------------ */
    /*  Helpers                                                            */
    /* ------------------------------------------------------------------ */

    private fun createPatternMatcher(pattern: String): (String) -> Boolean {
        val regex = globToRegex(pattern)
        return { name -> regex.matches(name) }
    }

    /**
     * Converts a simple glob pattern (with * and ? wildcards) into a [Regex].
     */
    private fun globToRegex(pattern: String): Regex {
        val sb = StringBuilder("^")
        pattern.forEach { ch ->
            when (ch) {
                '*' -> sb.append(".*")
                '?' -> sb.append(".")
                '.', '\\', '+', '[', ']', '(', ')', '{', '}', '^', '$', '|' -> {
                    sb.append('\\').append(ch)
                }

                else -> sb.append(ch)
            }
        }
        sb.append('$')
        return Regex(sb.toString(), RegexOption.IGNORE_CASE)
    }

    private fun fileToMap(file: File): Map<String, Any> {
        return mapOf(
            "path" to file.absolutePath,
            "name" to file.name,
            "size" to file.length(),
            "lastModified" to file.lastModified(),
            "isDirectory" to file.isDirectory,
            "subfileCount" to if (file.isDirectory) file.list()?.size ?: 0 else 0
        )
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        streamJob?.cancel()
        scope.cancel()
    }
}
