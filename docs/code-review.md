# Code Review Checklist

Run this checklist after every code change. Each item is a quick check — not a deep audit.

## 1. Analysis

- [ ] `flutter analyze` passes with no errors or warnings
- [ ] No new lint violations introduced
- [ ] `dart format --set-exit-if-changed .` passes (no formatting changes needed)

## 2. Tests

- [ ] Tests added or updated for the change
- [ ] **Prefer unit tests over widget tests** — test logic in services/controllers/models directly; use widget tests only for UI behavior that can't be checked otherwise (dialogs, focus, navigation)
- [ ] Platform channels (`path_provider`, clipboard, etc.) are mocked in tests — never call into native pickers/dialogs that hang headless runners
- [ ] `flutter test` passes (all tests, not just the changed one)
- [ ] Test file mirrors the `lib/` structure (e.g., `lib/services/foo.dart` → `test/services/foo_test.dart`)

## 3. Domain Language

- [ ] All domain terms match [context.md](docs/context.md) (e.g., `Song` not `Track`, `Library` not `saved songs`)
- [ ] No new domain terms introduced without adding them to context.md

## 4. Spec Compliance

- [ ] Relevant spec in `docs/specs/` was read before coding
- [ ] Spec updated to reflect new behavior (if behavior changed)
- [ ] Spec uses GEARS format (see [spec-format.md](spec-format.md))

## 5. Code Quality

- [ ] Uses existing helpers from `lib/utils/` and `lib/interfaces/` before writing new ones
- [ ] `LogService().debug()` / `LogService().error()` used instead of `print` / `debugPrint`
- [ ] Comments explain *why*, not *what*
- [ ] No unrequested abstractions (no interface with one implementation, no factory for one product)
- [ ] No new dependencies added unless necessary

## 6. Memory

- [ ] New patterns, mistakes, or domain terms appended to the correct doc (see doc-separation rule in `AGENTS.md`)
- [ ] `docs/learnings.md` contains only one-off discoveries — no restating of rules/specs/checklist already in `AGENTS.md`/`docs/specs/`/`docs/code-review.md`
- [ ] Significant conventions added to `AGENTS.md` if they apply project-wide
