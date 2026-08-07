import 'package:flutter/material.dart';
import '../../controllers/main_controller.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../widgets/playlist_picker_content.dart';

/// Show the playlist picker bottom sheet for adding a streaming song.
///
/// ponytail: replaces copy-pasted PlaylistPickerContent + create-and-add
/// logic that appeared in search, album detail, and player kebab.
Future<void> showPlaylistPicker(
  BuildContext context,
  SongResponse song,
  MainController controller, {
  VoidCallback? onAdded,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => PlaylistPickerContent(
      playlists: controller.playlists,
      onSelectPlaylist: (playlist) {
        Navigator.pop(context);
        controller.addStreamingSongToPlaylist(song, playlist);
        onAdded?.call();
      },
    ),
  );
}
