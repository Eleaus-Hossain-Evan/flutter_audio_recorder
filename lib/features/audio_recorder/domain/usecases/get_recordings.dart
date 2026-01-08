import '../entities/recording_entity.dart';
import '../repositories/audio_recorder_repository.dart';

/// Use case for retrieving all recordings.
class GetRecordings {
  final AudioRecorderRepository _repository;

  GetRecordings(this._repository);

  /// Executes the use case and returns all recordings.
  Future<List<RecordingEntity>> call() async {
    return await _repository.getRecordings();
  }
}
