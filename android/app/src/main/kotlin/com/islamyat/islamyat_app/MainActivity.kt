package com.islamyat.islamyat_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.islamyat.islamyat_app/dynamic_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

        // Apply correct icon immediately and schedule next transition (6:00 AM or 6:00 PM)
        IconSwitchReceiver.updateLauncherIcon(this)
        IconSwitchReceiver.scheduleNextAlarm(this)
    }
}


