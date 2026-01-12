import 'dart:math' as math;

import '../domain/i_waveform_processor.dart';
import '../domain/models/amplitude_sample.dart';

/// Implementation of waveform processor using max-pooling aggregation.
///
/// This processor divides samples into buckets and takes the maximum amplitude
/// from each bucket, providing prominent peak visibility ideal for music and speech.
class WaveformProcessor implements IWaveformProcessor {
  @override
  List<double> aggregateSamples(List<AmplitudeSample> samples, int targetBars) {
    if (samples.isEmpty || targetBars <= 0) {
      return [];
    }

    // If we have fewer samples than target bars, use simple interpolation
    if (samples.length <= targetBars) {
      return _interpolateSamples(samples, targetBars);
    }

    // Otherwise, use max-pooling aggregation
    return _maxPooling(samples, targetBars);
  }

  /// Max-pooling: divide samples into buckets and take the maximum from each.
  List<double> _maxPooling(List<AmplitudeSample> samples, int targetBars) {
    final result = <double>[];
    final bucketSize = samples.length / targetBars;

    for (int i = 0; i < targetBars; i++) {
      final startIndex = (i * bucketSize).floor();
      final endIndex = math.min(((i + 1) * bucketSize).floor(), samples.length);

      double maxAmplitude = 0.0;
      for (int j = startIndex; j < endIndex; j++) {
        maxAmplitude = math.max(maxAmplitude, samples[j].value);
      }

      result.add(maxAmplitude);
    }

    return result;
  }

  /// Interpolates samples when we have fewer than target bars.
  List<double> _interpolateSamples(
    List<AmplitudeSample> samples,
    int targetBars,
  ) {
    if (samples.length == 1) {
      // Edge case: single sample, repeat it
      return List.filled(targetBars, samples[0].value);
    }

    final result = <double>[];
    final step = (samples.length - 1) / (targetBars - 1);

    for (int i = 0; i < targetBars; i++) {
      final exactIndex = i * step;
      final lowerIndex = exactIndex.floor();
      final upperIndex = math.min(lowerIndex + 1, samples.length - 1);
      final fraction = exactIndex - lowerIndex;

      // Linear interpolation between two closest samples
      final lower = samples[lowerIndex].value;
      final upper = samples[upperIndex].value;
      final interpolated = lower + (upper - lower) * fraction;

      result.add(interpolated);
    }

    return result;
  }
}
