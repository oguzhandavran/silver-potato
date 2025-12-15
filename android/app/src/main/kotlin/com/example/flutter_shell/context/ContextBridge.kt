package com.example.flutter_shell.context

import android.app.Activity
import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object ContextBridge {
    private const val METHOD_CHANNEL = "com.example.flutter_shell/context_bridge"

    private const val EVENT_NOTIFICATIONS = "com.example.flutter_shell/context_events/notifications"
    private const val EVENT_ACCESSIBILITY = "com.example.flutter_shell/context_events/accessibility"
    private const val EVENT_AUDIO_FEATURES = "com.example.flutter_shell/context_events/audio_features"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            handleMethodCall(activity, call, result)
        }

        registerEventChannel(messenger, EVENT_NOTIFICATIONS, "notifications")
        registerEventChannel(messenger, EVENT_ACCESSIBILITY, "accessibility")
        registerEventChannel(messenger, EVENT_AUDIO_FEATURES, "audio_features")
    }

    private fun registerEventChannel(messenger: BinaryMessenger, channelName: String, key: String) {
        EventChannel(messenger, channelName).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                ContextEventEmitter.setSink(key, events)
            }

            override fun onCancel(arguments: Any?) {
                ContextEventEmitter.setSink(key, null)
            }
        })
    }

    private fun handleMethodCall(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openNotificationListenerSettings" -> {
                activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(null)
            }

            "openAccessibilitySettings" -> {
                activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                result.success(null)
            }

            "openUsageAccessSettings" -> {
                activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                result.success(null)
            }

            "isNotificationListenerEnabled" -> {
                result.success(isNotificationListenerEnabled(activity))
            }

            "isAccessibilityServiceEnabled" -> {
                result.success(isAccessibilityServiceEnabled(activity))
            }

            "hasUsageStatsAccess" -> {
                result.success(hasUsageStatsAccess(activity))
            }

            "startAudioFeaturesService" -> {
                val intent = Intent(activity, ContextAudioFeaturesService::class.java)
                try {
                    ContextCompat.startForegroundService(activity, intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("start_failed", e.message, null)
                }
            }

            "stopAudioFeaturesService" -> {
                val intent = Intent(activity, ContextAudioFeaturesService::class.java)
                try {
                    activity.stopService(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("stop_failed", e.message, null)
                }
            }

            "isAudioFeaturesServiceRunning" -> {
                result.success(ContextAudioFeaturesService.isRunning())
            }

            "drainPendingEvents" -> {
                val channel = call.argument<String>("channel")
                if (channel == null) {
                    result.error("bad_args", "Missing channel", null)
                    return
                }

                val drained = ContextEventStorage.drain(activity.applicationContext, channel)
                result.success(drained)
            }

            "getBrowserUsageSummary" -> {
                val windowMs = call.argument<Number>("windowMs")?.toLong() ?: (24L * 60L * 60L * 1000L)
                result.success(getBrowserUsageSummary(activity, windowMs))
            }

            else -> result.notImplemented()
        }
    }

    private fun isNotificationListenerEnabled(activity: Activity): Boolean {
        val enabled = Settings.Secure.getString(activity.contentResolver, "enabled_notification_listeners") ?: return false
        val component = ComponentName(activity, ContextNotificationListenerService::class.java).flattenToString()
        return enabled.contains(component)
    }

    private fun isAccessibilityServiceEnabled(activity: Activity): Boolean {
        val accessibilityEnabled = Settings.Secure.getInt(activity.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0) == 1
        if (!accessibilityEnabled) return false

        val enabledServices = Settings.Secure.getString(activity.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            ?: return false

        val component = ComponentName(activity, ContextAccessibilityService::class.java).flattenToString()
        return enabledServices.contains(component)
    }

    private fun hasUsageStatsAccess(activity: Activity): Boolean {
        val appOps = activity.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), activity.packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), activity.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getBrowserUsageSummary(activity: Activity, windowMs: Long): List<Map<String, Any>> {
        val end = System.currentTimeMillis()
        val start = end - windowMs

        val usageStatsManager = activity.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        val stats = usageStatsManager.queryUsageStats(android.app.usage.UsageStatsManager.INTERVAL_DAILY, start, end)
            ?: emptyList()

        val targetPackages = setOf(
            "com.android.chrome",
            "org.mozilla.firefox",
            "org.mozilla.firefox_beta",
            "org.mozilla.fenix",
        )

        val out = ArrayList<Map<String, Any>>()
        for (s in stats) {
            if (!targetPackages.contains(s.packageName)) continue

            val map = HashMap<String, Any>()
            map["packageName"] = s.packageName
            map["totalTimeInForegroundMs"] = s.totalTimeInForeground
            map["lastTimeUsedMs"] = s.lastTimeUsed
            out.add(map)
        }
        return out
    }
}
