/// Recorder status enum.
enum RecorderStatus {
  /// Not recording, idle state.
  idle,

  /// Currently recording.
  recording,

  /// Recording stopped.
  stopped,

  /// Error state.
  error,
}

extension RecorderStatusExtension on RecorderStatus {
  /// Checks if the recorder is currently recording.
  String get statusText => switch (this) {
    RecorderStatus.idle => 'Ready',
    RecorderStatus.recording => '🔴 Recording...',
    RecorderStatus.stopped => 'Recording saved',
    RecorderStatus.error => 'Error',
  };
}
