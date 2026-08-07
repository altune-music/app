import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpad/dpad.dart';
import '../interfaces/queue_repeat_mode.dart';
import '../services/player_manager.dart';
import '../services/player_ui_router.dart';
import '../widgets/artwork_image.dart';
import '../widgets/dpad_icon_button.dart';

class PlayerScreen extends StatefulWidget {
  final PlayerManager playerManager;
  final VoidCallback onOpenQueue;
  final VoidCallback onSkipPrevious;
  final VoidCallback onSkipNext;
  final VoidCallback? onKebabTap;
  const PlayerScreen({
    super.key,
    required this.playerManager,
    required this.onOpenQueue,
    required this.onSkipPrevious,
    required this.onSkipNext,
    this.onKebabTap,
  });

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    widget.playerManager.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.playerManager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _closeFullPlayer() {
    PlayerUIRouter().closeFullPlayer();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            PlayerUIRouter().hideMiniPlayer.value = false;
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxArtWidth =
                              constraints.maxWidth -
                              32; // ponytail: match horizontal padding
                          final textEstimate = 130.0;
                          final maxArtHeight =
                              (constraints.maxHeight - 48 - textEstimate).clamp(
                                0.0,
                                double.infinity,
                              );
                          final artSize = maxArtWidth < maxArtHeight
                              ? maxArtWidth
                              : maxArtHeight;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: artSize,
                                    height: artSize,
                                    child: ArtworkImage(
                                      imagePath: widget
                                          .playerManager
                                          .currentPlaying
                                          ?.localArtworkPath,
                                      imageUrl: widget
                                          .playerManager
                                          .currentPlaying
                                          ?.imageUrl,
                                      size: artSize,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget
                                              .playerManager
                                              .currentPlaying
                                              ?.title ??
                                          'No song playing',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget
                                              .playerManager
                                              .currentPlaying
                                              ?.artist ??
                                          '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DpadIconButton(
                          debugLabel: 'PlayerScreen Close',
                          onPressed: _closeFullPlayer,
                          icon: const Icon(Icons.expand_more),
                          iconSize: 28,
                          tooltip: 'Close',
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SleepTimerButton(
                              playerManager: widget.playerManager,
                            ),
                            const SizedBox(width: 8),
                            DpadIconButton(
                              debugLabel: 'PlayerScreen Queue',
                              onPressed: widget.onOpenQueue,
                              icon: const Icon(Icons.queue_music),
                              iconSize: 28,
                              tooltip: 'Queue',
                            ),
                            const SizedBox(width: 8),
                            if (widget.onKebabTap != null)
                              DpadIconButton(
                                debugLabel: 'PlayerScreen Kebab',
                                onPressed: widget.onKebabTap!,
                                icon: const Icon(Icons.more_vert),
                                iconSize: 28,
                                tooltip: 'More',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ControlsSection(
                playerManager: widget.playerManager,
                onSkipPrevious: widget.onSkipPrevious,
                onSkipNext: widget.onSkipNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepTimerButton extends StatefulWidget {
  final PlayerManager playerManager;
  const _SleepTimerButton({required this.playerManager});

  @override
  State<_SleepTimerButton> createState() => _SleepTimerButtonState();
}

class _SleepTimerButtonState extends State<_SleepTimerButton> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.playerManager.addListener(_syncTicker);
    _syncTicker();
  }

  @override
  void dispose() {
    widget.playerManager.removeListener(_syncTicker);
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    final active = widget.playerManager.hasSleepTimer;
    if (active && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
        if (!widget.playerManager.hasSleepTimer) {
          _ticker?.cancel();
          _ticker = null;
        }
      });
    } else if (!active && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.playerManager.hasSleepTimer;

    // Hide when no song loaded
    if (!active && widget.playerManager.currentPlaying == null) {
      return const SizedBox.shrink();
    }

    final remaining = widget.playerManager.sleepTimerRemaining;
    String? label;
    if (active && remaining != null) {
      label = PlayerScreen._formatDuration(remaining);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DpadIconButton(
          debugLabel: 'PlayerScreen SleepTimer',
          onPressed: () => _showTimerPicker(context),
          icon: Icon(active ? Icons.timer : Icons.timer_outlined),
          iconSize: 28,
          isSelected: active,
          tooltip: active ? 'Sleep Timer active\nTap to cancel' : 'Sleep Timer',
        ),
        if (label != null)
          Text(
            label,
            // Larger than bodySmall for better legibility next to the 28px header icon
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  void _showTimerPicker(BuildContext context) {
    if (widget.playerManager.hasSleepTimer) {
      widget.playerManager.cancelSleepTimer();
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sleep Timer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            for (final mins in [15, 30, 45, 60, 90])
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text('$mins minutes'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.playerManager.startSleepTimer(Duration(minutes: mins));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlsSection extends StatelessWidget {
  final PlayerManager playerManager;
  final VoidCallback onSkipPrevious;
  final VoidCallback onSkipNext;

  const _ControlsSection({
    required this.playerManager,
    required this.onSkipPrevious,
    required this.onSkipNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: playerManager.positionStream,
            initialData: playerManager.position,
            builder: (context, posSnapshot) {
              return StreamBuilder<Duration>(
                stream: playerManager.durationStream,
                initialData: playerManager.duration,
                builder: (context, durSnapshot) {
                  final position = posSnapshot.data ?? Duration.zero;
                  final duration = durSnapshot.data ?? Duration.zero;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(PlayerScreen._formatDuration(position)),
                          Expanded(
                            child: DpadFocusable(
                              debugLabel: 'PlayerScreen SeekBar',
                              onSelect: () {},
                              child: const SizedBox(),
                              builder: (context, state, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: state.focused
                                        ? colorScheme.secondaryContainer
                                              .withValues(alpha: 0.5)
                                        : null,
                                  ),
                                  child: Focus(
                                    onKeyEvent: (node, event) {
                                      if (event is KeyDownEvent ||
                                          event is KeyRepeatEvent) {
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowLeft) {
                                          final newMs =
                                              (position.inMilliseconds - 5000)
                                                  .clamp(
                                                    0,
                                                    duration.inMilliseconds,
                                                  );
                                          playerManager.seek(
                                            Duration(milliseconds: newMs),
                                          );
                                          return KeyEventResult.handled;
                                        }
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowRight) {
                                          final newMs =
                                              (position.inMilliseconds + 5000)
                                                  .clamp(
                                                    0,
                                                    duration.inMilliseconds,
                                                  );
                                          playerManager.seek(
                                            Duration(milliseconds: newMs),
                                          );
                                          return KeyEventResult.handled;
                                        }
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowUp) {
                                          FocusScope.of(
                                            context,
                                          ).focusInDirection(
                                            TraversalDirection.up,
                                          );
                                          return KeyEventResult.handled;
                                        }
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowDown) {
                                          FocusScope.of(
                                            context,
                                          ).focusInDirection(
                                            TraversalDirection.down,
                                          );
                                          return KeyEventResult.handled;
                                        }
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: SliderTheme(
                                      data: SliderThemeData(trackHeight: 6),
                                      child: Slider(
                                        value: duration.inMilliseconds > 0
                                            ? position.inMilliseconds
                                                  .clamp(
                                                    0,
                                                    duration.inMilliseconds,
                                                  )
                                                  .toDouble()
                                            : 0,
                                        max: duration.inMilliseconds > 0
                                            ? duration.inMilliseconds.toDouble()
                                            : 1000,
                                        onChanged: (value) {
                                          playerManager.seek(
                                            Duration(
                                              milliseconds: value.toInt(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Text(PlayerScreen._formatDuration(duration)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DpadIconButton(
                            debugLabel: 'PlayerScreen Shuffle',
                            onPressed: () => playerManager.toggleShuffle(),
                            icon: Icon(
                              playerManager.isShuffled
                                  ? Icons.shuffle
                                  : Icons.shuffle_outlined,
                            ),
                            iconSize: 28,
                            isSelected: playerManager.isShuffled,
                            tooltip: 'Shuffle',
                          ),
                          const SizedBox(width: 16),
                          DpadIconButton(
                            debugLabel: 'PlayerScreen SkipPrevious',
                            onPressed: onSkipPrevious,
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 40,
                          ),
                          const SizedBox(width: 16),
                          DpadIconButton(
                            debugLabel: 'PlayerScreen PlayPause',
                            onPressed: () {
                              if (playerManager.isPlaying) {
                                playerManager.pause();
                              } else {
                                playerManager.playCurrent();
                              }
                            },
                            icon: Icon(
                              playerManager.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                            ),
                            iconSize: 72,
                          ),
                          const SizedBox(width: 16),
                          DpadIconButton(
                            debugLabel: 'PlayerScreen SkipNext',
                            onPressed: onSkipNext,
                            icon: const Icon(Icons.skip_next),
                            iconSize: 40,
                          ),
                          const SizedBox(width: 16),
                          DpadIconButton(
                            debugLabel: 'PlayerScreen Repeat',
                            onPressed: () => playerManager.cycleRepeatMode(),
                            icon: Icon(
                              // Spotify/YouTube pattern: same icon for off/all, number for one
                              playerManager.repeatMode == QueueRepeatMode.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                            ),
                            iconSize: 28,
                            isSelected:
                                playerManager.repeatMode != QueueRepeatMode.off,
                            tooltip:
                                playerManager.repeatMode == QueueRepeatMode.off
                                ? 'Repeat Off'
                                : playerManager.repeatMode ==
                                      QueueRepeatMode.all
                                ? 'Repeat All'
                                : 'Repeat One',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
