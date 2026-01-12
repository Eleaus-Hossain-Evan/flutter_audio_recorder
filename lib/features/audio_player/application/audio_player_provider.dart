import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/i_audio_player_repo.dart';
import '../domain/i_audio_player_stream_repo.dart';
import '../domain/models/audio_player_exception.dart';
import '../domain/models/audio_player_state.dart';
import '../infrastructure/audio_player_repo.dart';
import '../infrastructure/just_audio_datasource.dart';

part 'audio_player_provider.g.dart';

/// Provides an auto-disposing instance of [IAudioPlayerRepo].
///
/// This repository is recreated when no longer watched (e.g., when dialog closes).
/// Resources are automatically cleaned up via onDispose.
@Riverpod(keepAlive: false)
IAudioPlayerRepo audioPlayerRepository(Ref ref) {
  final dataSource = JustAudioDataSource();

  // Clean up resources when this provider is disposed
  ref.onDispose(() async {
    await dataSource.dispose();
  });

  return AudioPlayerRepo(dataSource);
}

/// Main async notifier managing the audio player lifecycle and state.
///
/// This notifier handles:
/// - Loading audio files
/// - Playing and pausing playback
/// - Seeking to positions
/// - Setting volume and speed
/// - Managing errors
///
/// The state includes simplified playback information for the UI.
/// For real-time updates (position, duration), watch separate StreamProviders.
@Riverpod(keepAlive: false)
class AudioPlayer extends _$AudioPlayer {
  @override
  FutureOr<AudioPlayerState> build() {
    // Initialize with idle state
    return const AudioPlayerState(
      isPlaying: false,
      processingState: ProcessingState.idle,
    );
  }

  /// Loads an audio file from the given URL.
  ///
  /// The URL should be in the format "file:///absolute/path/to/audio.m4a"
  /// or a network URL.
  ///
  /// This method updates the state to include the loaded URL and duration.
  /// If loading fails, the state will contain an error.
  Future<void> loadUrl(String url) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(audioPlayerRepositoryProvider);
      final duration = await repo.setUrl(url);

      return AudioPlayerState(
        isPlaying: false,
        processingState: ProcessingState.idle,
        currentDuration: duration,
        loadedUrl: url,
      );
    });
  }

  /// Starts playback of the currently loaded audio.
  ///
  /// If no audio is loaded, this will throw an error in the state.
  Future<void> play() async {
    try {
      final repo = ref.read(audioPlayerRepositoryProvider);
      await repo.play();

      state = state.whenData((current) => current.copyWith(isPlaying: true));
    } catch (e) {
      state = AsyncError(
        AudioPlayerException('Failed to play: $e'),
        StackTrace.current,
      );
    }
  }

  /// Pauses the currently playing audio.
  ///
  /// Does nothing if playback is already paused.
  Future<void> pause() async {
    try {
      final repo = ref.read(audioPlayerRepositoryProvider);
      await repo.pause();

      state = state.whenData((current) => current.copyWith(isPlaying: false));
    } catch (e) {
      state = AsyncError(
        AudioPlayerException('Failed to pause: $e'),
        StackTrace.current,
      );
    }
  }

  /// Stops playback and resets the player to an idle state.
  ///
  /// After calling this, you should call [loadUrl] again before playing.
  Future<void> stop() async {
    try {
      final repo = ref.read(audioPlayerRepositoryProvider);
      await repo.stop();

      state = state.whenData(
        (current) => current.copyWith(
          isPlaying: false,
          processingState: ProcessingState.idle,
        ),
      );
    } catch (e) {
      state = AsyncError(
        AudioPlayerException('Failed to stop: $e'),
        StackTrace.current,
      );
    }
  }

  /// Seeks to the given position in the currently playing audio.
  ///
  /// The position should not exceed the total duration.
  Future<void> seek(Duration position) async {
    try {
      final repo = ref.read(audioPlayerRepositoryProvider);
      await repo.seek(position);
    } catch (e) {
      state = AsyncError(
        AudioPlayerException('Failed to seek: $e'),
        StackTrace.current,
      );
    }
  }

  /// Sets the playback volume.
  ///
  /// [volume] should be between 0.0 (silent) and 1.0 (full volume).
  Future<void> setVolume(double volume) async {
    try {
      final repo = ref.read(audioPlayerRepositoryProvider);
      await repo.setVolume(volume);
    } catch (e) {
      state = AsyncError(
        AudioPlayerException('Failed to set volume: $e'),
        StackTrace.current,
      );
    }
  }

  /// Sets the playback speed multiplier.
  ///
  /// Common values: 0.5, 0.75, 1.0, 1.25, 1.5, 2.0
  /// The player may not support all values.
  Future<void> setSpeed(double speed) async {
    try {
      final repo = ref.read(audioPlayerRepositoryProvider);
      await repo.setSpeed(speed);
    } catch (e) {
      state = AsyncError(
        AudioPlayerException('Failed to set speed: $e'),
        StackTrace.current,
      );
    }
  }
}

/// Stream provider emitting the current playback position.
///
/// This stream updates frequently as the audio plays, making it ideal
/// for updating seekbars and position displays in real-time.
///
/// Use with `ref.watch(audioPlayerPositionProvider)` to get position updates.
@Riverpod(keepAlive: false)
Stream<Duration> audioPlayerPosition(Ref ref) {
  final repo = ref.watch(audioPlayerRepositoryProvider);
  return (repo as IAudioPlayerStreamRepo).positionStream;
}

/// Stream provider emitting the total duration of the loaded audio.
///
/// Emits when audio is first loaded. May be null if metadata is unavailable.
///
/// Use with `ref.watch(audioPlayerDurationProvider)` to get duration updates.
@Riverpod(keepAlive: false)
Stream<Duration?> audioPlayerDuration(Ref ref) {
  final repo = ref.watch(audioPlayerRepositoryProvider);
  return (repo as IAudioPlayerStreamRepo).durationStream;
}

/// Stream provider emitting the current playing state.
///
/// Emits true when [play] is called, false when [pause] is called.
///
/// Use with `ref.watch(audioPlayerPlayingProvider)` to update UI button state.
@Riverpod(keepAlive: false)
Stream<bool> audioPlayerPlaying(Ref ref) {
  final repo = ref.watch(audioPlayerRepositoryProvider);
  return (repo as IAudioPlayerStreamRepo).playingStream;
}

/// Stream provider emitting the current processing state.
///
/// Indicates loading, buffering, ready, or completed states.
///
/// Use with `ref.watch(audioPlayerProcessingStateProvider)` to show loading spinners.
@Riverpod(keepAlive: false)
Stream<ProcessingState> audioPlayerProcessingState(Ref ref) {
  final repo = ref.watch(audioPlayerRepositoryProvider);
  return (repo as IAudioPlayerStreamRepo).processingStateStream;
}

/// Stream provider emitting the buffered position.
///
/// Indicates how much of the audio has been buffered/downloaded.
///
/// Use with `ref.watch(audioPlayerBufferedPositionProvider)` for buffering displays.
@Riverpod(keepAlive: false)
Stream<Duration> audioPlayerBufferedPosition(Ref ref) {
  final repo = ref.watch(audioPlayerRepositoryProvider);
  return (repo as IAudioPlayerStreamRepo).bufferedPositionStream;
}

/// Stream provider emitting the current playback speed.
///
/// Emits when [setSpeed] is called.
///
/// Use with `ref.watch(audioPlayerSpeedProvider)` to update speed display.
@Riverpod(keepAlive: false)
Stream<double> audioPlayerSpeed(Ref ref) {
  final repo = ref.watch(audioPlayerRepositoryProvider);
  return (repo as IAudioPlayerStreamRepo).speedStream;
}

/// Stream provider emitting the current volume level.
///
/// Emits when [setVolume] is called.
///
/// Use with `ref.watch(audioPlayerVolumeProvider)` to update volume display.
@Riverpod(keepAlive: false)
Stream<double> audioPlayerVolume(Ref ref) {
  final repo = ref.watch(audioPlayerRepositoryProvider);
  return (repo as IAudioPlayerStreamRepo).volumeStream;
}
