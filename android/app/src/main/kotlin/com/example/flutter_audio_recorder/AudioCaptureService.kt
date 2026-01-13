package com.example.flutter_audio_recorder

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat

/**
 * Foreground service for MediaProjection-based audio capture.
 * Required to maintain MediaProjection session while recording internal audio.
 */
@RequiresApi(Build.VERSION_CODES.Q)
class AudioCaptureService : Service() {

    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "audio_capture_channel"
        private const val CHANNEL_NAME = "Audio Recording"
        
        const val ACTION_START_CAPTURE = "com.example.flutter_audio_recorder.START_CAPTURE"
        const val ACTION_STOP_CAPTURE = "com.example.flutter_audio_recorder.STOP_CAPTURE"
        
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        
        private var isServiceRunning = false

        /**
         * Check if the service is currently running.
         */
        fun isRunning(): Boolean = isServiceRunning

        /**
         * Start the audio capture service.
         */
        fun startService(context: Context, resultCode: Int, data: Intent) {
            val intent = Intent(context, AudioCaptureService::class.java).apply {
                action = ACTION_START_CAPTURE
                putExtra(EXTRA_RESULT_CODE, resultCode)
                putExtra(EXTRA_RESULT_DATA, data)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /**
         * Stop the audio capture service.
         */
        fun stopService(context: Context) {
            val intent = Intent(context, AudioCaptureService::class.java).apply {
                action = ACTION_STOP_CAPTURE
            }
            context.startService(intent)
        }
    }

    private var mediaProjectionHelper: MediaProjectionHelper? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_CAPTURE -> {
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(EXTRA_RESULT_DATA)
                }
                
                startCapture(resultCode, data)
            }
            ACTION_STOP_CAPTURE -> {
                stopCapture()
            }
        }
        
        return START_NOT_STICKY
    }

    private fun startCapture(resultCode: Int, data: Intent?) {
        if (isServiceRunning) return

        // Create and show notification
        val notification = createNotification()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ requires specifying foreground service type
            startForeground(
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Initialize MediaProjection
        mediaProjectionHelper = MediaProjectionHelper(this)
        if (data != null) {
            mediaProjectionHelper?.initMediaProjection(resultCode, data)
        }

        isServiceRunning = true
    }

    private fun stopCapture() {
        if (!isServiceRunning) return

        // Release MediaProjection
        mediaProjectionHelper?.release()
        mediaProjectionHelper = null

        isServiceRunning = false
        stopForeground(true)
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        stopCapture()
    }

    /**
     * Create notification channel for Android O+.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Recording audio from VoIP calls"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

    /**
     * Create foreground notification.
     */
    private fun createNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationCompat.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            NotificationCompat.Builder(this)
        }

        return builder
            .setContentTitle("Recording Audio")
            .setContentText("Recording VoIP call audio")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }

    /**
     * Get the MediaProjectionHelper instance.
     * Only available when service is running.
     */
    fun getMediaProjectionHelper(): MediaProjectionHelper? = mediaProjectionHelper
}
