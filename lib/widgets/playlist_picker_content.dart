import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../models/saved_playlist.dart';

class PlaylistPickerContent extends StatelessWidget {
  final List<SavedPlaylist> playlists;
  final void Function(SavedPlaylist playlist) onSelectPlaylist;

  const PlaylistPickerContent({
    super.key,
    required this.playlists,
    required this.onSelectPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final userPlaylists = playlists.where((p) => !p.isSystem).toList();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add to playlist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (userPlaylists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No playlists yet'),
            )
          else
            ...userPlaylists.asMap().entries.map((entry) {
              final playlist = entry.value;
              return DpadFocusable(
                debugLabel: 'Playlist ${playlist.name}',
                onSelect: () => onSelectPlaylist(playlist),
                child: ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(playlist.name),
                  onTap: () => onSelectPlaylist(playlist),
                ),
              );
            }),
        ],
      ),
    );
  }
}
