import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Melora Design System - Audio Wave Animation
class AudioWaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color? color;
  final double height;
  final int barCount;

  const AudioWaveAnimation({
    super.key,
    this.isPlaying = false,
    this.color,
    this.height = 40,
    this.barCount = 30,
  });

  @override
  State<AudioWaveAnimation> createState() => _AudioWaveAnimationState();
}

class _AudioWaveAnimationState extends State<AudioWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(AudioWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WavePainter(
            progress: _controller.value,
            color: widget.color ?? MeloraColors.primary.withOpacity(0.4),
            barCount: widget.barCount,
            isPlaying: widget.isPlaying,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int barCount;
  final bool isPlaying;

  _WavePainter({
    required this.progress,
    required this.color,
    required this.barCount,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / (barCount * 2);
    final random = Random(42);

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth * 2) + barWidth / 2;
      final seed = random.nextDouble();
      final phase = seed * 2 * pi + progress * 2 * pi;
      final amplitude = isPlaying ? (0.3 + seed * 0.7) : 0.15;
      final barHeight = size.height * amplitude * (0.5 + 0.5 * sin(phase));
      final clampedHeight = barHeight.clamp(3.0, size.height);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height / 2),
          width: barWidth * 0.7,
          height: clampedHeight,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}
