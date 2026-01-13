package com.example.flutter_audio_recorder

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaPlayer
import android.media.MediaMetadataRetriever
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.HandlerThread
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class AudioRecorderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener,
    EventChannel.StreamHandler {

    private lateinit var channel: MethodChannel
    private var stateEventChannel: EventChannel? = null
    private var amplitudeEventChannel: EventChannel? = null
    private var playbackChannel: MethodChannel? = null
    private var playbackStateEventChannel: EventChannel? = null
    private var playbackPositionEventChannel: EventChannel? = null
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    
    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingPath: String? = null
    private var recordingStartTime: Long = 0
    
    // Dual-stream recording (mic + app audio)
    private var micAudioRecord: AudioRecord? = null
    private var mediaProjectionHelper: MediaProjectionHelper? = null
    private var audioMixer: AudioMixer? = null
    private var isDualStreamRecording = false
    private var pendingMediaProjectionResult: MethodChannel.Result? = null
    
    private var permissionResult: MethodChannel.Result? = null
    
    private var stateEventSink: EventChannel.EventSink? = null
    private var amplitudeEventSink: EventChannel.EventSink? = null
    private var playbackStateEventSink: EventChannel.EventSink? = null
    private var playbackPositionEventSink: EventChannel.EventSink? = null
    
    private var amplitudeMeteringThread: HandlerThread? = null
    private var amplitudeMeteringHandler: Handler? = null
    private var recordingInProgress = false

    private var mediaPlayer: MediaPlayer? = null
    private var playbackFilePath: String? = null
    private var playbackPositionThread: HandlerThread? = null
    private var playbackPositionHandler: Handler? = null

    companion object {
        private const val CHANNEL_NAME = "com.example.audio_recorder/methods"
        private const val STATE_EVENT_CHANNEL_NAME = "com.example.audio_recorder/events/recording_state"
        private const val AMPLITUDE_EVENT_CHANNEL_NAME = "com.example.audio_recorder/events/amplitude"
        private const val PLAYBACK_CHANNEL_NAME = "com.example.audio_player/methods"
        private const val PLAYBACK_STATE_EVENT_CHANNEL_NAME = "com.example.audio_player/events/state"
        private const val PLAYBACK_POSITION_EVENT_CHANNEL_NAME = "com.example.audio_player/events/position"
        private const val PERMISSION_REQUEST_CODE = 1001
        private const val MEDIA_PROJECTION_REQUEST_CODE = 1002
        private const val AMPLITUDE_POLLING_INTERVAL_MS = 20L  // ~50 Hz
        private const val PLAYBACK_POSITION_INTERVAL_MS = 100L
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        stateEventChannel = EventChannel(binding.binaryMessenger, STATE_EVENT_CHANNEL_NAME)
        stateEventChannel?.setStreamHandler(this)
        
        amplitudeEventChannel = EventChannel(binding.binaryMessenger, AMPLITUDE_EVENT_CHANNEL_NAME)
        amplitudeEventChannel?.setStreamHandler(this)

        playbackChannel = MethodChannel(binding.binaryMessenger, PLAYBACK_CHANNEL_NAME)
        playbackChannel?.setMethodCallHandler(this)

        playbackStateEventChannel =
            EventChannel(binding.binaryMessenger, PLAYBACK_STATE_EVENT_CHANNEL_NAME)
        playbackStateEventChannel?.setStreamHandler(PlaybackStateStreamHandler(this))

        playbackPositionEventChannel =
            EventChannel(binding.binaryMessenger, PLAYBACK_POSITION_EVENT_CHANNEL_NAME)
        playbackPositionEventChannel?.setStreamHandler(PlaybackPositionStreamHandler(this))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        playbackChannel?.setMethodCallHandler(null)
        stateEventChannel?.setStreamHandler(null)
        amplitudeEventChannel?.setStreamHandler(null)
        playbackStateEventChannel?.setStreamHandler(null)
        playbackPositionEventChannel?.setStreamHandler(null)
        stopPlaybackPositionUpdates()
        mediaPlayer?.release()
        mediaPlayer = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> requestPermission(result)
            "supportsInternalAudioCapture" -> supportsInternalAudioCapture(result)
            "requestMediaProjectionPermission" -> requestMediaProjectionPermission(result)
            "startRecording" -> startRecording(call, result)
            "stopRecording" -> stopRecording(result)
            "getRecordings" -> getRecordings(result)
            "loadLocal" -> loadLocal(call, result)
            "play" -> play(result)
            "pause" -> pause(result)
            "stop" -> stop(result)
            "seekTo" -> seekTo(call, result)
            "setVolume" -> setVolume(call, result)
            "setSpeed" -> setSpeed(call, result)
            else -> result.notImplemented()
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context is null", null)
            return
        }

        when {
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) 
                == PackageManager.PERMISSION_GRANTED -> {
                result.success(true)
            }
            else -> {
                permissionResult = result
                activityBinding?.activity?.let {
                    ActivityCompat.requestPermissions(
                        it,
                        arrayOf(Manifest.permission.RECORD_AUDIO),
                        PERMISSION_REQUEST_CODE
                    )
                } ?: result.error("NO_ACTIVITY", "Activity is null", null)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() 
                && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(granted)
            permissionResult = null
            return true
        }
        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == MEDIA_PROJECTION_REQUEST_CODE) {
            handleMediaProjectionResult(resultCode, data)
            return true
        }
        return false
    }

    private fun supportsInternalAudioCapture(result: MethodChannel.Result) {
        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
    }

    private fun requestMediaProjectionPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("UNSUPPORTED", "MediaProjection requires Android 10+", null)
            return
        }

        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }

        try {
            val helper = MediaProjectionHelper(activity)
            val intent = helper.createScreenCaptureIntent()
            pendingMediaProjectionResult = result
            activity.startActivityForResult(intent, MEDIA_PROJECTION_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("REQUEST_FAILED", "Failed to request MediaProjection: ${e.message}", null)
        }
    }

    // Handle MediaProjection permission result
    private fun handleMediaProjectionResult(resultCode: Int, data: Intent?) {
        val result = pendingMediaProjectionResult ?: return
        pendingMediaProjectionResult = null

        if (resultCode == Activity.RESULT_OK && data != null) {
            // Store the result for later use in startRecording
            val ctx = context ?: run {
                result.error("NO_CONTEXT", "Context is null", null)
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                AudioCaptureService.startService(ctx, resultCode, data)
            }
            result.success(true)
        } else {
            result.error("PERMISSION_DENIED", "MediaProjection permission denied", null)
        }
    }

    private fun startRecording(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context is null", null)
            return
        }

        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) 
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Microphone permission not granted", null)
            return
        }

        val captureAppAudio = call.argument<Boolean>("captureAppAudio") ?: false

        try {
            // Emit initializing state
            emitRecordingStateEvent(state = "initializing", reason = null)
            
            // Generate unique filename
            val timestamp = System.currentTimeMillis()
            val uuid = UUID.randomUUID().toString().substring(0, 8)
            val fileName = "record_${uuid}.m4a"
            
            // Get recordings directory
            val recordingsDir = ctx.getExternalFilesDir(Environment.DIRECTORY_MUSIC)
                ?: ctx.filesDir
            recordingsDir.mkdirs()
            
            val file = File(recordingsDir, fileName)
            currentRecordingPath = file.absolutePath
            recordingStartTime = timestamp

            if (captureAppAudio && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q 
                && AudioCaptureService.isRunning()) {
                // Dual-stream recording (mic + app audio)
                startDualStreamRecording(file, result)
            } else {
                // Standard mic-only recording with optimization
                startMicOnlyRecording(file, result)
            }
        } catch (e: Exception) {
            recordingInProgress = false
            emitRecordingStateEvent(state = "error", reason = e.message)
            result.error("RECORDING_FAILED", "Failed to start recording: ${e.message}", null)
        }
    }

    private fun startMicOnlyRecording(file: File, result: MethodChannel.Result) {
        val ctx = context ?: throw IllegalStateException("Context is null")

        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(ctx)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }.apply {
            // Use VOICE_COMMUNICATION for VoIP optimization on Android 10+
            val audioSource = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaRecorder.AudioSource.VOICE_COMMUNICATION
            } else {
                MediaRecorder.AudioSource.MIC
            }
            setAudioSource(audioSource)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setOutputFile(file.absolutePath)
            prepare()
            start()
        }

        isDualStreamRecording = false
        recordingInProgress = true
        emitRecordingStateEvent(state = "recording", reason = null)
        startAmplitudeMetering()
        result.success(null)
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.Q)
    private fun startDualStreamRecording(file: File, result: MethodChannel.Result) {
        val ctx = context ?: throw IllegalStateException("Context is null")

        try {
            // Create microphone AudioRecord
            val sampleRate = 44100
            val channelConfig = AudioFormat.CHANNEL_IN_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

            micAudioRecord = AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize * 2
            )

            // Get MediaProjection helper from service
            mediaProjectionHelper = MediaProjectionHelper(ctx)
            val appAudioRecord = mediaProjectionHelper?.createAudioPlaybackCapture()

            if (appAudioRecord == null) {
                throw RuntimeException("Failed to create AudioPlaybackCapture")
            }

            // Start both recordings
            micAudioRecord?.startRecording()
            mediaProjectionHelper?.startCapture()

            // Create mixer
            audioMixer = AudioMixer(file, micAudioRecord!!, appAudioRecord)
            audioMixer?.startMixing()

            isDualStreamRecording = true
            recordingInProgress = true
            emitRecordingStateEvent(state = "recording", reason = null)
            startAmplitudeMetering()
            result.success(null)
        } catch (e: Exception) {
            // Cleanup on failure
            micAudioRecord?.release()
            micAudioRecord = null
            mediaProjectionHelper?.release()
            mediaProjectionHelper = null
            throw e
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        val recordingPath = currentRecordingPath

        if (recordingPath == null || !recordingInProgress) {
            result.error("NO_RECORDING", "No recording in progress", null)
            return
        }

        try {
            // Stop amplitude metering
            stopAmplitudeMetering()
            
            // Emit stopping state
            emitRecordingStateEvent(state = "stopping", reason = null)
            
            if (isDualStreamRecording) {
                // Stop dual-stream recording
                audioMixer?.stopMixing()
                audioMixer = null
                
                micAudioRecord?.stop()
                micAudioRecord?.release()
                micAudioRecord = null
                
                mediaProjectionHelper?.release()
                mediaProjectionHelper = null
                
                isDualStreamRecording = false
            } else {
                // Stop standard recording
                mediaRecorder?.stop()
                mediaRecorder?.release()
                mediaRecorder = null
            }

            val file = File(recordingPath)
            if (!file.exists()) {
                recordingInProgress = false
                emitRecordingStateEvent(state = "error", reason = "Recording file not found")
                result.error("FILE_NOT_FOUND", "Recording file not found", null)
                return
            }

            // Get metadata
            val metadata = getRecordingMetadata(file)
            currentRecordingPath = null
            recordingInProgress = false
            
            // Emit stopped state
            emitRecordingStateEvent(state = "stopped", reason = null)
            
            result.success(metadata)
        } catch (e: Exception) {
            // Cleanup on error
            mediaRecorder?.release()
            mediaRecorder = null
            micAudioRecord?.release()
            micAudioRecord = null
            audioMixer = null
            mediaProjectionHelper?.release()
            mediaProjectionHelper = null
            currentRecordingPath = null
            recordingInProgress = false
            isDualStreamRecording = false
            emitRecordingStateEvent(state = "error", reason = e.message)
            result.error("STOP_FAILED", "Failed to stop recording: ${e.message}", null)
        }
    }

    private fun getRecordings(result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context is null", null)
            return
        }

        try {
            val recordingsDir = ctx.getExternalFilesDir(Environment.DIRECTORY_MUSIC)
                ?: ctx.filesDir
            
            if (!recordingsDir.exists()) {
                result.success(emptyList<Map<String, Any>>())
                return
            }

            val recordings = recordingsDir.listFiles()
                ?.filter { it.isFile && it.extension == "m4a" }
                ?.map { getRecordingMetadata(it) }
                ?.sortedByDescending { it["createdAt"] as String }
                ?: emptyList()

            result.success(recordings)
        } catch (e: Exception) {
            result.error("GET_RECORDINGS_FAILED", "Failed to get recordings: ${e.message}", null)
        }
    }

    private fun getRecordingMetadata(file: File): Map<String, Any> {
        val retriever = MediaMetadataRetriever()
        var durationMs = 0
        
        try {
            retriever.setDataSource(file.absolutePath)
            val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            durationMs = durationStr?.toIntOrNull() ?: 0
        } catch (e: Exception) {
            // Duration extraction failed, use 0
        } finally {
            retriever.release()
        }

        val createdAt = Date(file.lastModified())
        val isoFormatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }

        return mapOf(
            "id" to file.nameWithoutExtension,
            "filePath" to file.absolutePath,
            "fileName" to file.name,
            "durationMs" to durationMs,
            "sizeBytes" to file.length(),
            "createdAt" to isoFormatter.format(createdAt)
        )
    }

    // MARK: - Amplitude Metering
    
    private fun startAmplitudeMetering() {
        amplitudeMeteringThread = HandlerThread("AmplitudeMeteringThread")
        amplitudeMeteringThread?.start()
        
        amplitudeMeteringHandler = Handler(amplitudeMeteringThread!!.looper)
        scheduleAmplitudePolling()
    }
    
    private fun stopAmplitudeMetering() {
        amplitudeMeteringHandler?.removeCallbacksAndMessages(null)
        amplitudeMeteringThread?.quitSafely()
        amplitudeMeteringThread = null
        amplitudeMeteringHandler = null
    }
    
    private fun scheduleAmplitudePolling() {
        amplitudeMeteringHandler?.postDelayed({
            if (recordingInProgress && mediaRecorder != null) {
                emitAmplitudeSample()
                scheduleAmplitudePolling()  // Reschedule for next poll
            }
        }, AMPLITUDE_POLLING_INTERVAL_MS)
    }
    
    private fun emitAmplitudeSample() {
        try {
            val normalizedAmplitude = if (isDualStreamRecording) {
                // For dual-stream, use mic AudioRecord
                val recorder = micAudioRecord ?: return
                // AudioRecord doesn't have built-in amplitude, use a simple estimation
                // In production, you might want to sample the audio buffer
                0.5 // Placeholder - would need actual buffer sampling
            } else {
                // For standard recording, use MediaRecorder's max amplitude
                val recorder = mediaRecorder ?: return
                val maxAmplitude = recorder.maxAmplitude.toDouble()
                (maxAmplitude / 32767.0).coerceIn(0.0, 1.0)
            }
            
            amplitudeEventSink?.success(normalizedAmplitude)
        } catch (e: Exception) {
            // Silently skip if recorder state is invalid
        }
    }
    
    // MARK: - State Event Emission
    
    private fun emitRecordingStateEvent(state: String, reason: String?) {
        val event = mapOf(
            "state" to state,
            "timestamp" to getCurrentISO8601(),
            "reason" to reason
        )
        stateEventSink?.success(event)
    }
    
    private fun getCurrentISO8601(): String {
        val isoFormatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        return isoFormatter.format(Date())
    }
    
    // MARK: - EventChannel.StreamHandler Implementation
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        // Determine which stream this is based on which sink is null
        if (stateEventSink == null) {
            stateEventSink = events
        } else {
            amplitudeEventSink = events
        }
    }
    
    override fun onCancel(arguments: Any?) {
        // Cleanup on stream cancellation
        if (amplitudeEventSink != null) {
            amplitudeEventSink = null
            stopAmplitudeMetering()
        } else {
            stateEventSink = null
        }
    }

    private fun loadLocal(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        if (filePath.isNullOrBlank()) {
            result.error("INVALID_ARGS", "filePath is required", null)
            return
        }

        try {
            stopPlaybackPositionUpdates()
            mediaPlayer?.release()
            mediaPlayer = null

            playbackFilePath = filePath
            emitPlaybackStateEvent(state = "loading", reason = null)

            val player = MediaPlayer().apply {
                setDataSource(filePath)
                setOnCompletionListener {
                    stopPlaybackPositionUpdates()
                    emitPlaybackPositionEvent()
                    emitPlaybackStateEvent(state = "completed", reason = null)
                }
                prepare()
            }
            mediaPlayer = player
            emitPlaybackStateEvent(state = "paused", reason = null)
            emitPlaybackPositionEvent()
            result.success(null)
        } catch (e: Exception) {
            emitPlaybackStateEvent(state = "error", reason = e.message)
            result.error("LOAD_FAILED", "Failed to load audio: ${e.message}", null)
        }
    }

    private fun play(result: MethodChannel.Result) {
        val player = mediaPlayer
        if (player == null) {
            result.error("NO_PLAYER", "No audio loaded", null)
            return
        }
        try {
            player.start()
            emitPlaybackStateEvent(state = "playing", reason = null)
            startPlaybackPositionUpdates()
            result.success(null)
        } catch (e: Exception) {
            emitPlaybackStateEvent(state = "error", reason = e.message)
            result.error("PLAY_FAILED", "Failed to start playback: ${e.message}", null)
        }
    }

    private fun pause(result: MethodChannel.Result) {
        val player = mediaPlayer
        if (player == null) {
            result.error("NO_PLAYER", "No audio loaded", null)
            return
        }
        try {
            if (player.isPlaying) {
                player.pause()
            }
            stopPlaybackPositionUpdates()
            emitPlaybackStateEvent(state = "paused", reason = null)
            emitPlaybackPositionEvent()
            result.success(null)
        } catch (e: Exception) {
            emitPlaybackStateEvent(state = "error", reason = e.message)
            result.error("PAUSE_FAILED", "Failed to pause playback: ${e.message}", null)
        }
    }

    private fun stop(result: MethodChannel.Result) {
        val player = mediaPlayer
        if (player == null) {
            result.error("NO_PLAYER", "No audio loaded", null)
            return
        }
        try {
            if (player.isPlaying) {
                player.pause()
            }
            player.seekTo(0)
            stopPlaybackPositionUpdates()
            emitPlaybackStateEvent(state = "idle", reason = null)
            emitPlaybackPositionEvent()
            result.success(null)
        } catch (e: Exception) {
            emitPlaybackStateEvent(state = "error", reason = e.message)
            result.error("STOP_FAILED", "Failed to stop playback: ${e.message}", null)
        }
    }

    private fun seekTo(call: MethodCall, result: MethodChannel.Result) {
        val positionMs = call.argument<Int>("positionMs")
        if (positionMs == null) {
            result.error("INVALID_ARGS", "positionMs is required", null)
            return
        }
        val player = mediaPlayer
        if (player == null) {
            result.error("NO_PLAYER", "No audio loaded", null)
            return
        }
        try {
            player.seekTo(positionMs.coerceAtLeast(0))
            emitPlaybackPositionEvent()
            result.success(null)
        } catch (e: Exception) {
            emitPlaybackStateEvent(state = "error", reason = e.message)
            result.error("SEEK_FAILED", "Failed to seek: ${e.message}", null)
        }
    }

    private fun setVolume(call: MethodCall, result: MethodChannel.Result) {
        val volume = call.argument<Double>("volume")
        if (volume == null) {
            result.error("INVALID_ARGS", "volume is required", null)
            return
        }
        val player = mediaPlayer
        if (player == null) {
            result.error("NO_PLAYER", "No audio loaded", null)
            return
        }
        try {
            val v = volume.coerceIn(0.0, 1.0).toFloat()
            player.setVolume(v, v)
            result.success(null)
        } catch (e: Exception) {
            emitPlaybackStateEvent(state = "error", reason = e.message)
            result.error("VOLUME_FAILED", "Failed to set volume: ${e.message}", null)
        }
    }

    private fun setSpeed(call: MethodCall, result: MethodChannel.Result) {
        val speed = call.argument<Double>("speed")
        if (speed == null) {
            result.error("INVALID_ARGS", "speed is required", null)
            return
        }
        val player = mediaPlayer
        if (player == null) {
            result.error("NO_PLAYER", "No audio loaded", null)
            return
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val params = player.playbackParams
                params.speed = speed.coerceIn(0.5, 2.0).toFloat()
                player.playbackParams = params
                result.success(null)
            } else {
                result.error("UNSUPPORTED", "Playback speed requires API 23+", null)
            }
        } catch (e: Exception) {
            emitPlaybackStateEvent(state = "error", reason = e.message)
            result.error("SPEED_FAILED", "Failed to set speed: ${e.message}", null)
        }
    }

    private fun startPlaybackPositionUpdates() {
        if (playbackPositionHandler != null) return
        playbackPositionThread = HandlerThread("PlaybackPositionThread").apply { start() }
        playbackPositionHandler = Handler(playbackPositionThread!!.looper)
        schedulePlaybackPositionPolling()
    }

    private fun stopPlaybackPositionUpdates() {
        playbackPositionHandler?.removeCallbacksAndMessages(null)
        playbackPositionThread?.quitSafely()
        playbackPositionThread = null
        playbackPositionHandler = null
    }

    private fun schedulePlaybackPositionPolling() {
        playbackPositionHandler?.postDelayed({
            val player = mediaPlayer
            if (player != null && player.isPlaying) {
                emitPlaybackPositionEvent()
                schedulePlaybackPositionPolling()
            } else {
                emitPlaybackPositionEvent()
            }
        }, PLAYBACK_POSITION_INTERVAL_MS)
    }

    private fun emitPlaybackStateEvent(state: String, reason: String?) {
        val event = mapOf(
            "state" to state,
            "filePath" to playbackFilePath,
            "reason" to reason
        )
        playbackStateEventSink?.success(event)
    }

    private fun emitPlaybackPositionEvent() {
        val player = mediaPlayer ?: return
        val durationMs = try {
            player.duration
        } catch (_: Exception) {
            0
        }
        val positionMs = try {
            player.currentPosition
        } catch (_: Exception) {
            0
        }
        val event = mapOf(
            "positionMs" to positionMs,
            "durationMs" to durationMs,
            "filePath" to (playbackFilePath ?: "")
        )
        playbackPositionEventSink?.success(event)
    }

    private class PlaybackStateStreamHandler(
        private val plugin: AudioRecorderPlugin,
    ) : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            plugin.playbackStateEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            plugin.playbackStateEventSink = null
        }
    }

    private class PlaybackPositionStreamHandler(
        private val plugin: AudioRecorderPlugin,
    ) : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            plugin.playbackPositionEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            plugin.playbackPositionEventSink = null
            plugin.stopPlaybackPositionUpdates()
        }
    }
}
