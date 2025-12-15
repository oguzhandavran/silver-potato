package com.example.flutter_shell.context

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONObject
import java.security.MessageDigest

class ContextNotificationListenerService : NotificationListenerService() {

    private val allowedPackages = setOf(
        "com.whatsapp",
        "com.socialnmobile.dictapps.notepad.color.note",
        // StarNote package names vary by vendor; this stub uses best-effort filtering.
        "com.star.note",
        "com.starnote",
    )

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        if (!allowedPackages.contains(packageName)) return

        val notification = sbn.notification ?: return
        val extras = notification.extras

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

        val payload = JSONObject()
        payload.put("source", "notification")
        payload.put("type", "notification_posted")
        payload.put("timestampMs", sbn.postTime)
        payload.put("packageName", packageName)
        payload.put("notificationId", sbn.id)
        payload.put("titleLength", title?.length ?: 0)
        payload.put("textLength", text?.length ?: 0)
        payload.put("titleSha256", sha256OrNull(title))
        payload.put("textSha256", sha256OrNull(text))

        ContextEventEmitter.emit(applicationContext, "notifications", payload.toString())
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        if (!allowedPackages.contains(packageName)) return

        val payload = JSONObject()
        payload.put("source", "notification")
        payload.put("type", "notification_removed")
        payload.put("timestampMs", System.currentTimeMillis())
        payload.put("packageName", packageName)
        payload.put("notificationId", sbn.id)

        ContextEventEmitter.emit(applicationContext, "notifications", payload.toString())
    }

    private fun sha256OrNull(value: String?): String? {
        if (value == null) return null
        return try {
            val digest = MessageDigest.getInstance("SHA-256").digest(value.toByteArray(Charsets.UTF_8))
            digest.joinToString(separator = "") { byte -> "%02x".format(byte) }
        } catch (_: Exception) {
            null
        }
    }
}
