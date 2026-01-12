import 'package:just_audio/just_audio.dart';

/// Interface defining streaming operations for audio playback.
///
/// Exposes real-time streams of playback state that are ideal for
/// Riverpod StreamProvider integration and UI updates.
abstract interface class IAudioPlayerStreamRepo {
  /// Stream of the current playback position.
  ///
  /// Emits frequently (multiple times per second) as the audio plays.
  Stream<Duration> get positionStream;

  /// Stream of the total duration of the loaded audio.
  ///
  /// Emits when audio is first loaded and if duration changes.
  /// May be null if audio metadata is not available.
  Stream<Duration?> get durationStream;

  /// Stream of the current processing state.
  ///
  /// Emits when the player transitions between idle, loading, buffering,
  /// ready, and completed states.
  Stream<ProcessingState> get processingStateStream;

  /// Stream of the playing state.
  ///
  /// Emits true when play() is called and false when pause() is called.
  /// Does not reflect the processing state, only user intent.
  Stream<bool> get playingStream;

  /// Stream of the current buffered position.
  ///
  /// Indicates how much of the audio has been buffered/downloaded.
  Stream<Duration> get bufferedPositionStream;

  /// Stream of the current playback speed.
  ///
  /// Emits when the speed is changed via [setSpeed].
  Stream<double> get speedStream;

  /// Stream of the current volume level.
  ///
  /// Emits when the volume is changed via [setVolume].
  Stream<double> get volumeStream;
}
