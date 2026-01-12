import 'package:flutter/material.dart';

/// Precomputed waveform visualizer that renders bars from stored amplitude data.
///
/// Features:
/// - Renders static waveform from pre-computed data
/// - Displays interactive playhead synced to playback position
/// - Supports tap-to-seek functionality
/// - Dual-color gradient (played vs unplayed sections)
class PrecomputedWaveformWidget extends StatelessWidget {
  const PrecomputedWaveformWidget({
    super.key,
    required this.waveformData,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
    this.height = 120,
    this.playedColor,
    this.unplayedColor,
  });

  /// Pre-computed normalized amplitude values (0.0-1.0) for each bar.
  final List<double> waveformData;

  /// Current playback position.
  final Duration currentPosition;

  /// Total audio duration.
  final Duration totalDuration;

  /// Callback when user taps to seek.
  final ValueChanged<Duration> onSeek;

  /// Height of the waveform widget.
  final double height;

  /// Color for the played portion (defaults to primary color).
  final Color? playedColor;

  /// Color for the unplayed portion (defaults to primary with opacity).
  final Color? unplayedColor;

  @override
  Widget build(BuildContext context) {
    if (waveformData.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No waveform data')),
      );
    }

    final theme = Theme.of(context);
    final effectivePlayedColor = playedColor ?? theme.colorScheme.primary;
    final effectiveUnplayedColor =
        unplayedColor ?? theme.colorScheme.primary.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: (details) {
        final tapX = details.localPosition.dx;
        final width = context.size?.width ?? 0;
        if (width > 0) {
          final ratio = (tapX / width).clamp(0.0, 1.0);
          final seekPosition = totalDuration * ratio;
          onSeek(seekPosition);
        }
      },
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _PrecomputedWaveformPainter(
            waveformData: waveformData,
            currentPosition: currentPosition,
            totalDuration: totalDuration,
            playedColor: effectivePlayedColor,
            unplayedColor: effectiveUnplayedColor,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _PrecomputedWaveformPainter extends CustomPainter {
  _PrecomputedWaveformPainter({
    required this.waveformData,
    required this.currentPosition,
    required this.totalDuration,
    required this.playedColor,
    required this.unplayedColor,
  });

  final List<double> waveformData;
  final Duration currentPosition;
  final Duration totalDuration;
  final Color playedColor;
  final Color unplayedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty || size.width <= 0 || size.height <= 0) return;

    final barCount = waveformData.length;
    final barWidth = size.width / (barCount * 1.8);
    final gap = barWidth * 0.8;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.9;
    final minBarHeight = size.height * 0.12;

    // Calculate playhead position
    final playheadX = totalDuration.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds) *
              size.width
        : 0.0;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Draw bars
    for (int i = 0; i < barCount; i++) {
      final amplitude = waveformData[i].clamp(0.0, 1.0);
      final h = minBarHeight + (maxBarHeight - minBarHeight) * amplitude;
      final x = i * (barWidth + gap) + gap;

      // Determine color based on playhead position
      final barColor = x < playheadX ? playedColor : unplayedColor;
      paint.color = barColor;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, centerY), width: barWidth, height: h),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }

    // Draw playhead line
    final playheadPaint = Paint()
      ..color = playedColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PrecomputedWaveformPainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.waveformData != waveformData ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.unplayedColor != unplayedColor;
  }
}
