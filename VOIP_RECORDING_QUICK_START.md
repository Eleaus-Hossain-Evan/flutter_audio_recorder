# VoIP Call Recording - Quick Start Guide

## Overview
This feature enables recording both sides of VoIP calls on Android 10+ and optimized mic recording on iOS.

## Platform Support

| Platform | Capability | Requirements |
|----------|-----------|--------------|
| Android 10+ | ✅ Both sides (mic + app audio) | MediaProjection permission |
| Android 9 and below | ⚠️ Mic-only (VoIP optimized) | Microphone permission |
| iOS | ⚠️ Mic-only (VoIP optimized) | Microphone permission |

## Quick Implementation (Flutter/Dart)

### 1. Check Device Capability

```dart
// Add to your audio recorder service/provider
Future<bool> supportsInternalAudioCapture() async {
  try {
    final result = await methodChannel.invokeMethod<bool>(
      'supportsInternalAudioCapture'
    );
    return result ?? false;
  } catch (e) {
    return false;
  }
}
```

### 2. Request MediaProjection Permission (Android Only)

```dart
Future<bool> requestMediaProjectionPermission() async {
  if (!await supportsInternalAudioCapture()) {
    return false; // Not supported on this device
  }

  try {
    final result = await methodChannel.invokeMethod<bool>(
      'requestMediaProjectionPermission'
    );
    return result ?? false;
  } catch (e) {
    debugPrint('MediaProjection permission denied: $e');
    return false;
  }
}
```

### 3. Start Recording with App Audio

```dart
Future<void> startVoIPRecording() async {
  final supportsAppAudio = await supportsInternalAudioCapture();
  
  if (supportsAppAudio) {
    // Request MediaProjection permission first
    final granted = await requestMediaProjectionPermission();
    
    if (!granted) {
      // Fall back to mic-only or show error
      await startMicOnlyRecording();
      return;
    }
  }

  // Start recording
  await methodChannel.invokeMethod('startRecording', {
    'captureAppAudio': supportsAppAudio, // true for Android 10+, false otherwise
  });
}

Future<void> startMicOnlyRecording() async {
  await methodChannel.invokeMethod('startRecording', {
    'captureAppAudio': false,
  });
}
```

### 4. Complete Example with UI

```dart
class VoIPRecorderWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioRecorder = ref.watch(audioRecorderProvider);
    final supportsAppAudio = ref.watch(supportsInternalAudioProvider);

    return Column(
      children: [
        // Show badge if dual-stream recording is available
        if (supportsAppAudio.value == true)
          Chip(
            label: Text('Both Sides Recording Available'),
            avatar: Icon(Icons.check_circle, color: Colors.green),
          ),

        // Record button
        ElevatedButton.icon(
          onPressed: audioRecorder.isRecording 
            ? null 
            : () async {
                if (supportsAppAudio.value == true) {
                  // Request permission first
                  final granted = await ref
                    .read(audioRecorderProvider.notifier)
                    .requestMediaProjectionPermission();
                  
                  if (!granted) {
                    // Show dialog explaining why permission is needed
                    await showPermissionDialog(context);
                    return;
                  }
                }
                
                // Start recording
                await ref
                  .read(audioRecorderProvider.notifier)
                  .startRecording(
                    captureAppAudio: supportsAppAudio.value == true,
                  );
              },
          icon: Icon(Icons.mic),
          label: Text(
            supportsAppAudio.value == true 
              ? 'Record Both Sides' 
              : 'Record Mic Only'
          ),
        ),

        // Stop button
        if (audioRecorder.isRecording)
          ElevatedButton.icon(
            onPressed: () => ref
              .read(audioRecorderProvider.notifier)
              .stopRecording(),
            icon: Icon(Icons.stop),
            label: Text('Stop Recording'),
          ),
      ],
    );
  }

  Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'To record both sides of the call, we need permission to capture '
          'audio from other apps. This will show a notification while recording.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Retry permission request
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
```

## Provider Implementation (Riverpod)

### Add to your audio recorder provider

```dart
@riverpod
class AudioRecorder extends _$AudioRecorder {
  static const _methodChannel = MethodChannel('com.example.audio_recorder/methods');

  @override
  AudioRecorderState build() {
    return const AudioRecorderState();
  }

  Future<bool> supportsInternalAudioCapture() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'supportsInternalAudioCapture'
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestMediaProjectionPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'requestMediaProjectionPermission'
      );
      return result ?? false;
    } catch (e) {
      debugPrint('MediaProjection permission error: $e');
      return false;
    }
  }

  Future<void> startRecording({bool captureAppAudio = false}) async {
    try {
      state = state.copyWith(isRecording: true);
      
      await _methodChannel.invokeMethod('startRecording', {
        'captureAppAudio': captureAppAudio,
      });
    } catch (e) {
      state = state.copyWith(isRecording: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      final result = await _methodChannel.invokeMethod('stopRecording');
      state = state.copyWith(isRecording: false);
      return result as Map<String, dynamic>?;
    } catch (e) {
      state = state.copyWith(isRecording: false);
      rethrow;
    }
  }
}

// Helper provider to cache capability check
@riverpod
Future<bool> supportsInternalAudio(SupportsInternalAudioRef ref) async {
  final recorder = ref.watch(audioRecorderProvider.notifier);
  return recorder.supportsInternalAudioCapture();
}
```

## User Experience Considerations

### 1. Permission Explanation
Always explain why MediaProjection permission is needed:

```dart
Text(
  'To record both sides of your VoIP calls, we need permission to '
  'capture audio from other apps. A notification will appear during '
  'recording to comply with Android privacy requirements.'
)
```

### 2. Notification Handling
Inform users about the persistent notification:

```dart
if (Platform.isAndroid && await supportsInternalAudioCapture()) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Notification During Recording'),
      content: Text(
        'While recording, you\'ll see a "Recording Audio" notification. '
        'This is required by Android and ensures you\'re aware that '
        'audio capture is active. The notification will disappear when '
        'you stop recording.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

### 3. Graceful Degradation
Always provide fallback to mic-only:

```dart
Future<void> startVoIPRecording() async {
  final supportsAppAudio = await supportsInternalAudioCapture();
  bool captureAppAudio = false;

  if (supportsAppAudio) {
    // Try to get MediaProjection permission
    final granted = await requestMediaProjectionPermission();
    captureAppAudio = granted;
    
    if (!granted) {
      // Show toast/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording mic only. Partner\'s voice won\'t be captured.'),
        ),
      );
    }
  } else {
    // Show toast/snackbar for iOS or old Android
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Platform.isIOS 
            ? 'iOS can only record your voice due to system limitations.'
            : 'Your Android version only supports mic recording.'
        ),
      ),
    );
  }

  await methodChannel.invokeMethod('startRecording', {
    'captureAppAudio': captureAppAudio,
  });
}
```

## Testing Guide

### Manual Testing Steps

#### Android 10+ Device
1. Request microphone permission
2. Request MediaProjection permission
3. Start VoIP call (WhatsApp, Zoom, etc.)
4. Start recording with `captureAppAudio: true`
5. Verify notification appears
6. Speak into microphone
7. Listen to partner speak
8. Stop recording
9. Verify notification disappears
10. Play back recording - both voices should be audible

#### Android 9 Device
1. Request microphone permission
2. Start VoIP call
3. Start recording with `captureAppAudio: false` (or true, will auto-fallback)
4. Verify mic recording works
5. Stop and playback - only user voice audible

#### iOS Device
1. Request microphone permission
2. Start VoIP call
3. Start recording
4. Verify echo cancellation works
5. Stop and playback - only user voice audible

### Automated Testing

```dart
// Unit test
test('supportsInternalAudioCapture returns true on Android 10+', () async {
  // Mock method channel
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'supportsInternalAudioCapture') {
        return true;
      }
      return null;
    });

  final recorder = AudioRecorder();
  final result = await recorder.supportsInternalAudioCapture();
  expect(result, true);
});

// Widget test
testWidgets('shows dual-stream badge when supported', (tester) async {
  // Setup provider override
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportsInternalAudioProvider.overrideWith((ref) => Future.value(true)),
      ],
      child: MaterialApp(
        home: VoIPRecorderWidget(),
      ),
    ),
  );

  await tester.pumpAndSettle();
  
  expect(find.text('Both Sides Recording Available'), findsOneWidget);
});
```

## Common Issues & Solutions

### Issue: MediaProjection Permission Always Denied
**Solution**: Ensure you're calling `requestMediaProjectionPermission()` before `startRecording()`. The permission must be granted in the same user session.

### Issue: Only Mic Audio in Recording
**Possible Causes**:
1. VoIP app opted out of AudioPlaybackCapture
2. MediaProjection service not running
3. Permission not granted

**Solution**: Check logs for errors. Try with different VoIP apps.

### Issue: Poor Audio Quality on iOS
**Solution**: Ensure you're not overriding the audio session elsewhere in your app. The `.voiceChat` mode provides best quality.

## Performance Tips

1. **Stop recording when app backgrounded** (optional):
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused && isRecording) {
    stopRecording();
  }
}
```

2. **Limit recording duration** to manage storage:
```dart
Timer? _recordingTimer;

void startRecording() async {
  await methodChannel.invokeMethod('startRecording', {...});
  
  // Auto-stop after 2 hours
  _recordingTimer = Timer(Duration(hours: 2), () {
    stopRecording();
  });
}
```

3. **Monitor storage space**:
```dart
import 'package:disk_space/disk_space.dart';

Future<bool> hasEnoughStorage() async {
  final freeSpace = await DiskSpace.getFreeDiskSpace;
  return freeSpace > 100; // MB
}
```

## Summary

✅ Check capability with `supportsInternalAudioCapture()`  
✅ Request MediaProjection permission before recording  
✅ Handle permission denial gracefully  
✅ Inform users about persistent notification  
✅ Provide mic-only fallback  
✅ Test on multiple VoIP apps  

For detailed technical documentation, see [VOIP_RECORDING_IMPLEMENTATION.md](VOIP_RECORDING_IMPLEMENTATION.md).
