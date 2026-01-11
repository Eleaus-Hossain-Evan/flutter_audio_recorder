import '../domain/models/recording_model.dart';

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

/// State for audio recorder.
class AudioRecorderState {
  final RecorderStatus status;
  final List<RecordingModel> recordings;
  final String? errorMessage;

  const AudioRecorderState({
    required this.status,
    required this.recordings,
    this.errorMessage,
  });

  /// Initial state.
  factory AudioRecorderState.initial() {
    return const AudioRecorderState(
      status: RecorderStatus.idle,
      recordings: [],
    );
  }

  /// Creates a copy with optional field replacements.
  AudioRecorderState copyWith({
    RecorderStatus? status,
    List<RecordingModel>? recordings,
    String? errorMessage,
  }) {
    return AudioRecorderState(
      status: status ?? this.status,
      recordings: recordings ?? this.recordings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AudioRecorderState &&
        other.status == status &&
        other.recordings == recordings &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(status, recordings, errorMessage);
  }
}
