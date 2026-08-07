# Recent Songs is history-only, not offline

Recent Songs is a system playlist that tracks playback history (auto-populated, FIFO-capped). Songs in Recent Songs are **not** available offline.

The alternative was to make Recent Songs also save songs offline (like Library and user playlists). Rejected because:
- Storage cost: every streamed song would persist on disk just from being played
- User intent: history is a log, not a collection. Users expect to control what consumes storage
- Consistency: Library and user playlists represent explicit user intent to keep a song. Recent Songs does not.

The trade-off: recently played songs may be unavailable offline if the user didn't explicitly save them. This is acceptable — the user can always add to Library or a playlist to pin a song.
