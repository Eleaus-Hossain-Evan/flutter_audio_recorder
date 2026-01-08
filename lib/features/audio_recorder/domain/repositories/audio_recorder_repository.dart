import '../entities/recording_entity.dart';

/// Audio recorder repository contract.
///
/// Defines the interface for managing audio recordings.
/// Implementations must not expose platform-specific types.
abstract class AudioRecorderRepository {
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
  /// Returns a [RecordingEntity] with file path, duration, and other metadata.
  /// Throws [Exception] if no recording is in progress.
  Future<RecordingEntity> stopRecording();

  /// Retrieves all saved recordings.
  ///
  /// Returns a list of [RecordingEntity] ordered by creation time (newest first).
  Future<List<RecordingEntity>> getRecordings();
}
