package com.example.flutter_audio_recorder

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class AudioRecorderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    
    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingPath: String? = null
    private var recordingStartTime: Long = 0
    
    private var permissionResult: MethodChannel.Result? = null

    companion object {
        private const val CHANNEL_NAME = "com.example.audio_recorder/methods"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
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

            result.success(null)
        } catch (e: Exception) {
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
            recorder.stop()
            recorder.release()
            mediaRecorder = null

            val file = File(recordingPath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "Recording file not found", null)
                return
            }

            // Get metadata
            val metadata = getRecordingMetadata(file)
            currentRecordingPath = null
            
            result.success(metadata)
        } catch (e: Exception) {
            mediaRecorder?.release()
            mediaRecorder = null
            currentRecordingPath = null
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
}
