# AGENT.md — Native Audio Recorder (Phase 1: Record & List)

## 1. Purpose
This agent guides the incremental development of a **Native Audio Recorder** in Flutter using **Method Channels only** (Event Channels deferred). The initial scope is intentionally minimal:

- Request microphone permission
- Start recording
- Stop recording
- Persist audio files to native storage
- Retrieve and display a list of recorded files

This phase establishes a clean, testable platform boundary that can later be extended with Event Channels (amplitude, FFT, state streaming).

---

## 2. Non‑Goals (Explicitly Out of Scope)

- Waveform visualization
- Real‑time amplitude or FFT streaming
- Pause / resume recording
- Audio playback
- Background recording
- Cloud sync or sharing

---

## 3. Architectural Principles

- **Clean Architecture**
  - Flutter layer must not import platform‑specific concepts
  - Platform channel logic isolated in data layer

- **Single Responsibility**
  - Method Channel handles commands and queries only

- **Deterministic State**
  - Recording state is derived from explicit method responses

- **Extensibility First**
  - Channel contract designed to support future Event Channels

---

## 4. Platform Channel Contract

### Channel Name
```
com.example.audio_recorder/methods
```

### Supported Methods (Phase 1)

| Method | Direction | Description | Return Type |
|------|----------|-------------|-------------|
| `requestPermission` | Flutter → Native | Request mic permission | `bool` |
| `startRecording` | Flutter → Native | Start audio recording | `void` |
| `stopRecording` | Flutter → Native | Stop recording | `Map<String, dynamic>` |
| `getRecordings` | Flutter → Native | List saved recordings | `List<Map>` |

### Recording Metadata Schema

```json
{
  "id": "string",
  "filePath": "string",
  "fileName": "string",
  "durationMs": 12345,
  "sizeBytes": 456789,
  "createdAt": "ISO-8601"
}
```

---

## 5. Native Responsibilities

### Android (Kotlin)

- Use `MediaRecorder`
- Save files to:
  - `context.getExternalFilesDir(Environment.DIRECTORY_MUSIC)`
- Generate unique file names
- Persist metadata in:
  - In‑memory list (Phase 1)
  - Optional: SharedPreferences (Phase 1.5)

### iOS (Swift)

- Use `AVAudioRecorder`
- Save files to:
  - App Documents directory
- Maintain metadata array in memory

---

## 6. Flutter Module Structure

```
lib/
  features/
    audio_recorder/
      data/
        repositories/
          audio_recorder_repository_impl.dart
        datasources/
          audio_recorder_method_channel.dart
      domain/
        entities/
          recording_entity.dart
        repositories/
          audio_recorder_repository.dart
        usecases/
          start_recording.dart
          stop_recording.dart
          get_recordings.dart
      presentation/
        providers/
          audio_recorder_provider.dart
        pages/
          recorder_page.dart
```

---

## 7. Repository Contract (Flutter)

```dart
abstract class AudioRecorderRepository {
  Future<bool> requestPermission();
  Future<void> startRecording();
  Future<RecordingEntity> stopRecording();
  Future<List<RecordingEntity>> getRecordings();
}
```

---

## 8. State Model

```dart
enum RecorderStatus {
  idle,
  recording,
  stopped,
  error,
}
```

State must be **derived**, not inferred:
- `recording` → after successful `startRecording`
- `stopped` → after successful `stopRecording`

---

## 9. Riverpod Strategy

- Use `AsyncNotifier`
- Expose:
  - Current `RecorderStatus`
  - List of `RecordingEntity`

Avoid side effects in UI widgets.

---

## 10. Error Handling Rules

- Native errors must map to `PlatformException`
- Flutter converts platform errors to domain‑level failures
- No silent failures

---

## 11. Acceptance Criteria (Phase 1)

- User can grant microphone permission
- User can start recording
- User can stop recording
- Recording is saved natively
- Recording appears in list after stopping
- App survives hot restart without crash

---

## 12. Phase 2 Preview (Not Implemented)

- Event Channel: `recordingState`
- Event Channel: `amplitudeStream`
- Event Channel: `fftStream`
- Background recording support

---

## 13. Development Discipline

- No direct UI → MethodChannel calls
- No platform imports in domain layer
- Channel method names are immutable once published

---

## 14. Definition of Done

Phase 1 is complete when:
- Platform channel contract is stable
- Repository fully abstracts native APIs
- UI lists recordings accurately
- Code is ready for Event Channel expansion

