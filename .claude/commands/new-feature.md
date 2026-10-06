---
description: Plan and scaffold a new feature in the canonical order (Model → DTO/Mapper → Repository → Service → Controller → Binding → UI → Route)
argument-hint: <domain> <FeatureName> [one-line purpose]
---

Create a new feature: `$ARGUMENTS`.

Domain is the first word (logistics, collection, service, inhouse, personalization, common). FeatureName is PascalCase.

Steps:
1. Run the `feature-planner` agent with the arguments and wait for the plan.
2. Show the plan to the user as a numbered checklist and pause for confirmation **only** if it introduces a new SQLite table, a new `/api4` endpoint, or a Firebase dependency. Otherwise proceed.
3. Scaffold in this order, one file per step, copying the pattern from the reference file the plan names:
   1. `lib/features/<domain>/models/<snake>_model.dart`
   2. `lib/features/<domain>/dtos/` + `mappers/`
   3. DAO + `db_schema.dart` (only if local persistence is planned)
   4. `lib/data/repositories/<context>/<snake>_repository.dart` returning `Result<T>`
   5. Service interface + implementation (only if cross-cutting)
   6. Controller with constructor-injected dependencies
   7. `Get.lazyPut(..., fenix: true)` lines in `lib/bindings/app/general_bindings.dart`, placed after the repositories they depend on, inside or outside the Firebase guard as the plan says
   8. Screen/page widgets with a single bottom-inset pad at the outermost bottom widget
   9. `BRoutes.<camel>` + `GetPage` in `AppRoutes.pages`
   10. Tests: mapper test, DAO test (if any), widget test under `test/features/<domain>/`
4. Run `/check`.
5. Add a doc stub at `docs/modules/<slug>/README.md` and an index line in `docs/README.md`.

Rules: no `print()`, no repo instantiation inside controllers, no `/api3`, every file must compile on Windows and Android. Do not commit.
