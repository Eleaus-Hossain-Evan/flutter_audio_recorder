/// Exception thrown when audio player operations fail.
class AudioPlayerException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Creates a new [AudioPlayerException] with the given [message].
  AudioPlayerException(this.message);

  @override
  String toString() => 'AudioPlayerException: $message';
}
