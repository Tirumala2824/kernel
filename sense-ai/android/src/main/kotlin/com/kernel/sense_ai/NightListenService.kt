package com.kernel.sense_ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * `microphone`-type foreground service for night listening. It holds no
 * audio itself: it keeps the process eligible for microphone access while
 * the screen is off, and shows the ongoing notification with a Stop
 * action. [ListenController] starts it only while the app is visible
 * (Android 14+ forbids starting a microphone FGS from the background).
 */
class NightListenService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            ListenController.stop(ListenController.REASON_NOTIFICATION)
            stopSelfCompat()
            return START_NOT_STICKY
        }
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= 29) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: RuntimeException) {
            // Not allowed (e.g. started while not visible): stop listening.
            ListenController.stop(ListenController.REASON_NOT_VISIBLE)
            stopSelfCompat()
        }
        // Never restarted by the system: listening needs the user present.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        if (ListenController.isNight) ListenController.stop(null)
        super.onDestroy()
    }

    private fun stopSelfCompat() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26 && manager?.getNotificationChannel(CHANNEL_ID) == null) {
            manager?.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, getString(R.string.sense_listen_channel), NotificationManager.IMPORTANCE_LOW),
            )
        }
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, NightListenService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 2, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL_ID) else @Suppress("DEPRECATION") Notification.Builder(this)
        builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(getString(R.string.sense_listen_notification_title))
            .setContentText(getString(R.string.sense_listen_notification_text))
            .setOngoing(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(Notification.Action.Builder(null, getString(R.string.sense_listen_stop), stop).build())
        if (open != null) builder.setContentIntent(open)
        if (Build.VERSION.SDK_INT >= 31) builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        return builder.build()
    }

    companion object {
        private const val CHANNEL_ID = "sense_ai_listen"
        private const val NOTIFICATION_ID = 0x5E45
        private const val ACTION_STOP = "com.kernel.sense_ai.action.STOP_LISTENING"

        fun start(context: Context) {
            val intent = Intent(context, NightListenService::class.java)
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, NightListenService::class.java))
        }
    }
}
