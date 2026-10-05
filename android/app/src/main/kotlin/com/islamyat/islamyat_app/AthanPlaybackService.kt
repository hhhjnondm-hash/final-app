package com.islamyat.islamyat_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AthanPlaybackService : Service() {

    companion object {
        const val ACTION_STOP_ATHAN = "com.islamyat.islamyat_app.ACTION_STOP_ATHAN"
        private const val TAG = "AthanPlaybackService"
        private const val CHANNEL_ID = "athan_native_foreground_v5"
        private const val MISSED_CHANNEL_ID = "missed_prayer_channel_v5"
        private const val NOTIFICATION_ID = 9991
        private const val MISSED_NOTIFICATION_ID = 9992
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var dismissHandler: Handler? = null
    private var dismissRunnable: Runnable? = null
    private var currentArabicName: String = "الصلاة"
    private var isReceiverRegistered = false

    private val volumeChangeReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            if (action == "android.media.VOLUME_CHANGED_ACTION" ||
                action == AudioManager.RINGER_MODE_CHANGED_ACTION) {
                Log.d(TAG, "Volume or ringer changed during Athan: Silencing and stopping Athan immediately")
                stopAthanPlayback(userInitiated = true)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: Initializing AthanPlaybackService")

        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Islamiyat:AthanPlaybackServiceWakeLock"
        )?.apply {
            acquire(3 * 60 * 1000L /* 3 minutes max */)
        }

        if (!isReceiverRegistered) {
            val filter = android.content.IntentFilter().apply {
                addAction("android.media.VOLUME_CHANGED_ACTION")
                addAction(AudioManager.RINGER_MODE_CHANGED_ACTION)
            }
            try {
                registerReceiver(volumeChangeReceiver, filter)
                isReceiverRegistered = true
                Log.d(TAG, "Registered volumeChangeReceiver for instant silence on volume buttons")
            } catch (e: Exception) {
                Log.e(TAG, "Error registering volumeChangeReceiver: ${e.message}")
            }
        }

        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "onStartCommand received action: $action")

        if (action == ACTION_STOP_ATHAN) {
            stopAthanPlayback(userInitiated = true)
            return START_NOT_STICKY
        }

        val prayerName = intent?.getStringExtra("prayer_name") ?: "Prayer"
        val arabicName = intent?.getStringExtra("arabic_name") ?: "الصلاة"
        val isFajr = intent?.getBooleanExtra("is_fajr", false) ?: false
        val respectSilentMode = intent?.getBooleanExtra("respect_silent_mode", true) ?: true
        currentArabicName = arabicName

        // Cancel previous Islamic reminders & old prayer notifications to keep notification drawer clean
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(IslamicReminderReceiver.UNIFIED_REMINDER_NOTIFICATION_ID)
        notificationManager?.cancel(MISSED_NOTIFICATION_ID)

        // 1. Build and show Ongoing Foreground Notification
        val notification = buildAthanNotification(prayerName, arabicName)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service: ${e.message}", e)
        }

        // 2. Check if device is in Silent or Vibrate mode
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val isSilent = audioManager?.let {
            it.ringerMode == AudioManager.RINGER_MODE_SILENT ||
            it.ringerMode == AudioManager.RINGER_MODE_VIBRATE
        } ?: false

        val shortAthanOnSilent = intent?.getBooleanExtra("short_athan_on_silent", true) ?: true
        val isShortAthan = isSilent && respectSilentMode && shortAthanOnSilent

        // 3. Play Athan Audio using MediaPlayer on USAGE_ALARM stream
        try {
            val audioResId = if (isFajr) R.raw.athan_fajr else R.raw.athan_sound
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
                setAudioAttributes(audioAttributes)
                val afd = resources.openRawResourceFd(audioResId)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                setVolume(1.0f, 1.0f)
                setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                prepare()
                setOnCompletionListener {
                    Log.d(TAG, "Athan playback completed normally")
                    stopAthanPlayback(userInitiated = false)
                }
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                    stopAthanPlayback(userInitiated = false)
                    true
                }
                start()
            }
            Log.d(TAG, "MediaPlayer started successfully for $arabicName (isSilent=$isSilent, isShortAthan=$isShortAthan)")

            if (isShortAthan) {
                Log.d(TAG, "Short Athan mode: Scheduled auto-stop after 28 seconds (Takbeerat & Shahada)")
                dismissHandler = Handler(Looper.getMainLooper())
                dismissRunnable = Runnable {
                    Log.d(TAG, "Short Athan duration elapsed: Stopping audio playback gracefully")
                    stopAthanPlayback(userInitiated = false)
                }
                dismissHandler?.postDelayed(dismissRunnable!!, 28 * 1000L)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize/play MediaPlayer: ${e.message}", e)
            stopAthanPlayback(userInitiated = false)
        }

        return START_NOT_STICKY
    }

    private fun buildAthanNotification(prayerName: String, arabicName: String): Notification {
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        // Full-screen / tap intent opens MainActivity
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(this, 1001, openAppIntent, pendingIntentFlags)

        // Stop Athan action intent
        val stopIntent = Intent(this, AthanPlaybackService::class.java).apply {
            action = ACTION_STOP_ATHAN
        }
        val stopPendingIntent = PendingIntent.getService(this, 1002, stopIntent, pendingIntentFlags)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("🕌 حان الآن أَذَان صلاة $arabicName")
            .setContentText("حي على الصلاة .. حي على الفلاح (قال تعالى: ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾)")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("حان الآن موعد أذان صلاة $arabicName - أقم صلاتك يرحمك الله.\nقال الله تعالى: ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(openAppPendingIntent)
            .addAction(R.mipmap.ic_launcher, "إيقاف الأذان 🔕", stopPendingIntent)
            .addAction(R.mipmap.ic_launcher, "هيا إلى الصلاة 🧎", openAppPendingIntent)
            .build()
    }

    private fun stopAthanPlayback(userInitiated: Boolean) {
        Log.d(TAG, "stopAthanPlayback called (userInitiated=$userInitiated)")

        dismissRunnable?.let { dismissHandler?.removeCallbacks(it) }

        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.release()
            }
            mediaPlayer = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaPlayer: ${e.message}")
        }

        // Release WakeLock immediately so CPU goes to sleep and phone stays cool
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            wakeLock = null
        } catch (e: Exception) {
            // ignore
        }

        // Remove foreground notification
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        // Show Missed Prayer Reminder follow-up notification only if stopped naturally or after timeout
        if (!userInitiated) {
            showMissedPrayerReminder(currentArabicName)
        }

        stopSelf()
    }

    private fun showMissedPrayerReminder(arabicName: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val openIntent = Intent(this, MainActivity::class.java)
            openIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val pendingIntent = PendingIntent.getActivity(this, 1003, openIntent, flags)

            val missedNotification = NotificationCompat.Builder(this, MISSED_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("⏰ تذكير: هل صليت صلاة $arabicName؟")
                .setContentText("قال النبي ﷺ: «من حافظ عليها كانت له نوراً وبرهاناً ونجاةً يوم القيامة»")
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .bigText("أخي المسلم الكريم، هل أديت صلاة $arabicName؟\nقال رسول الله ﷺ: «من حافظ عليها كانت له نوراً وبرهاناً ونجاةً يوم القيامة» [رواه أحمد]")
                )
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build()

            notificationManager.notify(MISSED_NOTIFICATION_ID, missedNotification)
            Log.d(TAG, "Missed prayer reminder posted successfully for $arabicName")
        } catch (e: Exception) {
            Log.e(TAG, "Error posting missed prayer reminder: ${e.message}")
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return

            // 1. Foreground Athan Channel
            val athanChannel = NotificationChannel(
                CHANNEL_ID,
                "أذان الصلوات المفروضة (تنبيه مستمر)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "قناة إشعار وتشغيل الأذان الصوتي الإجباري في موعد الصلاة"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null) // Audio is handled directly by MediaPlayer to avoid overlapping sounds
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(athanChannel)

            // 2. Missed Prayer Follow-up Channel
            val missedChannel = NotificationChannel(
                MISSED_CHANNEL_ID,
                "تذكير بالصلوات المفروضة",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تنبيه لمتابعة أداء الصلاة بعد الأذان"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(missedChannel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy: Cleaning up resources")
        dismissRunnable?.let { dismissHandler?.removeCallbacks(it) }

        if (isReceiverRegistered) {
            try {
                unregisterReceiver(volumeChangeReceiver)
                isReceiverRegistered = false
                Log.d(TAG, "Unregistered volumeChangeReceiver")
            } catch (e: Exception) {
                // ignore
            }
        }

        try {
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {
            // ignore
        }
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            wakeLock = null
        } catch (e: Exception) {
            // ignore
        }
    }
}
