import 'package:just_audio/just_audio.dart';

import '../domain/i_audio_player_repo.dart';
import '../domain/i_audio_player_stream_repo.dart';
import '../domain/models/audio_player_exception.dart';
import 'just_audio_datasource.dart';

/// Implementation of [IAudioPlayerRepo] and [IAudioPlayerStreamRepo] using just_audio.
///
/// This repository wraps the underlying [AudioPlayer] from just_audio
/// and provides both command-based control and stream-based state observation.
class AudioPlayerRepo implements IAudioPlayerRepo, IAudioPlayerStreamRepo {
  final JustAudioDataSource _dataSource;

  /// Creates a new [AudioPlayerRepo] with the given [JustAudioDataSource].
  AudioPlayerRepo(this._dataSource);

  @override
  Future<Duration?> setUrl(String url) async {
    try {
      return await _dataSource.player.setUrl(url);
    } on PlayerException catch (e) {
      throw AudioPlayerException('Failed to load audio: ${e.message}');
    } catch (e) {
      throw AudioPlayerException('Unexpected error while loading audio: $e');
    }
  }

  @override
  Future<void> play() async {
    try {
      await _dataSource.player.play();
    } on PlayerException catch (e) {
      throw AudioPlayerException('Failed to play: ${e.message}');
    } catch (e) {
      throw AudioPlayerException('Unexpected error while playing: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _dataSource.player.pause();
    } on PlayerException catch (e) {
      throw AudioPlayerException('Failed to pause: ${e.message}');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _dataSource.player.stop();
    } on PlayerException catch (e) {
      throw AudioPlayerException('Failed to stop: ${e.message}');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _dataSource.player.seek(position);
    } on PlayerException catch (e) {
      throw AudioPlayerException('Failed to seek: ${e.message}');
    } catch (e) {
      throw AudioPlayerException('Unexpected error while seeking: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _dataSource.player.setVolume(volume);
    } catch (e) {
      throw AudioPlayerException('Failed to set volume: $e');
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _dataSource.player.setSpeed(speed);
    } on PlayerException catch (e) {
      throw AudioPlayerException('Failed to set speed: ${e.message}');
    } catch (e) {
      throw AudioPlayerException('Unexpected error while setting speed: $e');
    }
  }

  @override
  Duration? getCurrentDuration() => _dataSource.player.duration;

  @override
  bool isPlaying() => _dataSource.player.playing;

  @override
  ProcessingState getProcessingState() => _dataSource.player.processingState;

  // ===================== Streaming Interface =====================

  @override
  Stream<Duration> get positionStream => _dataSource.player.positionStream;

  @override
  Stream<Duration?> get durationStream => _dataSource.player.durationStream;

  @override
  Stream<ProcessingState> get processingStateStream =>
      _dataSource.player.processingStateStream;

  @override
  Stream<bool> get playingStream => _dataSource.player.playingStream;

  @override
  Stream<Duration> get bufferedPositionStream =>
      _dataSource.player.bufferedPositionStream;

  @override
  Stream<double> get speedStream => _dataSource.player.speedStream;

  @override
  Stream<double> get volumeStream => _dataSource.player.volumeStream;
}
