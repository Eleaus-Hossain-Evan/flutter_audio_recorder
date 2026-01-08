import 'package:flutter/services.dart';

import '../../domain/entities/recording_entity.dart';

/// Method channel datasource for audio recording.
///
/// Wraps platform channel calls and converts raw responses to typed data.
class AudioRecorderMethodChannel {
  static const _channel = MethodChannel('com.example.audio_recorder/methods');

  /// Requests microphone permission.
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to request permission: ${e.message}');
    }
  }

  /// Starts audio recording.
  Future<void> startRecording() async {
    try {
      await _channel.invokeMethod<void>('startRecording');
    } on PlatformException catch (e) {
      throw Exception('Failed to start recording: ${e.message}');
    }
  }

  /// Stops audio recording and returns metadata.
  Future<RecordingEntity> stopRecording() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'stopRecording',
      );
      if (result == null) {
        throw Exception('stopRecording returned null');
      }

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final map = Map<String, dynamic>.from(result);
      return RecordingEntity.fromMap(map);
    } on PlatformException catch (e) {
      throw Exception('Failed to stop recording: ${e.message}');
    }
  }

  /// Retrieves all saved recordings.
  Future<List<RecordingEntity>> getRecordings() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'getRecordings',
      );
      if (result == null) {
        return [];
      }

      return result
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) => RecordingEntity.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get recordings: ${e.message}');
    }
  }
}
