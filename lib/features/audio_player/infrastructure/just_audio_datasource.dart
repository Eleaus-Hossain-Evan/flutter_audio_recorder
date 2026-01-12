import 'package:just_audio/just_audio.dart';

/// Internal wrapper around just_audio's [AudioPlayer].
///
/// This class manages the lifecycle of the [AudioPlayer] instance,
/// ensuring proper resource cleanup through [dispose].
class JustAudioDataSource {
  late final AudioPlayer _player;

  /// Creates a new [JustAudioDataSource] with a lazy-initialized [AudioPlayer].
  JustAudioDataSource() {
    _player = AudioPlayer();
  }

  /// Gets the underlying [AudioPlayer] instance.
  ///
  /// This instance is lazily created on first access.
  AudioPlayer get player => _player;

  /// Releases all resources held by the [AudioPlayer].
  ///
  /// Call this when the player is no longer needed, typically when
  /// the playback dialog is dismissed or the app is closing.
  /// After calling this, you should not use this datasource instance anymore.
  Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
  }
}
