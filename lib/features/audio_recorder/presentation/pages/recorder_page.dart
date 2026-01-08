import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/audio_recorder_provider.dart';
import '../providers/audio_recorder_state.dart';

/// Audio recorder page with record/stop controls and recordings list.
class RecorderPage extends HookConsumerWidget {
  const RecorderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorderState = ref.watch(audioRecorderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(audioRecorderProvider.notifier).refresh();
            },
            tooltip: 'Refresh recordings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Recording controls
          _buildRecordingControls(context, ref, recorderState),

          // Error message
          if (recorderState.errorMessage != null)
            _buildErrorBanner(recorderState.errorMessage!),

          // Recordings list
          Expanded(child: _buildRecordingsList(recorderState)),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(
    BuildContext context,
    WidgetRef ref,
    AudioRecorderState state,
  ) {
    final isRecording = state.status == RecorderStatus.recording;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status indicator
          Text(
            _getStatusText(state.status),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Record/Stop button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRecording)
                ElevatedButton.icon(
                  onPressed: () => _onRecordPressed(ref),
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
                  onPressed: () {
                    ref.read(audioRecorderProvider.notifier).stop();
                  },
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

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade900)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList(AudioRecorderState state) {
    if (state.recordings.isEmpty) {
      return const Center(child: Text('No recordings yet'));
    }

    return ListView.builder(
      itemCount: state.recordings.length,
      itemBuilder: (context, index) {
        final recording = state.recordings[index];
        final durationSeconds = recording.durationMs ~/ 1000;
        final sizeKb = recording.sizeBytes ~/ 1024;

        return ListTile(
          leading: const Icon(Icons.audiotrack),
          title: Text(recording.fileName),
          subtitle: Text(
            '${durationSeconds}s • ${sizeKb}KB\n${_formatDateTime(recording.createdAt)}',
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showRecordingDetails(context, recording);
            },
          ),
        );
      },
    );
  }

  String _getStatusText(RecorderStatus status) {
    switch (status) {
      case RecorderStatus.idle:
        return 'Ready';
      case RecorderStatus.recording:
        return '🔴 Recording...';
      case RecorderStatus.stopped:
        return 'Recording saved';
      case RecorderStatus.error:
        return 'Error';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _onRecordPressed(WidgetRef ref) async {
    // Request permission first
    final granted = await ref
        .read(audioRecorderProvider.notifier)
        .requestPermission();

    if (granted) {
      // Start recording
      await ref.read(audioRecorderProvider.notifier).start();
    }
  }

  void _showRecordingDetails(BuildContext context, recording) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', recording.id),
            _buildDetailRow('File', recording.fileName),
            _buildDetailRow('Path', recording.filePath),
            _buildDetailRow('Duration', '${recording.durationMs ~/ 1000}s'),
            _buildDetailRow('Size', '${recording.sizeBytes ~/ 1024}KB'),
            _buildDetailRow('Created', _formatDateTime(recording.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
