import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models/amplitude_sample.dart';
import '../domain/models/recorder_state_event.dart';
import 'audio_recorder_provider.dart';

part 'audio_recorder_stream_provider.g.dart';

/// Stream provider for recording state events.
///
/// Emits [RecorderStateEvent] on each state change during recording.
/// Auto-cancels on subscription disposal or when recording stops.
///
/// Usage:
/// ```dart
/// ref.watch(recordingStateStreamProvider).when(
///   data: (stateEvent) => Text('State: ${stateEvent.state}'),
///   error: (error, stack) => Text('Error'),
///   loading: () => CircularProgressIndicator(),
/// )
/// ```
@riverpod
Stream<RecorderStateEvent> recordingStateStream(Ref ref) {
  // Access the repository through the existing provider and cast to streaming interface
  final repository = ref.watch(audioRecorderRepositoryProvider);
  // Safe cast since AudioRecorderRepo implements IAudioRecorderStreamRepository
  final streamRepo = repository as dynamic;
  return streamRepo.recordingStateStream() as Stream<RecorderStateEvent>;
}

/// Stream provider for real-time amplitude samples.
///
/// Emits [AmplitudeSample] at ~30-60 Hz during active recording.
/// Values are normalized to 0.0-1.0 by the native layer.
/// Auto-cancels on subscription disposal or when recording stops.
///
/// Usage:
/// ```dart
/// ref.watch(amplitudeStreamProvider).whenData((sample) {
///   print('Amplitude: ${sample.value}');
/// })
/// ```
@riverpod
Stream<AmplitudeSample> amplitudeStream(Ref ref) {
  // Access the repository through the existing provider and cast to streaming interface
  final repository = ref.watch(audioRecorderRepositoryProvider);
  // Safe cast since AudioRecorderRepo implements IAudioRecorderStreamRepository
  final streamRepo = repository as dynamic;
  return streamRepo.amplitudeStream() as Stream<AmplitudeSample>;
}
