---
description: Run flutter analyze and flutter test (optionally scoped) and report pass/fail with verbatim errors
argument-hint: [test path or glob]
allowed-tools: Bash(flutter analyze:*), Bash(flutter test:*), Bash(git diff:*), Bash(git ls-files:*)
---

Verify the current working tree.

1. Run `flutter analyze` on the whole project.
2. If `$ARGUMENTS` is given, run `flutter test $ARGUMENTS`. Otherwise:
   - collect changed and untracked files (`git diff --name-only; git ls-files --others --exclude-standard`),
   - run the matching `*_test.dart` files first (mirror `lib/` path under `test/`),
   - include `test/common/widgets/bottom_inset_test.dart` if any UI file changed,
   - then run the full `flutter test`.
3. Do not run `flutter build`.

Report `analyze: PASS/FAIL` and `tests: PASS (n)/FAIL`, with any failing output verbatim in a code block. Never say it passed unless the command ran in this session.
