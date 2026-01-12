import 'package:just_audio/just_audio.dart';

/// Simplified playback state model representing the current state of audio playback.
///
/// This model abstracts away the complexity of just_audio's raw state
/// and provides a clean domain-specific interface for the UI.
class AudioPlayerState {
  /// Whether the audio is currently playing.
  final bool isPlaying;

  /// The current processing state of the audio player.
  ///
  /// This indicates whether the player is idle, loading, buffering, ready, or completed.
  final ProcessingState processingState;

  /// The total duration of the loaded audio file.
  ///
  /// Will be null if no audio is loaded.
  final Duration? currentDuration;

  /// The file path or URL of the currently loaded audio.
  ///
  /// Will be null if no audio is loaded.
  final String? loadedUrl;

  /// The last error that occurred during playback, if any.
  final PlayerException? lastError;

  /// Creates a new [AudioPlayerState].
  const AudioPlayerState({
    required this.isPlaying,
    required this.processingState,
    this.currentDuration,
    this.loadedUrl,
    this.lastError,
  });

  /// Returns true if the player is currently loading audio.
  bool get isLoading => processingState == ProcessingState.loading;

  /// Returns true if the player is currently buffering audio.
  bool get isBuffering => processingState == ProcessingState.buffering;

  /// Returns true if the audio is ready to play.
  bool get isReady => processingState == ProcessingState.ready;

  /// Returns true if playback has completed.
  bool get isCompleted => processingState == ProcessingState.completed;

  /// Returns true if the player is idle (no audio loaded or after stop).
  bool get isIdle => processingState == ProcessingState.idle;

  /// Creates a copy of this state with the given fields replaced.
  AudioPlayerState copyWith({
    bool? isPlaying,
    ProcessingState? processingState,
    Duration? currentDuration,
    String? loadedUrl,
    PlayerException? lastError,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      currentDuration: currentDuration ?? this.currentDuration,
      loadedUrl: loadedUrl ?? this.loadedUrl,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioPlayerState &&
          runtimeType == other.runtimeType &&
          isPlaying == other.isPlaying &&
          processingState == other.processingState &&
          currentDuration == other.currentDuration &&
          loadedUrl == other.loadedUrl &&
          lastError == other.lastError;

  @override
  int get hashCode =>
      isPlaying.hashCode ^
      processingState.hashCode ^
      currentDuration.hashCode ^
      loadedUrl.hashCode ^
      lastError.hashCode;
}
