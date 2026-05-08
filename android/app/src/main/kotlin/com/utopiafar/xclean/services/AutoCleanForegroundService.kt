package com.utopiafar.xclean.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground service stub for auto-clean operations.
 *
 * The service posts a low-priority notification and runs in the foreground
 * so that the system is less likely to kill it during long-running cleanup.
 *
 * Real cleanup logic will be integrated here in a future iteration.
 */
class AutoCleanForegroundService : Service() {

    companion object {
        private const val TAG = "AutoCleanFgService"
        private const val CHANNEL_ID = "xclean_auto_clean_channel"
        private const val NOTIFICATION_ID = 1001
        const val EXTRA_RULE_IDS = "rule_ids"

        /**
         * Convenience helper to start this service in the foreground.
         */
        fun start(context: Context, ruleIds: List<Int>) {
            val intent = Intent(context, AutoCleanForegroundService::class.java).apply {
                putExtra(EXTRA_RULE_IDS, ruleIds.toIntArray())
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val ruleIds = intent?.getIntArrayExtra(EXTRA_RULE_IDS)?.toList() ?: emptyList()
        Log.i(TAG, "Foreground service started with rules: $ruleIds")

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("XClean Auto Clean")
            .setContentText("Running automatic cleanup...")
            .setSmallIcon(android.R.drawable.ic_menu_delete)
            .setOngoing(true)
            .setSilent(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // TODO: Integrate actual cleanup engine here in future iterations.

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Auto Clean",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for automatic cleaning tasks"
            }
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
