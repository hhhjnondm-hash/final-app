package com.islamyat.islamyat_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log

class AthanAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TRIGGER_ATHAN = "com.islamyat.islamyat_app.ACTION_TRIGGER_ATHAN"
        private const val TAG = "AthanAlarmReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.d(TAG, "onReceive triggered with action: $action")

        when (action) {
            ACTION_TRIGGER_ATHAN -> {
                // Acquire partial wake lock to keep CPU active while foreground service spins up
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                val wakeLock = powerManager?.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Islamiyat:AthanAlarmReceiverWakeLock"
                )
                wakeLock?.acquire(3 * 60 * 1000L /* 3 minutes */)

                val serviceIntent = Intent(context, AthanPlaybackService::class.java).apply {
                    putExtras(intent)
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    Log.d(TAG, "Started AthanPlaybackService successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start AthanPlaybackService: ${e.message}", e)
                } finally {
                    try {
                        if (wakeLock?.isHeld == true) {
                            wakeLock.release()
                        }
                    } catch (e: Exception) {
                        // ignore release error
                    }
                }
            }

            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_SET,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                Log.d(TAG, "Device rebooted or time changed: Rescheduling saved prayer athan alarms")
                AthanAlarmScheduler.rescheduleSavedAlarms(context)
            }
        }
    }
}
