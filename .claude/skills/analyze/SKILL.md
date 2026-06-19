---
name: analyze
description: Run flutter analyze and surface all issues with file locations. Use after a batch of edits to catch lint errors before running the app.
---

Run `flutter analyze` in the project root and report the results.

- If there are no issues, say so briefly.
- If there are issues, list them grouped by file with the error message and line number.
- Suggest fixes for any errors that are straightforward (unused imports, missing types, deprecated APIs).
- Do not auto-fix — just report and suggest.
