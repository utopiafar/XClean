package com.utopiafar.xclean.utils

import android.content.Context
import android.os.Build
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Small persistent diagnostic log for storage operations.
 *
 * It is intentionally separate from cleanup history: these entries explain
 * what the native layer attempted and why a deletion was accepted or rejected.
 */
object DiagnosticLog {
    private const val TAG = "XCleanDiag"
    private const val MAX_BYTES = 512 * 1024
    private const val KEEP_CHARS = 256 * 1024

    @Volatile
    private var logFile: File? = null

    fun init(context: Context) {
        logFile = File(context.filesDir, "xclean_diagnostic.log")
        write(
            "app.init",
            "device=${Build.MANUFACTURER}/${Build.MODEL} brand=${Build.BRAND} " +
                    "android=${Build.VERSION.RELEASE} sdk=${Build.VERSION.SDK_INT}"
        )
    }

    @Synchronized
    fun write(event: String, message: String, throwable: Throwable? = null) {
        val sanitizedMessage = message.replace('\n', ' ').replace('\r', ' ')
        val line = "${timestamp()} [$event] $sanitizedMessage"
        if (throwable == null) {
            Log.d(TAG, line)
        } else {
            Log.d(TAG, line, throwable)
        }

        val file = logFile ?: return
        try {
            file.parentFile?.mkdirs()
            file.appendText(line + "\n")
            throwable?.let {
                file.appendText("${timestamp()} [$event.error] ${it::class.java.simpleName}: ${it.message}\n")
            }
            trimIfNeeded(file)
        } catch (ignored: Exception) {
            Log.d(TAG, "failed to write diagnostic log", ignored)
        }
    }

    @Synchronized
    fun read(): String {
        val file = logFile ?: return ""
        return try {
            if (file.exists()) file.readText() else ""
        } catch (e: Exception) {
            "Unable to read diagnostic log: ${e.message}"
        }
    }

    @Synchronized
    fun clear() {
        val file = logFile ?: return
        try {
            file.writeText("")
        } catch (ignored: Exception) {
            Log.d(TAG, "failed to clear diagnostic log", ignored)
        }
    }

    private fun trimIfNeeded(file: File) {
        if (file.length() <= MAX_BYTES) return

        val text = file.readText()
        file.writeText("--- log trimmed ---\n${text.takeLast(KEEP_CHARS)}")
    }

    private fun timestamp(): String {
        return SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
    }
}
