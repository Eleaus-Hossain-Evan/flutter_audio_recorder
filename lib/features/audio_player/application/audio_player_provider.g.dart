// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioPlayerRepositoryHash() =>
    r'e3ab1cd3182d9b86a2f6ab8068672f9d9483ae74';

/// Provides an auto-disposing instance of [IAudioPlayerRepo].
///
/// This repository is recreated when no longer watched (e.g., when dialog closes).
/// Resources are automatically cleaned up via onDispose.
///
/// Copied from [audioPlayerRepository].
@ProviderFor(audioPlayerRepository)
final audioPlayerRepositoryProvider =
    AutoDisposeProvider<IAudioPlayerRepo>.internal(
      audioPlayerRepository,
      name: r'audioPlayerRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioPlayerRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerRepositoryRef = AutoDisposeProviderRef<IAudioPlayerRepo>;
String _$audioPlayerPositionHash() =>
    r'6ed4dc2faa3511b1712da5e70c9884968f1b85ef';

/// Stream provider emitting the current playback position.
///
/// This stream updates frequently as the audio plays, making it ideal
/// for updating seekbars and position displays in real-time.
///
/// Use with `ref.watch(audioPlayerPositionProvider)` to get position updates.
///
/// Copied from [audioPlayerPosition].
@ProviderFor(audioPlayerPosition)
final audioPlayerPositionProvider =
    AutoDisposeStreamProvider<Duration>.internal(
      audioPlayerPosition,
      name: r'audioPlayerPositionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioPlayerPositionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerPositionRef = AutoDisposeStreamProviderRef<Duration>;
String _$audioPlayerDurationHash() =>
    r'191f7242e349f1ed61a5323db3fe02a901eb1ec6';

/// Stream provider emitting the total duration of the loaded audio.
///
/// Emits when audio is first loaded. May be null if metadata is unavailable.
///
/// Use with `ref.watch(audioPlayerDurationProvider)` to get duration updates.
///
/// Copied from [audioPlayerDuration].
@ProviderFor(audioPlayerDuration)
final audioPlayerDurationProvider =
    AutoDisposeStreamProvider<Duration?>.internal(
      audioPlayerDuration,
      name: r'audioPlayerDurationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioPlayerDurationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerDurationRef = AutoDisposeStreamProviderRef<Duration?>;
String _$audioPlayerPlayingHash() =>
    r'44d82ea84fe46dea0bd983fb89c58b70097517ae';

/// Stream provider emitting the current playing state.
///
/// Emits true when [play] is called, false when [pause] is called.
///
/// Use with `ref.watch(audioPlayerPlayingProvider)` to update UI button state.
///
/// Copied from [audioPlayerPlaying].
@ProviderFor(audioPlayerPlaying)
final audioPlayerPlayingProvider = AutoDisposeStreamProvider<bool>.internal(
  audioPlayerPlaying,
  name: r'audioPlayerPlayingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioPlayerPlayingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerPlayingRef = AutoDisposeStreamProviderRef<bool>;
String _$audioPlayerProcessingStateHash() =>
    r'1fd520ea7f5d1bef386fb7772410701c61029e2c';

/// Stream provider emitting the current processing state.
///
/// Indicates loading, buffering, ready, or completed states.
///
/// Use with `ref.watch(audioPlayerProcessingStateProvider)` to show loading spinners.
///
/// Copied from [audioPlayerProcessingState].
@ProviderFor(audioPlayerProcessingState)
final audioPlayerProcessingStateProvider =
    AutoDisposeStreamProvider<ProcessingState>.internal(
      audioPlayerProcessingState,
      name: r'audioPlayerProcessingStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioPlayerProcessingStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerProcessingStateRef =
    AutoDisposeStreamProviderRef<ProcessingState>;
String _$audioPlayerBufferedPositionHash() =>
    r'9f923a594936cfa4d2c8af7c588de482200023bb';

/// Stream provider emitting the buffered position.
///
/// Indicates how much of the audio has been buffered/downloaded.
///
/// Use with `ref.watch(audioPlayerBufferedPositionProvider)` for buffering displays.
///
/// Copied from [audioPlayerBufferedPosition].
@ProviderFor(audioPlayerBufferedPosition)
final audioPlayerBufferedPositionProvider =
    AutoDisposeStreamProvider<Duration>.internal(
      audioPlayerBufferedPosition,
      name: r'audioPlayerBufferedPositionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioPlayerBufferedPositionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerBufferedPositionRef = AutoDisposeStreamProviderRef<Duration>;
String _$audioPlayerSpeedHash() => r'e5719cd515fa1d46f07eed238b64b4e12e89438d';

/// Stream provider emitting the current playback speed.
///
/// Emits when [setSpeed] is called.
///
/// Use with `ref.watch(audioPlayerSpeedProvider)` to update speed display.
///
/// Copied from [audioPlayerSpeed].
@ProviderFor(audioPlayerSpeed)
final audioPlayerSpeedProvider = AutoDisposeStreamProvider<double>.internal(
  audioPlayerSpeed,
  name: r'audioPlayerSpeedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioPlayerSpeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerSpeedRef = AutoDisposeStreamProviderRef<double>;
String _$audioPlayerVolumeHash() => r'b4cb3f557f7f88777a421f71d76aaf632497bbda';

/// Stream provider emitting the current volume level.
///
/// Emits when [setVolume] is called.
///
/// Use with `ref.watch(audioPlayerVolumeProvider)` to update volume display.
///
/// Copied from [audioPlayerVolume].
@ProviderFor(audioPlayerVolume)
final audioPlayerVolumeProvider = AutoDisposeStreamProvider<double>.internal(
  audioPlayerVolume,
  name: r'audioPlayerVolumeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioPlayerVolumeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerVolumeRef = AutoDisposeStreamProviderRef<double>;
String _$audioPlayerHash() => r'e0f0ba31781dd4e6c8a11808eb57d395bb518cf1';

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
///
/// Copied from [AudioPlayer].
@ProviderFor(AudioPlayer)
final audioPlayerProvider =
    AutoDisposeAsyncNotifierProvider<AudioPlayer, AudioPlayerState>.internal(
      AudioPlayer.new,
      name: r'audioPlayerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioPlayerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AudioPlayer = AutoDisposeAsyncNotifier<AudioPlayerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
