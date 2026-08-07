/// A playlist definition stored in `altune_state.json` playlists array.
///
/// `songIds` are references into the `songs` metadata pool — not copies.
/// Multiple playlists (including Library and Recent Songs) can share the same song.
class SavedPlaylist {
  final String id;
  final String name;
  final List<String> songIds;
  final String? coverImageUrl;
  final bool isSystem;

  SavedPlaylist({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.coverImageUrl,
    this.isSystem = false,
  });

  factory SavedPlaylist.fromJson(Map<String, dynamic> json) => SavedPlaylist(
    id: json['id'] as String,
    name: json['name'] as String,
    songIds: (json['songIds'] as List?)?.cast<String>() ?? [],
    coverImageUrl: json['coverImageUrl'] as String?,
    isSystem: json['isSystem'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'coverImageUrl': coverImageUrl,
    'isSystem': isSystem,
  };
}
