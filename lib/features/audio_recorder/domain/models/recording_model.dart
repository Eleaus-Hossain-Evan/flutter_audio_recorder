/// Recording metadata model.
///
/// Represents a single audio recording with its metadata.
/// Generated using Dart Data Class Generator.
class RecordingModel {
  /// Unique identifier for the recording.
  final String id;

  /// Absolute file path on the device.
  final String filePath;

  /// File name (e.g., record_123.m4a).
  final String fileName;

  /// Duration of the recording in milliseconds.
  final int durationMs;

  /// File size in bytes.
  final int sizeBytes;

  /// Creation timestamp.
  final DateTime createdAt;

  const RecordingModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.durationMs,
    required this.sizeBytes,
    required this.createdAt,
  });

  /// Creates a [RecordingModel] from a map (platform channel response).
  factory RecordingModel.fromMap(Map<String, dynamic> map) {
    return RecordingModel(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      durationMs: map['durationMs'] as int,
      sizeBytes: map['sizeBytes'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converts this entity to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'durationMs': durationMs,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy with optional field replacements.
  RecordingModel copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? durationMs,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecordingModel &&
        other.id == id &&
        other.filePath == filePath &&
        other.fileName == fileName &&
        other.durationMs == durationMs &&
        other.sizeBytes == sizeBytes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      filePath,
      fileName,
      durationMs,
      sizeBytes,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'RecordingEntity(id: $id, filePath: $filePath, fileName: $fileName, durationMs: $durationMs, sizeBytes: $sizeBytes, createdAt: $createdAt)';
  }
}
