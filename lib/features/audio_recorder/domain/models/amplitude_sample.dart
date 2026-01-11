/// Real-time amplitude sample emitted during recording.
///
/// Represents normalized audio level (0.0 to 1.0) at a specific time.
/// Emitted via the `amplitude` EventChannel at ~30-60 Hz during active recording.
class AmplitudeSample {
  /// Normalized amplitude value (0.0 = silence, 1.0 = maximum).
  /// Platform-agnostic: native layer handles iOS dB → 0.0-1.0 and Android amplitude → 0.0-1.0 normalization.
  final double value;

  /// Timestamp when the sample was captured (native time, ISO 8601).
  final String timestamp;

  const AmplitudeSample({required this.value, required this.timestamp});

  /// Creates an [AmplitudeSample] from a map (EventChannel payload).
  /// The EventChannel may emit either a map or a raw double; handle both.
  factory AmplitudeSample.fromMap(dynamic data) {
    if (data is double) {
      // Raw double value; use current timestamp.
      return AmplitudeSample(
        value: data.clamp(0.0, 1.0),
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    if (data is Map<dynamic, dynamic>) {
      return AmplitudeSample(
        value: (data['value'] as num).toDouble().clamp(0.0, 1.0),
        timestamp:
            data['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      );
    }

    throw FormatException('Invalid amplitude sample format: $data');
  }

  /// Converts this sample to a map.
  Map<String, dynamic> toMap() {
    return {'value': value, 'timestamp': timestamp};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AmplitudeSample &&
        other.value == value &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => value.hashCode ^ timestamp.hashCode;

  @override
  String toString() =>
      'AmplitudeSample(value: ${value.toStringAsFixed(3)}, timestamp: $timestamp)';
}
