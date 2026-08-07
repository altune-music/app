# altune

## Commands

```bash
# Test
flutter test

# Format
dart format .                 # Format all Dart code

# Build
flutter build apk --release   # Android release APK
```

## Rules

### General

- **Never auto-commit.** Wait for user to explicitly say "commit" or "commit this".
- **Tests for every change.** Include or update tests. Run `flutter test` before finishing.
- **Prefer unit tests over widget tests.** Unit-test logic where it lives — services, controllers, models, pure helpers — so behavior is verified without booting a widget tree. Reserve widget tests for UI behavior that genuinely can't be checked any other way (e.g., a dialog opening, focus/navigation). Widget tests that just assert text/layout are a smell; push that logic down into a testable unit instead. Mock platform channels (e.g. `path_provider`, clipboard) rather than spawning native dialogs, which hang headless test runners.
- **Document *why*, not *what*.** Inline comments must explain intent, trade-offs, and non-obvious decisions. Obvious code needs no comment.
- **Use existing code first.** Check `lib/utils/`, `lib/interfaces/`, and existing patterns before writing new helpers. Reuse over reimplement.
- **Single source of truth for state.** Mutable app state (playback, queue, settings, UI flags) lives in one owner — typically a `ChangeNotifier` or controller. UI reads from that owner and never reaches past it to read or mutate implementation details directly. Bypassing the owner creates parallel state that silently desyncs.
- **Log with LogService.** Use `LogService().debug()` and `LogService().error()` instead of `print` or `debugPrint`.
- **Keep docs separated; never duplicate across them.**
  - General rules and conventions → `AGENTS.md`
  - Behavior the user sees (no code, no class names) → `docs/specs/` (GEARS)
  - Verification steps → `docs/code-review.md`
  - Concrete mistakes, root causes, and project gotchas → `docs/learnings.md`
  - Before writing a note in any doc, check the others so each fact lives in exactly one place. `docs/learnings.md` must **not** restate rules, spec behavior, or checklist items already covered elsewhere — it exists only for discoveries those docs don't contain.
- **Update your memory after every task.** Append new patterns, mistakes, and domain terms to `docs/learnings.md` (and to `AGENTS.md`/specs/`code-review.md` when the finding is a general rule, behavior, or a check — not a one-off discovery). This is how the agent evolves with the project.
- **Be lazy, not careless.** Use the ponytail skill (`/ponytail`) — reach for stdlib before custom code, reuse over reimplement, delete before adding. Mark deliberate simplifications with `// ponytail:` comments.
- **Review before finishing.** Run `dart format`, `flutter analyze`, and `flutter test`. Check domain terms against [context.md](docs/context.md). Update the relevant spec. See [docs/code-review.md](docs/code-review.md) for the full checklist.

### Workflow

For any code change, follow these steps in order.

**Step 0 — Decide: write a spec or skip?**

| Change type | Spec? | Why |
|-------------|-------|-----|
| Bug fix | Yes, if the bug reveals missing/incorrect behavior | Captures what *should* happen |
| New feature | Yes | Defines acceptance criteria before coding |
| Refactor | No | Behavior doesn't change, only structure |
| Typo / minor fix | No | Too small to warrant a spec |
| Pattern change | Yes | Affects multiple files, needs clear boundaries |

**Steps 1–6** (for changes that need a spec or have meaningful scope):

1. **Spec.** Read the relevant `.spec.md` in `docs/specs/`. If no spec exists and the change warrants one, write it first in GEARS format. See [spec-format.md](docs/spec-format.md). Check `docs/context.md` for domain terms.
2. **Plan.** Identify the files to change. Check `lib/utils/` and `lib/interfaces/` for existing helpers to reuse.
3. **Implement.** Use the ponytail ladder — smallest change that works. No unrequested abstractions.
4. **Verify.** Run `dart format`, `flutter analyze`, and `flutter test`. Fix any issues before moving on.
5. **Review.** Run through the [code review checklist](docs/code-review.md).
6. **Remember.** Append new patterns, mistakes, or domain terms to the right doc — see the doc-separation rule above. `docs/learnings.md` is for one-off discoveries only; general rules go in `AGENTS.md`, behavior in `docs/specs/`, checks in `docs/code-review.md`.

**For small changes** (typo, one-line fix, minor adjustment): skip the spec and go straight to steps 3–6.

### Specs

- **Specs first.** Read the relevant `.spec.md` in `docs/specs/` before writing code. Update it to reflect new behavior *before* writing code. Specs document what the user sees — no code, class names, or technical specs. Use [context.md](docs/context.md) for canonical terminology.
- **Review spec changes before committing.** Whenever a `.spec.md` is modified, review the diff and confirm every new criterion describes behavior the user sees — not implementation details, class names, or internal architecture. If a change only documents how something is built, it does not belong in a spec.
- **Specs state present behavior, not absent bugs.** Never write negative criteria like "shall not crash" — a spec describes behavior that exists, not what it avoids.
- **Check ADRs.** Read `docs/adr/` before flagging design issues — some decisions are intentional.
- **GEARS format.** See [docs/spec-format.md](docs/spec-format.md) for the spec syntax.

## Project Map

```
├── lib/
│   ├── main.dart                          # App entry point, initialization
│   ├── controllers/
│   │   └── main_controller.dart           # Core app logic, API calls, localSongs, playlists
│   ├── screens/
│   │   ├── album_detail_screen.dart       # Album details with song list
│   │   ├── library_screen.dart            # Library and playlists screen
│   │   ├── player_screen.dart             # Full-screen player
│   │   ├── playlist_detail_screen.dart    # Playlist songs list view
│   │   ├── queue_screen.dart              # Playback queue management
│   │   ├── search_screen.dart             # Search songs/albums
│   │   └── settings_screen.dart           # Settings
│   ├── interfaces/
│   │   └── queue_repeat_mode.dart         # Repeat mode enum
│   ├── layouts/
│   │   └── app_layout.dart                # Adaptive layout scaffold (sidebar/content)
│   ├── services/
│   │   ├── log_service.dart               # Debug logging utility
│   │   ├── player_manager.dart            # Unified playback + state (AudioPlayer owner)
│   │   ├── player_ui_router.dart          # Navigation between mini/full player
│   │   └── queue_manager.dart             # Queue ordering, shuffle, repeat
│   ├── models/
│   │   ├── song.dart                      # Unified domain model for a track
│   │   ├── saved_playlist.dart            # User-created playlist model
│   │   └── song_list_item_data.dart       # UI display model for song rows
│   ├── widgets/
│   │   ├── album_list_item.dart           # Album row widget
│   │   ├── app_back_button.dart           # Shared back button (chevron_left)
│   │   ├── backup_dialog.dart             # Pre-backup confirmation dialog (path, counts, copy)
│   │   ├── restore_dialog.dart            # Pre-restore confirmation dialog (path, counts, copy)
│   │   ├── artwork_image.dart             # Image widget (local + network)
│   │   ├── dpad_icon_button.dart          # D-pad focusable icon button
│   │   ├── mini_player.dart               # Bottom player bar (mobile)
│   │   ├── pill_button.dart               # Pill-style tab button
│   │   ├── playlist_picker_content.dart   # Playlist picker bottom sheet content
│   │   ├── search_song_list_item.dart     # Song row for search results
│   │   ├── sidebar_player.dart            # Player widget in tablet sidebar
│   │   ├── song_actions_modal.dart        # Bottom sheet with Play/Queue/Library actions
│   │   ├── song_list_item.dart            # Reusable song row widget
│   │   └── tablet_sidebar.dart            # Left sidebar (tablet/TV)
│   └── utils/
│       ├── app_constants.dart             # App-wide constants
│       ├── image_quality_helper.dart      # Image URL resolution selector
│       ├── string_utils.dart              # Text cleaning helpers
│       └── tablet_utils.dart              # Screen size breakpoints
├── docs/
│   ├── context.md                         # Domain glossary index (links to topic files)
│   ├── context/                           # Domain glossary topic files
│   │   ├── core-entities.md
│   │   ├── playlists.md
│   │   ├── playback.md
│   │   ├── offline.md
│   │   ├── persistence.md
│   │   ├── screens-ui.md
│   │   ├── layout.md
│   │   ├── actions.md
│   │   ├── controls.md
│   │   ├── ui-elements.md
│   │   └── dpad.md
│   ├── learnings.md                       # One-off discoveries only (mistakes, root causes, gotchas) — never duplicates AGENTS.md/specs/code-review.md
│   ├── spec-format.md                     # GEARS spec syntax reference
│   ├── specs/                             # Behavioral specifications (GEARS format)
│   │   ├── browsing.spec.md
│   │   ├── library.spec.md
│   │   ├── playback.spec.md
│   │   └── ui.spec.md
│   └── adr/                               # Architecture Decision Records
├── test/                                  # Unit tests (mirrors lib/ structure)
├── assets/
│   └── app_icon.svg                       # Source icon
├── android/                               # Android platform config
└── linux/                                 # Linux platform config
```
