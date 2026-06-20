# KRepoXplorer

**[Website](https://elkuku.github.io/KRepoXplorer/)** · [Releases](https://github.com/elkuku/KRepoXplorer/releases)

A desktop Git repository manager built with Flutter. Scan a base folder, browse all the Git repos inside it, and inspect branches, commits, working-tree changes, and diffs — all from one window.

## Features

- **Repository browser** — add one or more base folders; KRepoXplorer discovers all Git repos inside them automatically.
- **Overview tab** — current branch, remote URL, and working-tree status at a glance.
- **Branches tab** — list of local and remote branches.
- **Commits tab** — recent commit history with author and date.
- **Changes tab** — list of modified/added/deleted files with per-file diffs.
- **Diff tab** — full working-tree diff for the selected repository.
- **Unified diff** — syntax-highlighted diff with green/red line coloring.
- **Side-by-side diff** — two-column view pairing removed and added lines, with per-token syntax highlighting for 19 languages.
- **Settings** — toggle between unified and side-by-side diff modes; preference is persisted across sessions.
- **Auto-refresh** — optional 5-second polling to keep the view current.

## Supported platforms

Linux · macOS · Windows

## Getting started

```bash
flutter pub get
flutter run -d linux
```

## Building

```bash
flutter build linux    # Linux
flutter build macos    # macOS
flutter build windows  # Windows
```

## Languages with syntax highlighting

Dart · JavaScript/TypeScript · Python · Java · Kotlin · Swift · Go · Rust · C/C++ · CSS · HTML/XML · JSON · YAML · Bash · SQL · Markdown · PHP · Ruby
