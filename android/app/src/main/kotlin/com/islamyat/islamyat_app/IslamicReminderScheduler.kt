package com.islamyat.islamyat_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

object IslamicReminderScheduler {
    private const val TAG = "IslamicReminderScheduler"
    private const val PREFS_NAME = "islamic_reminder_prefs"
    private const val KEY_REMINDERS_JSON = "reminders_json"

    fun scheduleRemindersList(context: Context, remindersJson: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_REMINDERS_JSON, remindersJson).apply()

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        try {
            val jsonArray = JSONArray(remindersJson)
            val now = System.currentTimeMillis()

            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val id = obj.optInt("id", 1000 + i)
                val title = obj.optString("title", "تذكير إيماني")
                val body = obj.optString("body", "")
                val category = obj.optString("category", "تذكير")
                val timestampMs = obj.optLong("timestampMs", 0L)

                cancelSingleReminder(context, alarmManager, id)

                if (timestampMs > now) {
                    val triggerIntent = Intent(context, IslamicReminderReceiver::class.java).apply {
                        action = IslamicReminderReceiver.ACTION_TRIGGER_REMINDER
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("body", body)
                        putExtra("category", category)
                    }

                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }

                    val pendingIntent = PendingIntent.getBroadcast(context, id, triggerIntent, flags)

                    val showIntent = Intent(context, MainActivity::class.java)
                    val showPendingIntent = PendingIntent.getActivity(context, id + 90000, showIntent, flags)

                    val alarmClockInfo = AlarmManager.AlarmClockInfo(timestampMs, showPendingIntent)
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    Log.d(TAG, "Scheduled AlarmClock for reminder $id ($title) at $timestampMs")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling reminders list: ${e.message}", e)
        }
    }

    fun scheduleSingleReminder(context: Context, id: Int, title: String, body: String, timestampMs: Long, category: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val now = System.currentTimeMillis()
        if (timestampMs <= now) return

        cancelSingleReminder(context, alarmManager, id)

        val triggerIntent = Intent(context, IslamicReminderReceiver::class.java).apply {
            action = IslamicReminderReceiver.ACTION_TRIGGER_REMINDER
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("category", category)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getBroadcast(context, id, triggerIntent, flags)

        val showIntent = Intent(context, MainActivity::class.java)
        val showPendingIntent = PendingIntent.getActivity(context, id + 90000, showIntent, flags)

        val alarmClockInfo = AlarmManager.AlarmClockInfo(timestampMs, showPendingIntent)
        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
        Log.d(TAG, "Scheduled single AlarmClock for reminder $id ($title) at $timestampMs")
    }

    private fun cancelSingleReminder(context: Context, alarmManager: AlarmManager, id: Int) {
        try {
            val intent = Intent(context, IslamicReminderReceiver::class.java).apply {
                action = IslamicReminderReceiver.ACTION_TRIGGER_REMINDER
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_NO_CREATE
            }
            val existing = PendingIntent.getBroadcast(context, id, intent, flags)
            if (existing != null) {
                alarmManager.cancel(existing)
                existing.cancel()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling reminder $id: ${e.message}")
        }
    }

    fun cancelAllReminders(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val remindersJson = prefs.getString(KEY_REMINDERS_JSON, null)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        if (remindersJson != null) {
            try {
                val jsonArray = JSONArray(remindersJson)
                for (i in 0 until jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val id = obj.optInt("id", 1000 + i)
                    cancelSingleReminder(context, alarmManager, id)
                }
            } catch (e: Exception) {
                // ignore
            }
        }
        prefs.edit().remove(KEY_REMINDERS_JSON).apply()
        Log.d(TAG, "Cancelled all scheduled islamic reminders")
    }

    fun rescheduleSavedReminders(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val remindersJson = prefs.getString(KEY_REMINDERS_JSON, null) ?: return
        Log.d(TAG, "Rescheduling saved reminders after reboot/time change")
        scheduleRemindersList(context, remindersJson)
    }
}
