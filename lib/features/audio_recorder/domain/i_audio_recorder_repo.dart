import 'models/recording_model.dart';

/// Audio recorder repository contract.
///
/// Defines the interface for managing audio recordings.
/// Implementations must not expose platform-specific types.
abstract interface class IAudioRecorderRepo {
  /// Requests microphone permission from the user.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestPermission();

  /// Starts a new audio recording.
  ///
  /// Throws [Exception] if recording fails to start or permission is denied.
  Future<void> startRecording();

  /// Stops the current recording and returns its metadata.
  ///
  /// Returns a [RecordingModel] with file path, duration, and other metadata.
  /// Throws [Exception] if no recording is in progress.
  Future<RecordingModel> stopRecording();

  /// Retrieves all saved recordings.
  ///
  /// Returns a list of [RecordingModel] ordered by creation time (newest first).
  Future<List<RecordingModel>> getRecordings();
}
