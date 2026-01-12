/// Waveform visualization constants.
///
/// Centralizes configuration for waveform processing and rendering.
class WaveformConstants {
  WaveformConstants._();

  /// Number of bars to display in waveform visualization.
  ///
  /// This determines:
  /// - How many amplitude buckets are created during recording aggregation
  /// - How many bars are rendered in the precomputed waveform widget
  /// - Storage size: ~4 bytes per bar (double precision)
  ///
  /// 80 bars = ~320 bytes per recording, optimal balance between
  /// visual detail and storage overhead.
  static const int kWaveformBars = 80;
}
