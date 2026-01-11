import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constant/recorder_status.dart';
import '../../application/audio_recorder_provider.dart';
import '../widgets/error_banner_widget.dart';
import '../widgets/recording_controls_widget.dart';
import '../widgets/recordings_list_widget.dart';
import '../widgets/waveform_visualizer_widget.dart';

/// Audio recorder page with record/stop controls and recordings list.
class RecorderPage extends HookConsumerWidget {
  const RecorderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorderState = ref.watch(audioRecorderProvider);
    final notifier = ref.read(audioRecorderProvider.notifier);
    final isRecording = recorderState.status == RecorderStatus.recording;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
            tooltip: 'Refresh recordings',
          ),
        ],
      ),
      body: Column(
        children: [
          RecordingControlsWidget(status: recorderState.status),
          // Show waveform visualizer only during active recording
          if (isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: WaveformVisualizerWidget(),
            ),
          if (recorderState.errorMessage != null)
            ErrorBannerWidget(message: recorderState.errorMessage!),
          Expanded(
            child: RecordingsListWidget(recordings: recorderState.recordings),
          ),
        ],
      ),
    );
  }
}
