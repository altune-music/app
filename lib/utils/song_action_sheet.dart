import 'package:jiosaavn/jiosaavn.dart';
import 'package:flutter/material.dart';
import '../../controllers/main_controller.dart';
import '../widgets/song_actions_modal.dart';
import 'playlist_picker_helper.dart';

/// Show a song actions bottom sheet with standard callbacks wired to [controller].
///
/// ponytail: replaces 4x copy-pasted SongActionsModal wiring across
/// library, search, album detail, and player kebab.
Future<void> showSongActionSheet(
  BuildContext context,
  SongResponse song,
  MainController controller, {
  VoidCallback? onToggleLibrary,
}) async {
  showModalBottomSheet(
    context: context,
    builder: (context) => SongActionsModal(
      songResponse: song,
      controller: controller,
      onPlay: () => controller.streamSong(song),
      onPlayNext: () => controller.streamSongAndQueueNext(song),
      onAddToQueue: () => controller.streamSongAndAddToQueue(song),
      onToggleLibrary:
          onToggleLibrary ?? () => controller.toggleSongInLibrary(song),
      onAddToPlaylist: () => showPlaylistPicker(context, song, controller),
    ),
  );
}
