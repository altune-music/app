import 'package:flutter/material.dart';
import '../../controllers/main_controller.dart';
import '../../services/player_manager.dart';
import '../widgets/playlist_picker_content.dart';
import '../widgets/song_actions_modal.dart';

/// Player kebab menu bottom sheet.
///
/// ponytail: extracted from duplicated _buildPlayerKebab in app_layout.dart
/// and album_detail_screen.dart.
class PlayerKebabMenu extends StatelessWidget {
  final PlayerManager playerManager;
  final MainController controller;

  const PlayerKebabMenu({
    super.key,
    required this.playerManager,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final info = playerManager.currentPlaying;
    if (info == null) return const SizedBox.shrink();
    final ctx = context;

    return SongActionsModal(
      song: info,
      controller: controller,
      onPlay: () {
        playerManager.seek(Duration.zero);
        playerManager.play();
      },
      onToggleLibrary: () => controller.toggleCurrentInLibrary(),
      onAddToPlaylist: () {
        Navigator.pop(ctx);
        showModalBottomSheet(
          context: ctx,
          isScrollControlled: true,
          builder: (ctx) => PlaylistPickerContent(
            playlists: controller.playlists,
            onSelectPlaylist: (playlist) {
              Navigator.pop(ctx);
              final current = playerManager.currentPlaying;
              final dl = controller.localSongs
                  .where((d) => d.id == current?.id)
                  .firstOrNull;
              if (dl != null) {
                controller.addToPlaylist(dl, playlist);
              }
            },
          ),
        );
      },
    );
  }
}
