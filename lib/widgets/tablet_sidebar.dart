import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dpad/dpad.dart';
import '../utils/app_constants.dart';
import 'sidebar_player.dart';
import 'dpad_icon_button.dart';
import '../services/player_manager.dart';

class TabletSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final PlayerManager playerManager;
  final VoidCallback? onPlayPause;
  final VoidCallback? onOpenPlayer;
  final VoidCallback? onSkipPrevious;
  final VoidCallback? onSkipNext;
  final VoidCallback? onToggleLibrary;
  final bool Function(String)? isSongInLibrary;

  const TabletSidebar({
    super.key,
    this.selectedIndex = 0,
    required this.onItemSelected,
    required this.playerManager,
    this.onPlayPause,
    this.onOpenPlayer,
    this.onSkipPrevious,
    this.onSkipNext,
    this.onToggleLibrary,
    this.isSongInLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = (screenWidth * 0.30).clamp(
      AppConstants.sidebarMinWidthDp,
      AppConstants.sidebarMaxWidthDp,
    );

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: AppConstants.sidebarMinWidthDp,
          maxWidth: sidebarWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/app_icon_logo.svg',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DpadRegion(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DpadIconButton(
                      debugLabel: 'Sidebar Search',
                      onPressed: () => onItemSelected(1),
                      icon: const Icon(Icons.search),
                      isSelected: selectedIndex == 1,
                      showCircleBackground: true,
                    ),
                    const SizedBox(width: 8),
                    DpadIconButton(
                      debugLabel: 'Sidebar Library',
                      onPressed: () => onItemSelected(0),
                      icon: const Icon(Icons.library_music),
                      isSelected: selectedIndex == 0,
                      showCircleBackground: true,
                      entry: true,
                    ),
                    const SizedBox(width: 8),
                    DpadIconButton(
                      debugLabel: 'Sidebar Settings',
                      onPressed: () => onItemSelected(2),
                      icon: const Icon(Icons.settings),
                      isSelected: selectedIndex == 2,
                      showCircleBackground: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DpadRegion(
                verticalEdge: DpadEdgeBehavior.leave,
                child: SidebarPlayer(
                  playerManager: playerManager,
                  onPlayPause: onPlayPause ?? () {},
                  onSkipPrevious: onSkipPrevious ?? () {},
                  onSkipNext: onSkipNext ?? () {},
                  onTap: onOpenPlayer ?? () {},
                  onToggleLibrary: onToggleLibrary,
                  isSongInLibrary: isSongInLibrary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
