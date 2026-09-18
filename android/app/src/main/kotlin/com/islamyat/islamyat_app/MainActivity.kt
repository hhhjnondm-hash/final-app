package com.islamyat.islamyat_app

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.islamyat.islamyat_app/dynamic_icon"
    private val SYSTEM_CHANNEL = "com.islamyat.islamyat_app/system_status"
    private val ATHAN_NATIVE_CHANNEL = "com.islamyat.islamyat_app/athan_native"
    private val REMINDERS_NATIVE_CHANNEL = "com.islamyat.islamyat_app/reminders_native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Dynamic App Launcher Icon Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateIconByTime" -> {
                    val activeMode = IconSwitchReceiver.updateLauncherIcon(this)
                    IconSwitchReceiver.scheduleNextAlarm(this)
                    result.success(activeMode)
                }
                "getCurrentIconMode" -> {
                    val currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
                    val mode = if (currentHour in 6..17) "day" else "night"
                    result.success(mode)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // System Status Channel (Silent / Vibrate detection)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSilentMode" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                        val isSilent = audioManager.ringerMode == android.media.AudioManager.RINGER_MODE_SILENT ||
                                      audioManager.ringerMode == android.media.AudioManager.RINGER_MODE_VIBRATE
                        result.success(isSilent)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Native Background Athan Alarms & Foreground Service Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ATHAN_NATIVE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAthanAlarms" -> {
                    try {
                        val alarmsJson = call.argument<String>("alarmsJson") ?: "[]"
                        val respectSilentMode = call.argument<Boolean>("respectSilentMode") ?: true
                        AthanAlarmScheduler.scheduleAlarms(this, alarmsJson, respectSilentMode)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "cancelAllAthanAlarms" -> {
                    try {
                        AthanAlarmScheduler.cancelAllAlarms(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                "stopAthanSound" -> {
                    try {
                        val stopIntent = Intent(this, AthanPlaybackService::class.java).apply {
                            action = AthanPlaybackService.ACTION_STOP_ATHAN
                        }
                        startService(stopIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
                "testNativeAthan" -> {
                    try {
                        val prayer = call.argument<String>("prayer") ?: "Dhuhr"
                        val arabicName = call.argument<String>("arabicName") ?: "الظهر"
                        val isFajr = call.argument<Boolean>("isFajr") ?: false
                        val respectSilentMode = call.argument<Boolean>("respectSilentMode") ?: true

                        val serviceIntent = Intent(this, AthanPlaybackService::class.java).apply {
                            putExtra("prayer_name", prayer)
                            putExtra("arabic_name", arabicName)
                            putExtra("is_fajr", isFajr)
                            putExtra("respect_silent_mode", respectSilentMode)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("TEST_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Native Background Islamic Reminders Channel (AlarmClock & Lock Screen wakeup)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, REMINDERS_NATIVE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleRemindersList" -> {
                    try {
                        val remindersJson = call.argument<String>("remindersJson") ?: "[]"
                        IslamicReminderScheduler.scheduleRemindersList(this, remindersJson)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_REMINDERS_ERROR", e.message, null)
                    }
                }
                "scheduleSingleReminder" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 9001
                        val title = call.argument<String>("title") ?: "تذكير إيماني"
                        val body = call.argument<String>("body") ?: ""
                        val timestampMs = call.argument<Long>("timestampMs") ?: 0L
                        val category = call.argument<String>("category") ?: "تذكير"
                        IslamicReminderScheduler.scheduleSingleReminder(this, id, title, body, timestampMs, category)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_SINGLE_ERROR", e.message, null)
                    }
                }
                "cancelAllReminders" -> {
                    try {
                        IslamicReminderScheduler.cancelAllReminders(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_REMINDERS_ERROR", e.message, null)
                    }
                }
                "testNativeReminder" -> {
                    try {
                        val title = call.argument<String>("title") ?: "📖 آية وتدبر: قال الله تعالى"
                        val body = call.argument<String>("body") ?: "﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾"
                        val category = call.argument<String>("category") ?: "آية وتدبر"
                        val testTime = System.currentTimeMillis() + 1000L // 1 second in future
                        IslamicReminderScheduler.scheduleSingleReminder(this, 9998, title, body, testTime, category)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("TEST_REMINDER_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Apply correct icon immediately and schedule next transition (6:00 AM or 6:00 PM)
        IconSwitchReceiver.updateLauncherIcon(this)
        IconSwitchReceiver.scheduleNextAlarm(this)
    }
}
