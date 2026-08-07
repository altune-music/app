import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../services/player_manager.dart';
import '../widgets/artwork_image.dart';
import '../widgets/dpad_icon_button.dart';

class SidebarPlayer extends StatefulWidget {
  final PlayerManager playerManager;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onTap;
  final VoidCallback? onToggleLibrary;
  final bool Function(String songId)? isSongInLibrary;

  const SidebarPlayer({
    super.key,
    required this.playerManager,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onTap,
    this.onToggleLibrary,
    this.isSongInLibrary,
  });

  @override
  State<SidebarPlayer> createState() => _SidebarPlayerState();
}

class _SidebarPlayerState extends State<SidebarPlayer> {
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

  @override
  Widget build(BuildContext context) {
    final info =
        widget.playerManager.currentPlaying ??
        widget.playerManager.lastPlayedSong;
    if (info == null) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: DpadFocusable(
                debugLabel: 'SidebarPlayer Artwork',
                onSelect: widget.onTap,
                child: const SizedBox(),
                builder: (context, state, child) {
                  return GestureDetector(
                    onTap: widget.onTap,
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final artSize =
                                    constraints.maxWidth < constraints.maxHeight
                                    ? constraints.maxWidth
                                    : constraints.maxHeight;
                                return DecoratedBox(
                                  decoration: state.focused
                                      ? BoxDecoration(
                                          border: Border.all(
                                            color: colorScheme.secondary,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        )
                                      : const BoxDecoration(),
                                  position: DecorationPosition.foreground,
                                  child: SizedBox(
                                    width: artSize,
                                    height: artSize,
                                    child: ArtworkImage(
                                      imagePath: info.localArtworkPath,
                                      imageUrl: info.imageUrl,
                                      size: artSize,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          info.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.artist,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.onToggleLibrary != null) ...[
                    const SizedBox(width: 4),
                    DpadIconButton(
                      debugLabel: 'SidebarPlayer ToggleLibrary',
                      onPressed: widget.onToggleLibrary!,
                      icon: Icon(
                        (widget.playerManager.currentPlaying != null
                                ? (widget.isSongInLibrary?.call(
                                        widget.playerManager.currentPlaying!.id,
                                      ) ??
                                      false)
                                : false)
                            ? Icons.library_add_check
                            : Icons.library_add_outlined,
                      ),
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      showCircleBackground: true,
                      isSelected: widget.playerManager.currentPlaying != null
                          ? (widget.isSongInLibrary?.call(
                                  widget.playerManager.currentPlaying!.id,
                                ) ??
                                false)
                          : false,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<Duration>(
              stream: widget.playerManager.positionStream,
              builder: (context, posSnapshot) {
                return StreamBuilder<Duration>(
                  stream: widget.playerManager.durationStream,
                  builder: (context, durSnapshot) {
                    final position = posSnapshot.data ?? Duration.zero;
                    final duration = durSnapshot.data ?? Duration.zero;
                    return LinearProgressIndicator(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds.toDouble() /
                                duration.inMilliseconds.toDouble()
                          : 0,
                      backgroundColor: colorScheme.secondaryContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DpadIconButton(
                  debugLabel: 'SidebarPlayer SkipPrevious',
                  onPressed: widget.onSkipPrevious,
                  icon: const Icon(Icons.skip_previous),
                  showCircleBackground: true,
                ),
                DpadIconButton(
                  debugLabel: 'SidebarPlayer PlayPause',
                  onPressed: widget.onPlayPause,
                  icon: Icon(
                    widget.playerManager.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 36,
                  ),
                  iconSize: 36,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  showCircleBackground: true,
                ),
                DpadIconButton(
                  debugLabel: 'SidebarPlayer SkipNext',
                  onPressed: widget.onSkipNext,
                  icon: const Icon(Icons.skip_next),
                  showCircleBackground: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
