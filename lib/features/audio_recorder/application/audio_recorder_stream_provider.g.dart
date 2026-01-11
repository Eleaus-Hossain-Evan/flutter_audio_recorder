// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_recorder_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recordingStateStreamHash() =>
    r'6905689ea3fdd1585fe254be33b35abf5f35d201';

/// Stream provider for recording state events.
///
/// Emits [RecorderStateEvent] on each state change during recording.
/// Auto-cancels on subscription disposal or when recording stops.
///
/// Usage:
/// ```dart
/// ref.watch(recordingStateStreamProvider).when(
///   data: (stateEvent) => Text('State: ${stateEvent.state}'),
///   error: (error, stack) => Text('Error'),
///   loading: () => CircularProgressIndicator(),
/// )
/// ```
///
/// Copied from [recordingStateStream].
@ProviderFor(recordingStateStream)
final recordingStateStreamProvider =
    AutoDisposeStreamProvider<RecorderStateEvent>.internal(
      recordingStateStream,
      name: r'recordingStateStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recordingStateStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecordingStateStreamRef =
    AutoDisposeStreamProviderRef<RecorderStateEvent>;
String _$amplitudeStreamHash() => r'398bfe854ce1ed2296fd42991307eb65003d526f';

/// Stream provider for real-time amplitude samples.
///
/// Emits [AmplitudeSample] at ~30-60 Hz during active recording.
/// Values are normalized to 0.0-1.0 by the native layer.
/// Auto-cancels on subscription disposal or when recording stops.
///
/// Usage:
/// ```dart
/// ref.watch(amplitudeStreamProvider).whenData((sample) {
///   print('Amplitude: ${sample.value}');
/// })
/// ```
///
/// Copied from [amplitudeStream].
@ProviderFor(amplitudeStream)
final amplitudeStreamProvider =
    AutoDisposeStreamProvider<AmplitudeSample>.internal(
      amplitudeStream,
      name: r'amplitudeStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$amplitudeStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AmplitudeStreamRef = AutoDisposeStreamProviderRef<AmplitudeSample>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
