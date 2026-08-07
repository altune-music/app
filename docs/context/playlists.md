# Playlists

**Library**:
A system playlist containing songs the user has explicitly saved. Songs in Library are available offline. Cannot be deleted or renamed.
_Avoid_: collection, saved songs

**User playlist**:
A playlist created by the user. Songs added to any user playlist are available offline. Can be renamed, deleted, and have songs added/removed.
_Avoid_: custom playlist, user list

**System playlist**:
A playlist managed by the app that cannot be deleted or renamed. Library and Recent Songs are system playlists.
_Avoid_: built-in playlist, app playlist

**Recent Songs**:
A system playlist auto-populated from playback history. Capped at a maximum entries (FIFO eviction). Songs in Recent Songs are **not** available offline. The song data persists (in `altune_state.json`) so recents survive restarts, but they are excluded from the library export.
_Avoid_: history, recently played

**Queue**:
An ordered list of songs waiting to be played. Persists across app restarts (with the current index, shuffle, and repeat) so the user returns to where they left off. Shuffling is a destructive reorder of this list.
_Avoid_: up next, playlist
