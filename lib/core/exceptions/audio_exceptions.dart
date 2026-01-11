/// Exceptions for audio recording flows.
class AudioPermissionException implements Exception {
  const AudioPermissionException(this.message);
  final String message;

  @override
  String toString() => 'AudioPermissionException: $message';
}

class AudioRecordingException implements Exception {
  const AudioRecordingException(this.message);
  final String message;

  @override
  String toString() => 'AudioRecordingException: $message';
}

class AudioFileException implements Exception {
  const AudioFileException(this.message);
  final String message;

  @override
  String toString() => 'AudioFileException: $message';
}
