# Single source of truth: one JSON state file

All persistent app state lives in a single JSON file (`altune_state.json`): the song pool (Library + user playlists + Recent Songs), playlist definitions, the queue (stored as ordered song IDs, with a separate `transient` list for queue-only songs not in the library, plus current index, shuffle, repeat), the current song ID, and UI preferences (library sort mode, playlist sort mode). The file is schema-versioned (`v`) so future migrations can detect old formats. `MainController.saveState()` / `loadState()` are the only write/read choke points, writes create the parent directory before writing, and the loader tolerates legacy formats (`queue.songs`, `currentPlaying`).

The alternative was the previous per-domain split (`saved_library.json`, `playlists.json`, `queue.json`, `playing_info` in `SharedPreferences`, `recent_songs.json`). Rejected because:
- Multiple files each became independent sources of truth that drifted apart, producing bugs like a library song being overwritten by the playing song and newly added songs being lost on restart.
- `shared_preferences` explicitly warns it "must not be used for storing critical data" and only supports scalar types, yet it was holding the current playing song and sort preferences.

JSON files over SQLite/Isar/Hive: at this scale (hundreds of songs, no relational queries) JSON is sufficient, dependency-free, debuggable, and — importantly — the human-readable, shareable format the library backup/restore feature needs.

`LibraryExportService` owns backup and restore: `exportLibrary()` writes only Library + user-playlist songs, on demand, for sharing. `restoreLibrary()` imports from a user-selected backup JSON, merging by song and playlist id. Recent Songs are persisted (so they survive restarts) but are excluded from the backup.

`SavedLibrary.json` is now a derived artifact: it is not the live store.

Trade-offs: one file is rewritten on each state change (e.g., every play updates Recent Songs). Fine at this scale; if the library grows large, revisit with a database or per-domain files behind a single repository abstraction.
