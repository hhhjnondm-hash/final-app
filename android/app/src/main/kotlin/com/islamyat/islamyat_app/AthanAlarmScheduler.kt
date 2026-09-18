package com.islamyat.islamyat_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

object AthanAlarmScheduler {
    private const val TAG = "AthanAlarmScheduler"
    private const val PREFS_NAME = "athan_alarm_prefs"
    private const val KEY_ALARMS_JSON = "alarms_json"
    private const val KEY_RESPECT_SILENT = "respect_silent_mode"
    private const val BASE_REQUEST_CODE = 8000

    fun scheduleAlarms(context: Context, alarmsJson: String, respectSilentMode: Boolean) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_ALARMS_JSON, alarmsJson)
            .putBoolean(KEY_RESPECT_SILENT, respectSilentMode)
            .apply()

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        try {
            val jsonArray = JSONArray(alarmsJson)
            val now = System.currentTimeMillis()

            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val prayerName = obj.optString("prayer", "")
                val arabicName = obj.optString("arabicName", prayerName)
                val timestampMs = obj.optLong("timestampMs", 0L)
                val isFajr = obj.optBoolean("isFajr", false)
                val requestCode = BASE_REQUEST_CODE + i

                // Cancel any existing alarm for this slot
                cancelSingleAlarm(context, alarmManager, requestCode)

                // Schedule if in the future
                if (timestampMs > now) {
                    val triggerIntent = Intent(context, AthanAlarmReceiver::class.java).apply {
                        action = AthanAlarmReceiver.ACTION_TRIGGER_ATHAN
                        putExtra("prayer_name", prayerName)
                        putExtra("arabic_name", arabicName)
                        putExtra("is_fajr", isFajr)
                        putExtra("request_code", requestCode)
                        putExtra("respect_silent_mode", respectSilentMode)
                    }

                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }

                    val pendingIntent = PendingIntent.getBroadcast(context, requestCode, triggerIntent, flags)

                    val showIntent = Intent(context, MainActivity::class.java)
                    val showPendingIntent = PendingIntent.getActivity(context, requestCode + 500, showIntent, flags)

                    val alarmClockInfo = AlarmManager.AlarmClockInfo(timestampMs, showPendingIntent)
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    Log.d(TAG, "Scheduled AlarmClock for $prayerName ($arabicName) at $timestampMs")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling athan alarms: ${e.message}", e)
        }
    }

    private fun cancelSingleAlarm(context: Context, alarmManager: AlarmManager, requestCode: Int) {
        try {
            val intent = Intent(context, AthanAlarmReceiver::class.java).apply {
                action = AthanAlarmReceiver.ACTION_TRIGGER_ATHAN
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_NO_CREATE
            }
            val existing = PendingIntent.getBroadcast(context, requestCode, intent, flags)
            if (existing != null) {
                alarmManager.cancel(existing)
                existing.cancel()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling alarm $requestCode: ${e.message}")
        }
    }

    fun cancelAllAlarms(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        for (i in 0..10) {
            cancelSingleAlarm(context, alarmManager, BASE_REQUEST_CODE + i)
        }
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_ALARMS_JSON).apply()
        Log.d(TAG, "Cancelled all scheduled athan alarms")
    }

    fun rescheduleSavedAlarms(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alarmsJson = prefs.getString(KEY_ALARMS_JSON, null) ?: return
        val respectSilentMode = prefs.getBoolean(KEY_RESPECT_SILENT, true)
        Log.d(TAG, "Rescheduling saved alarms after reboot/time change")
        scheduleAlarms(context, alarmsJson, respectSilentMode)
    }
}
