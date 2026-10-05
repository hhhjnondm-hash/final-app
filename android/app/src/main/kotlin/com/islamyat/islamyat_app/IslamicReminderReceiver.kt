package com.islamyat.islamyat_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class IslamicReminderReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TRIGGER_REMINDER = "com.islamyat.islamyat_app.ACTION_TRIGGER_REMINDER"
        private const val TAG = "IslamicReminderReceiver"
        private const val CHANNEL_ID = "islamic_reminders_v5"
        const val UNIFIED_REMINDER_NOTIFICATION_ID = 7777
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.d(TAG, "onReceive triggered with action: $action")

        when (action) {
            ACTION_TRIGGER_REMINDER -> {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                val wakeLock = powerManager?.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Islamiyat:IslamicReminderWakeLock"
                )
                wakeLock?.acquire(5 * 1000L /* 5 seconds */)

                try {
                    val id = intent.getIntExtra("id", UNIFIED_REMINDER_NOTIFICATION_ID)
                    val title = intent.getStringExtra("title") ?: "تذكير إيماني"
                    val body = intent.getStringExtra("body") ?: "سبحان الله وبحمده، سبحان الله العظيم"
                    val category = intent.getStringExtra("category") ?: "رفيق المسلم"

                    createNotificationChannel(context)
                    showNotification(context, id, title, body, category)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to display reminder notification: ${e.message}", e)
                } finally {
                    try {
                        if (wakeLock?.isHeld == true) {
                            wakeLock.release()
                        }
                    } catch (e: Exception) {
                        // ignore
                    }
                }
            }

            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.TIME_SET",
            Intent.ACTION_TIMEZONE_CHANGED -> {
                Log.d(TAG, "Device rebooted or time changed: Rescheduling saved islamic reminders")
                IslamicReminderScheduler.rescheduleSavedReminders(context)
            }
        }
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return

            val channel = NotificationChannel(
                CHANNEL_ID,
                "التذكيرات الإيمانية اليومية",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "آيات وأدعية وأذكار يومية مباركة تظهر حتى مع قفل الشاشة"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                enableVibration(true)
                enableLights(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(context: Context, id: Int, title: String, body: String, category: String) {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val openIntent = Intent(context, MainActivity::class.java)
        openIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val pendingIntent = PendingIntent.getActivity(context, UNIFIED_REMINDER_NOTIFICATION_ID, openIntent, flags)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body).setSummaryText(category))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = NotificationManagerCompat.from(context)
        try {
            // Cancel previous active reminder first to ensure only 1 clean reminder remains
            notificationManager.cancel(UNIFIED_REMINDER_NOTIFICATION_ID)
            // Post with unified ID so it gracefully replaces previous notification
            notificationManager.notify(UNIFIED_REMINDER_NOTIFICATION_ID, notification)
            Log.d(TAG, "Single Islamic reminder notification posted cleanly with ID: $UNIFIED_REMINDER_NOTIFICATION_ID ($title)")
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException posting notification: ${e.message}")
        }
    }
}
