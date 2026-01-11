import '../domain/i_audio_recorder_datasource.dart';
import '../domain/i_audio_recorder_repo.dart';
import '../domain/i_audio_recorder_stream_repo.dart';
import '../domain/models/amplitude_sample.dart';
import '../domain/models/recorder_state_event.dart';
import '../domain/models/recording_model.dart';
import 'event_channels/audio_recorder_amplitude_channel.dart';
import 'event_channels/audio_recorder_recording_state_channel.dart';

/// Implementation of [IAudioRecorderRepo] and [IAudioRecorderStreamRepository].
///
/// Delegates command execution to method channel datasource.
/// Delegates streaming to EventChannel datasources.
class AudioRecorderRepo
    implements IAudioRecorderRepo, IAudioRecorderStreamRepository {
  final IAudioRecorderDataSource _dataSource;
  final AudioRecorderRecordingStateChannel _stateChannel;
  final AudioRecorderAmplitudeChannel _amplitudeChannel;

  AudioRecorderRepo(
    this._dataSource, {
    AudioRecorderRecordingStateChannel? stateChannel,
    AudioRecorderAmplitudeChannel? amplitudeChannel,
  }) : _stateChannel = stateChannel ?? AudioRecorderRecordingStateChannel(),
       _amplitudeChannel = amplitudeChannel ?? AudioRecorderAmplitudeChannel();

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

  @override
  Stream<RecorderStateEvent> recordingStateStream() {
    return _stateChannel.stateStream;
  }

  @override
  Stream<AmplitudeSample> amplitudeStream() {
    return _amplitudeChannel.amplitudeStream;
  }
}
