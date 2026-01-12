// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waveform_processor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$waveformProcessorHash() => r'0d9e7d2037a6cbfb4aa92d1594da6814b4e59042';

/// Provides a singleton instance of [IWaveformProcessor].
///
/// This processor is used to aggregate amplitude samples captured during
/// recording into a fixed-size waveform array for visualization.
///
/// Copied from [waveformProcessor].
@ProviderFor(waveformProcessor)
final waveformProcessorProvider = Provider<IWaveformProcessor>.internal(
  waveformProcessor,
  name: r'waveformProcessorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$waveformProcessorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WaveformProcessorRef = ProviderRef<IWaveformProcessor>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
