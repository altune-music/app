# Save adds library entry before file completes

When a user adds a song to Library, the app adds a `Song` entry with empty `filePath` immediately, then fires an async download. The library shows the entry right away.

If the save fails or the app closes mid-save, a "ghost entry" remains (song in library but no file). This is an acceptable UX trade-off — the user sees the song in their library instantly with no loading gap.

The alternative was to wait for the download to complete before showing the entry, but that creates a confusing delay with no feedback.
