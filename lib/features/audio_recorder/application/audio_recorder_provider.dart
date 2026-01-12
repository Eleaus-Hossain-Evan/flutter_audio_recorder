import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constant/recorder_status.dart';
import '../../../core/constant/waveform_constants.dart';
import '../../../core/exceptions/audio_exceptions.dart';
import '../domain/i_audio_recorder_repo.dart';
import '../domain/i_audio_recorder_stream_repo.dart';
import '../domain/models/amplitude_sample.dart';
import '../domain/models/recording_model.dart';
import '../infrastructure/audio_recorder_method_channel.dart';
import '../infrastructure/audio_recorder_repo.dart';
import 'audio_recorder_state.dart';
import 'waveform_processor_provider.dart';

part 'audio_recorder_provider.g.dart';

/// Provider for audio recorder repository.
///
/// Returns both command and streaming capabilities through the unified [AudioRecorderRepo].
/// Casting to [IAudioRecorderStreamRepository] is safe since the implementation provides both interfaces.
@riverpod
IAudioRecorderRepo audioRecorderRepository(Ref ref) {
  return AudioRecorderRepo(AudioRecorderMethodChannel());
}

/// Audio recorder notifier that manages recording state.
///
/// Coordinates:
/// - Command execution (requestPermission, startRecording, stopRecording)
/// - Stream lifecycle (streams auto-cancel on stop/error)
/// - Amplitude sample collection for waveform generation
@riverpod
class AudioRecorder extends _$AudioRecorder {
  /// Captured amplitude samples for the current recording session.
  final List<AmplitudeSample> _capturedSamples = [];

  @override
  AudioRecorderState build() {
    // Load recordings on init
    _loadRecordings();
    return AudioRecorderState.initial();
  }

  /// Loads recordings from native storage.
  Future<void> _loadRecordings() async {
    try {
      final repository = ref.read(audioRecorderRepositoryProvider);
      final recordings = await repository.getRecordings();
      state = state.copyWith(recordings: recordings);
    } on AudioFileException catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: 'Failed to load recordings: $e',
      );
    }
  }

  /// Requests microphone permission.
  Future<bool> requestPermission() async {
    try {
      final repository = ref.read(audioRecorderRepositoryProvider);
      final granted = await repository.requestPermission();

      if (!granted) {
        state = state.copyWith(
          status: RecorderStatus.error,
          errorMessage: 'Microphone permission denied',
        );
      }

      return granted;
    } on AudioPermissionException catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: 'Permission request failed: $e',
      );
      return false;
    }
  }

  /// Starts recording.
  ///
  /// On success, emits recording state and amplitude streams
  /// (via [recordingStateStreamProvider] and [amplitudeStreamProvider]).
  /// Streams auto-cancel when [stop] is called or on error.
  /// Amplitude samples are captured for waveform generation.
  Future<void> start() async {
    try {
      // Clear previous samples
      _capturedSamples.clear();

      final repository = ref.read(audioRecorderRepositoryProvider);
      await repository.startRecording();

      // Start collecting amplitude samples
      _listenToAmplitudeStream();

      state = state.copyWith(
        status: RecorderStatus.recording,
        errorMessage: null,
      );
    } on AudioRecordingException catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  /// Stops recording and adds the new recording to the list.
  ///
  /// Streams are canceled by the native layer when recording stops.
  /// Amplitude samples are aggregated into waveform data before saving.
  Future<void> stop() async {
    try {
      final repository = ref.read(audioRecorderRepositoryProvider);
      final recording = await repository.stopRecording();

      // Generate waveform from captured samples
      List<double>? waveformData;
      if (_capturedSamples.isNotEmpty) {
        final processor = ref.read(waveformProcessorProvider);
        waveformData = processor.aggregateSamples(
          _capturedSamples,
          WaveformConstants.kWaveformBars,
        );
      }

      // Attach waveform to recording
      final recordingWithWaveform = recording.copyWith(
        waveformData: waveformData,
      );

      // Clear captured samples
      _capturedSamples.clear();

      // Add new recording to the beginning of the list
      final updatedRecordings = <RecordingModel>[
        recordingWithWaveform,
        ...state.recordings,
      ];

      state = state.copyWith(
        status: RecorderStatus.stopped,
        recordings: updatedRecordings,
        errorMessage: null,
      );
    } on AudioRecordingException catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: 'Failed to stop recording: $e',
      );
    }
  }

  /// Refreshes the recordings list.
  Future<void> refresh() async {
    await _loadRecordings();
  }

  /// Listens to amplitude stream and captures samples for waveform generation.
  void _listenToAmplitudeStream() {
    final repository = ref.read(audioRecorderRepositoryProvider);
    final streamRepo = repository as IAudioRecorderStreamRepository;

    streamRepo.amplitudeStream().listen(
      (sample) {
        _capturedSamples.add(sample);
      },
      onError: (error) {
        // Log error but don't stop recording
        // Waveform will fallback to null if samples are empty
      },
    );
  }
}
