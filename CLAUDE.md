# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run -d linux       # primary run target
flutter build linux        # production build
flutter analyze            # lint check
flutter test               # unit/widget tests
dart format lib/           # format all Dart files
```

After every code change, rebuild and relaunch with `flutter run -d linux` to verify the change works in the real app.

## Architecture

- **State**: Single `AppProvider` (`lib/providers/app_provider.dart`) using `Provider` + `ChangeNotifier`. All app-wide state lives here.
- **Git ops**: `lib/services/git_service.dart` shells out to the `git` CLI via `Process.run()`. No Dart git library — requires `git` in PATH. Errors are caught and surfaced via provider state, not exceptions.
- **UI**: Single screen (`MainScreen`) with a resizable two-pane layout — sidebar (folder/repo tree) + detail panel (tabs: Overview, Branches, Commits, Changes). No Navigator/routing.
- **Storage**: `lib/services/storage_service.dart` persists only base folder paths via `SharedPreferences`.

## CI/CD

`.github/workflows/ci.yml` runs on every push and PR:
- `flutter analyze` + `flutter test` on every push to `main` and all PRs.
- On `v*.*.*` tags: builds the Linux release bundle, packages it as `krepo_xplorer-linux-x64-<tag>.tar.gz`, and publishes a GitHub release with auto-generated notes.

To cut a release: `git tag v0.x.y && git push --tags`

## Diff view

`lib/widgets/detail/diff_view.dart` supports two modes (toggled via Settings):
- **Unified** — syntax-highlighted single-column diff.
- **Side by side** — `lib/widgets/detail/side_by_side_diff_view.dart`, pairs removed/added lines column-by-column with per-token syntax highlighting via `flutter_highlight`.

Language is detected from the `--- a/file.ext` header; 19 languages are registered on first use.

## Conventions

- Material 3 theme with seed color `0xFF4A6CF7`; respects system light/dark mode.
- New git operations go in `git_service.dart`; call them through `AppProvider`.
- New settings are persisted via `StorageService` (SharedPreferences wrapper).
