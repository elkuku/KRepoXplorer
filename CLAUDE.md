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

## Diff view

Current diff display is in `lib/widgets/detail/diff_view.dart` — plain text, no syntax highlighting.

## Conventions

- Material 3 theme with seed color `0xFF4A6CF7`; respects system light/dark mode.
- New git operations go in `git_service.dart`; call them through `AppProvider`.
- New settings are persisted via `StorageService` (SharedPreferences wrapper).
