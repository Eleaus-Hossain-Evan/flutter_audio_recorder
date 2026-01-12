import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../audio_player/application/audio_player_provider.dart';

/// A placeholder animated waveform visualizer for playback.
///
/// This widget does not reflect the real waveform; instead it animates
/// a set of bars for a pleasing, lightweight visualization.
class PlaybackWaveformWidget extends HookConsumerWidget {
  const PlaybackWaveformWidget({
    super.key,
    this.height = 120,
    this.barCount = 24,
  });

  final double height;
  final int barCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    final isPlaying = ref
        .watch(audioPlayerPlayingProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    // Pause animation when not playing
    useEffect(() {
      if (isPlaying) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [isPlaying]);

    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value; // 0..1
          return CustomPaint(
            painter: _BarsPainter(
              progress: t,
              barCount: barCount,
              color: Theme.of(context).colorScheme.primary,
              secondary: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.45),
            ),
          );
        },
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.progress,
    required this.barCount,
    required this.color,
    required this.secondary,
  });

  final double progress;
  final int barCount;
  final Color color;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / (barCount * 1.8);
    final gap = barWidth * 0.8;

    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.9;
    final minBarHeight = size.height * 0.12;

    for (int i = 0; i < barCount; i++) {
      final phase = (i / barCount) * math.pi * 2;
      final wave = (math.sin((progress * math.pi * 2) + phase) + 1) / 2; // 0..1
      final pulse = 0.25 + 0.75 * wave; // 0.25..1.0

      final h = minBarHeight + (maxBarHeight - minBarHeight) * pulse;
      final x = i * (barWidth + gap) + gap;

      // Gradient-like effect by blending two colors
      final barPaint = paint
        ..color = Color.lerp(secondary, color, pulse) ?? color;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, centerY), width: barWidth, height: h),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.barCount != barCount ||
        oldDelegate.color != color ||
        oldDelegate.secondary != secondary;
  }
}
