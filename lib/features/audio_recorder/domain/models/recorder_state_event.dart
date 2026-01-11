/// Recording state event emitted by the native layer.
///
/// Represents a state change in the audio recorder with optional context.
/// Emitted via the `recording_state` EventChannel.
class RecorderStateEvent {
  /// Current state of the recorder.
  final String state;

  /// ISO 8601 timestamp when the state change occurred (native time).
  final String timestamp;

  /// Optional reason for the state change (e.g., error message).
  final String? reason;

  const RecorderStateEvent({
    required this.state,
    required this.timestamp,
    this.reason,
  });

  /// Creates a [RecorderStateEvent] from a map (EventChannel payload).
  factory RecorderStateEvent.fromMap(Map<dynamic, dynamic> map) {
    return RecorderStateEvent(
      state: map['state'] as String,
      timestamp: map['timestamp'] as String,
      reason: map['reason'] as String?,
    );
  }

  /// Converts this event to a map.
  Map<String, dynamic> toMap() {
    return {'state': state, 'timestamp': timestamp, 'reason': reason};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecorderStateEvent &&
        other.state == state &&
        other.timestamp == timestamp &&
        other.reason == reason;
  }

  @override
  int get hashCode => state.hashCode ^ timestamp.hashCode ^ reason.hashCode;

  @override
  String toString() =>
      'RecorderStateEvent(state: $state, timestamp: $timestamp, reason: $reason)';
}
