import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/i_waveform_processor.dart';
import '../infrastructure/waveform_processor.dart';

part 'waveform_processor_provider.g.dart';

/// Provides a singleton instance of [IWaveformProcessor].
///
/// This processor is used to aggregate amplitude samples captured during
/// recording into a fixed-size waveform array for visualization.
@Riverpod(keepAlive: true)
IWaveformProcessor waveformProcessor(Ref ref) {
  return WaveformProcessor();
}
