import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../../controllers/main_controller.dart';
import '../../models/song.dart';
import '../../utils/string_utils.dart';
import 'package:jiosaavn/jiosaavn.dart';

class SongActionsModal extends StatelessWidget {
  final Song? song;
  final SongResponse? songResponse;
  final MainController? controller;
  final bool isInLibrary;

  final VoidCallback onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onToggleLibrary;
  final VoidCallback? onRemoveFromLibrary;

  const SongActionsModal({
    super.key,
    this.song,
    this.songResponse,
    this.controller,
    this.isInLibrary = false,
    required this.onPlay,
    this.onPlayNext,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onToggleLibrary,
    this.onRemoveFromLibrary,
  });

  // cleanString(null) returns '', so the final ?? '' is redundant.
  // ponytail: one extraction point for display info, regardless of song type
  String get _songName => song?.name ?? cleanString(songResponse?.name);
  String get _songArtists =>
      song?.primaryArtists ?? cleanString(songResponse?.primaryArtists);
  String get _songAlbum => song?.album ?? cleanString(songResponse?.album.name);
  String get _songYear => song?.year ?? cleanString(songResponse?.year);
  String? get _bitrate =>
      song?.bitrate ??
      (controller != null && songResponse != null
          ? controller!.bitrateFromLinks(songResponse!.downloadUrl)
          : null);

  // ponytail: compute from controller so modal never shows stale library state
  bool get _isInLibrary {
    final id = song?.id ?? songResponse?.id;
    if (id == null || id.isEmpty || controller == null) return isInLibrary;
    return controller!.isSongInLibrary(id);
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      avatar: Icon(icon, size: 14, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bitrateText = (_bitrate != null && _bitrate!.isNotEmpty)
        ? _bitrate
        : null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.music_note),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _songName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          if (_songArtists.isNotEmpty)
                            _chip(Icons.mic, _songArtists),
                          if (_songAlbum.isNotEmpty)
                            _chip(Icons.album, _songAlbum),
                          if (_songYear.isNotEmpty)
                            _chip(Icons.calendar_today, _songYear),
                          if (bitrateText != null)
                            _chip(Icons.settings, bitrateText),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _actionTile(
            context,
            icon: Icons.play_arrow,
            label: 'Play',
            onTap: onPlay,
          ),
          if (onPlayNext != null)
            _actionTile(
              context,
              icon: Icons.queue_music,
              label: 'Play Next',
              onTap: onPlayNext!,
            ),
          if (onAddToQueue != null)
            _actionTile(
              context,
              icon: Icons.queue_play_next,
              label: 'Add to Queue',
              onTap: onAddToQueue!,
            ),
          if (_isInLibrary && onRemoveFromLibrary != null)
            _actionTile(
              context,
              icon: Icons.library_add_check,
              label: 'Remove from Library',
              onTap: onRemoveFromLibrary!,
            ),
          if (_isInLibrary &&
              onRemoveFromLibrary == null &&
              onToggleLibrary != null)
            _actionTile(
              context,
              icon: Icons.library_add_check,
              label: 'Remove from Library',
              onTap: onToggleLibrary!,
            ),
          if (!_isInLibrary && onToggleLibrary != null)
            _actionTile(
              context,
              icon: Icons.library_add_outlined,
              label: 'Add to Library',
              onTap: onToggleLibrary!,
            ),
          if (onAddToPlaylist != null && onRemoveFromPlaylist == null)
            _actionTile(
              context,
              icon: Icons.playlist_add,
              label: 'Add to Playlist',
              onTap: onAddToPlaylist!,
            ),
          if (onRemoveFromPlaylist != null)
            _actionTile(
              context,
              icon: Icons.playlist_remove,
              label: 'Remove from Playlist',
              onTap: onRemoveFromPlaylist!,
            ),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return DpadFocusable(
      debugLabel: 'SongAction $label',
      onSelect: () {
        Navigator.pop(context);
        onTap();
      },
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }
}
