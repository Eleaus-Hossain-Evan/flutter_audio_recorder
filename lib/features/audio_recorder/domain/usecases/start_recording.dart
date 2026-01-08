import '../repositories/audio_recorder_repository.dart';

/// Use case for starting audio recording.
class StartRecording {
  final AudioRecorderRepository _repository;

  StartRecording(this._repository);

  /// Executes the use case.
  Future<void> call() async {
    await _repository.startRecording();
  }
}
