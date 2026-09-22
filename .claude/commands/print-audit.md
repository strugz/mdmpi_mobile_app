---
description: Find print() calls and /api3 references in lib/ and replace prints with logDebug()
argument-hint: [--fix]
allowed-tools: Bash(grep:*), Bash(flutter analyze:*)
---

Audit forbidden patterns in `lib/`.

1. `grep -rn "print(" lib --include=*.dart` excluding `debugPrint`, `logDebug`, and comment lines.
2. `grep -rn "/api3" lib --include=*.dart`.
3. `grep -rn "viewInsets.bottom > 0" lib --include=*.dart`.

If `$ARGUMENTS` contains `--fix`:
- Replace each `print(x)` with `logDebug(x)` and add `import 'package:mdmpi_mobile_app/base/utils/logger.dart';` if missing (match the import style already used in that file).
- Do not touch `bin/` or `tool/`; prints there are expected.
- Do not auto-fix `/api3` or `viewInsets` hits; list them for the user.
- Run `flutter analyze`.

Report a table: file, line, pattern, action taken.
