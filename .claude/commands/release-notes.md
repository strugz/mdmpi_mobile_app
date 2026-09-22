---
description: Draft the chat release announcement (card format) for commits since the last version bump
argument-hint: [version]
---

Draft the release announcement for `$ARGUMENTS` (default: the version in `pubspec.yaml`).

Launch the `release-scribe` agent and relay its output verbatim in chat. Do not write a file.

Format reminder for the agent's output:

```
<emoji> Role · Heading
One sentence on what changed. (after the server update)   <- flag only when backend-dependent
→ Screen > Section
```

Ends with a `✅` verification line and a `📦` version/share line.
