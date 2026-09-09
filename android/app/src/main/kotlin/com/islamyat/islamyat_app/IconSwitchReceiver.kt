package com.islamyat.islamyat_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import java.util.Calendar

class IconSwitchReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_SWITCH_ICON = "com.islamyat.islamyat_app.ACTION_SWITCH_ICON"
        private const val REQUEST_CODE = 9021

        fun scheduleNextAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, IconSwitchReceiver::class.java).apply {
                action = ACTION_SWITCH_ICON
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags)

            // Determine the next 6:00 AM or 6:00 PM transition
            val now = Calendar.getInstance()
            val nextTransition = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val currentHour = now.get(Calendar.HOUR_OF_DAY)
            if (currentHour < 6) {
                // Next transition is today 6:00 AM
                nextTransition.set(Calendar.HOUR_OF_DAY, 6)
                nextTransition.set(Calendar.MINUTE, 0)
            } else if (currentHour < 18) {
                // Next transition is today 6:00 PM (18:00)
                nextTransition.set(Calendar.HOUR_OF_DAY, 18)
                nextTransition.set(Calendar.MINUTE, 0)
            } else {
                // Next transition is tomorrow 6:00 AM
                nextTransition.add(Calendar.DAY_OF_YEAR, 1)
                nextTransition.set(Calendar.HOUR_OF_DAY, 6)
                nextTransition.set(Calendar.MINUTE, 0)
            }

            val triggerMillis = nextTransition.timeInMillis

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerMillis, pendingIntent)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun updateLauncherIcon(context: Context): String {
            val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            val isDay = hour in 6..17 // 6:00 AM until 5:59 PM

            val pm = context.packageManager
            val dayComponent = ComponentName(context, "com.islamyat.islamyat_app.MainActivityDay")
            val nightComponent = ComponentName(context, "com.islamyat.islamyat_app.MainActivityNight")

            try {
                if (isDay) {
                    if (pm.getComponentEnabledSetting(dayComponent) != PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                        pm.setComponentEnabledSetting(
                            dayComponent,
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                            PackageManager.DONT_KILL_APP
                        )
                    }
                    if (pm.getComponentEnabledSetting(nightComponent) != PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
                        pm.setComponentEnabledSetting(
                            nightComponent,
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                            PackageManager.DONT_KILL_APP
                        )
                    }
                    return "day"
                } else {
                    if (pm.getComponentEnabledSetting(nightComponent) != PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                        pm.setComponentEnabledSetting(
                            nightComponent,
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                            PackageManager.DONT_KILL_APP
                        )
                    }
                    if (pm.getComponentEnabledSetting(dayComponent) != PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
                        pm.setComponentEnabledSetting(
                            dayComponent,
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                            PackageManager.DONT_KILL_APP
                        )
                    }
                    return "night"
                }
            } catch (e: Exception) {
                e.printStackTrace()
                return "error"
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        // Update icon based on current time (Day vs Night)
        updateLauncherIcon(context)
        // Reschedule next alarm for continuous 6:00 AM / 6:00 PM transitions
        scheduleNextAlarm(context)
    }
}
