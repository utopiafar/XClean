package com.utopiafar.xclean.channels

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.utopiafar.xclean.services.AutoCleanWorker
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

/**
 * MethodChannel handler for background / auto-clean scheduling.
 *
 * Channel: com.utopiafar.xclean/background
 *
 * Uses [WorkManager] to enqueue periodic work. Foreground-service integration
 * is stubbed for future expansion.
 */
class BackgroundChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.utopiafar.xclean/background"
        const val AUTO_CLEAN_WORK_NAME = "xclean_auto_clean"
    }

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scheduleAutoClean" -> {
                val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 60
                val ruleIds = call.argument<List<Int>>("ruleIds") ?: emptyList()
                val useForegroundService =
                    call.argument<Boolean>("useForegroundService") ?: false

                result.success(scheduleAutoClean(intervalMinutes, ruleIds, useForegroundService))
            }

            "cancelAutoClean" -> {
                result.success(cancelAutoClean())
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Schedules a periodic [AutoCleanWorker] via WorkManager.
     *
     * @param intervalMinutes Minimum interval is 15 minutes (enforced by WorkManager).
     * @param ruleIds IDs of the cleanup rules to apply.
     * @param useForegroundService Reserved for future foreground-service mode.
     */
    private fun scheduleAutoClean(
        intervalMinutes: Int,
        ruleIds: List<Int>,
        useForegroundService: Boolean
    ): Boolean {
        return try {
            val interval = intervalMinutes.coerceAtLeast(15).toLong()

            val workRequest = PeriodicWorkRequestBuilder<AutoCleanWorker>(
                interval,
                TimeUnit.MINUTES
            ).setInputData(
                workDataOf(
                    AutoCleanWorker.KEY_RULE_IDS to ruleIds.toIntArray(),
                    AutoCleanWorker.KEY_USE_FOREGROUND to useForegroundService
                )
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                AUTO_CLEAN_WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                workRequest
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Cancels the unique periodic auto-clean work.
     */
    private fun cancelAutoClean(): Boolean {
        return try {
            WorkManager.getInstance(context).cancelUniqueWork(AUTO_CLEAN_WORK_NAME)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
