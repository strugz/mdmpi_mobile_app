# .claude/ — modular Claude Code configuration

Project-level config for Claude Code. `CLAUDE.md` at the repo root stays thin; the
detail lives here and in `AGENTS.md`.

```
.claude/
├── rules/       path-scoped guidance, auto-loaded when matching files are touched
├── agents/      subagents (Agent tool / "use the X agent")
├── commands/    slash commands (/check, /review, /new-feature, ...)
└── settings.local.json   personal permissions (git-ignored, not shared)
```

## rules/

| File                    | Loads for                                          |
|-------------------------|----------------------------------------------------|
| `00-core.md`            | always                                             |
| `getx-di.md`            | bindings, controllers                              |
| `data-layer.md`         | `lib/data/**`, models, dtos, mappers               |
| `api-routing.md`        | http helpers, api env, repositories                |
| `ui-widgets.md`         | screens, pages, widgets, navigation shell          |
| `routes.md`             | `BRoutes`, `AppRoutes`, `app_router.dart`          |
| `platform-bootstrap.md` | `main.dart`, `platform_init.dart`, android/, windows/ |
| `testing.md`            | `test/**`                                          |
| `docs-qa.md`            | `docs/**`, `qa/**`, agent instruction files        |
| `collection.md`         | Collection module and its repo/tests               |

Add a rule by dropping a `.md` in `rules/` with a `paths:` frontmatter list. No `paths` means always-on.

## agents/

| Agent                 | Purpose                                                      | Read-only |
|-----------------------|--------------------------------------------------------------|-----------|
| `repo-search`         | locate symbols/routes/tables/bindings ("Search" in AGENTS.md) | yes       |
| `feature-planner`     | ordered implementation plan ("Plan" in AGENTS.md)             | yes       |
| `convention-reviewer` | diff review against repo conventions                          | yes       |
| `flutter-verifier`    | run analyze + targeted tests, report verbatim                 | yes       |
| `db-schema-auditor`   | SQLite schema/DAO/mapper/test audit                           | yes       |
| `release-scribe`      | chat release announcement in card format                      | yes       |

## commands/

| Command          | What it does                                                    |
|------------------|-----------------------------------------------------------------|
| `/check`         | `flutter analyze` + scoped then full `flutter test`             |
| `/review`        | convention review + verification of the current diff           |
| `/new-feature`   | plan and scaffold Model → ... → Route                           |
| `/new-route`     | add `BRoutes` constant + `GetPage`                              |
| `/qa`            | run `generate_module_qa.dart` and enrich the checklist          |
| `/bump-version`  | edit `pubspec.yaml` version; user commits                       |
| `/build-apk`     | release APK with JDK/Gradle env workarounds                     |
| `/release-notes` | draft the announcement since the last version bump              |
| `/print-audit`   | find `print()`, `/api3`, bad viewInsets checks; `--fix` prints  |
| `/db`            | audit a table/DAO/model or inspect DB images                    |

None of the commands commit or push. That remains a manual step.
