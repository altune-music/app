import 'package:html_character_entities/html_character_entities.dart';

/// Unified domain model for a track.
///
/// Represents a song regardless of its state (streaming-only, offline, or both).
/// API responses (`SongResponse`) are mapped to `Song` at the boundary.
///
/// - `filePath`: null = streaming only, non-null = offline available (persistent)
/// - `url`: temporary streaming URL, fetched on-demand, expires
class Song {
  final String id;
  final String? name;
  final String? primaryArtists;
  final String? album;
  final String? filePath;
  final String imageUrl;
  final String? localArtworkPath;
  final String? bitrate;
  final String? year;
  final DateTime dateAdded;
  final String? url;

  Song({
    required this.id,
    this.name,
    this.primaryArtists,
    this.album,
    this.filePath,
    this.imageUrl = '',
    this.localArtworkPath,
    this.bitrate,
    this.year,
    DateTime? dateAdded,
    this.url,
  }) : dateAdded = dateAdded ?? DateTime.now();

  /// Display title (empty string if null).
  String get title => name ?? '';

  /// Display artist (empty string if null).
  String get artist => primaryArtists ?? '';

  /// Whether this song has a persistent local file (offline available).
  bool get isOffline => filePath != null && filePath!.isNotEmpty;

  /// Whether this song has local artwork.
  bool get hasLocalArtwork =>
      localArtworkPath != null && localArtworkPath!.isNotEmpty;

  /// Create a copy with updated fields.
  Song copyWith({
    String? id,
    String? name,
    String? primaryArtists,
    String? album,
    String? filePath,
    String? imageUrl,
    String? localArtworkPath,
    String? bitrate,
    String? year,
    DateTime? dateAdded,
    String? url,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryArtists: primaryArtists ?? this.primaryArtists,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      imageUrl: imageUrl ?? this.imageUrl,
      localArtworkPath: localArtworkPath ?? this.localArtworkPath,
      bitrate: bitrate ?? this.bitrate,
      year: year ?? this.year,
      dateAdded: dateAdded ?? this.dateAdded,
      url: url ?? this.url,
    );
  }

  /// Create from JSON.
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String? ?? '',
      name: _decodeHtml(json['name'] as String?),
      primaryArtists: _decodeHtml(json['primaryArtists'] as String?),
      album: _decodeHtml(json['album'] as String?),
      filePath: json['filePath'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      localArtworkPath: json['localArtworkPath'] as String?,
      bitrate: json['bitrate'] as String?,
      year: json['year'] as String?,
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded'] as String)
          : null,
      url: json['url'] as String?,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryArtists': primaryArtists,
      'album': album,
      'filePath': filePath,
      'imageUrl': imageUrl,
      'localArtworkPath': localArtworkPath,
      'bitrate': bitrate,
      'year': year,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  /// Decode HTML entities (e.g., &amp; → &).
  static String? _decodeHtml(String? text) {
    if (text == null || text.isEmpty) return null;
    return HtmlCharacterEntities.decode(text);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';
}
