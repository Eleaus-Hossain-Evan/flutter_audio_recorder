import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/features/audio_recorder/domain/models/recording_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extension/extensions.dart';
import 'audio_playback_dialog.dart';

class RecordingsListWidget extends ConsumerWidget {
  const RecordingsListWidget({super.key, required this.recordings});

  final List<RecordingModel> recordings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onOpenDialog: () async {
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (dialogContext) =>
                  AudioPlaybackDialog(recording: recording),
            );
          },
        );
      },
    );
  }
}

class _RecordingListItemWidget extends StatelessWidget {
  const _RecordingListItemWidget({
    super.key,
    required this.recording,
    required this.onOpenDialog,
  });

  final RecordingModel recording;
  final VoidCallback onOpenDialog;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      leading: const Icon(Icons.audiotrack),
      title: Text(recording.fileName, overflow: TextOverflow.ellipsis),
      subtitle: Text(_subtitleText(recording)),
      isThreeLine: true,
      onTap: onOpenDialog,
      trailing: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showRecordingDetails(context, recording),
      ),
    );
  }

  String _subtitleText(RecordingModel recording) {
    final durationSeconds = recording.durationMs ~/ 1000;
    final sizeKb = recording.sizeBytes ~/ 1024;
    return '${durationSeconds}s • ${sizeKb}KB\n${recording.createdAt.toReadableString()}';
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
              value: recording.createdAt.toReadableString(),
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
