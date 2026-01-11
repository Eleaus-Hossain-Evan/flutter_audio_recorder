import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/audio_recorder_provider.dart';
import '../../application/audio_recorder_state.dart';
import '../../domain/models/recording_model.dart';

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
          _RecordingControlsWidget(
            status: recorderState.status,
            statusText: _statusText(recorderState.status),
            onStart: () => _handleStart(ref),
            onStop: notifier.stop,
          ),
          if (recorderState.errorMessage != null)
            _ErrorBannerWidget(message: recorderState.errorMessage!),
          Expanded(
            child: _RecordingsListWidget(
              recordings: recorderState.recordings,
              formatDateTime: _formatDateTime,
              onShowDetails: (recording) =>
                  _showRecordingDetails(context, recording),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStart(WidgetRef ref) async {
    final notifier = ref.read(audioRecorderProvider.notifier);
    final granted = await notifier.requestPermission();
    if (granted) {
      await notifier.start();
    }
  }

  void _showRecordingDetails(BuildContext context, RecordingModel recording) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recording Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRowWidget(label: 'ID', value: recording.id),
            _DetailRowWidget(label: 'File', value: recording.fileName),
            _DetailRowWidget(label: 'Path', value: recording.filePath),
            _DetailRowWidget(
              label: 'Duration',
              value: '${recording.durationMs ~/ 1000}s',
            ),
            _DetailRowWidget(
              label: 'Size',
              value: '${recording.sizeBytes ~/ 1024}KB',
            ),
            _DetailRowWidget(
              label: 'Created',
              value: _formatDateTime(recording.createdAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _RecordingControlsWidget extends StatelessWidget {
  const _RecordingControlsWidget({
    required this.status,
    required this.statusText,
    required this.onStart,
    required this.onStop,
  });

  final RecorderStatus status;
  final String statusText;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final isRecording = status == RecorderStatus.recording;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(statusText, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRecording)
                ElevatedButton.icon(
                  onPressed: onStart,
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
                  onPressed: onStop,
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

class _ErrorBannerWidget extends StatelessWidget {
  const _ErrorBannerWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingsListWidget extends StatelessWidget {
  const _RecordingsListWidget({
    required this.recordings,
    required this.formatDateTime,
    required this.onShowDetails,
  });

  final List<RecordingModel> recordings;
  final String Function(DateTime) formatDateTime;
  final void Function(RecordingModel) onShowDetails;

  @override
  Widget build(BuildContext context) {
    if (recordings.isEmpty) {
      return const Center(child: Text('No recordings yet'));
    }

    return ListView.builder(
      itemCount: recordings.length,
      itemBuilder: (context, index) {
        final recording = recordings[index];
        return _RecordingListItemWidget(
          key: ValueKey(recording.id),
          recording: recording,
          subtitle: _subtitleText(recording, formatDateTime),
          onShowDetails: () => onShowDetails(recording),
        );
      },
    );
  }

  String _subtitleText(
    RecordingModel recording,
    String Function(DateTime) fmt,
  ) {
    final durationSeconds = recording.durationMs ~/ 1000;
    final sizeKb = recording.sizeBytes ~/ 1024;
    return '${durationSeconds}s • ${sizeKb}KB\n${fmt(recording.createdAt)}';
  }
}

class _RecordingListItemWidget extends StatelessWidget {
  const _RecordingListItemWidget({
    super.key,
    required this.recording,
    required this.subtitle,
    required this.onShowDetails,
  });

  final RecordingModel recording;
  final String subtitle;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.audiotrack),
      title: Text(recording.fileName, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: onShowDetails,
      ),
    );
  }
}

class _DetailRowWidget extends StatelessWidget {
  const _DetailRowWidget({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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

String _statusText(RecorderStatus status) {
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
  final date =
      '${dateTime.year}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')}';
  final time =
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
