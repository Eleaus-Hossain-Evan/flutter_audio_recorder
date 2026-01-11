package com.example.flutter_audio_recorder

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
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
    PluginRegistry.RequestPermissionsResultListener, EventChannel.StreamHandler {

    private lateinit var channel: MethodChannel
    private var stateEventChannel: EventChannel? = null
    private var amplitudeEventChannel: EventChannel? = null
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    
    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingPath: String? = null
    private var recordingStartTime: Long = 0
    
    private var permissionResult: MethodChannel.Result? = null
    
    private var stateEventSink: EventChannel.EventSink? = null
    private var amplitudeEventSink: EventChannel.EventSink? = null
    
    private var amplitudeMeteringThread: HandlerThread? = null
    private var amplitudeMeteringHandler: Handler? = null
    private var recordingInProgress = false

    companion object {
        private const val CHANNEL_NAME = "com.example.audio_recorder/methods"
        private const val STATE_EVENT_CHANNEL_NAME = "com.example.audio_recorder/events/recording_state"
        private const val AMPLITUDE_EVENT_CHANNEL_NAME = "com.example.audio_recorder/events/amplitude"
        private const val PERMISSION_REQUEST_CODE = 1001
        private const val AMPLITUDE_POLLING_INTERVAL_MS = 20L  // ~50 Hz
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        stateEventChannel = EventChannel(binding.binaryMessenger, STATE_EVENT_CHANNEL_NAME)
        stateEventChannel?.setStreamHandler(this)
        
        amplitudeEventChannel = EventChannel(binding.binaryMessenger, AMPLITUDE_EVENT_CHANNEL_NAME)
        amplitudeEventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stateEventChannel?.setStreamHandler(null)
        amplitudeEventChannel?.setStreamHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> requestPermission(result)
            "startRecording" -> startRecording(result)
            "stopRecording" -> stopRecording(result)
            "getRecordings" -> getRecordings(result)
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

    private fun startRecording(result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context is null", null)
            return
        }

        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) 
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Microphone permission not granted", null)
            return
        }

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

            // Initialize MediaRecorder
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(ctx)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setOutputFile(currentRecordingPath)
                prepare()
                start()
            }

            recordingInProgress = true
            
            // Emit recording state
            emitRecordingStateEvent(state = "recording", reason = null)
            
            // Start amplitude metering
            startAmplitudeMetering()

            result.success(null)
        } catch (e: Exception) {
            recordingInProgress = false
            emitRecordingStateEvent(state = "error", reason = e.message)
            result.error("RECORDING_FAILED", "Failed to start recording: ${e.message}", null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        val recorder = mediaRecorder
        val recordingPath = currentRecordingPath

        if (recorder == null || recordingPath == null) {
            result.error("NO_RECORDING", "No recording in progress", null)
            return
        }

        try {
            // Stop amplitude metering
            stopAmplitudeMetering()
            
            // Emit stopping state
            emitRecordingStateEvent(state = "stopping", reason = null)
            
            recorder.stop()
            recorder.release()
            mediaRecorder = null

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
            mediaRecorder?.release()
            mediaRecorder = null
            currentRecordingPath = null
            recordingInProgress = false
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
        val recorder = mediaRecorder ?: return
        
        try {
            // Get max amplitude (0-32767)
            val maxAmplitude = recorder.maxAmplitude.toDouble()
            
            // Normalize: 0 → 0.0, 32767 → 1.0
            val normalizedAmplitude = (maxAmplitude / 32767.0).coerceIn(0.0, 1.0)
            
            // Emit as raw double
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
}

