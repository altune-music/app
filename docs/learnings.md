# Agent Learnings — altune

The agent's memory of **concrete discoveries**: mistakes made and how they were
fixed, project-specific gotchas, and non-obvious root causes.

This file is the *only* home for findings that are **not** already captured
elsewhere:

- General rules → `AGENTS.md`
- Behavior the user sees → `docs/specs/`
- Verification steps → `docs/code-review.md`

> **Do not restate content from those docs here.** If a lesson is a general rule,
> put it in `AGENTS.md`; if it's behavior, put it in a spec; if it's a check,
> put it in `code-review.md`. Keep this file to what those docs *don't* say.

## Mistakes & Fixes

### 2026-03-08: Backup result must stay in the dialog, not a SnackBar
- **Anti-pattern**: reporting backup/restore success/failure with a `SnackBar`
  hides the file path the moment it auto-dismisses.
- **Fix**: `BackupDialog` and `RestoreDialog` confirm inline — a success state
  shows the written/restored counts (and the path, copyable) + Done; failure
  shows an error + Retry. They stay open.
- **Gotcha**: `backupSummary` must reuse `_collectBackupData` (the same selection
  as `buildBackupPayload`) so the dialog's counts can never drift from the
  exported JSON. Restore counts come straight from `prepareRestore`'s
  `RestorePreview`, so they inherently match the file.

### 2026-03-08: Dart does not promote nullable fields via flow analysis
- **Gotcha**: `controller != null && songResponse != null` followed by
  `controller!.method()` is required for class fields — removing the `!` causes
  `unchecked_use_of_nullable_value`. Only local variables get promoted, not
  members.
- **When to use**: when the analyzer flags a `!` on a field as redundant.

### 2026-03-08: `firstWhereOrNull` is unavailable in this Dart version
- **Fix**: use `where((s) => s.id == id).firstOrNull` instead.

### 2026-03-08: DpadFocusable ignores taps, only D-pad keys
- **Symptom**: `_buildActionTile` (Backup, Restore, View on Github) did nothing
  on touch/click — `DpadFocusable.onSelect` fires only on D-pad enter/select/space.
- **Fix**: wrap the tile `Container` in `GestureDetector(onTap: onSelect)` inside
  the `DpadFocusable` so both D-pad and touch work.

### 2026-03-08: Restore did not trigger offline downloads
- **Gotcha**: restored songs had empty `filePath` (streaming-only). Fixed by
  `LibraryController.restoreSongs()`, which downloads sequentially with a delay
  to avoid API rate limits and skips songs that already have a local file.

### 2026-03-08: Restore folder JSON selection
- **Gotcha**: with multiple `*.json` in `/Restore`, `findRestoreFile()` returns
  the most-recently-modified one, so the restore dialog's path line is what lets
  the user confirm the right file. If the folder is empty, the error must name the
  folder path, not a specific filename.

### 2026-08-06: Android play button does not toggle in mini/full player
- **Symptom**: tapping play on a local song started audio, but the play/pause icon stayed on play in `MiniPlayer` and `PlayerScreen`.
- **Root cause**: `album_detail_screen.dart` tablet sidebar bypassed `PlayerManager` and read `widget.controller.audioPlayer.playing` directly. The app uses `just_audio_media_kit`, whose backend does not report `playing` in its stream. `PlayerManager._isPlaying` was updated by `play()`/`pause()`, but the sidebar's bypass left a parallel source of truth that could desync from it.
- **Fix**: all UI now reads `playerManager.isPlaying` and calls `playerManager.play()` / `playerManager.pause()`. `PlayerManager` is the single source of truth; `AudioPlayer` is an implementation detail.
- **When to use**: whenever you are tempted to read `audioPlayer.playing`, `audioPlayer.position`, or call `audioPlayer.play()`/`pause()` from a widget or controller — route through `PlayerManager` instead.

### 2026-08-06: Restore error screen should show the Restore folder path in a copyable field
- **Problem**: the restore dialog's error state (no file found) only displayed
  the error message text with an inline Copy button that copied the *entire
  message*. The Restore folder path was embedded inside that message, not
  available as a standalone copyable field.
- **Fix**: `_loadPreview()` now resolves `LibraryExportService.restoreDirectoryPath()`
  when no file is found and stores it in `_restorePath`. The error state reuses
  the same `_pathField` (bordered text box + copy button) as other phases, so
  the folder path is copyable on its own.
- **Related**: `prepareRestore()` no longer embeds the folder path in its
  `FormatException` message — the dialog resolves and displays it separately.

## Patterns Discovered

- **No native file pickers**: backups auto-save to the Backups folder and restore
  reads any `*.json` from `/Restore` — no `file_picker`. (Full behavior is in the
  spec; the lesson is simply: don't reintroduce pickers.)
- **Both Backup and Restore use a confirmation dialog** with in-dialog result
  feedback (path + counts + copy, success/error states). Don't regress either to
  a transient SnackBar, and don't port a native file picker back in.
- **just_audio requires URIs upfront**: `AudioSource.uri()` takes a required `Uri`
  at construction. You cannot create a source and provide the URL later. This means
  the AudioPlayer playlist cannot contain songs without resolved URLs, which creates
  a length mismatch with the Dart-side queue. The simplest workaround is a
  single-source AudioPlayer (only the current song), which avoids index mapping
  entirely but means the system notification has no skip-next/skip-prev buttons.
  If you need notification skip controls, you must either resolve all URLs before
  calling `setAudioSources()`, or maintain a bidirectional index mapping between
  the filtered AudioPlayer playlist and the full queue.
- **`play()` vs `playCurrent()`**: `play()` is a no-op when the AudioPlayer has no
  sources (e.g., after app restart). For UI entry points that must work in that
  state (mini player, sidebar, full player), use `playCurrent()`, which falls
  through to `_onPlayRequested` to trigger URL resolution and playlist setup.
