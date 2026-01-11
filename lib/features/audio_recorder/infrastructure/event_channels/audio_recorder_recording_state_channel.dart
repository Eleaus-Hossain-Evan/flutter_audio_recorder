import 'package:flutter/services.dart';

import '../../domain/models/recorder_state_event.dart';

/// Recording state EventChannel datasource.
///
/// Handles low-level communication with the native recording state EventChannel.
/// Emits [RecorderStateEvent] on each state transition.
/// No business logic—native side owns emission timing and content.
class AudioRecorderRecordingStateChannel {
  static const _channel = EventChannel(
    'com.example.audio_recorder/events/recording_state',
  );

  /// Returns a stream of recording state events from the native layer.
  ///
  /// The stream is active only while the recording is in progress.
  /// Native side is responsible for lifecycle management (start on `startRecording`,
  /// stop on `stopRecording` or error).
  Stream<RecorderStateEvent> get stateStream {
    return _channel
        .receiveBroadcastStream()
        .map((dynamic event) {
          if (event is! Map<dynamic, dynamic>) {
            throw FormatException(
              'Invalid recording state event format: $event',
            );
          }
          return RecorderStateEvent.fromMap(event);
        })
        .handleError((Object error) {
          // Propagate platform errors without transformation.
          throw PlatformException(
            code: 'STATE_STREAM_ERROR',
            message: 'Recording state stream error: $error',
          );
        });
  }
}
