// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_recorder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioRecorderRepositoryHash() =>
    r'3ea1e8e3f2592d5758af594584428382c43d7893';

/// Provider for audio recorder repository.
///
/// Copied from [audioRecorderRepository].
@ProviderFor(audioRecorderRepository)
final audioRecorderRepositoryProvider =
    AutoDisposeProvider<AudioRecorderRepository>.internal(
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
typedef AudioRecorderRepositoryRef =
    AutoDisposeProviderRef<AudioRecorderRepository>;
String _$audioRecorderHash() => r'791a20ba6e80e7a5bab02b59e28419433743262b';

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
