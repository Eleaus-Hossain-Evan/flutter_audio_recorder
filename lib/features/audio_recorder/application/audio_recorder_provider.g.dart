// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_recorder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioRecorderRepositoryHash() =>
    r'ec197c1bf9dbf03f7001e39f35057f23ef789ea5';

/// Provider for audio recorder repository.
///
/// Copied from [audioRecorderRepository].
@ProviderFor(audioRecorderRepository)
final audioRecorderRepositoryProvider =
    AutoDisposeProvider<IAudioRecorderRepo>.internal(
      audioRecorderRepository,
      name: r'audioRecorderRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioRecorderRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioRecorderRepositoryRef = AutoDisposeProviderRef<IAudioRecorderRepo>;
String _$audioRecorderHash() => r'3a256af409bb83f7911bfbd700c00d9235b9ef18';

/// Audio recorder notifier that manages recording state.
///
/// Copied from [AudioRecorder].
@ProviderFor(AudioRecorder)
final audioRecorderProvider =
    AutoDisposeNotifierProvider<AudioRecorder, AudioRecorderState>.internal(
      AudioRecorder.new,
      name: r'audioRecorderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioRecorderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AudioRecorder = AutoDisposeNotifier<AudioRecorderState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
