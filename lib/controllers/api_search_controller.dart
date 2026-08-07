import 'package:jiosaavn/jiosaavn.dart';
import '../../models/song.dart';
import '../../services/log_service.dart';
import '../../utils/image_quality_helper.dart';
import '../../utils/string_utils.dart';

/// Owns API search and streaming URL resolution.
///
/// Extracted from MainController so browsing logic is isolated from
/// playback orchestration and local persistence.
class ApiSearchController {
  final JioSaavnClient client;

  ApiSearchController({required this.client});

  SongResponse? _lastStreamedSong;

  SongResponse? get lastStreamedSong => _lastStreamedSong;

  Future<List<SongResponse>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    try {
      final results = await client.search.songs(query, limit: 20);
      return results.results;
    } catch (e) {
      LogService().error('Error in searchSongs', error: e);
      return [];
    }
  }

  Future<List<AlbumResponse>> searchAlbums(String query) async {
    if (query.isEmpty) return [];
    try {
      final results = await client.search.albums(query, limit: 20);
      return results.results;
    } catch (e) {
      LogService().error('Error in searchAlbums', error: e);
      return [];
    }
  }

  Future<AlbumResponse> getAlbumDetails(
    String albumId, {
    AlbumResponse? fallback,
  }) async {
    try {
      final result = await client.albums.detailsById(albumId);
      if (result.songs.isNotEmpty) {
        return result;
      }
    } catch (e) {
      LogService().error('Error in getAlbumDetails for $albumId', error: e);
    }

    if (fallback != null) {
      return AlbumResponse(
        id: fallback.id,
        name: fallback.name,
        year: fallback.year,
        url: fallback.url,
        image: fallback.image,
        primaryArtists: fallback.primaryArtists,
        artists: fallback.artists,
        featuredArtists: fallback.featuredArtists,
        songCount: fallback.songCount,
        songs: [],
      );
    }
    throw Exception('Failed to fetch album details for $albumId');
  }

  /// Convert API response to domain Song, resolving the best audio URL.
  Song songResponseToSong(SongResponse song, {String? streamUrl}) {
    final link = streamUrl ?? getBestAudioUrl(song.downloadUrl)?.link;
    return Song(
      id: song.id,
      name: cleanString(song.name),
      primaryArtists: cleanString(song.primaryArtists),
      album: song.album.name,
      year: song.year,
      imageUrl: _getBestImageUrl(song.image) ?? '',
      url: (link != null && link.isNotEmpty) ? link : null,
    );
  }

  DownloadLink? getBestAudioUrl(List<DownloadLink>? links) {
    return ImageQualityHelper.getHighestQualityDownloadLink(links);
  }

  String? _getBestImageUrl(List<DownloadLink>? images) {
    return ImageQualityHelper.getHighestQualityLink(images);
  }

  String? _getBitrate(List<DownloadLink>? links) {
    return getBestAudioUrl(links)?.quality;
  }

  String? bitrateFromLinks(List<DownloadLink>? links) => _getBitrate(links);

  /// Resolve the best streaming URL for a song, fetching details if needed.
  Future<String?> resolveStreamUrl(SongResponse song) async {
    String? url = getBestAudioUrl(song.downloadUrl)?.link;
    if (url == null || url.isEmpty) {
      final details = await client.songs.detailsById([song.id]);
      if (details.isNotEmpty) {
        url = getBestAudioUrl(details.first.downloadUrl)?.link;
      }
    }
    return url;
  }
}
