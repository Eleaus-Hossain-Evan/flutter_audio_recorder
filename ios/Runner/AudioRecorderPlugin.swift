import Flutter
import UIKit
import AVFoundation

public class AudioRecorderPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var stateEventChannel: FlutterEventChannel?
    private var amplitudeEventChannel: FlutterEventChannel?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingStartTime: Date?
    private var currentRecordingURL: URL?
    
    private var stateEventSink: FlutterEventSink?
    private var amplitudeEventSink: FlutterEventSink?
    
    private var meringTimer: Timer?
    private var recordingInProgress = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.example.audio_recorder/methods",
            binaryMessenger: registrar.messenger()
        )
        let stateEventChannel = FlutterEventChannel(
            name: "com.example.audio_recorder/events/recording_state",
            binaryMessenger: registrar.messenger()
        )
        let amplitudeEventChannel = FlutterEventChannel(
            name: "com.example.audio_recorder/events/amplitude",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = AudioRecorderPlugin()
        instance.methodChannel = methodChannel
        instance.stateEventChannel = stateEventChannel
        instance.amplitudeEventChannel = amplitudeEventChannel
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        stateEventChannel.setStreamHandler(instance)
        amplitudeEventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermission":
            requestPermission(result: result)
        case "startRecording":
            startRecording(result: result)
        case "stopRecording":
            stopRecording(result: result)
        case "getRecordings":
            getRecordings(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestPermission(result: @escaping FlutterResult) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                result(granted)
            }
        }
    }
    
    private func startRecording(result: @escaping FlutterResult) {
        // Check permission
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        guard permissionStatus == .granted else {
            result(FlutterError(
                code: "PERMISSION_DENIED",
                message: "Microphone permission not granted",
                details: nil
            ))
            return
        }
        
        do {
            // Emit initializing state
            emitRecordingStateEvent(state: "initializing", timestamp: currentISO8601(), reason: nil)
            
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Generate unique filename
            let uuid = UUID().uuidString.prefix(8)
            let fileName = "record_\(uuid).m4a"
            
            // Get documents directory
            guard let documentsPath = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first else {
                result(FlutterError(
                    code: "DIRECTORY_ERROR",
                    message: "Could not access documents directory",
                    details: nil
                ))
                return
            }
            
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            // Audio settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Create and start recorder
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            guard let recorder = audioRecorder else {
                result(FlutterError(
                    code: "RECORDING_FAILED",
                    message: "Failed to create audio recorder",
                    details: nil
                ))
                return
            }
            
            // Enable metering for amplitude
            recorder.isMeteringEnabled = true
            recorder.record()
            
            currentRecordingURL = fileURL
            recordingStartTime = Date()
            recordingInProgress = true
            
            // Emit recording state
            emitRecordingStateEvent(state: "recording", timestamp: currentISO8601(), reason: nil)
            
            // Start amplitude metering (30-60 Hz; here using 50 Hz)
            startAmplitudeMetering()
            
            result(nil)
        } catch {
            recordingInProgress = false
            emitRecordingStateEvent(state: "error", timestamp: currentISO8601(), reason: error.localizedDescription)
            result(FlutterError(
                code: "RECORDING_FAILED",
                message: "Failed to start recording: \(error.localizedDescription)",
                details: nil
            ))
        }
    }
    
    private func stopRecording(result: @escaping FlutterResult) {
        guard let recorder = audioRecorder,
              let recordingURL = currentRecordingURL else {
            result(FlutterError(
                code: "NO_RECORDING",
                message: "No recording in progress",
                details: nil
            ))
            return
        }
        
        // Stop metering
        stopAmplitudeMetering()
        
        // Emit stopping state
        emitRecordingStateEvent(state: "stopping", timestamp: currentISO8601(), reason: nil)
        
        recorder.stop()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            // Ignore deactivation errors
        }
        
        // Get metadata
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            recordingInProgress = false
            emitRecordingStateEvent(state: "error", timestamp: currentISO8601(), reason: "Recording file not found")
            result(FlutterError(
                code: "FILE_NOT_FOUND",
                message: "Recording file not found",
                details: nil
            ))
            return
        }
        
        let metadata = getRecordingMetadata(fileURL: recordingURL)
        
        audioRecorder = nil
        currentRecordingURL = nil
        recordingStartTime = nil
        recordingInProgress = false
        
        // Emit stopped state
        emitRecordingStateEvent(state: "stopped", timestamp: currentISO8601(), reason: nil)
        
        result(metadata)
    }
    
    private func getRecordings(result: @escaping FlutterResult) {
        guard let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            result(FlutterError(
                code: "DIRECTORY_ERROR",
                message: "Could not access documents directory",
                details: nil
            ))
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let recordings = fileURLs
                .filter { $0.pathExtension == "m4a" }
                .map { getRecordingMetadata(fileURL: $0) }
                .sorted { ($0["createdAt"] as? String ?? "") > ($1["createdAt"] as? String ?? "") }
            
            result(recordings)
        } catch {
            result(FlutterError(
                code: "GET_RECORDINGS_FAILED",
                message: "Failed to get recordings: \(error.localizedDescription)",
                details: nil
            ))
        }
    }
    
    private func getRecordingMetadata(fileURL: URL) -> [String: Any] {
        let fileName = fileURL.lastPathComponent
        let fileNameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
        
        var durationMs = 0
        var sizeBytes: Int64 = 0
        var createdAt = Date()
        
        // Get file attributes
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            sizeBytes = attributes[.size] as? Int64 ?? 0
            createdAt = attributes[.modificationDate] as? Date ?? Date()
        } catch {
            // Use defaults
        }
        
        // Get duration
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let sampleRate = audioFile.processingFormat.sampleRate
            let length = audioFile.length
            let duration = Double(length) / sampleRate
            durationMs = Int(duration * 1000)
        } catch {
            // Duration extraction failed, use 0
        }
        
        // Format date to ISO 8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoDate = isoFormatter.string(from: createdAt)
        
        return [
            "id": fileNameWithoutExtension,
            "filePath": fileURL.path,
            "fileName": fileName,
            "durationMs": durationMs,
            "sizeBytes": sizeBytes,
            "createdAt": isoDate
        ]
    }
    
    // MARK: - Amplitude Metering
    
    private func startAmplitudeMetering() {
        // Timer at ~50 Hz (0.02 second interval) for amplitude sampling
        meringTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            self?.emitAmplitudeSample()
        }
    }
    
    private func stopAmplitudeMetering() {
        meringTimer?.invalidate()
        meringTimer = nil
    }
    
    private func emitAmplitudeSample() {
        guard let recorder = audioRecorder, recordingInProgress else { return }
        
        recorder.updateMeters()
        
        // Get average power in dB (-160 to 0)
        let averagePower = recorder.averagePower(forChannel: 0)
        
        // Normalize: -160 dB → 0.0, 0 dB → 1.0
        let normalizedAmplitude = max(0.0, min(1.0, (averagePower + 160.0) / 160.0))
        
        // Emit as raw double
        amplitudeEventSink?(normalizedAmplitude)
    }
    
    // MARK: - State Event Emission
    
    private func emitRecordingStateEvent(state: String, timestamp: String, reason: String?) {
        let event: [String: Any?] = [
            "state": state,
            "timestamp": timestamp,
            "reason": reason
        ]
        stateEventSink?(event)
    }
    
    private func currentISO8601() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}

// MARK: - FlutterStreamHandler Implementation

extension AudioRecorderPlugin: FlutterStreamHandler {
    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        // Determine which stream this is by checking the current event sink
        // This is a simplification; in production, use a named handler per channel
        if stateEventSink == nil {
            stateEventSink = events
        } else {
            amplitudeEventSink = events
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Cleanup on stream cancellation
        if amplitudeEventSink != nil {
            amplitudeEventSink = nil
            stopAmplitudeMetering()
        } else {
            stateEventSink = nil
        }
        return nil
    }
}

