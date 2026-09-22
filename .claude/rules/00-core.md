# Core rules (always loaded)

- [AGENTS.md](../../AGENTS.md) is the canonical playbook. Read it before non-trivial work.
  When a convention changes, update AGENTS.md first, then keep CLAUDE.md thin.
- Every change must work on **Android and Windows desktop** unless the task says otherwise.
- Shell is PowerShell: chain with `;`, never `&&`.
- Gate Dart work on `flutter analyze` **and** `flutter test`. `flutter build windows` is
  blocked by pre-existing issues; do not treat a Windows build failure as your regression
  unless analyze/test also fail.
- Never `git commit` or `git push` unless explicitly told to. Finish, verify, report, wait.
- Never commit or stage `.env`, keystores (`*.jks`, `*.keystore`, `key.properties`),
  or spreadsheets. `places_service.dart` has a legacy hardcoded key; do not copy that pattern.
- No `print()` in `lib/`. Use `logDebug()` from `lib/base/utils/logger.dart` or `BloggerHelper`.
  Expected exceptions: `bin/*.dart`, `tool/*.dart`.
- Files snake_case, classes PascalCase, utility classes `B`-prefixed (`BRoutes`, `BFormatter`).
- New `.md` docs go in `docs/` unless told otherwise. Module docs index: `docs/README.md`.
- Search `lib/base/utils/` and `lib/common/widgets/` for an existing helper before adding one.
