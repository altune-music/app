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

## Release Pipeline Gotchas (2026-08-08)

- **fpm version must be the app version, not the run number**: the `3882229`
  refactor (drop AppImage, add deb/rpm) accidentally wired `github.run_number`
  into the `fpm -v` flag, so `.deb`/`.rpm` reported versions like "87" instead
  of the tag version. The same refactor also dropped the `${VERSION#v}`
  stripping (from `b0534b4`) for `--build-name`. Always re-verify version
  plumbing after a workflow refactor — it regresses silently and only shows up
  as weird package metadata.
- **deb/rpm/Android versionName reject a leading `v`**: `deb` versions must
  start with a digit; pass `${VERSION#v}` to fpm and `--build-name`, and keep
  the `v` only in artifact filenames.
- **GitHub Actions secrets: never inline-interpolate into `run:` blocks**.
  `printf "%s" "${{ secrets.X }}"` puts the secret on the process command line,
  and an unquoted heredoc with inline secrets lets a password containing `$`,
  backticks, or a literal `EOF` line inject shell. Pass secrets via `env:` and
  reference `$VAR` — expansion is single-pass so the value can't re-inject.
- **`_atomicWrite` was not atomic**: persist callbacks fire `saveState()`
  unawaited, so two `writeAsString` calls can overlap and a concurrent reader
  can hit a truncated or missing `altune_state.json` (CI-only flake in
  `library_persistence_test.dart`, passed 6/6 locally). Fixed by writing a
  sibling `.tmp` file and `rename()`-ing it into place (atomic on POSIX).
  Don't trust the name — the old implementation was a plain truncating write.

## Android Launch Crash — Context in Field Initializers (2026-08-08)

- **`MainActivity` NPE'd at launch on every device** ("Unable to instantiate
  activity ... `getPackageName()` on a null object reference"). Cause:
  `private val FILE_PROVIDER_AUTHORITY = "$packageName.fileprovider"` — a field
  initializer reads `Context.packageName`, but the framework attaches the
  Context (sets `ContextWrapper.mBase`) only AFTER the constructor returns.
  Field initializers run inside the constructor → NPE. Symptom: app dies
  before the splash/launch background ever draws.
- **Fix**: `by lazy { "$packageName.fileprovider" }` — evaluated on first use
  inside the method channel handler, where the activity is attached.
- **Gotcha**: an APK that "worked on an old phone" but crashes on a newer one
  is often the same APK never having run anywhere — verify the actual APK on
  an emulator before assuming device-specific behavior. Reproduced the crash
  on an Android 15 x86_64 AVD with `adb install` + `am start` + `logcat -b
  crash`; confirmed the fix the same way (process stays alive, 0 FATALs).
- **Emulator setup on this machine**: AVDs live under
  `~/.config/.android/avd` (XDG), so launch with
  `ANDROID_AVD_HOME=~/.config/.android/avd emulator -avd <name> -no-window
  -gpu swiftshader_indirect`. adb is on PATH via the mise android-sdk.

## Linux Build Drops --build-name/--build-number (2026-08-08)

- **`flutter build linux --build-name X --build-number Y` is silently ignored**:
  package_info_plus on Linux reads `bundle/data/flutter_assets/version.json`,
  which is generated by the `LinuxBundle` target from `environment.defines`.
  But the Linux CMake path calls `buildInfo.toEnvironmentConfig()`, which
  omits `kBuildName`/`kBuildNumber` — only `toBuildSystemEnvironment()`
  (used by Android/web/bundle_builder paths) includes them. Result:
  `version.json` always contains the pubspec version (0.0.0+0), so Settings
  shows 0.0.0 and the in-app update check compares against 0.0.0.
- **Workaround**: rewrite `version.json` after `flutter build linux`, before
  packaging (all of tarball/deb/rpm copy the bundle dir). The release
  workflow has a "Stamp version.json" step for this.
- **Verify**: `cat build/linux/x64/release/bundle/data/flutter_assets/version.json`
  after any Linux build — if it says 0.0.0, the version flags didn't land.
