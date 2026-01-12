import 'package:just_audio/just_audio.dart';

/// Interface defining synchronous command operations for audio playback.
///
/// This interface abstracts the just_audio AudioPlayer and provides
/// a clean contract for playback control methods.
abstract interface class IAudioPlayerRepo {
  /// Loads audio from the given file URL.
  ///
  /// Returns the duration of the audio, or null if loading fails.
  /// The URL should be in the format "file:///path/to/audio.m4a".
  Future<Duration?> setUrl(String url);

  /// Starts playback of the currently loaded audio.
  ///
  /// If no audio is loaded, this will throw an [AudioPlayerException].
  Future<void> play();

  /// Pauses playback of the currently playing audio.
  ///
  /// Does nothing if playback is already paused.
  Future<void> pause();

  /// Stops playback and releases resources.
  ///
  /// After calling this, you should call [setUrl] again before playing.
  Future<void> stop();

  /// Seeks to the given position in the currently playing audio.
  ///
  /// If the position is beyond the duration, it will seek to the end.
  Future<void> seek(Duration position);

  /// Sets the playback volume.
  ///
  /// The volume should be between 0.0 (silent) and 1.0 (full volume).
  Future<void> setVolume(double volume);

  /// Sets the playback speed multiplier.
  ///
  /// Common values are 0.5, 0.75, 1.0, 1.25, 1.5, and 2.0.
  /// The player may not support all values.
  Future<void> setSpeed(double speed);

  /// Gets the current total duration of the loaded audio.
  Duration? getCurrentDuration();

  /// Returns true if audio is currently playing.
  bool isPlaying();

  /// Gets the current processing state of the player.
  ProcessingState getProcessingState();
}
