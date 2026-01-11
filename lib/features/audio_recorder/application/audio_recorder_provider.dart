import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constant/recorder_status.dart';
import '../../../core/exceptions/audio_exceptions.dart';
import '../domain/i_audio_recorder_repo.dart';
import '../domain/models/recording_model.dart';
import '../infrastructure/audio_recorder_method_channel.dart';
import '../infrastructure/audio_recorder_repo.dart';
import 'audio_recorder_state.dart';

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
@riverpod
class AudioRecorder extends _$AudioRecorder {
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
  Future<void> start() async {
    try {
      final repository = ref.read(audioRecorderRepositoryProvider);
      await repository.startRecording();

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
  Future<void> stop() async {
    try {
      final repository = ref.read(audioRecorderRepositoryProvider);
      final recording = await repository.stopRecording();

      // Add new recording to the beginning of the list
      final updatedRecordings = <RecordingModel>[
        recording,
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
}
