import 'package:flutter/services.dart';

import '../../../core/exceptions/audio_exceptions.dart';
import '../domain/i_audio_recorder_datasource.dart';
import '../domain/models/recording_model.dart';

/// Method channel datasource for audio recording.
///
/// Wraps platform channel calls and converts raw responses to typed data.
class AudioRecorderMethodChannel implements IAudioRecorderDataSource {
  static const _channel = MethodChannel('com.example.audio_recorder/methods');

  /// Requests microphone permission.
  @override
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      throw AudioPermissionException(
        'Failed to request permission: ${e.message}',
      );
    }
  }

  /// Starts audio recording.
  @override
  Future<void> startRecording() async {
    try {
      await _channel.invokeMethod<void>('startRecording');
    } on PlatformException catch (e) {
      throw AudioRecordingException('Failed to start recording: ${e.message}');
    }
  }

  /// Stops audio recording and returns metadata.
  @override
  Future<RecordingModel> stopRecording() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'stopRecording',
      );
      if (result == null) {
        throw const AudioRecordingException('stopRecording returned null');
      }

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final map = Map<String, dynamic>.from(result);
      return RecordingModel.fromMap(map);
    } on PlatformException catch (e) {
      throw AudioRecordingException('Failed to stop recording: ${e.message}');
    }
  }

  /// Retrieves all saved recordings.
  @override
  Future<List<RecordingModel>> getRecordings() async {
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
            (item) => RecordingModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PlatformException catch (e) {
      throw AudioFileException('Failed to get recordings: ${e.message}');
    }
  }
}
