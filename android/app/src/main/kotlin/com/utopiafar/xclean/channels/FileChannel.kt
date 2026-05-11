package com.utopiafar.xclean.channels

import android.content.ContentUris
import android.content.Context
import android.media.MediaScannerConnection
import android.provider.BaseColumns
import android.provider.MediaStore
import android.os.Environment
import android.os.StatFs
import com.utopiafar.xclean.engine.RootFileEngine
import com.utopiafar.xclean.engine.ShizukuFileEngine
import com.utopiafar.xclean.utils.DiagnosticLog
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
    private val context: Context,
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
        val engine: String,
        val minSizeBytes: Long?
    )

    private data class TargetState(
        val exists: Boolean,
        val isFile: Boolean,
        val isDirectory: Boolean,
        val canRead: Boolean,
        val canWrite: Boolean,
        val length: Long,
        val lastModified: Long,
        val parentExists: Boolean,
        val parentCanRead: Boolean,
        val parentCanWrite: Boolean,
        val parentContains: Boolean?
    ) {
        val confirmedPresent: Boolean
            get() = exists || parentContains == true

        val confirmedAbsent: Boolean
            get() = !exists && parentContains == false

        fun toLogString(): String {
            return "exists=$exists isFile=$isFile isDir=$isDirectory canRead=$canRead " +
                    "canWrite=$canWrite length=$length lastModified=$lastModified " +
                    "parentExists=$parentExists parentCanRead=$parentCanRead " +
                    "parentCanWrite=$parentCanWrite parentContains=$parentContains"
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanPath" -> {
                val path = call.argument<String>("path")
                    ?: return result.error("INVALID_ARG", "path is required", null)
                val pattern = call.argument<String>("pattern")
                val recursive = call.argument<Boolean>("recursive") ?: true
                val engine = call.argument<String>("engine") ?: "auto"
                val minSizeBytes = numberArgument(call, "minSizeBytes")

                scope.launch(Dispatchers.IO) {
                    try {
                        DiagnosticLog.write(
                            "scan.request",
                            "path=$path recursive=$recursive engine=$engine " +
                                    "minSizeBytes=${minSizeBytes ?: ""} pattern=${pattern ?: ""}"
                        )
                        val files = scanPathInternal(path, pattern, recursive, engine, minSizeBytes)
                        withContext(Dispatchers.Main) { result.success(files) }
                    } catch (e: Exception) {
                        DiagnosticLog.write("scan.error", "path=$path engine=$engine", e)
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
                val minSizeBytes = numberArgument(call, "minSizeBytes")

                pendingStreamArgs = ScanArgs(path, pattern, recursive, engine, minSizeBytes)
                result.success(true)
            }

            "deleteFiles" -> {
                val paths = call.argument<List<String>>("paths")
                    ?: return result.error("INVALID_ARG", "paths is required", null)
                val engine = call.argument<String>("engine") ?: "auto"
                val requireExisting = call.argument<Boolean>("requireExisting") ?: true

                scope.launch(Dispatchers.IO) {
                    try {
                        DiagnosticLog.write(
                            "delete.request",
                            "count=${paths.size} engine=$engine requireExisting=$requireExisting"
                        )
                        val deleteResult = deleteFilesInternal(paths, engine, requireExisting)
                        withContext(Dispatchers.Main) { result.success(deleteResult) }
                    } catch (e: Exception) {
                        DiagnosticLog.write("delete.error", "count=${paths.size} engine=$engine", e)
                        withContext(Dispatchers.Main) {
                            result.error("DELETE_ERROR", e.message, null)
                        }
                    }
                }
            }

            "getDiagnosticLogs" -> result.success(DiagnosticLog.read())

            "clearDiagnosticLogs" -> {
                DiagnosticLog.clear()
                result.success(true)
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

            "getVideoThumbnail" -> {
                val path = call.argument<String>("path")
                    ?: return result.error("INVALID_ARG", "path is required", null)
                scope.launch(Dispatchers.IO) {
                    try {
                        val thumbPath = getVideoThumbnailInternal(path)
                        withContext(Dispatchers.Main) { result.success(thumbPath) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) { result.success(null) }
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
                scanPathStreamInternal(
                    args.path,
                    args.pattern,
                    args.recursive,
                    args.engine,
                    args.minSizeBytes,
                    events
                )
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
        engine: String,
        minSizeBytes: Long?
    ): List<Map<String, Any>> {
        val resolvedEngine = resolveEngine(engine)
        val results = when (resolvedEngine) {
            ENGINE_ROOT -> RootFileEngine.listFiles(path, recursive, pattern)
                .filterByMinSize(minSizeBytes)
            ENGINE_SHIZUKU -> ShizukuFileEngine.listFiles(path, recursive, pattern)
                .filterByMinSize(minSizeBytes)
            else -> {
                val results = mutableListOf<Map<String, Any>>()
                val root = File(path)
                if (!root.exists()) {
                    DiagnosticLog.write(
                        "scan.path_missing",
                        "path=$path requestedEngine=$engine resolvedEngine=$resolvedEngine"
                    )
                    return results
                }

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
                    if (!matchesMinSize(file, minSizeBytes)) return@forEach
                    results.add(fileToMap(file))
                }
                results
            }
        }
        DiagnosticLog.write(
            "scan.result",
            "path=$path requestedEngine=$engine resolvedEngine=$resolvedEngine " +
                    "minSizeBytes=${minSizeBytes ?: ""} count=${results.size}"
        )
        return results
    }

    private suspend fun scanPathStreamInternal(
        path: String,
        pattern: String?,
        recursive: Boolean,
        engine: String,
        minSizeBytes: Long?,
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
            if (!matchesMinSize(file, minSizeBytes)) return@forEach

            withContext(Dispatchers.Main) {
                events.success(fileToMap(file))
            }
            yield() // Cooperate with cancellation
        }
    }

    private fun deleteFilesInternal(paths: List<String>, engine: String, requireExisting: Boolean): Map<String, Any> {
        val resolvedEngine = resolveEngine(engine)
        DiagnosticLog.write(
            "delete.engine",
            "requestedEngine=$engine resolvedEngine=$resolvedEngine count=${paths.size}"
        )
        return when (resolvedEngine) {
            ENGINE_ROOT -> RootFileEngine.deleteFiles(paths)
            ENGINE_SHIZUKU -> ShizukuFileEngine.deleteFiles(paths)
            else -> deleteFilesWithNormalEngine(paths, requireExisting)
        }
    }

    private fun deleteFilesWithNormalEngine(paths: List<String>, requireExisting: Boolean): Map<String, Any> {
        val deletedPaths = mutableListOf<String>()
        val failedPaths = mutableListOf<String>()
        var successCount = 0
        var failCount = 0
        var freedBytes = 0L

        paths.forEach { path ->
            val file = File(path)
            val beforeState = inspectTarget(file)
            val size = when {
                beforeState.isFile -> beforeState.length
                beforeState.isDirectory -> getDirectorySizeInternal(path, ENGINE_NORMAL)
                else -> 0L
            }

            DiagnosticLog.write(
                "delete.normal.before",
                "path=$path requireExisting=$requireExisting size=$size ${beforeState.toLogString()}"
            )

            var deleteReturned = false
            var deleteError: String? = null
            try {
                deleteReturned = file.deleteRecursively()
            } catch (e: Exception) {
                deleteError = "${e::class.java.simpleName}: ${e.message}"
                DiagnosticLog.write("delete.normal.direct_error", "path=$path", e)
            }

            var afterState = inspectTarget(file)
            DiagnosticLog.write(
                "delete.normal.after_direct",
                "path=$path deleteReturned=$deleteReturned deleteError=${deleteError ?: ""} ${afterState.toLogString()}"
            )

            var mediaStoreRows = 0
            if (!afterState.confirmedAbsent) {
                mediaStoreRows = deleteViaMediaStore(path)
                if (mediaStoreRows > 0) {
                    notifyMediaScanner(path)
                    afterState = inspectTarget(file)
                }
                DiagnosticLog.write(
                    "delete.normal.after_mediastore",
                    "path=$path rows=$mediaStoreRows ${afterState.toLogString()}"
                )
            } else {
                notifyMediaScanner(path)
            }

            val wasKnownMissing = !beforeState.confirmedPresent && beforeState.confirmedAbsent
            val success = afterState.confirmedAbsent && (!requireExisting || beforeState.confirmedPresent || wasKnownMissing)

            if (success) {
                successCount++
                freedBytes += size
                deletedPaths.add(path)
                DiagnosticLog.write(
                    "delete.normal.success",
                    "path=$path size=$size directReturned=$deleteReturned mediaStoreRows=$mediaStoreRows"
                )
            } else {
                failCount++
                failedPaths.add(path)
                DiagnosticLog.write(
                    "delete.normal.fail",
                    "path=$path directReturned=$deleteReturned mediaStoreRows=$mediaStoreRows " +
                            "beforeConfirmedPresent=${beforeState.confirmedPresent} " +
                            "afterConfirmedAbsent=${afterState.confirmedAbsent}"
                )
            }
        }

        DiagnosticLog.write(
            "delete.summary",
            "engine=$ENGINE_NORMAL success=$successCount fail=$failCount freedBytes=$freedBytes"
        )

        return mapOf(
            "successCount" to successCount,
            "failCount" to failCount,
            "freedBytes" to freedBytes,
            "deletedPaths" to deletedPaths,
            "failedPaths" to failedPaths
        )
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

    private fun inspectTarget(file: File): TargetState {
        val parent = file.parentFile
        val parentNames = try {
            parent?.list()
        } catch (e: Exception) {
            DiagnosticLog.write("file.inspect_parent_error", "path=${file.absolutePath}", e)
            null
        }
        val parentContains = parentNames?.contains(file.name)

        return TargetState(
            exists = safeBoolean("exists", file) { file.exists() },
            isFile = safeBoolean("isFile", file) { file.isFile },
            isDirectory = safeBoolean("isDirectory", file) { file.isDirectory },
            canRead = safeBoolean("canRead", file) { file.canRead() },
            canWrite = safeBoolean("canWrite", file) { file.canWrite() },
            length = try {
                file.length()
            } catch (_: Exception) {
                0L
            },
            lastModified = try {
                file.lastModified()
            } catch (_: Exception) {
                0L
            },
            parentExists = parent?.let { safeBoolean("parent.exists", it) { it.exists() } } ?: false,
            parentCanRead = parent?.let { safeBoolean("parent.canRead", it) { it.canRead() } } ?: false,
            parentCanWrite = parent?.let { safeBoolean("parent.canWrite", it) { it.canWrite() } } ?: false,
            parentContains = parentContains
        )
    }

    private fun safeBoolean(label: String, file: File, block: () -> Boolean): Boolean {
        return try {
            block()
        } catch (e: Exception) {
            DiagnosticLog.write("file.$label.error", "path=${file.absolutePath}", e)
            false
        }
    }

    private fun deleteViaMediaStore(path: String): Int {
        return try {
            val resolver = context.contentResolver
            val collection = MediaStore.Files.getContentUri("external")
            val ids = mutableListOf<Long>()
            resolver.query(
                collection,
                arrayOf(BaseColumns._ID),
                "${MediaStore.MediaColumns.DATA}=?",
                arrayOf(path),
                null
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(BaseColumns._ID)
                while (cursor.moveToNext()) {
                    ids.add(cursor.getLong(idColumn))
                }
            }

            var deletedRows = 0
            ids.forEach { id ->
                val uri = ContentUris.withAppendedId(collection, id)
                deletedRows += resolver.delete(uri, null, null)
            }
            DiagnosticLog.write("delete.mediastore", "path=$path ids=${ids.size} deletedRows=$deletedRows")
            deletedRows
        } catch (e: Exception) {
            DiagnosticLog.write("delete.mediastore_error", "path=$path", e)
            0
        }
    }

    private fun notifyMediaScanner(path: String) {
        try {
            MediaScannerConnection.scanFile(context, arrayOf(path), null) { scannedPath, uri ->
                DiagnosticLog.write("media.scan", "path=$scannedPath uri=${uri ?: ""}")
            }
        } catch (e: Exception) {
            DiagnosticLog.write("media.scan_error", "path=$path", e)
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

    private fun numberArgument(call: MethodCall, name: String): Long? {
        return when (val raw = call.argument<Any>(name)) {
            is Number -> raw.toLong()
            else -> null
        }
    }

    private fun matchesMinSize(file: File, minSizeBytes: Long?): Boolean {
        if (minSizeBytes == null || file.isDirectory) return true
        return file.length() >= minSizeBytes
    }

    private fun List<Map<String, Any>>.filterByMinSize(minSizeBytes: Long?): List<Map<String, Any>> {
        if (minSizeBytes == null) return this
        return filter { item ->
            val isDirectory = item["isDirectory"] as? Boolean ?: false
            val size = item["size"] as? Number ?: return@filter false
            isDirectory || size.toLong() >= minSizeBytes
        }
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

    private fun getVideoThumbnailInternal(videoPath: String): String? {
        val file = File(videoPath)
        if (!file.exists() || !file.isFile) return null

        return try {
            val retriever = android.media.MediaMetadataRetriever()
            retriever.setDataSource(videoPath)
            val bitmap = retriever.getFrameAtTime(0, android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            retriever.release()

            if (bitmap != null) {
                val cacheDir = android.os.Environment.getExternalStorageDirectory()?.let { File(it, "Android/data/com.utopiafar.xclean/cache/thumbs") }
                    ?: File(file.parentFile, ".xclean_thumbs")
                cacheDir.mkdirs()
                val thumbFile = File(cacheDir, "thumb_${file.name.hashCode()}.jpg")
                java.io.FileOutputStream(thumbFile).use { out ->
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, out)
                }
                thumbFile.absolutePath
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
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
