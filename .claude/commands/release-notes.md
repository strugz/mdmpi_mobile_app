---
description: Draft the chat release announcement for a published version
argument-hint: [version]
---

Draft the release announcement for `$ARGUMENTS` (default: the version in `pubspec.yaml`).

Launch the `release-scribe` agent and relay its output verbatim in chat. Do not write a file.

The format is fixed; see "Release announcement" in `CLAUDE.md`: title, nothing-to-set-up line,
the main download link, the `+sms` download link for Android 11 and below, and the office
Wi-Fi line. No change list.
