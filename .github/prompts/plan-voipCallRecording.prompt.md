# Plan: VoIP Call Recording (Both Sides)

Implement internal audio capture to record both microphone input AND app audio output during VoIP calls (WhatsApp, Zoom, Google Meet, etc.). This requires platform-specific native implementations due to OS restrictions.

## Steps

1. **Add Android MediaProjection audio capture** — Implement [AudioRecorderPlugin.kt](android/app/src/main/kotlin/com/example/flutter_audio_recorder/AudioRecorderPlugin.kt) with `AudioPlaybackCapture` API (API 29+) to mix microphone + app audio streams, add foreground service with notification, handle MediaProjection permission flow
2. **Update Android manifest & permissions** — Add to [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml): `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PROJECTION`, `MODIFY_AUDIO_SETTINGS` permissions; declare foreground service component

3. **Optimize iOS audio session for VoIP** — Update [AudioRecorderPlugin.swift](ios/Runner/AudioRecorderPlugin.swift#L133-L134) to use `.voiceChat` mode with `.allowBluetooth` and `.mixWithOthers` options (captures mic only - iOS sandbox prevents app audio capture)

4. **Add dual-mode recording parameter** — Extend `startRecording` method channel call to accept `captureAppAudio: bool` parameter in Flutter layer; route to appropriate native implementation (MediaProjection vs standard MediaRecorder)

5. **Implement audio stream mixing** — Create Android `AudioMixer` class to synchronize and combine `MediaRecorder` (mic) + `AudioPlaybackCapture` (app audio) streams into single output file with proper timing alignment

## Further Considerations

1. **iOS limitation** — Cannot capture app audio on iOS due to sandbox restrictions. iOS implementation will be mic-only even with optimizations. Accept this or consider building custom VoIP integration?

2. **Android API 28 and below fallback** — `AudioPlaybackCapture` requires API 29+. Should fallback to `VOICE_COMMUNICATION` source (mic-only) for older devices?

3. **User consent & foreground service** — MediaProjection shows persistent notification and requires explicit screen recording permission. Need UI flow for permission request before recording starts?

## Implementation Details

### Android Architecture

#### Current Implementation (Mic-Only)

- **File**: `android/app/src/main/kotlin/com/example/flutter_audio_recorder/AudioRecorderPlugin.kt`
- **Line 247**: `setAudioSource(MediaRecorder.AudioSource.MIC)`
- **Output**: MPEG-4 AAC, mono, mic input only

#### Target Implementation (Dual-Stream)

```
┌─────────────────┐
│ Microphone      │──┐
└─────────────────┘  │
                     ├──> AudioMixer ──> Output File (Both Sides)
┌─────────────────┐  │
│ App Audio       │──┘
│ (VoIP Partner)  │
└─────────────────┘
```

**Components Needed**:

1. **MediaProjection Service** (foreground)

   - Manages screen/audio capture permission
   - Shows persistent notification
   - Lifecycle management

2. **AudioPlaybackCapture**

   - Captures app audio output (partner's voice)
   - Requires API 29+
   - Needs MediaProjection token

3. **MediaRecorder** (existing)

   - Continues to capture microphone
   - Standard implementation

4. **AudioMixer** (new)
   - Synchronizes both streams
   - Mixes to single output
   - Handles timing alignment

### iOS Architecture

#### Current Implementation

- **File**: `ios/Runner/AudioRecorderPlugin.swift`
- **Lines 133-134**: `setCategory(.playAndRecord, mode: .default)`
- **Limitation**: Mic input only (sandbox restriction)

#### Target Implementation

```swift
// Optimize for VoIP quality (still mic-only)
try audioSession.setCategory(
    .playAndRecord,
    mode: .voiceChat,  // Echo cancellation, noise suppression
    options: [
        .allowBluetooth,
        .allowBluetoothA2DP,
        .defaultToSpeaker,
        .mixWithOthers
    ]
)
```

**iOS Limitation**: Cannot capture app audio from other apps. This is a fundamental sandbox restriction. Options:

- Accept mic-only recording on iOS
- Build custom VoIP SDK integration (only for apps you control)

### Flutter Layer Changes

#### Method Channel Update

```dart
// Current
await platform.invokeMethod('startRecording');

// Target
await platform.invokeMethod('startRecording', {
  'captureAppAudio': true,  // Request internal audio capture
});
```

#### Feature Detection

```dart
// Check if device supports internal audio capture
final bool supportsInternalAudio = await platform.invokeMethod(
  'supportsInternalAudioCapture'
);

// Platform returns:
// Android API 29+: true
// Android API < 29: false
// iOS: false (always)
```

### Permission Flow

#### Android Flow

```
1. Request RECORD_AUDIO (existing)
   ↓
2. If captureAppAudio == true:
   ↓
3. Request MediaProjection permission
   - Shows system dialog
   - User must approve screen recording
   ↓
4. Start foreground service
   - Shows persistent notification
   ↓
5. Start dual-stream recording
   - MediaRecorder (mic)
   - AudioPlaybackCapture (app audio)
   ↓
6. Mix streams in real-time
```

#### iOS Flow

```
1. Request microphone permission (existing)
   ↓
2. Configure AVAudioSession for VoIP
   ↓
3. Start recording (mic-only)
```

## Code Changes Required

### 1. Android Manifest

**File**: `android/app/src/main/AndroidManifest.xml`

Add after line 2:

```xml
<!-- Existing -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- NEW: For internal audio capture -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION"
                 android:minSdkVersion="34" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

Add service declaration in `<application>`:

```xml
<service
    android:name=".AudioCaptureService"
    android:foregroundServiceType="mediaProjection"
    android:enabled="true"
    android:exported="false" />
```

### 2. Android AudioRecorderPlugin.kt

**File**: `android/app/src/main/kotlin/com/example/flutter_audio_recorder/AudioRecorderPlugin.kt`

**Changes**:

- Add `mediaProjectionManager` and `audioPlaybackCapture` fields
- Add `requestMediaProjectionPermission()` method
- Update `startRecording()` to accept `captureAppAudio` parameter
- Implement dual-stream recording with `AudioMixer`
- Add `supportsInternalAudioCapture()` method

**Key modifications** (Line 247):

```kotlin
// Current
setAudioSource(MediaRecorder.AudioSource.MIC)

// New (simplified example)
val captureAppAudio = call.argument<Boolean>("captureAppAudio") ?: false

if (captureAppAudio && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
    // Start MediaProjection-based capture
    startDualStreamRecording(result)
} else {
    // Fallback to mic-only with optimization
    setAudioSource(
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaRecorder.AudioSource.VOICE_COMMUNICATION
        } else {
            MediaRecorder.AudioSource.MIC
        }
    )
}
```

### 3. New Android Classes

**AudioCaptureService.kt** (~150 lines)

- Foreground service for MediaProjection
- Notification management
- Lifecycle handling

**AudioMixer.kt** (~200 lines)

- Real-time audio stream mixing
- Synchronization logic
- Buffer management

**MediaProjectionHelper.kt** (~100 lines)

- Permission request flow
- MediaProjection setup
- AudioPlaybackCapture configuration

### 4. iOS AudioRecorderPlugin.swift

**File**: `ios/Runner/AudioRecorderPlugin.swift`

**Line 133-134**, replace:

```swift
// Current
try audioSession.setCategory(.playAndRecord, mode: .default)
try audioSession.setActive(true)

// New
try audioSession.setCategory(
    .playAndRecord,
    mode: .voiceChat,
    options: [
        .allowBluetooth,
        .allowBluetoothA2DP,
        .defaultToSpeaker,
        .mixWithOthers
    ]
)
try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
```

### 5. Flutter Interface Updates

**Domain Model**: Add `captureAppAudio` parameter to recording start
**Provider**: Expose platform capability check
**UI**: Add toggle for internal audio capture (with platform availability)

## Estimated Complexity

| Component                           | Lines of Code | Complexity | Time Estimate |
| ----------------------------------- | ------------- | ---------- | ------------- |
| Android MediaProjection setup       | ~100          | Medium     | 4h            |
| Android AudioCaptureService         | ~150          | Medium     | 4h            |
| Android AudioMixer                  | ~200          | High       | 8h            |
| Android AudioRecorderPlugin updates | ~150          | Medium     | 4h            |
| iOS AVAudioSession optimization     | ~20           | Low        | 1h            |
| Flutter interface updates           | ~50           | Low        | 2h            |
| Testing & debugging                 | -             | High       | 8h            |
| **Total**                           | **~670**      | **High**   | **~31h**      |

## Testing Strategy

1. **Android API 29+ devices**: Test dual-stream recording with VoIP apps
2. **Android API 28 and below**: Verify graceful fallback to mic-only
3. **iOS devices**: Verify VoIP-optimized mic recording
4. **Permission flows**: Test all permission grant/deny scenarios
5. **Audio quality**: Verify both voices are clear and balanced
6. **Background/foreground**: Test app lifecycle during recording
7. **Multiple apps**: Test with WhatsApp, Zoom, Google Meet, Messenger

## Success Criteria

- ✅ Android 10+ captures both mic + app audio during VoIP calls
- ✅ Android 9 and below gracefully falls back to optimized mic-only
- ✅ iOS captures mic with VoIP-optimized quality
- ✅ Both voices audible and balanced in output file
- ✅ Proper permission handling with clear user messaging
- ✅ No crashes or audio glitches during recording
- ✅ Works with major VoIP apps (WhatsApp, Zoom, Meet, Messenger)

## Risks & Mitigations

| Risk                                 | Impact | Mitigation                                                  |
| ------------------------------------ | ------ | ----------------------------------------------------------- |
| iOS cannot capture app audio         | High   | Document limitation clearly; optimize mic quality           |
| Android API fragmentation            | Medium | Implement robust API level detection and fallbacks          |
| VoIP app audio routing issues        | Medium | Test with multiple apps; adjust AudioPlaybackCapture config |
| MediaProjection permission rejection | Medium | Provide clear UI explanation; allow fallback to mic-only    |
| Audio sync issues in mixer           | High   | Implement precise timestamping; extensive testing           |
| Foreground service notification UX   | Low    | Design clear, non-intrusive notification                    |

## References

- [Android AudioPlaybackCapture API](https://developer.android.com/guide/topics/media/playback-capture)
- [Android MediaProjection](https://developer.android.com/reference/android/media/projection/MediaProjection)
- [iOS AVAudioSession Programming Guide](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [iOS Audio Session Categories and Modes](https://developer.apple.com/documentation/avfaudio/avaudiosession/category)
