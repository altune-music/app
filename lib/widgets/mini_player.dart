import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../services/player_manager.dart';
import '../widgets/artwork_image.dart';
import '../widgets/dpad_icon_button.dart';

class MiniPlayer extends StatefulWidget {
  final PlayerManager playerManager;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.playerManager,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onTap,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  @override
  void initState() {
    super.initState();
    widget.playerManager.addListener(_onPlayerManagerChanged);
  }

  @override
  void dispose() {
    widget.playerManager.removeListener(_onPlayerManagerChanged);
    super.dispose();
  }

  void _onPlayerManagerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final info =
        widget.playerManager.currentPlaying ??
        widget.playerManager.lastPlayedSong;

    return StreamBuilder<Duration>(
      stream: widget.playerManager.positionStream,
      builder: (context, posSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.playerManager.durationStream,
          builder: (context, durSnapshot) {
            final duration = durSnapshot.data ?? Duration.zero;
            final position = posSnapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds.toDouble() /
                      duration.inMilliseconds.toDouble()
                : 0.0;

            final progressBar = LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 3,
            );

            if (info == null) return const SizedBox.shrink();

            return DpadFocusable(
              debugLabel: 'MiniPlayer',
              onSelect: widget.onTap,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      progressBar,
                      Expanded(
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: ArtworkImage(
                                  imagePath: info.localArtworkPath,
                                  imageUrl: info.imageUrl,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    info.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    info.artist,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            DpadIconButton(
                              debugLabel: 'MiniPlayer PlayPause',
                              onPressed: widget.onPlayPause,
                              icon: Icon(
                                widget.playerManager.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                            ),
                            DpadIconButton(
                              debugLabel: 'MiniPlayer SkipNext',
                              onPressed: widget.onSkipNext,
                              icon: const Icon(Icons.skip_next),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
