import '../../domain/entities/recording_entity.dart';
import '../../domain/repositories/audio_recorder_repository.dart';
import '../datasources/audio_recorder_method_channel.dart';

/// Implementation of [AudioRecorderRepository] using method channels.
class AudioRecorderRepositoryImpl implements AudioRecorderRepository {
  final AudioRecorderMethodChannel _dataSource;

  AudioRecorderRepositoryImpl(this._dataSource);

  @override
  Future<bool> requestPermission() async {
    return await _dataSource.requestPermission();
  }

  @override
  Future<void> startRecording() async {
    await _dataSource.startRecording();
  }

  @override
  Future<RecordingEntity> stopRecording() async {
    return await _dataSource.stopRecording();
  }

  @override
  Future<List<RecordingEntity>> getRecordings() async {
    final recordings = await _dataSource.getRecordings();
    // Sort by creation time, newest first
    recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recordings;
  }
}
