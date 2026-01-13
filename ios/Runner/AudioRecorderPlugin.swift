import Flutter
import UIKit
import AVFoundation

public class AudioRecorderPlugin: NSObject, FlutterPlugin, AVAudioPlayerDelegate {
    private var methodChannel: FlutterMethodChannel?
    private var stateEventChannel: FlutterEventChannel?
    private var amplitudeEventChannel: FlutterEventChannel?

    private var playbackMethodChannel: FlutterMethodChannel?
    private var playbackStateEventChannel: FlutterEventChannel?
    private var playbackPositionEventChannel: FlutterEventChannel?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingStartTime: Date?
    private var currentRecordingURL: URL?
    
    private var stateEventSink: FlutterEventSink?
    private var amplitudeEventSink: FlutterEventSink?
    
    private var meringTimer: Timer?
    private var recordingInProgress = false

    private var playbackPlayer: AVAudioPlayer?
    private var playbackFilePath: String?
    private var playbackStateSink: FlutterEventSink?
    private var playbackPositionSink: FlutterEventSink?
    private var playbackTimer: Timer?
    
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

        let playbackMethodChannel = FlutterMethodChannel(
            name: "com.example.audio_player/methods",
            binaryMessenger: registrar.messenger()
        )
        let playbackStateEventChannel = FlutterEventChannel(
            name: "com.example.audio_player/events/state",
            binaryMessenger: registrar.messenger()
        )
        let playbackPositionEventChannel = FlutterEventChannel(
            name: "com.example.audio_player/events/position",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = AudioRecorderPlugin()
        instance.methodChannel = methodChannel
        instance.stateEventChannel = stateEventChannel
        instance.amplitudeEventChannel = amplitudeEventChannel
        instance.playbackMethodChannel = playbackMethodChannel
        instance.playbackStateEventChannel = playbackStateEventChannel
        instance.playbackPositionEventChannel = playbackPositionEventChannel
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        registrar.addMethodCallDelegate(instance, channel: playbackMethodChannel)

        stateEventChannel.setStreamHandler(EventSinkHandler(
            onListen: { sink in instance.stateEventSink = sink },
            onCancel: {
                instance.stateEventSink = nil
            }
        ))
        amplitudeEventChannel.setStreamHandler(EventSinkHandler(
            onListen: { sink in instance.amplitudeEventSink = sink },
            onCancel: {
                instance.amplitudeEventSink = nil
                instance.stopAmplitudeMetering()
            }
        ))
        playbackStateEventChannel.setStreamHandler(EventSinkHandler(
            onListen: { sink in instance.playbackStateSink = sink },
            onCancel: {
                instance.playbackStateSink = nil
            }
        ))
        playbackPositionEventChannel.setStreamHandler(EventSinkHandler(
            onListen: { sink in instance.playbackPositionSink = sink },
            onCancel: {
                instance.playbackPositionSink = nil
                instance.stopPlaybackPositionUpdates()
            }
        ))
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
        case "loadLocal":
            loadLocal(call: call, result: result)
        case "play":
            play(result: result)
        case "pause":
            pause(result: result)
        case "stop":
            stop(result: result)
        case "seekTo":
            seekTo(call: call, result: result)
        case "setVolume":
            setVolume(call: call, result: result)
        case "setSpeed":
            setSpeed(call: call, result: result)
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
            
            // Configure audio session for VoIP with optimizations
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,  // Optimized for VoIP: echo cancellation, noise suppression
                options: [
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .defaultToSpeaker,
                    .mixWithOthers
                ]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
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

    private func loadLocal(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "filePath is required", details: nil))
            return
        }

        stopPlaybackPositionUpdates()
        playbackPlayer?.stop()
        playbackPlayer = nil
        playbackFilePath = filePath

        emitPlaybackStateEvent(state: "loading", reason: nil)

        let url = URL(fileURLWithPath: filePath)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.enableRate = true
            player.delegate = self
            player.prepareToPlay()
            playbackPlayer = player
            emitPlaybackStateEvent(state: "paused", reason: nil)
            emitPlaybackPositionEvent()
            result(nil)
        } catch {
            emitPlaybackStateEvent(state: "error", reason: error.localizedDescription)
            result(FlutterError(code: "LOAD_FAILED", message: "Failed to load audio: \(error.localizedDescription)", details: nil))
        }
    }

    private func play(result: @escaping FlutterResult) {
        guard let player = playbackPlayer else {
            result(FlutterError(code: "NO_PLAYER", message: "No audio loaded", details: nil))
            return
        }
        if player.play() {
            emitPlaybackStateEvent(state: "playing", reason: nil)
            startPlaybackPositionUpdates()
            result(nil)
        } else {
            emitPlaybackStateEvent(state: "error", reason: "Failed to start playback")
            result(FlutterError(code: "PLAY_FAILED", message: "Failed to start playback", details: nil))
        }
    }

    private func pause(result: @escaping FlutterResult) {
        guard let player = playbackPlayer else {
            result(FlutterError(code: "NO_PLAYER", message: "No audio loaded", details: nil))
            return
        }
        player.pause()
        stopPlaybackPositionUpdates()
        emitPlaybackStateEvent(state: "paused", reason: nil)
        emitPlaybackPositionEvent()
        result(nil)
    }

    private func stop(result: @escaping FlutterResult) {
        playbackPlayer?.stop()
        playbackPlayer?.currentTime = 0
        stopPlaybackPositionUpdates()
        emitPlaybackStateEvent(state: "idle", reason: nil)
        emitPlaybackPositionEvent()
        result(nil)
    }

    private func seekTo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let positionMs = args["positionMs"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "positionMs is required", details: nil))
            return
        }
        guard let player = playbackPlayer else {
            result(FlutterError(code: "NO_PLAYER", message: "No audio loaded", details: nil))
            return
        }
        player.currentTime = Double(positionMs) / 1000.0
        emitPlaybackPositionEvent()
        result(nil)
    }

    private func setVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let volume = args["volume"] as? Double else {
            result(FlutterError(code: "INVALID_ARGS", message: "volume is required", details: nil))
            return
        }
        guard let player = playbackPlayer else {
            result(FlutterError(code: "NO_PLAYER", message: "No audio loaded", details: nil))
            return
        }
        player.volume = Float(max(0.0, min(1.0, volume)))
        result(nil)
    }

    private func setSpeed(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let speed = args["speed"] as? Double else {
            result(FlutterError(code: "INVALID_ARGS", message: "speed is required", details: nil))
            return
        }
        guard let player = playbackPlayer else {
            result(FlutterError(code: "NO_PLAYER", message: "No audio loaded", details: nil))
            return
        }
        player.rate = Float(max(0.5, min(2.0, speed)))
        result(nil)
    }

    private func startPlaybackPositionUpdates() {
        stopPlaybackPositionUpdates()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.emitPlaybackPositionEvent()
        }
    }

    private func stopPlaybackPositionUpdates() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func emitPlaybackStateEvent(state: String, reason: String?) {
        let event: [String: Any?] = [
            "state": state,
            "filePath": playbackFilePath,
            "reason": reason
        ]
        playbackStateSink?(event)
    }

    private func emitPlaybackPositionEvent() {
        guard let player = playbackPlayer else { return }
        let positionMs = Int(player.currentTime * 1000.0)
        let durationMs = Int(player.duration * 1000.0)
        let event: [String: Any] = [
            "positionMs": positionMs,
            "durationMs": durationMs,
            "filePath": playbackFilePath ?? ""
        ]
        playbackPositionSink?(event)
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaybackPositionUpdates()
        emitPlaybackPositionEvent()
        emitPlaybackStateEvent(state: "completed", reason: flag ? nil : "Playback did not complete successfully")
    }
}

final class EventSinkHandler: NSObject, FlutterStreamHandler {
    private let onListenCallback: (FlutterEventSink) -> Void
    private let onCancelCallback: () -> Void

    init(onListen: @escaping (FlutterEventSink) -> Void, onCancel: @escaping () -> Void) {
        self.onListenCallback = onListen
        self.onCancelCallback = onCancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onListenCallback(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onCancelCallback()
        return nil
    }
}
