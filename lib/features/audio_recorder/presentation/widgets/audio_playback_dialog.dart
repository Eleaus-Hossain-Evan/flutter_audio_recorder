import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/extension/extensions.dart';
import '../../../audio_player/application/audio_player_provider.dart';
import '../../../audio_recorder/domain/models/recording_model.dart';
import 'playback_waveform_widget.dart';
import 'precomputed_waveform_widget.dart';

class AudioPlaybackDialog extends HookConsumerWidget {
  const AudioPlaybackDialog({super.key, required this.recording});

  final RecordingModel recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(audioPlayerProvider.notifier);

    // Load the URL when the dialog opens
    useEffect(() {
      final uri = Uri.file(recording.filePath).toString();
      Future.microtask(() async {
        await notifier.loadUrl(uri);
      });
      // Cleanup: ensure the player stops when dialog closes
      return () {
        notifier.stop();
      };
    }, const []);

    final position = ref
        .watch(audioPlayerPositionProvider)
        .maybeWhen(data: (d) => d, orElse: () => Duration.zero);
    final duration = ref
        .watch(audioPlayerDurationProvider)
        .maybeWhen(
          data: (d) => d ?? Duration(milliseconds: recording.durationMs),
          orElse: () => Duration(milliseconds: recording.durationMs),
        );
    final processing = ref
        .watch(audioPlayerProcessingStateProvider)
        .maybeWhen(data: (s) => s, orElse: () => ProcessingState.idle);
    final isPlaying = ref
        .watch(audioPlayerPlayingProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    // Volume and speed live values
    final volume = ref
        .watch(audioPlayerVolumeProvider)
        .maybeWhen(data: (v) => v, orElse: () => 1.0);
    final speed = ref
        .watch(audioPlayerSpeedProvider)
        .maybeWhen(data: (v) => v, orElse: () => 1.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: filename + created time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.fileName,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${recording.createdAt.toReadableString()} • ${_fmt(duration)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Waveform visualization (precomputed or animated fallback)
              _buildWaveform(ref, recording, position, duration),

              const SizedBox(height: 12),

              // Seekbar with labels
              _PositionSlider(
                position: position,
                duration: duration,
                onChanged: (v) =>
                    notifier.seek(Duration(milliseconds: v.toInt())),
              ),

              const SizedBox(height: 8),

              // Controls row
              Row(
                children: [
                  // Play / Pause
                  _PlayPauseButton(
                    isPlaying: isPlaying,
                    processingState: processing,
                    onPlay: notifier.play,
                    onPause: notifier.pause,
                  ),
                  const SizedBox(width: 12),

                  // Speed selector
                  _SpeedControl(
                    current: speed,
                    onChanged: (v) => notifier.setSpeed(v),
                  ),

                  const Spacer(),

                  // Volume control (icon + slider)
                  Icon(_volumeIcon(volume)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Slider(
                      min: 0,
                      max: 1,
                      value: volume.clamp(0, 1),
                      onChanged: (v) => notifier.setVolume(v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final h = d.inHours;
    if (h > 0) {
      return '${_pad2(h)}:${_pad2(m % 60)}:${_pad2(s)}';
    }
    return '${_pad2(m)}:${_pad2(s)}';
  }

  static IconData _volumeIcon(double v) {
    if (v <= 0.0) return Icons.volume_mute;
    if (v < 0.33) return Icons.volume_down;
    if (v < 0.66) return Icons.volume_up;
    return Icons.volume_up_rounded;
  }

  /// Builds waveform widget conditionally based on data availability.
  ///
  /// - If precomputed waveform data exists: render interactive waveform with playhead
  /// - Otherwise: fallback to animated placeholder (for legacy recordings)
  Widget _buildWaveform(
    WidgetRef ref,
    RecordingModel recording,
    Duration position,
    Duration duration,
  ) {
    final hasWaveformData = recording.waveformData?.isNotEmpty ?? false;

    if (hasWaveformData) {
      return PrecomputedWaveformWidget(
        waveformData: recording.waveformData!,
        currentPosition: position,
        totalDuration: duration,
        onSeek: (seekPosition) {
          final notifier = ref.read(audioPlayerProvider.notifier);
          notifier.seek(seekPosition);
        },
        height: 120,
      );
    } else {
      // Legacy fallback for recordings without waveform data
      return const PlaybackWaveformWidget(height: 120);
    }
  }
}

class _PositionSlider extends StatelessWidget {
  const _PositionSlider({
    required this.position,
    required this.duration,
    required this.onChanged,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final valueMs = position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(min: 0, max: maxMs, value: valueMs, onChanged: onChanged),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AudioPlaybackDialog._fmt(position),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              AudioPlaybackDialog._fmt(duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.processingState,
    required this.onPlay,
    required this.onPause,
  });

  final bool isPlaying;
  final ProcessingState processingState;
  final Future<void> Function() onPlay;
  final Future<void> Function() onPause;

  bool get _isLoading =>
      processingState == ProcessingState.loading ||
      processingState == ProcessingState.buffering;

  @override
  Widget build(BuildContext context) {
    // if (processingState == ProcessingState.loading ||
    //     processingState == ProcessingState.buffering) {
    //   return const SizedBox(
    //     width: 36 * 2,
    //     height: 36 * 2,
    //     child: Padding(
    //       padding: EdgeInsets.all(12.0),
    //       child: CircularProgressIndicator(strokeWidth: 2),
    //     ),
    //   );
    // }
    return IconButton.filled(
      iconSize: 36,
      onPressed: isPlaying ? onPause : onPlay,
      icon: _isLoading
          ? CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
          : Icon(isPlaying ? Icons.pause : Icons.play_arrow),

      tooltip: _isLoading
          ? 'Loading...'
          : isPlaying
          ? 'Pause'
          : 'Play',
    );
  }
}

class _SpeedControl extends StatelessWidget {
  const _SpeedControl({required this.current, required this.onChanged});

  final double current;
  final ValueChanged<double> onChanged;

  static const _speeds = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<double>(
      value: _closest(current),
      items: _speeds
          .map(
            (s) => DropdownMenuItem<double>(
              value: s,
              child: Text('${s.toStringAsFixed(2)}x'),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      underline: const SizedBox.shrink(),
    );
  }

  double _closest(double value) {
    double closest = _speeds.first;
    double minDiff = (value - closest).abs();
    for (final s in _speeds) {
      final diff = (value - s).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }
    return closest;
  }
}
