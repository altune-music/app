# Core Entities

**Song**:
The unified domain model for a track. Contains metadata (id, title, artist, album, artwork URL), an optional local file path (null = streaming only, non-null = offline available), and an optional streaming URL (fetched on-demand, expires). API responses (`SongResponse`) are mapped to `Song` at the boundary.
_Avoid_: track, item, audio, SavedSong, SongResponse, PlayingInfo

**Album**:
A collection of songs by an artist, identified by album name and artwork. Songs reference their parent album.
_Avoid_: record, release
