import 'models/recording_model.dart';

/// Data source contract for audio recorder platform calls.
abstract class IAudioRecorderDataSource {
  Future<bool> requestPermission();
  Future<void> startRecording();
  Future<RecordingModel> stopRecording();
  Future<List<RecordingModel>> getRecordings();
}
