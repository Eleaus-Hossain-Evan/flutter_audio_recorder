package com.example.flutter_audio_recorder

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.min

/**
 * AudioMixer handles real-time mixing of two audio streams:
 * 1. Microphone input (user's voice)
 * 2. App audio output (VoIP partner's voice)
 *
 * The streams are synchronized, mixed, and encoded to a single output file.
 */
class AudioMixer(
    private val outputFile: File,
    private val micAudioRecord: AudioRecord,
    private val appAudioRecord: AudioRecord
) {
    private var isRecording = false
    private var mixerThread: Thread? = null
    
    private var mediaCodec: MediaCodec? = null
    private var mediaMuxer: MediaMuxer? = null
    private var audioTrackIndex = -1
    private var muxerStarted = false

    companion object {
        private const val SAMPLE_RATE = 44100
        private const val CHANNEL_COUNT = 1
        private const val BIT_RATE = 128000
        private const val BUFFER_SIZE = 4096
        
        // Mixing gain factors (0.0 to 1.0)
        private const val MIC_GAIN = 0.7f
        private const val APP_GAIN = 0.7f
    }

    /**
     * Start mixing and recording both audio streams.
     */
    fun startMixing() {
        if (isRecording) return

        isRecording = true
        setupEncoder()
        
        mixerThread = Thread {
            mixAudioStreams()
        }.apply {
            priority = Thread.MAX_PRIORITY
            start()
        }
    }

    /**
     * Stop mixing and finalize the output file.
     */
    fun stopMixing() {
        isRecording = false
        mixerThread?.join(2000) // Wait up to 2 seconds
        releaseEncoder()
    }

    /**
     * Setup MediaCodec encoder and MediaMuxer for output.
     */
    private fun setupEncoder() {
        try {
            // Configure audio format for AAC encoding
            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC,
                SAMPLE_RATE,
                CHANNEL_COUNT
            ).apply {
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, BUFFER_SIZE * 2)
            }

            // Create and configure encoder
            mediaCodec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC).apply {
                configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                start()
            }

            // Create muxer
            mediaMuxer = MediaMuxer(
                outputFile.absolutePath,
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
            )
        } catch (e: Exception) {
            e.printStackTrace()
            throw RuntimeException("Failed to setup audio encoder: ${e.message}")
        }
    }

    /**
     * Main mixing loop - reads from both audio sources, mixes, and encodes.
     */
    private fun mixAudioStreams() {
        val micBuffer = ByteArray(BUFFER_SIZE)
        val appBuffer = ByteArray(BUFFER_SIZE)
        val mixedBuffer = ByteArray(BUFFER_SIZE)

        try {
            while (isRecording) {
                // Read from microphone
                val micBytesRead = micAudioRecord.read(micBuffer, 0, BUFFER_SIZE)
                
                // Read from app audio
                val appBytesRead = appAudioRecord.read(appBuffer, 0, BUFFER_SIZE)

                if (micBytesRead > 0 && appBytesRead > 0) {
                    // Mix the two audio streams
                    val bytesToMix = min(micBytesRead, appBytesRead)
                    mixAudio(micBuffer, appBuffer, mixedBuffer, bytesToMix)
                    
                    // Encode mixed audio
                    encodeMixedAudio(mixedBuffer, bytesToMix)
                } else if (micBytesRead > 0) {
                    // Only mic audio available
                    applyGain(micBuffer, micBytesRead, MIC_GAIN)
                    encodeMixedAudio(micBuffer, micBytesRead)
                } else if (appBytesRead > 0) {
                    // Only app audio available
                    applyGain(appBuffer, appBytesRead, APP_GAIN)
                    encodeMixedAudio(appBuffer, appBytesRead)
                }

                // Drain encoder output
                drainEncoder(false)
            }

            // Final drain
            drainEncoder(true)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Mix two PCM audio buffers with gain control.
     * Converts bytes to shorts, mixes with gain, and converts back.
     */
    private fun mixAudio(
        micBuffer: ByteArray,
        appBuffer: ByteArray,
        outputBuffer: ByteArray,
        size: Int
    ) {
        // Process in 16-bit samples (2 bytes per sample)
        val sampleCount = size / 2
        
        for (i in 0 until sampleCount) {
            val offset = i * 2
            
            // Convert bytes to 16-bit samples
            val micSample = ((micBuffer[offset + 1].toInt() shl 8) or 
                            (micBuffer[offset].toInt() and 0xFF)).toShort()
            val appSample = ((appBuffer[offset + 1].toInt() shl 8) or 
                            (appBuffer[offset].toInt() and 0xFF)).toShort()
            
            // Mix with gain and clamp to prevent overflow
            var mixed = (micSample * MIC_GAIN + appSample * APP_GAIN).toInt()
            mixed = mixed.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
            
            // Convert back to bytes (little-endian)
            outputBuffer[offset] = (mixed and 0xFF).toByte()
            outputBuffer[offset + 1] = ((mixed shr 8) and 0xFF).toByte()
        }
    }

    /**
     * Apply gain to an audio buffer in-place.
     */
    private fun applyGain(buffer: ByteArray, size: Int, gain: Float) {
        val sampleCount = size / 2
        
        for (i in 0 until sampleCount) {
            val offset = i * 2
            
            // Convert bytes to 16-bit sample
            var sample = ((buffer[offset + 1].toInt() shl 8) or 
                         (buffer[offset].toInt() and 0xFF)).toShort()
            
            // Apply gain and clamp
            sample = (sample * gain).toInt().coerceIn(
                Short.MIN_VALUE.toInt(),
                Short.MAX_VALUE.toInt()
            ).toShort()
            
            // Convert back to bytes
            buffer[offset] = (sample.toInt() and 0xFF).toByte()
            buffer[offset + 1] = ((sample.toInt() shr 8) and 0xFF).toByte()
        }
    }

    /**
     * Feed mixed audio data to the encoder.
     */
    private fun encodeMixedAudio(audioData: ByteArray, size: Int) {
        val codec = mediaCodec ?: return

        try {
            val inputBufferIndex = codec.dequeueInputBuffer(10000)
            if (inputBufferIndex >= 0) {
                val inputBuffer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    codec.getInputBuffer(inputBufferIndex)
                } else {
                    @Suppress("DEPRECATION")
                    codec.inputBuffers[inputBufferIndex]
                }

                inputBuffer?.clear()
                inputBuffer?.put(audioData, 0, size)
                
                val presentationTimeUs = System.nanoTime() / 1000
                codec.queueInputBuffer(inputBufferIndex, 0, size, presentationTimeUs, 0)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Drain encoded data from encoder and write to muxer.
     */
    private fun drainEncoder(endOfStream: Boolean) {
        val codec = mediaCodec ?: return
        val muxer = mediaMuxer ?: return

        val bufferInfo = MediaCodec.BufferInfo()
        
        while (true) {
            val outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 0)
            
            when {
                outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) break
                }
                outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (muxerStarted) {
                        throw RuntimeException("Format changed after muxer started")
                    }
                    audioTrackIndex = muxer.addTrack(codec.outputFormat)
                    muxer.start()
                    muxerStarted = true
                }
                outputBufferIndex >= 0 -> {
                    val outputBuffer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        codec.getOutputBuffer(outputBufferIndex)
                    } else {
                        @Suppress("DEPRECATION")
                        codec.outputBuffers[outputBufferIndex]
                    } ?: continue

                    if (bufferInfo.size > 0 && muxerStarted) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(audioTrackIndex, outputBuffer, bufferInfo)
                    }

                    codec.releaseOutputBuffer(outputBufferIndex, false)

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        break
                    }
                }
            }
        }

        if (endOfStream) {
            val inputBufferIndex = codec.dequeueInputBuffer(10000)
            if (inputBufferIndex >= 0) {
                codec.queueInputBuffer(
                    inputBufferIndex, 0, 0, 0,
                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                )
            }
        }
    }

    /**
     * Release encoder and muxer resources.
     */
    private fun releaseEncoder() {
        try {
            mediaCodec?.stop()
            mediaCodec?.release()
            mediaCodec = null

            if (muxerStarted) {
                mediaMuxer?.stop()
            }
            mediaMuxer?.release()
            mediaMuxer = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Check if mixer is currently recording.
     */
    fun isRecording(): Boolean = isRecording
}
