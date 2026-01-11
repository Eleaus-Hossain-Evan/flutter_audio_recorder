import 'package:flutter/services.dart';

import '../../domain/models/amplitude_sample.dart';

/// Amplitude EventChannel datasource.
///
/// Handles low-level communication with the native amplitude EventChannel.
/// Emits [AmplitudeSample] at ~30-60 Hz during active recording.
/// No business logic—native side owns emission timing and normalization.
class AudioRecorderAmplitudeChannel {
  static const _channel = EventChannel(
    'com.example.audio_recorder/events/amplitude',
  );

  /// Returns a stream of amplitude samples from the native layer.
  ///
  /// Emits normalized amplitude values (0.0-1.0) during active recording.
  /// The stream is active only while the recording is in progress.
  /// Target frequency: 30-60 Hz (adjustable on native side based on performance).
  ///
  /// Backpressure handling:
  /// - Native side reduces emission if Flutter cannot keep up
  /// - No buffering on Flutter side; samples are dropped if unprocessed
  Stream<AmplitudeSample> get amplitudeStream {
    return _channel
        .receiveBroadcastStream()
        .map((dynamic event) {
          try {
            return AmplitudeSample.fromMap(event);
          } on FormatException catch (e) {
            throw PlatformException(
              code: 'AMPLITUDE_FORMAT_ERROR',
              message: 'Invalid amplitude sample format: ${e.message}',
            );
          }
        })
        .handleError((Object error) {
          // Propagate platform errors without transformation.
          throw PlatformException(
            code: 'AMPLITUDE_STREAM_ERROR',
            message: 'Amplitude stream error: $error',
          );
        });
  }
}
