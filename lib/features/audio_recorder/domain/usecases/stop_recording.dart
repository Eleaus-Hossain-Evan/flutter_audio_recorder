import '../entities/recording_entity.dart';
import '../repositories/audio_recorder_repository.dart';

/// Use case for stopping audio recording.
class StopRecording {
  final AudioRecorderRepository _repository;

  StopRecording(this._repository);

  /// Executes the use case and returns the recording metadata.
  Future<RecordingEntity> call() async {
    return await _repository.stopRecording();
  }
}
