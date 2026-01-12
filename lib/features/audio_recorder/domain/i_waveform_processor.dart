import 'models/amplitude_sample.dart';

/// Interface for processing and aggregating amplitude samples into waveform data.
///
/// This abstraction allows different aggregation strategies (max-pooling, RMS averaging)
/// to be implemented and tested independently.
abstract interface class IWaveformProcessor {
  /// Aggregates a list of amplitude samples into a fixed-size waveform array.
  ///
  /// [samples] - Raw amplitude samples captured during recording (normalized 0.0-1.0)
  /// [targetBars] - Number of bars to generate (typically 60-120)
  ///
  /// Returns a list of normalized amplitude values (0.0-1.0), one per bar.
  /// Uses max-pooling: takes the highest amplitude in each bucket.
  ///
  /// If [samples] is empty, returns an empty list.
  /// If [samples] has fewer elements than [targetBars], applies interpolation.
  List<double> aggregateSamples(List<AmplitudeSample> samples, int targetBars);
}
