import 'package:jiosaavn/jiosaavn.dart';
import '../models/song.dart';
import '../utils/image_quality_helper.dart';
import '../utils/string_utils.dart';

class SongListItemData {
  final String id;
  final String name;
  final String primaryArtists;
  final String imageUrl;
  final String? localArtworkPath;

  SongListItemData({
    required this.id,
    required this.name,
    required this.primaryArtists,
    required this.imageUrl,
    this.localArtworkPath,
  });

  factory SongListItemData.fromSongResponse(SongResponse song) {
    return SongListItemData(
      id: song.id,
      name: cleanString(song.name),
      primaryArtists: cleanString(song.primaryArtists),
      imageUrl: ImageQualityHelper.getSmallImageUrl(song.image) ?? '',
    );
  }

  factory SongListItemData.fromSong(Song song) {
    return SongListItemData(
      id: song.id,
      name: cleanString(song.name),
      primaryArtists: cleanString(song.primaryArtists),
      imageUrl: song.imageUrl,
      localArtworkPath: song.localArtworkPath,
    );
  }
}
