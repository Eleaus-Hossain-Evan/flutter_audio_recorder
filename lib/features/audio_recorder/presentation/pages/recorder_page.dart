import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/audio_recorder_provider.dart';
import '../widgets/error_banner_widget.dart';
import '../widgets/recording_controls_widget.dart';
import '../widgets/recordings_list_widget.dart';

/// Audio recorder page with record/stop controls and recordings list.
class RecorderPage extends HookConsumerWidget {
  const RecorderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorderState = ref.watch(audioRecorderProvider);
    final notifier = ref.read(audioRecorderProvider.notifier);

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
