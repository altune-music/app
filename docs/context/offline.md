# Offline

**Offline availability**:
A derived state: a song is available offline when it belongs to Library or any user playlist. The local file is deleted only when the song is in zero such playlists.
_Avoid_: saved, pinned, downloaded

**Stream cache**:
Temporary local storage managed by `just_audio`. All streamed songs are cached automatically. Enables offline replay for recently streamed songs (e.g., Recent Songs). Invisible to the domain model — not tracked in `Song`.
_Avoid_: cache path, temp file
