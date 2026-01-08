import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/audio_recorder_method_channel.dart';
import '../../data/repositories/audio_recorder_repository_impl.dart';
import '../../domain/repositories/audio_recorder_repository.dart';
import 'audio_recorder_state.dart';

part 'audio_recorder_provider.g.dart';

/// Provider for audio recorder repository.
@riverpod
AudioRecorderRepository audioRecorderRepository(Ref ref) {
  return AudioRecorderRepositoryImpl(AudioRecorderMethodChannel());
}

/// Audio recorder notifier that manages recording state.
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
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: 'Permission request failed: $e',
      );
      return false;
    }
  }

  /// Starts recording.
  Future<void> start() async {
    try {
      final repository = ref.read(audioRecorderRepositoryProvider);
      await repository.startRecording();
      
      state = state.copyWith(
        status: RecorderStatus.recording,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.error,
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  /// Stops recording and adds the new recording to the list.
  Future<void> stop() async {
    try {
      final repository = ref.read(audioRecorderRepositoryProvider);
      final recording = await repository.stopRecording();
      
      // Add new recording to the beginning of the list
      final updatedRecordings = [recording, ...state.recordings];
      
      state = state.copyWith(
        status: RecorderStatus.stopped,
        recordings: updatedRecordings,
        errorMessage: null,
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
