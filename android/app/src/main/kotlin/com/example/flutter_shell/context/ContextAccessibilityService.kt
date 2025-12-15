package com.example.flutter_shell.context

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import org.json.JSONObject

class ContextAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == this.packageName) return

        val payload = JSONObject()
        payload.put("source", "accessibility")
        payload.put("type", "accessibility_event")
        payload.put("timestampMs", event.eventTime)
        payload.put("eventType", event.eventType)
        payload.put("packageName", packageName)
        payload.put("className", event.className?.toString())

        // Intentionally do not include event.text/contentDescription to avoid capturing sensitive content.

        ContextEventEmitter.emit(applicationContext, "accessibility", payload.toString())
    }

    override fun onInterrupt() {
        // No-op.
    }
}
