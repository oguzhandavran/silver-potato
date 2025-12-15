package com.example.flutter_shell.context

import android.content.Context
import org.json.JSONArray

object ContextEventStorage {
    private const val PREFS_NAME = "context_collectors"

    private fun keyFor(channel: String): String = "pending_events_$channel"

    fun append(context: Context, channel: String, json: String, maxEvents: Int = 200) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = keyFor(channel)

        val existing = prefs.getString(key, "[]") ?: "[]"
        val array = try {
            JSONArray(existing)
        } catch (_: Exception) {
            JSONArray()
        }

        array.put(json)

        if (array.length() > maxEvents) {
            val trimmed = JSONArray()
            val start = array.length() - maxEvents
            for (i in start until array.length()) {
                trimmed.put(array.get(i))
            }
            prefs.edit().putString(key, trimmed.toString()).apply()
        } else {
            prefs.edit().putString(key, array.toString()).apply()
        }
    }

    fun drain(context: Context, channel: String): List<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = keyFor(channel)

        val existing = prefs.getString(key, "[]") ?: "[]"
        prefs.edit().remove(key).apply()

        val array = try {
            JSONArray(existing)
        } catch (_: Exception) {
            JSONArray()
        }

        val out = ArrayList<String>(array.length())
        for (i in 0 until array.length()) {
            val value = array.optString(i, null)
            if (value != null) {
                out.add(value)
            }
        }
        return out
    }
}
