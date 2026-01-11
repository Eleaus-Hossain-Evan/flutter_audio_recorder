import '../domain/i_audio_recorder_datasource.dart';
import '../domain/i_audio_recorder_repo.dart';
import '../domain/models/recording_model.dart';

/// Implementation of [IAudioRecorderRepo] using method channels.
class AudioRecorderRepo implements IAudioRecorderRepo {
  final IAudioRecorderDataSource _dataSource;

  AudioRecorderRepo(this._dataSource);

  @override
  Future<bool> requestPermission() async {
    return await _dataSource.requestPermission();
  }

  @override
  Future<void> startRecording() async {
    await _dataSource.startRecording();
  }

  @override
  Future<RecordingModel> stopRecording() async {
    return await _dataSource.stopRecording();
  }

  @override
  Future<List<RecordingModel>> getRecordings() async {
    final recordings = await _dataSource.getRecordings();
    // Sort by creation time, newest first
    recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recordings;
  }
}
