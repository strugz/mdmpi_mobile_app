---
description: Review the current diff (or given files) against repo conventions using the convention-reviewer agent, then run /check
argument-hint: [files...]
---

Review scope: `$ARGUMENTS` if given, otherwise the current diff plus untracked files.

1. Launch the `convention-reviewer` agent with the scope. Ask for the ranked list and verdict.
2. In parallel, launch the `flutter-verifier` agent with the same scope.
3. Merge both results into one message:
   - blockers first, then should-fix, then nits (each `path:line`, one sentence, suggested fix),
   - analyze/test status with verbatim failures,
   - a final verdict: "safe to finish" or "needs changes".

Do not apply fixes; the user decides. Do not commit.
