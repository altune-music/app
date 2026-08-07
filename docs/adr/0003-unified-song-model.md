# Unified Song model

One `Song` domain type represents a track regardless of its state (streaming-only, offline, or both). `SavedSong`, `SongListItemData`, and `PlayingInfo` are eliminated.

`Song` contains:
- Metadata (id, title, artist, album, artwork URL)
- Optional `filePath` (null = streaming only, non-null = offline available)
- Optional `url` (temporary, fetched on-demand)

API responses (`SongResponse` from jiosaavn) are mapped to `Song` at the boundary — the external type stays external.

The currently playing track is a live `Song` reference plus playback state, not a frozen copy. This means metadata changes (e.g., artwork URL update) propagate to the player UI automatically.

Rejected alternatives:
- **Separate `SavedSong` / `OnlineSong` types:** Duplication of shared metadata fields. Two type hierarchies to maintain.
- **`PlayingInfo` as snapshot:** Marginal value — URLs are already fetched on-demand. Adds a type with no real benefit over a live reference.
- **`SongListItemData` for UI rows:** Extra mapping layer. UI can work with `Song` directly.
