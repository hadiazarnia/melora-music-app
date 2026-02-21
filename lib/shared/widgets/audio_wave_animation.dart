import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Audio Wave Animation that responds to audio level
class AudioWaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final double audioLevel;
  final Color? color;
  final double height;
  final int barCount;

  const AudioWaveAnimation({
    super.key,
    this.isPlaying = false,
    this.audioLevel = 0.5,
    this.color,
    this.height = 40,
    this.barCount = 40,
  });

  @override
  State<AudioWaveAnimation> createState() => _AudioWaveAnimationState();
}

class _AudioWaveAnimationState extends State<AudioWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _barHeights.addAll(List.generate(widget.barCount, (_) => 0.15));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _controller.addListener(_updateBars);

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  void _updateBars() {
    if (!widget.isPlaying) return;

    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        // Create smooth wave effect based on audio level
        final baseLevel = widget.audioLevel * 0.7;
        final randomFactor = _random.nextDouble() * 0.3;
        final waveOffset =
            sin((i / widget.barCount) * pi * 2 + _controller.value * pi * 4) *
            0.2;

        _barHeights[i] = (baseLevel + randomFactor + waveOffset).clamp(
          0.1,
          1.0,
        );
      }
    });
  }

  @override
  void didUpdateWidget(AudioWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      // Animate bars down when stopped
      setState(() {
        for (int i = 0; i < _barHeights.length; i++) {
          _barHeights[i] = 0.1;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          final height = widget.height * _barHeights[index];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 3,
            height: height.clamp(3.0, widget.height),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  widget.color ?? MeloraColors.primary.withAlpha(102),
                  (widget.color ?? MeloraColors.primary).withAlpha(
                    ((widget.audioLevel * 0.7 + 0.3) * 255).round().clamp(
                      50,
                      255,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Simple equalizer bars for smaller spaces
class MiniEqualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;

  const MiniEqualizer({
    super.key,
    this.isPlaying = false,
    this.color = MeloraColors.primary,
    this.size = 16,
  });

  @override
  State<MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<MiniEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MiniEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying) {
      _controller.stop();
      _controller.value = 0;
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final value = widget.isPlaying
                  ? (((_controller.value + delay) % 1.0) * 2 - 1).abs()
                  : 0.2;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 3,
                height: widget.size * (0.3 + value * 0.7),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
