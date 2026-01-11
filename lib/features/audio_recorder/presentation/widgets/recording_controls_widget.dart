import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/core/constant/recorder_status.dart';
import 'package:flutter_audio_recorder/features/audio_recorder/application/audio_recorder_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RecordingControlsWidget extends HookConsumerWidget {
  const RecordingControlsWidget({super.key, required this.status});

  final RecorderStatus status;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = status == RecorderStatus.recording;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            status.statusText,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRecording)
                ElevatedButton.icon(
                  onPressed: () async {
                    final notifier = ref.read(audioRecorderProvider.notifier);
                    final granted = await notifier.requestPermission();
                    if (granted) {
                      await notifier.start();
                    }
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Recording'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(audioRecorderProvider.notifier).stop(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
