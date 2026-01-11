import 'models/amplitude_sample.dart';
import 'models/recorder_state_event.dart';

/// Audio recorder streaming repository contract.
///
/// Defines the interface for real-time streaming of recording state and amplitude data.
/// Implementations must expose platform-agnostic streams with normalized data.
abstract interface class IAudioRecorderStreamRepository {
  /// Stream of recording state changes emitted by the native layer.
  ///
  /// Emits [RecorderStateEvent] on each state transition.
  /// Lifecycle:
  /// - Starts only after successful `startRecording`
  /// - Stops immediately on `stopRecording` or error
  /// - Canceled on subscription disposal
  ///
  /// Event Channel: `com.example.audio_recorder/events/recording_state`
  Stream<RecorderStateEvent> recordingStateStream();

  /// Stream of real-time amplitude samples during recording.
  ///
  /// Emits [AmplitudeSample] at ~30-60 Hz during active recording.
  /// Values are normalized to 0.0-1.0 by the native layer.
  /// Lifecycle:
  /// - Starts only after successful `startRecording`
  /// - Stops immediately on `stopRecording` or error
  /// - Canceled on subscription disposal
  ///
  /// Event Channel: `com.example.audio_recorder/events/amplitude`
  Stream<AmplitudeSample> amplitudeStream();
}
