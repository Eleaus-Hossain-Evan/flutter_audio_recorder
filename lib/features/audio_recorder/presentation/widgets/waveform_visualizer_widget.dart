import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/audio_recorder_stream_provider.dart';

/// Waveform visualizer that displays real-time amplitude during recording.
///
/// Features:
/// - Smooth interpolation between amplitude samples
/// - Ring buffer of last 100-150 samples (~2-3 seconds at 50Hz)
/// - Gradient fill from top to bottom
/// - Frame-synced rendering
/// - Auto-hides when not recording
class WaveformVisualizerWidget extends HookConsumerWidget {
  /// Number of samples to retain in the waveform buffer.
  /// At 50Hz frequency, 120 samples = ~2.4 seconds of waveform history.
  static const int maxSamples = 120;

  /// Gradient colors for waveform fill (top to bottom).
  final List<Color> colors;

  /// Waveform line stroke width.
  final double strokeWidth;

  /// Animation smoothing factor (0.0-1.0).
  /// Higher values = more smoothing between samples.
  final double smoothingFactor;

  const WaveformVisualizerWidget({
    super.key,
    this.colors = const [
      Color(0xFF64B5F6), // Light blue
      Color(0xFF2196F3), // Blue
      Color(0xFF1976D2), // Dark blue
    ],
    this.strokeWidth = 2.0,
    this.smoothingFactor = 0.5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch amplitude stream
    final amplitudeStreamAsync = ref.watch(amplitudeStreamProvider);

    // Use a hook to maintain the sample buffer (ring buffer pattern)
    final sampleBuffer = useState<DoubleLinkedQueue<double>>(
      DoubleLinkedQueue<double>(),
    );

    ref.listen(amplitudeStreamProvider, (previous, next) {
      next.whenData((data) {
        // Trigger rebuild on new data
        // (Handled by useState and useEffect above)
        // Add to buffer and remove oldest if full
        sampleBuffer.value.addLast(data.value);
        if (sampleBuffer.value.length > maxSamples) {
          sampleBuffer.value.removeFirst();
        }
      });
    });

    return amplitudeStreamAsync.when(
      data: (_) {
        // Render waveform if samples exist
        return SizedBox(
          height: 100,
          child: CustomPaint(
            painter: WaveformPainter(
              samples: sampleBuffer.value.toList(),
              colors: colors,
              strokeWidth: strokeWidth,
              smoothingFactor: smoothingFactor,
            ),
            size: Size.infinite,
          ),
        );
      },
      loading: () {
        // Stream loading state
        return const SizedBox(
          height: 100,
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      error: (error, stack) {
        // Stream error state
        return SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'Waveform unavailable',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for waveform visualization.
class WaveformPainter extends CustomPainter {
  /// Normalized amplitude samples (0.0-1.0).
  final List<double> samples;

  /// Gradient colors for fill.
  final List<Color> colors;

  /// Line stroke width.
  final double strokeWidth;

  /// Smoothing factor for interpolation.
  final double smoothingFactor;

  WaveformPainter({
    required this.samples,
    required this.colors,
    required this.strokeWidth,
    required this.smoothingFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) {
      // Draw empty state (baseline)
      _drawBaseline(canvas, size);
      return;
    }

    // Create gradient for fill
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      colors,
      List<double>.generate(colors.length, (i) => i / (colors.length - 1)),
    );

    // Paint for waveform line
    final linePaint = Paint()
      ..color = colors.first
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paint for fill area
    final fillPaint = Paint()
      ..shader = gradient
      ..strokeWidth = 0;

    // Build the waveform path
    final path = _buildWaveformPath(size);

    if (path != null) {
      // Draw filled area
      canvas.drawPath(path, fillPaint);

      // Draw waveform line
      canvas.drawPath(path, linePaint);
    } else {
      _drawBaseline(canvas, size);
    }
  }

  /// Builds the waveform path from samples with smooth interpolation.
  Path? _buildWaveformPath(Size size) {
    if (samples.isEmpty) return null;

    final path = Path();
    final centerY = size.height / 2;
    final width = size.width;
    final height = size.height;

    // Spacing between points
    final spacing = width / (samples.length - 1).clamp(1, samples.length);

    // Start at bottom-left
    path.moveTo(0, centerY);

    // Draw interpolated waveform
    for (int i = 0; i < samples.length; i++) {
      final x = i * spacing;
      // Amplitude is 0.0-1.0; map to vertical position
      // 0.0 = center, 1.0 = top
      final yOffset = (samples[i] * height / 2) * smoothingFactor;
      final y = centerY - yOffset;

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        // Use quadratic Bézier for smooth interpolation
        final prevX = (i - 1) * spacing;
        final prevY =
            centerY - ((samples[i - 1] * height / 2) * smoothingFactor);
        final cp1X = (prevX + x) / 2;
        final cp1Y = (prevY + y) / 2;
        path.quadraticBezierTo(cp1X, cp1Y, x, y);
      }
    }

    // Close path to create filled area
    path.lineTo(width, centerY);
    path.lineTo(width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  /// Draws a baseline when no samples are available.
  void _drawBaseline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.first.withOpacity(0.3)
      ..strokeWidth = 1;

    final centerY = size.height / 2;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.colors != colors ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.smoothingFactor != smoothingFactor;
  }
}
