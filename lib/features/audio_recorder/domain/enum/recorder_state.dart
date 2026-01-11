/// Enumeration of recording states throughout the recorder lifecycle.
///
/// These states are emitted by the native layer via EventChannel
/// and represent the definitive state of the audio recorder.
enum RecorderState {
  /// Recorder is idle and not recording.
  idle,

  /// Recorder is initializing resources (preparing to record).
  initializing,

  /// Recorder is actively recording audio.
  recording,

  /// Recorder is paused (reserved for Phase 3).
  paused,

  /// Recorder is stopping and finalizing the recording file.
  stopping,

  /// Recorder has stopped and finalized the recording.
  stopped,

  /// An error occurred during recording.
  error;

  /// Returns whether this state represents an active recording.
  bool get isRecording =>
      this == RecorderState.recording || this == RecorderState.paused;

  /// Returns whether this state is a terminal state.
  bool get isTerminal =>
      this == RecorderState.stopped || this == RecorderState.error;
}
