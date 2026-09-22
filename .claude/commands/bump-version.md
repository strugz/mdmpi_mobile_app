---
description: Bump the pubspec version (patch by default) and stage nothing; prepares a "Bump version to X" change for the user to commit
argument-hint: [patch|minor|major|<explicit version>]
allowed-tools: Bash(grep:*), Bash(git log:*), Bash(git diff:*)
---

Bump the app version: `$ARGUMENTS` (default `patch`).

1. Read the current line: `grep -n '^version:' pubspec.yaml`. Format is `MAJOR.MINOR.PATCH+BUILD` or `MAJOR.MINOR.PATCH`.
2. Compute the new version. For `patch` increment PATCH; for `minor` increment MINOR and zero PATCH; for `major` increment MAJOR and zero the rest. If a `+BUILD` suffix exists, increment it by one as well. An explicit version replaces the whole value.
3. Edit only that line in `pubspec.yaml`.
4. Show `git diff pubspec.yaml`.
5. Print the suggested commit message on its own line: `Bump version to <new version>`.

Do **not** run `git add`, `git commit`, or `git push`. The user commits. Do not build.
