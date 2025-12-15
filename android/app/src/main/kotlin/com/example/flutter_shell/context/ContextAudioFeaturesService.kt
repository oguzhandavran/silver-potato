package com.example.flutter_shell.context

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.sqrt

class ContextAudioFeaturesService : Service() {

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "context_audio_features"
        private const val NOTIFICATION_ID = 4242

        private val running = AtomicBoolean(false)

        fun isRunning(): Boolean = running.get()
    }

    private var audioRecord: AudioRecord? = null
    private var audioThread: Thread? = null
    private val stopFlag = AtomicBoolean(false)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running.set(true)
    }

    override fun onDestroy() {
        stopRecording()
        running.set(false)
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startInForeground()
        startRecordingIfNeeded()
        return START_STICKY
    }

    private fun startInForeground() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Context audio features",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Context collection running")
            .setContentText("Sampling microphone to compute activity features (no audio stored).")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun startRecordingIfNeeded() {
        if (audioThread != null) return

        stopFlag.set(false)

        val sampleRate = 16000
        val bufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        if (bufferSize == AudioRecord.ERROR || bufferSize == AudioRecord.ERROR_BAD_VALUE) {
            return
        }

        val record = AudioRecord(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        audioRecord = record
        record.startRecording()

        audioThread = Thread {
            val buffer = ShortArray(bufferSize / 2)
            var lastEmit = 0L

            while (!stopFlag.get()) {
                val read = try {
                    record.read(buffer, 0, buffer.size)
                } catch (_: Exception) {
                    break
                }

                if (read <= 0) continue

                val rms = computeRms(buffer, read)
                val activity = (rms / 32768.0).coerceIn(0.0, 1.0)
                val vadActive = activity > 0.02

                val now = System.currentTimeMillis()
                if (now - lastEmit >= 500) {
                    lastEmit = now
                    val payload = JSONObject()
                    payload.put("source", "audioFeatures")
                    payload.put("type", "audio_activity")
                    payload.put("timestampMs", now)
                    payload.put("activityLevel", activity)
                    payload.put("vadActive", vadActive)

                    ContextEventEmitter.emit(applicationContext, "audio_features", payload.toString())
                }
            }
        }

        audioThread?.start()
    }

    private fun stopRecording() {
        stopFlag.set(true)
        try {
            audioThread?.join(300)
        } catch (_: Exception) {
            // ignore
        }
        audioThread = null

        try {
            audioRecord?.stop()
        } catch (_: Exception) {
            // ignore
        }

        try {
            audioRecord?.release()
        } catch (_: Exception) {
            // ignore
        }
        audioRecord = null
    }

    private fun computeRms(buffer: ShortArray, length: Int): Double {
        var sum = 0.0
        for (i in 0 until length) {
            val v = buffer[i].toDouble()
            sum += v * v
        }
        return sqrt(sum / length.toDouble())
    }
}
