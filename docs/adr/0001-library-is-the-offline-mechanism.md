# Library is the offline mechanism

Library membership is the sole user-facing way to save songs for offline playback. There is no separate "pin" or "download" concept. Adding a song to Library (or any user playlist) triggers the offline save; removing it from all playlists triggers deletion.

This couples "collection" with "storage" — a song cannot be in Library without being offline, and cannot be deleted while in Library. The alternative was a separate download/pin feature decoupled from playlist membership, but that adds UI complexity and a second mental model for users to track.

User playlists also save songs offline, so the file lifecycle is: deleted only when the song is in zero Library + user playlist memberships.
