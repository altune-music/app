import 'package:flutter/material.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../models/song_list_item_data.dart';
import 'song_list_item.dart';

class SearchSongListItem extends StatelessWidget {
  final SongResponse song;
  final VoidCallback onTap;
  final VoidCallback onKebabTap;

  const SearchSongListItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onKebabTap,
  });

  @override
  Widget build(BuildContext context) {
    return SongListItem(
      song: SongListItemData.fromSongResponse(song),
      onTap: onTap,
      onMenuTap: onKebabTap,
    );
  }
}
