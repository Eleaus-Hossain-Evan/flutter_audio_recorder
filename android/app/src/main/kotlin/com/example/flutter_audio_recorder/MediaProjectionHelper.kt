package com.example.flutter_audio_recorder

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * Helper class for managing MediaProjection and AudioPlaybackCapture setup.
 * Used to capture internal app audio during VoIP calls on Android 10+.
 */
@RequiresApi(Build.VERSION_CODES.Q)
class MediaProjectionHelper(private val context: Context) {

    private val mediaProjectionManager: MediaProjectionManager =
        context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

    private var mediaProjection: MediaProjection? = null
    private var audioPlaybackCapture: AudioRecord? = null

    companion object {
        const val MEDIA_PROJECTION_REQUEST_CODE = 1002
        
        // Audio capture configuration
        private const val SAMPLE_RATE = 44100
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        
        /**
         * Check if the device supports internal audio capture.
         * Requires Android 10 (API 29) or higher.
         */
        fun supportsInternalAudioCapture(): Boolean {
            return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        }
    }

    /**
     * Create an intent to request MediaProjection permission from the user.
     * This should be started with startActivityForResult() to receive the result.
     */
    fun createScreenCaptureIntent(): Intent {
        return mediaProjectionManager.createScreenCaptureIntent()
    }

    /**
     * Initialize MediaProjection with the result from the permission request.
     * Call this in onActivityResult() after the user grants permission.
     *
     * @param resultCode The result code from onActivityResult()
     * @param data The intent data from onActivityResult()
     * @return True if initialization was successful
     */
    fun initMediaProjection(resultCode: Int, data: Intent?): Boolean {
        if (resultCode != Activity.RESULT_OK || data == null) {
            return false
        }

        try {
            mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
            return mediaProjection != null
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * Create and configure AudioPlaybackCapture (AudioRecord) for capturing app audio.
     * This captures the audio output from other apps (VoIP partner's voice).
     *
     * @return AudioRecord instance configured for playback capture, or null if failed
     */
    fun createAudioPlaybackCapture(): AudioRecord? {
        val projection = mediaProjection ?: return null

        try {
            // Build AudioPlaybackCaptureConfiguration
            val config = AudioPlaybackCaptureConfiguration.Builder(projection)
                .addMatchingUsage(android.media.AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .addMatchingUsage(android.media.AudioAttributes.USAGE_MEDIA)
                .build()

            // Calculate buffer size
            val bufferSize = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT
            )

            if (bufferSize == AudioRecord.ERROR || bufferSize == AudioRecord.ERROR_BAD_VALUE) {
                return null
            }

            // Create AudioRecord with playback capture
            audioPlaybackCapture = AudioRecord.Builder()
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AUDIO_FORMAT)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(CHANNEL_CONFIG)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize * 2)
                .setAudioPlaybackCaptureConfig(config)
                .build()

            return audioPlaybackCapture
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    /**
     * Start capturing audio playback.
     * Call this after createAudioPlaybackCapture() and before reading audio data.
     */
    fun startCapture() {
        audioPlaybackCapture?.startRecording()
    }

    /**
     * Read audio data from the playback capture.
     *
     * @param buffer The buffer to write audio data into
     * @param offset The offset in the buffer
     * @param size The number of bytes to read
     * @return Number of bytes read, or negative error code
     */
    fun readAudioData(buffer: ByteArray, offset: Int, size: Int): Int {
        return audioPlaybackCapture?.read(buffer, offset, size) ?: -1
    }

    /**
     * Stop and release all resources.
     * Call this when recording is finished.
     */
    fun release() {
        try {
            audioPlaybackCapture?.stop()
            audioPlaybackCapture?.release()
            audioPlaybackCapture = null

            mediaProjection?.stop()
            mediaProjection = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Check if MediaProjection is currently active.
     */
    fun isActive(): Boolean {
        return mediaProjection != null
    }

    /**
     * Get the sample rate used for audio capture.
     */
    fun getSampleRate(): Int = SAMPLE_RATE

    /**
     * Get the audio format used for audio capture.
     */
    fun getAudioFormat(): Int = AUDIO_FORMAT

    /**
     * Get the channel configuration used for audio capture.
     */
    fun getChannelConfig(): Int = CHANNEL_CONFIG
}
