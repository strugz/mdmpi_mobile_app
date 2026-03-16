AGENTS for mdmpi_mobile_app
==========================

Purpose
-------
This file gives concise, actionable guidance for automated coding agents (Copilot-style or LLM assistants) to be productive immediately in this repo. It focuses on discoverable, enforced patterns and concrete examples found in the codebase.

Quick start (commands)
----------------------
- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Run tests: `flutter test`
- Generate module QA: `dart run bin/generate_module_qa.dart --name "My Module" --area Logistics --routes "/route"`
- Inspect DB images: `dart run bin/inspect_db_images.dart`

Important architectural notes
----------------------------
- State & DI: GetX is used everywhere. Repositories extend `GetxController` and are registered in `lib/bindings/general_bindings.dart` via `Get.lazyPut(..., fenix: true)`.
  - Example: `Get.lazyPut(() => RoleRepository(), fenix: true);`
  - Controllers resolve deps with `Get.find()` — do not instantiate repos inside controllers.
- Early/ eager registration: some platform services are registered in `lib/main.dart` using `Get.put(...)` before bindings run (notably `PermissionService`, `NotificationService`, and `AuthenticationRepository` after Firebase init). See `lib/main.dart`.
- Navigation: Named routes via `BRoutes` + `AppRoutes.pages` (under `lib/base/utils/routes`). Department-specific post-auth routing is handled by `lib/app_router.dart`.

- Note: several core services/controllers are registered eagerly via `Get.put` in `lib/bindings/general_bindings.dart` (not only in `main.dart`). Examples: `Get.put(NetworkManager())`, `Get.put(WebSocketNotificationController())`, `Get.put(MessagingController())`, and `Get.put(UserController(), permanent: true)`. Always inspect `GeneralBindings` for the exact registration style and ordering used by the app.

Conventions & patterns to follow (concrete)
-----------------------------------------
- Folder layout: See top-level map in `.github/copilot-instructions.md` and `README.md`. New artifacts follow the feature-generation order: Model → DTO/Mapper → Repository → Service (if cross-cutting) → Controller → Binding → UI → Route.
- Naming: files use snake_case, classes use PascalCase. Utility classes use the `B` prefix (e.g., `BAppTheme`, `BHttpHelper`, `BRoutes`).
- Logging: do NOT use `print`. Use `logDebug()` (`lib/base/utils/logger.dart`) or `BloggerHelper` (`lib/base/utils/logging/`).
- Error/result handling: Async operations should return `Result<T>` (see `lib/base/utils/result.dart`) rather than throwing raw exceptions.
- UI: Keep business/data logic out of widget `build`. Use controllers for logic and `Obx` to observe minimal subtrees.

- Prefer domain-specific helpers and global formatters instead of private utility methods inside widgets. For example, the collection feature now centralizes status handling in `features/collection/helpers/CollectionStatusColors` and uses a shared `BFormatter.formatPesoCurrency` (see `lib/base/utils/formatters/`) and a reusable `BIconLabelChip` widget in `lib/common/widgets/` for compact metadata chips.

DI / registration gotchas
------------------------
- Repositories are expected to be registered before controllers that use them. `GeneralBindings` lists this ordering explicitly.
- Many services are registered with `fenix: true` so they are recreated as needed; only use `Get.put(..., permanent: true)` for singletons with clear justification (the project already uses `Get.put(UserController(), permanent: true)` in `GeneralBindings`).

- Authentication DI note: the project registers the authentication repository via its interface and wires use-cases in `GeneralBindings`. See `lib/bindings/general_bindings.dart` for examples:
  - `Get.lazyPut<IAuthenticationRepository>(() => AuthenticationRepository(), fenix: true);`
  - `Get.lazyPut(() => LoginWithEmailPasswordUseCase(...), fenix: true);`

- Binding exceptions: some registrations intentionally differ from the default `fenix: true` pattern. For example `UserRepository` is registered without `fenix` in `GeneralBindings` (`Get.lazyPut(() => UserRepository());`) and `SignupController` is registered with `Get.put(...)` to retain form state. Check `lib/bindings/general_bindings.dart` before adding new bindings to match existing intent.

Where to look for examples (key files)
-------------------------------------
- DI & ordering: `lib/bindings/general_bindings.dart` (the canonical registration list)
- App start & early services: `lib/main.dart` (Firebase init, permission/notification registration, HttpOverrides)
- Router & department logic: `lib/app_router.dart`
- App entry & bindings usage: `lib/app.dart`
- Result type: `lib/base/utils/result.dart`
- Logger wrapper: `lib/base/utils/logger.dart`
- Routes constants and GetPage list: `lib/base/utils/routes/` (BRoutes/AppRoutes)
- Feature QA tooling: `bin/generate_module_qa.dart` and `lib/features/logistics/screens/data_test/IMPLEMENTATION_SUMMARY.md`
- DB helper & schema: `lib/data/local/database_helper.dart` and `lib/data/local/db_schema.dart`

Developer workflows & scripts
-----------------------------
- Standard local dev: `flutter pub get` ; `flutter run` (use PowerShell on Windows; chain with `;` if needed).
- Analysis & tests: `flutter analyze` ; `flutter test`.
- Repo-specific generators:
  - `dart run bin/generate_module_qa.dart --name "Name" --area Logistics --routes "/route"` (creates docs/modules/<slug>/README.md and test CSVs)
  - `dart run bin/inspect_db_images.dart` (inspects DB images/signatures)

Integration & external deps to be aware of
----------------------------------------
- Firebase (core/auth/firestore/storage) — initialized in `lib/main.dart` using `firebase_options.dart`.
- Permissions & platform services: `permission_handler`, `location`, `google_maps_flutter`, `google_mlkit_text_recognition` — wrappers live under `lib/common/services/`.
- WebSockets: uses `web_socket_channel` and controllers such as `WebSocketNotificationController` registered early in bindings.

- Note: recent dependency maintenance updated minor package versions (see `pubspec.lock`). When changing dependencies, run `flutter pub get` and commit the updated lockfile. Example packages that have received minor bumps in recent workspace tasks include `dio`, `uuid`, and platform adapters.

- Documentation cleanup: `.github/copilot-instructions.md` received minor formatting cleanup (no functional changes). Read it first for AI-specific guidance.

What NOT to change / common pitfalls
-----------------------------------
- Do not move or rename `GeneralBindings` or migrate DI to a different pattern — bindings ordering is relied upon.
- Avoid registering repositories inline in controllers with `Get.put(...)`. Use `Get.find()` and register in `GeneralBindings` instead.
- Avoid `print` statements and in-widget business logic.

How to contribute code changes as an agent
----------------------------------------
1. Search for existing shared utilities before adding new widgets: `lib/base/utils/` and `lib/common/widgets/`.
2. Follow the feature-generation order; add a binding entry in `lib/bindings/general_bindings.dart`.
3. Use `Get.lazyPut(..., fenix: true)` for new controllers/repositories unless you have a reason for eager `Get.put`.
4. Update `BRoutes` and `AppRoutes.pages` for new screens.
5. Run `flutter analyze` and `flutter test` (where applicable) before submitting changes.

Notes about documentation placement
---------------------------------
The project normally keeps docs in `docs/`. This `AGENTS.md` was created at the project root per the current request; future `.md` files should go into `docs/` unless a different location is explicitly requested.

Contact points in repo (where agents should look first)
-----------------------------------------------------
- `.github/copilot-instructions.md` — project-specific AI guidelines (read first)
- `lib/bindings/general_bindings.dart` — DI and registration order
- `lib/main.dart` — early initializers and platform registration
- `lib/base/utils/result.dart` and `lib/base/utils/logger.dart` — error & logging APIs

End of guidance

