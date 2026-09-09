package com.islamyat.islamyat_app

import android.content.ComponentName
import android.content.pm.PackageManager
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
                    val hour = call.argument<Int>("hour") ?: Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
                    val activeMode = applyIconForHour(hour)
                    result.success(activeMode)
                }
                "getCurrentIconMode" -> {
                    result.success(getCurrentIconMode())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Apply correct icon based on current time upon launch
        val currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        applyIconForHour(currentHour)
    }

    private fun applyIconForHour(hour: Int): String {
        val isDay = hour in 6..17 // 6:00 AM until 5:59 PM (17:59)
        val dayAlias = "com.islamyat.islamyat_app.MainActivityDay"
        val nightAlias = "com.islamyat.islamyat_app.MainActivityNight"

        val pm = packageManager
        val dayComponent = ComponentName(this, dayAlias)
        val nightComponent = ComponentName(this, nightAlias)

        try {
            if (isDay) {
                // Enable Day Icon, Disable Night Icon
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
                // Enable Night Icon, Disable Day Icon
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

    private fun getCurrentIconMode(): String {
        val pm = packageManager
        val nightComponent = ComponentName(this, "com.islamyat.islamyat_app.MainActivityNight")
        val state = pm.getComponentEnabledSetting(nightComponent)
        return if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) "night" else "day"
    }
}

