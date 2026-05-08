package com.utopiafar.xclean.services

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * A [CoroutineWorker] that is triggered periodically by WorkManager
 * to perform automatic cleanup tasks.
 *
 * For the MVP this only logs invocation details; real cleaning logic
 * will be added in a later iteration.
 */
class AutoCleanWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        const val KEY_RULE_IDS = "rule_ids"
        const val KEY_USE_FOREGROUND = "use_foreground"
        private const val TAG = "AutoCleanWorker"
    }

    override suspend fun doWork(): Result {
        val ruleIds = inputData.getIntArray(KEY_RULE_IDS)?.toList() ?: emptyList()
        val useForegroundService = inputData.getBoolean(KEY_USE_FOREGROUND, false)

        Log.i(
            TAG,
            "AutoCleanWorker triggered. Rules: $ruleIds, useForegroundService: $useForegroundService"
        )

        // TODO: Wire up actual engine-based cleanup here in future iterations.

        return Result.success()
    }
}
