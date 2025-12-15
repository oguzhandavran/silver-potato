package com.example.flutter_shell.context

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap

object ContextEventEmitter {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val sinks = ConcurrentHashMap<String, EventChannel.EventSink?>()

    fun setSink(channel: String, sink: EventChannel.EventSink?) {
        sinks[channel] = sink
    }

    fun emit(context: Context, channel: String, json: String) {
        ContextEventStorage.append(context, channel, json)

        val sink = sinks[channel] ?: return
        mainHandler.post {
            try {
                sink.success(json)
            } catch (_: Exception) {
                // Ignore errors when Flutter side is detached.
            }
        }
    }
}
