import Flutter
import UIKit
import AVFoundation

public class AudioRecorderPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var audioRecorder: AVAudioRecorder?
    private var recordingStartTime: Date?
    private var currentRecordingURL: URL?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.audio_recorder/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = AudioRecorderPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
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
            audioRecorder?.record()
            
            currentRecordingURL = fileURL
            recordingStartTime = Date()
            
            result(nil)
        } catch {
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
        
        recorder.stop()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            // Ignore deactivation errors
        }
        
        // Get metadata
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
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
}
