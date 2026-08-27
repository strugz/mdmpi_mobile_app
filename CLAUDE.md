# CLAUDE.md

Guidance for Claude Code when working in this repository.

> **Canonical agent guide:** [AGENTS.md](AGENTS.md) is the authoritative, detailed
> agent playbook (originally maintained for Codex). Read it before non-trivial work.
> This file is a Claude Code entry point plus the deltas that differ between agents.
> `.github/copilot-instructions.md` holds the same conventions for Copilot.
> When conventions change, update AGENTS.md first and keep this file thin.

## What this project is

`mdmpi_mobile_app` — a multi-department Flutter app (Logistics, Collection, Service,
InHouse) using **GetX** for state management, DI, and routing. Targets **Android and
Windows desktop** — every change must work on both unless stated otherwise.

## Commands

```powershell
flutter pub get        # restore deps
flutter analyze        # static analysis (must pass before submitting)
flutter test           # unit/widget tests (test/*_test.dart)
flutter run            # local dev run
dart run bin/generate_module_qa.dart --name "Name" --area Logistics --routes "/route"
dart run bin/inspect_db_images.dart
```

Shell is PowerShell — chain commands with `;`, not `&&`.

## Architecture in one paragraph

DI lives in `lib/bindings/app/general_bindings.dart` (registration **order matters**;
Firestore-backed repos are wrapped in a `Firebase.apps.isNotEmpty` guard so desktop
works without FlutterFire). Early platform bootstrap is in `lib/main.dart` +
`lib/base/utils/platform_init.dart` (sqflite FFI on desktop, conditional Firebase
init). Navigation is named routes: `BRoutes` / `AppRoutes.pages` under
`lib/base/utils/routes/`, with department-based post-auth routing in
`lib/app_router.dart`. Local persistence is SQLite via `lib/data/local/`
(`database_helper.dart`, `db_schema.dart`, domain DAOs under `dao/`). Feature code is
under `lib/features/<domain>/` (controllers, screens, helpers); repositories under
`lib/data/repositories/<context>/`.

## Non-negotiable conventions

- New feature order: Model → DTO/Mapper → Repository → Service → Controller →
  Binding (in `GeneralBindings`) → UI → Route (`BRoutes` + `AppRoutes.pages`).
- Register with `Get.lazyPut(..., fenix: true)`; resolve with `Get.find()`. Never
  instantiate repositories inside controllers. Never move/rename `GeneralBindings`.
- No `print()` — use `logDebug()` (`lib/base/utils/logger.dart`) or `BloggerHelper`.
- Async operations return `Result<T>` (`lib/base/utils/result.dart`), not raw throws.
- No business logic in widget `build`; wrap minimal subtrees in `Obx`.
- Utility classes use the `B` prefix (`BRoutes`, `BFormatter`, `BHttpHelper`).
- Files snake_case, classes PascalCase.

## API routing boundary (do not break)

- `/api4/*` → sibling `MDMPI.App` ASP.NET backend (production-testing only).
  Debug-only local overrides: `API4_URL_WINDOWS` / `API4_URL_ANDROID`.
- `/api3/*` and everything else → live production backend (`API_URL`).
- Never redirect non-`/api4` traffic to `MDMPI.App`. See README "API Environments".

## Secrets

`.env` (from `.env.example`) is git-ignored and loaded in `main.dart`. Never commit
keys. `places_service.dart` has a legacy hardcoded key — do not copy that pattern.

## Developer-only tools (keep out of production UI)

Local Storage Data Viewer (`/local-storage-viewer`) and Signature Outbox
(`/signature-outbox`) — debug tools under Settings > Developer Tools.

## Claude Code specifics (deltas from AGENTS.md)

AGENTS.md references Codex-style `run_subagent` with agents named `Plan` and
`Search`. In Claude Code, use the **Agent tool**: `Plan` for implementation planning
and `Explore` (or `general-purpose`) for repository discovery. Everything else in
AGENTS.md applies as written.

## Docs map

- Module docs index: `docs/README.md` (per-module docs under `docs/modules/`)
- QA checklists: `qa/` (generated via `bin/generate_module_qa.dart`)
- New docs go in `docs/` unless told otherwise.
