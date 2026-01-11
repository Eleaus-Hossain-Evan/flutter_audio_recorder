# Audio Recorder Enhancement Plan: Configurable Recording Formats

## Current State
- **Recording Format**: Hardcoded to M4A (MPEG-4 container with AAC codec)
- **File Listing**: Now supports multiple extensions (m4a, 3gp, amr, ogg, webm, mp4, aac)
- **Limitation**: Users cannot choose recording format; all recordings use M4A

## Enhancement: Configurable Audio Recording Formats

### Overview
Allow users to select different audio formats when recording, with each format optimized for different use cases (quality, file size, compatibility).

---

## Phase 1: Domain Layer Updates

### 1.1 Create Audio Format Enum
**File**: `lib/features/audio_recorder/domain/models/audio_format.dart`

```dart
/// Supported audio recording formats
enum AudioFormat {
  /// M4A/AAC - High quality, widely supported (default)
  /// Best for: Music, general purpose
  m4a('m4a', 'M4A (AAC)', 'High quality, widely compatible'),
  
  /// 3GP/AMR-NB - Low bitrate, optimized for voice
  /// Best for: Voice notes, minimal file size
  threeGp('3gp', '3GP (AMR)', 'Voice optimized, smallest size'),
  
  /// OGG/Opus - Modern, efficient codec (Android 10+)
  /// Best for: High quality with good compression
  ogg('ogg', 'OGG (Opus)', 'Modern, efficient'),
  
  /// WebM/Opus - Web-friendly format (Android 10+)
  /// Best for: Web playback, streaming
  webm('webm', 'WebM (Opus)', 'Web-friendly');

  const AudioFormat(this.extension, this.displayName, this.description);
  
  final String extension;
  final String displayName;
  final String description;
}
```

### 1.2 Update Repository Interface
**File**: `lib/features/audio_recorder/domain/i_audio_recorder_repo.dart`

Add optional format parameter:
```dart
Future<void> startRecording({AudioFormat format = AudioFormat.m4a});
```

### 1.3 Update DataSource Interface
**File**: `lib/features/audio_recorder/domain/i_audio_recorder_datasource.dart`

Add format parameter to platform calls:
```dart
Future<void> startRecording({required String formatExtension});
```

---

## Phase 2: Infrastructure Layer Updates

### 2.1 Android Native Implementation
**File**: `android/app/src/main/kotlin/.../AudioRecorderPlugin.kt`

#### Changes Required:

1. **Update `startRecording` method signature**:
   ```kotlin
   private fun startRecording(call: MethodCall, result: MethodChannel.Result) {
       val format = call.argument<String>("format") ?: "m4a"
       // ...
   }
   ```

2. **Add format configuration helper**:
   ```kotlin
   private data class RecorderConfig(
       val outputFormat: Int,
       val audioEncoder: Int,
       val extension: String
   )
   
   private fun getRecorderConfig(format: String): RecorderConfig {
       return when (format.lowercase()) {
           "3gp" -> RecorderConfig(
               MediaRecorder.OutputFormat.THREE_GPP,
               MediaRecorder.AudioEncoder.AMR_NB,
               "3gp"
           )
           "ogg" -> RecorderConfig(
               MediaRecorder.OutputFormat.OGG,
               MediaRecorder.AudioEncoder.OPUS,
               "ogg"
           )
           "webm" -> RecorderConfig(
               MediaRecorder.OutputFormat.WEBM,
               MediaRecorder.AudioEncoder.OPUS,
               "webm"
           )
           else -> RecorderConfig( // Default: m4a
               MediaRecorder.OutputFormat.MPEG_4,
               MediaRecorder.AudioEncoder.AAC,
               "m4a"
           )
       }
   }
   ```

3. **Update MediaRecorder initialization**:
   ```kotlin
   val config = getRecorderConfig(format)
   val fileName = "record_${uuid}.${config.extension}"
   
   mediaRecorder = MediaRecorder().apply {
       setAudioSource(MediaRecorder.AudioSource.MIC)
       setOutputFormat(config.outputFormat)
       setAudioEncoder(config.audioEncoder)
       setOutputFile(currentRecordingPath)
       prepare()
       start()
   }
   ```

4. **Add API level checks for newer formats**:
   ```kotlin
   private fun isFormatSupported(format: String): Boolean {
       return when (format.lowercase()) {
           "ogg", "webm" -> Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
           else -> true
       }
   }
   ```

### 2.2 iOS Native Implementation
**File**: `ios/Runner/AudioRecorderPlugin.swift`

#### Changes Required:

1. **Update `startRecording` method**:
   ```swift
   case "startRecording":
       let format = (call.arguments as? [String: Any])?["format"] as? String ?? "m4a"
       startRecording(format: format, result: result)
   ```

2. **Add format configuration helper**:
   ```swift
   private func getRecorderSettings(format: String) -> [String: Any] {
       switch format.lowercased() {
       case "m4a":
           return [
               AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
               AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
               AVEncoderBitRateKey: 128000,
               AVNumberOfChannelsKey: 2,
               AVSampleRateKey: 44100.0
           ]
       case "caf": // Core Audio Format
           return [
               AVFormatIDKey: Int(kAudioFormatAppleLossless),
               AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
               AVNumberOfChannelsKey: 2,
               AVSampleRateKey: 44100.0
           ]
       default:
           return getRecorderSettings(format: "m4a")
       }
   }
   ```

3. **Update file naming**:
   ```swift
   let fileName = "record_\(uuid).\(format)"
   ```

### 2.3 Method Channel Implementation
**File**: `lib/features/audio_recorder/infrastructure/audio_recorder_method_channel.dart`

Update to pass format:
```dart
@override
Future<void> startRecording({required String formatExtension}) async {
  try {
    await _channel.invokeMethod<void>('startRecording', {
      'format': formatExtension,
    });
  } on PlatformException catch (e) {
    throw AudioRecordingException('Failed to start: ${e.message}');
  }
}
```

### 2.4 Repository Implementation
**File**: `lib/features/audio_recorder/infrastructure/audio_recorder_repo.dart`

```dart
@override
Future<void> startRecording({AudioFormat format = AudioFormat.m4a}) async {
  await _dataSource.startRecording(formatExtension: format.extension);
}
```

---

## Phase 3: Application Layer Updates

### 3.1 Update State
**File**: `lib/features/audio_recorder/application/audio_recorder_state.dart`

Add selected format to state:
```dart
class AudioRecorderState {
  final RecorderStatus status;
  final List<RecordingModel> recordings;
  final String? errorMessage;
  final AudioFormat selectedFormat; // NEW
  
  const AudioRecorderState({
    required this.status,
    required this.recordings,
    this.errorMessage,
    this.selectedFormat = AudioFormat.m4a, // DEFAULT
  });
}
```

### 3.2 Update Provider
**File**: `lib/features/audio_recorder/application/audio_recorder_provider.dart`

Add methods:
```dart
/// Sets the recording format
void setFormat(AudioFormat format) {
  state = state.copyWith(selectedFormat: format);
}

/// Starts recording with selected format
Future<void> start() async {
  try {
    final repository = ref.read(audioRecorderRepositoryProvider);
    await repository.startRecording(format: state.selectedFormat);
    
    state = state.copyWith(
      status: RecorderStatus.recording,
      errorMessage: null,
    );
  } on AudioRecordingException catch (e) {
    state = state.copyWith(
      status: RecorderStatus.error,
      errorMessage: e.message,
    );
  }
}
```

---

## Phase 4: Presentation Layer Updates

### 4.1 Add Format Selector Widget
**File**: `lib/features/audio_recorder/presentation/widgets/format_selector_widget.dart`

```dart
class FormatSelectorWidget extends StatelessWidget {
  const FormatSelectorWidget({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
    required this.isRecording,
  });

  final AudioFormat selectedFormat;
  final ValueChanged<AudioFormat> onFormatChanged;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording Format',
              style: context.textTheme.titleMedium?.semiBold,
            ),
            const SizedBox(height: 8),
            SegmentedButton<AudioFormat>(
              segments: AudioFormat.values.map((format) {
                return ButtonSegment(
                  value: format,
                  label: Text(format.displayName),
                  tooltip: format.description,
                );
              }).toList(),
              selected: {selectedFormat},
              onSelectionChanged: isRecording 
                  ? null 
                  : (Set<AudioFormat> selection) {
                      onFormatChanged(selection.first);
                    },
            ),
            if (selectedFormat.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                selectedFormat.description,
                style: context.textTheme.bodySmall?.colorSecondary(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 4.2 Update Recorder Page
**File**: `lib/features/audio_recorder/presentation/pages/recorder_page.dart`

Add format selector before controls:
```dart
body: Column(
  children: [
    FormatSelectorWidget(
      selectedFormat: recorderState.selectedFormat,
      onFormatChanged: notifier.setFormat,
      isRecording: recorderState.status == RecorderStatus.recording,
    ),
    _RecordingControlsWidget(
      status: recorderState.status,
      // ...
    ),
    // ... rest of UI
  ],
),
```

---

## Phase 5: Testing

### 5.1 Unit Tests
**File**: `test/features/audio_recorder/domain/models/audio_format_test.dart`
- Test enum values
- Test extension mapping
- Test default format

### 5.2 Widget Tests
**File**: `test/features/audio_recorder/presentation/widgets/format_selector_widget_test.dart`
- Test format selection
- Test disabled state when recording
- Test tooltip display

### 5.3 Integration Tests
**File**: `test/features/audio_recorder/integration/format_recording_test.dart`
- Test recording with each format
- Test format persistence across recordings
- Test platform-specific format support

### 5.4 Platform Tests
- **Android**: Test on API 28 (AMR, 3GP, M4A), API 29+ (OGG, WebM)
- **iOS**: Test M4A, CAF formats
- Verify file extensions match selected format
- Verify playback compatibility

---

## Phase 6: Documentation

### 6.1 Update README
Add section on supported formats:
```markdown
## Supported Audio Formats

| Format | Extension | Codec | Best For | Android | iOS |
|--------|-----------|-------|----------|---------|-----|
| M4A    | .m4a      | AAC   | General purpose | ✅ All | ✅ All |
| 3GP    | .3gp      | AMR-NB| Voice notes | ✅ All | ❌ |
| OGG    | .ogg      | Opus  | High quality | ✅ 10+ | ❌ |
| WebM   | .webm     | Opus  | Web playback | ✅ 10+ | ❌ |
| CAF    | .caf      | ALAC  | Lossless | ❌ | ✅ All |
```

### 6.2 Update Architecture Instructions
**File**: `.github/instructions/audio-formats.instructions.md` (NEW)

Document format handling patterns, codec selection, and platform compatibility.

---

## Implementation Checklist

- [ ] **Phase 1**: Domain layer (AudioFormat enum, update interfaces)
- [ ] **Phase 2**: Infrastructure layer
  - [ ] Android native format support
  - [ ] iOS native format support
  - [ ] Method channel updates
  - [ ] Repository implementation
- [ ] **Phase 3**: Application layer (state & provider updates)
- [ ] **Phase 4**: Presentation layer (format selector UI)
- [ ] **Phase 5**: Testing
  - [ ] Unit tests
  - [ ] Widget tests
  - [ ] Integration tests
  - [ ] Platform-specific tests
- [ ] **Phase 6**: Documentation
  - [ ] README updates
  - [ ] Architecture instructions
  - [ ] Code documentation

---

## Breaking Changes
None - this is a backwards-compatible enhancement. Default format remains M4A.

## Migration Guide
No migration needed. Existing code continues to work with M4A as default.

## Estimated Effort
- **Domain + Infrastructure**: 4-6 hours
- **Application + Presentation**: 2-3 hours
- **Testing**: 3-4 hours
- **Documentation**: 1-2 hours
- **Total**: ~10-15 hours

## Dependencies
- Android: Requires API 29+ for OGG/WebM support
- iOS: Native support for M4A, CAF
- No new Flutter package dependencies required

## Future Considerations
- Add audio quality presets (low/medium/high bitrate)
- Add sample rate configuration
- Add channel configuration (mono/stereo)
- Add codec-specific settings (AAC bitrate, Opus complexity)
