import 'package:flutter/material.dart';

/// Animated equalizer bars indicating a song is currently playing.
///
/// Modeled on the Spotify/Apple Music "now playing" cue: a set of vertical
/// bars whose heights oscillate while playing and freeze when paused. A single
/// repeating [AnimationController] drives all bars so the whole indicator is
/// one animation pass (no per-bar setState rebuild loop).
class EqualizerBars extends StatefulWidget {
  /// Whether playback is active. When false the bars freeze so the indicator
  /// doubles as a play/pause signal.
  final bool playing;
  final Color? color;
  final double size;
  final int barCount;

  const EqualizerBars({
    super.key,
    required this.playing,
    this.color,
    this.size = 20,
    this.barCount = 3,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.playing) {
      _controller.repeat();
    } else {
      // Freeze on a representative mid-height so paused still reads clearly.
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Height for a bar at index [i], derived from the shared controller value.
  // Phase offsets stagger the bars so they oscillate out of sync (more like
  // real audio) instead of moving in lockstep.
  double _barHeight(int i, double t) {
    final phase = (t + i * 0.33) % 1.0;
    final wave = (phase < 0.5) ? phase * 2 : (1 - phase) * 2; // triangle wave
    return 0.3 + 0.7 * wave;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final barWidth = widget.size / widget.barCount / 2;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.barCount; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      heightFactor: _barHeight(i, _controller.value),
                      child: Container(
                        width: barWidth,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
