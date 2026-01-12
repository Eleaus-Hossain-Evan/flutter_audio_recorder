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

  /// Pre-computed waveform visualization data.
  ///
  /// Contains normalized amplitude values (0.0-1.0) for each bar.
  /// Null for legacy recordings created before waveform capture was implemented.
  final List<double>? waveformData;

  const RecordingModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.durationMs,
    required this.sizeBytes,
    required this.createdAt,
    this.waveformData,
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
      waveformData: (map['waveformData'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
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
      'waveformData': waveformData,
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
    List<double>? waveformData,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      waveformData: waveformData ?? this.waveformData,
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
        other.createdAt == createdAt &&
        _listEquals(other.waveformData, waveformData);
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
      Object.hashAll(waveformData ?? []),
    );
  }

  @override
  String toString() {
    return 'RecordingEntity(id: $id, filePath: $filePath, fileName: $fileName, durationMs: $durationMs, sizeBytes: $sizeBytes, createdAt: $createdAt, waveformData: ${waveformData?.length ?? 0} bars)';
  }

  /// Helper to compare nullable lists.
  static bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
