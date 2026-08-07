# Persistence

**App state**:
All persistent app data in one JSON file (`altune_state.json`): the song pool (Library + user playlists + Recent Songs), playlist definitions, the queue, the currently playing song, and UI preferences (sort modes). A single source of truth, written atomically.
_Avoid_: database, store, app data

**Backup**:
A derived, on-demand JSON file containing only Library and user-playlist songs, intended for sharing or later restore. Not the live store.
_Avoid_: export, saved_library.json

**Restore**:
Importing songs and playlists from a backup JSON into the current app state. Merges by id, preserving existing entries.
_Avoid_: import, load backup
