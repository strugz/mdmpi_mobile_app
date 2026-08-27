# Codex → Claude Code Transition Workflow

**Date:** 2026-08-27
**Scope:** `mdmpi_mobile_app` (Flutter client). The sibling `MDMPI.App` ASP.NET repo
is out of scope but referenced where the workflows touch it.

This project was previously developed with Codex-style agents (guided by
[AGENTS.md](../AGENTS.md) and `.github/copilot-instructions.md`). This document
records how the project is now set up for Claude Code, what maps to what, and the
standard workflows going forward.

---

## 1. What was set up

| Item | Status |
|---|---|
| [CLAUDE.md](../CLAUDE.md) at repo root | **Created** — Claude Code's auto-loaded project context; thin entry point that defers to AGENTS.md |
| AGENTS.md | Kept as-is — remains the canonical, detailed agent playbook |
| `.github/copilot-instructions.md` | Kept as-is — Copilot continues to work unchanged |
| `.env` | **Created from `.env.example`** (was missing; `pubspec.yaml` declares it as an asset, so `flutter test`/`flutter run` fail without it). Placeholder values — fill in real keys before exercising API/AI flows |
| Dependencies | `flutter pub get` verified working (Flutter 3.41.4 stable, Dart 3.11.1) |

### Health baseline (2026-08-27)

- `flutter analyze`: **0 errors, 0 warnings, 94 info-level lints** (mostly
  `avoid_print` in `bin/`/`tool/` utilities, which is expected per AGENTS.md).
  Exit code is non-zero because of the infos — treat new errors/warnings as the
  regression signal, not the info count.
- `flutter test`: **38 passed, 6 failed** (pre-existing). Failing:
  `test/ai_agent_test.dart` (load error), `test/pull_out_model_from_json_test.dart`
  (load error), `test/request_dao_insert_test.dart` (setUpAll/tearDownAll),
  `test/standard_delivery_insert_mapper_test.dart`, and the template
  `test/widget_test.dart` counter smoke test. These predate the transition; fix or
  quarantine them in a dedicated task so the suite becomes a reliable gate.

### Guidance-file hierarchy (single source of truth)

```
AGENTS.md                      ← canonical: full conventions, DI gotchas, key files
├─ CLAUDE.md                   ← Claude Code entry point + Claude-specific deltas
└─ .github/copilot-instructions.md  ← Copilot mirror
```

**Rule:** when a convention changes, update AGENTS.md first, then sync the two
mirrors only if the change affects them. Do not let the three files diverge into
competing sources of truth.

## 2. Concept mapping: Codex → Claude Code

| Codex concept | Claude Code equivalent |
|---|---|
| `AGENTS.md` auto-context | `CLAUDE.md` auto-context (now points into AGENTS.md) |
| `run_subagent(agentName: "Plan", ...)` | Agent tool, `subagent_type: "Plan"` |
| `run_subagent(agentName: "Search", ...)` | Agent tool, `subagent_type: "Explore"` (or `general-purpose`) |
| Session memory | Persistent per-project memory directory + CLAUDE.md |
| Task instructions in prompt | Same, plus skills/slash commands (`/code-review`, `/security-review`, etc.) |

## 3. Standard workflows with Claude Code

### 3.1 New feature module (the established generation order)

1. **Plan** — for multi-step work, have Claude enter plan mode or spawn the `Plan`
   agent; verify the plan respects the DI ordering in `GeneralBindings`.
2. **Model → DTO/Mapper → Repository → Service → Controller → Binding → UI → Route**
   (unchanged from AGENTS.md).
3. Register in `lib/bindings/app/general_bindings.dart` with
   `Get.lazyPut(..., fenix: true)`; Firestore-backed repos inside the Firebase
   guard, REST+local-DB repos outside it.
4. Add route constants to `BRoutes` and a `GetPage` to `AppRoutes.pages`.
5. Generate QA scaffolding:
   `dart run bin/generate_module_qa.dart --name "Name" --area Logistics --routes "/route"`
6. Add/update module doc under `docs/modules/<slug>/` and the index in `docs/README.md`.

### 3.2 Every change, before submitting

```powershell
flutter analyze
flutter test
```

Both must pass. Claude Code runs these itself — expect it to report the real
output, including failures.

### 3.3 Review workflows

- `/code-review` — correctness/quality review of the current diff or a branch.
- `/security-review` — security pass on pending branch changes (relevant here:
  `.env` key handling, the legacy hardcoded key in `places_service.dart`, API
  routing boundary).

### 3.4 Full-stack work (with MDMPI.App)

Open `../MDMPI.FullStack.code-workspace`. Debug builds may use
`API4_URL_WINDOWS=http://localhost:5177` / `API4_URL_ANDROID=http://10.0.2.2:5177`
for `/api4/*` only. **Never** route `/api3/*` to the local backend.

## 4. Guardrails carried over (unchanged, enforced)

- Both **Android and Windows** targets must keep working.
- `GeneralBindings` must not be moved, renamed, or re-patterned.
- No `print()`; use `logDebug()` / `BloggerHelper`.
- Async returns `Result<T>`.
- Developer tools (Local Storage Viewer, Signature Outbox) stay hidden from
  production users.
- Never commit secrets; `flutter_ai_toolkit` / `firebase_ml_model_downloader`
  remain unpinned placeholders — pin versions when actually integrating.

## 5. Known debt Claude Code should be aware of

- `lib/common/services/implementations/places_service.dart` — hardcoded RapidAPI
  key (legacy; do not replicate).
- Empty scaffolds not registered in DI: `IAiService`/`AiService`,
  `IFeatureToggleService`/`FeatureToggleService`, `feature_guard.dart`,
  `data/repositories/backload/` (real repo is in `data/repositories/app_data/`),
  `sign_up_repository.dart`, `features/collection/domain/`.
- `RequestHotlineController` is a stub and **not** registered — don't `Get.find()` it.
- 138 packages have newer majors blocked by constraints (informational; upgrade
  deliberately, commit `pubspec.lock`).
- A stray in-widget `print` remains in `b_autocomplete_text_field.dart` (~line 193).

## 6. First-run checklist for a new machine

1. `flutter pub get`
2. Copy `.env.example` → `.env`, fill `API_URL`, `API_KEY`, AI toolkit keys.
   (Required even for tests — `.env` is a declared asset in `pubspec.yaml`.)
3. `flutter analyze` and `flutter test` to baseline.
4. `flutter run` (Windows desktop or Android emulator).
5. For `/api4` work, open the full-stack workspace and start `MDMPI.App` locally.
