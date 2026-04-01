
AGENTS for mdmpi_mobile_app
==========================

**Platform Note:** Always assume that all code, scripts, and guidance must cater to both Windows and Android app targets. All workflows, integrations, and platform-specific logic should be compatible with both environments unless explicitly stated otherwise.

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
 - In-app DB inspection: Use the Local Storage Data Viewer (see below for details)

Important architectural notes
----------------------------
- State & DI: GetX is used everywhere. Repositories extend `GetxController` and are registered in `lib/bindings/general_bindings.dart` via `Get.lazyPut(..., fenix: true)`.
  - Example: `Get.lazyPut(() => RoleRepository(), fenix: true);`
  - Controllers resolve deps with `Get.find()` — do not instantiate repos inside controllers.
- Early/ eager registration: some platform services are registered in `lib/main.dart` using `Get.put(...)` before bindings run (notably `PermissionService`, `NotificationService`, and `AuthenticationRepository` after Firebase init). See `lib/main.dart`.
- Navigation: Named routes via `BRoutes` + `AppRoutes.pages` (under `lib/base/utils/routes`). Department-specific post-auth routing is handled by `lib/app_router.dart`.

 - Text extraction service: The repository now registers an `ITextExtractor` implementation (`DocumentReferenceExtractor`) in `GeneralBindings` and composes it into camera-related controllers. Camera/text composition example:
   - `lib/bindings/general_bindings.dart` registers `Get.lazyPut<ITextExtractor>(() => DocumentReferenceExtractor(), fenix: true);`
   - `CameraHandlerController` / `CameraController` instances obtain `ICameraService`, `ITextRecognitionService`, and `ITextExtractor` via `Get.find()` (see `CameraHandlerController` registration in `GeneralBindings`).
   - Use `Get.find<ITextExtractor>()` in controllers/widgets when you need the extractor. Implement new extractors under `lib/common/services/abstracts/` and register them in `GeneralBindings` following the existing pattern.

- **Local Storage Data Viewer:** A developer-only tool for inspecting and managing SQLite database tables is available under `lib/features/logistics/screens/data_test/`. It is accessible from the Settings screen ("Developer Tools" section) and via the `/local-storage-viewer` route. This tool is for debugging and should not be exposed in production builds. See the feature's `README.md` for details.

- Platform initialization helper: `lib/base/utils/platform_init.dart` centralizes several early-start concerns used by `main.dart` (sqflite FFI initialization on desktop, conditional Firebase initialization, eager NotificationService init, and eager registration of `AuthenticationRepository` via `Get.put` when Firebase is available). Inspect `initPlatform(...)` when auditing early/eager registrations and desktop vs mobile platform behavior.

- Note: several core services/controllers are registered eagerly via `Get.put` in `lib/bindings/general_bindings.dart` (not only in `main.dart`). Examples: `Get.put(NetworkManager())`, `Get.put(WebSocketNotificationController())`, `Get.put(MessagingController())`, and `Get.put(UserController(), permanent: true)`. Always inspect `GeneralBindings` for the exact registration style and ordering used by the app.

Conventions & patterns to follow (concrete)
-----------------------------------------
- Folder layout: See top-level map in `.github/copilot-instructions.md` and `README.md`. New artifacts follow the feature-generation order: Model → DTO/Mapper → Repository → Service (if cross-cutting) → Controller → Binding → UI → Route.
- Naming: files use snake_case, classes use PascalCase. Utility classes use the `B` prefix (e.g., `BAppTheme`, `BHttpHelper`, `BRoutes`).
- Logging: do NOT use `print`. Use `logDebug()` (`lib/base/utils/logger.dart`) or `BloggerHelper` (`lib/base/utils/logging/`).
- Error/result handling: Async operations should return `Result<T>` (see `lib/base/utils/result.dart`) rather than throwing raw exceptions.
- UI: Keep business/data logic out of widget `build`. Use controllers for logic and `Obx` to observe minimal subtrees.

- Prefer domain-specific helpers and global formatters instead of private utility methods inside widgets. For example, the collection feature now centralizes status handling in `features/collection/helpers/CollectionStatusColors` and uses a shared `BFormatter.formatPesoCurrency` (see `lib/base/utils/formatters/`) and a reusable `BIconLabelChip` widget in `lib/common/widgets/` for compact metadata chips.

- **Developer/debug tools:** For in-app developer tools (such as the Local Storage Data Viewer), it is acceptable to instantiate controllers directly in the widget using `Get.put(...)` rather than registering in `GeneralBindings`. See `local_storage_data_viewer.dart` for an example. These tools must remain hidden from production users.

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

- Platform init & sqflite FFI: `lib/base/utils/platform_init.dart` — shows `ensureSqfliteFfiInitialized()`, conditional Firebase init, and the code path that registers `AuthenticationRepository` when Firebase is present.

 - Text extraction & camera examples:
   - `lib/common/services/abstracts/i_text_extractor.dart` (interface + `DocumentReferenceExtractor` implementation)
   - `lib/common/controllers/camera_controller.dart` (camera controller usage)
   - `lib/common/widgets/scanner/simple_text_scanner.dart` (example widget that resolves `ITextExtractor`)

- Local Storage Data Viewer: `lib/features/logistics/screens/data_test/local_storage_data_viewer.dart`, `local_storage_data_controller.dart`, and documentation in the same folder (`README.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_SUMMARY.md`).

Developer workflows & scripts
-----------------------------
- Standard local dev: `flutter pub get` ; `flutter run` (use PowerShell on Windows; chain with `;` if needed).
- Analysis & tests: `flutter analyze` ; `flutter test`.
- Repo-specific generators:
  - `dart run bin/generate_module_qa.dart --name "Name" --area Logistics --routes "/route"` (creates docs/modules/<slug>/README.md and test CSVs)
  - `dart run bin/inspect_db_images.dart` (inspects DB images/signatures)

- In-app DB inspection: Open the app, go to Settings > Developer Tools > Local Storage Viewer to inspect and manage local database tables. For direct navigation in development, use `Get.to(() => const LocalStorageDataViewer())`.

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

- Do not expose the Local Storage Data Viewer to production users; it is for development/debugging only.

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
- `.github/copilot-instructions.md` — project-specific AI guidelines (read first). NOTE: this file is referenced in docs but may not be checked into the repository; if it's missing, consult `docs/README.md` and the project `README.md` for equivalent conventions and the top-level `AGENTS.md` itself.
- `lib/bindings/general_bindings.dart` — DI and registration order
- `lib/main.dart` — early initializers and platform registration
- `lib/base/utils/result.dart` and `lib/base/utils/logger.dart` — error & logging APIs

Agent integration (use the platform-provided subagents)
-----------------------------------------------------
- The environment exposes a small set of specialized subagents. When a task matches a subagent's role (for example: research, plan, or outline), prefer delegating using the `run_subagent` tool.
- Available example: `Plan` — use `run_subagent(agentName: "Plan", task: "<detailed task...>")` to produce step-by-step research or implementation plans before making changes. This helps with multi-step refactors, large edits, or complex design decisions.
- Example usage pattern: for multi-step work, first call the `Plan` agent to produce an ordered checklist, then proceed to make edits and tests following that checklist.

End of guidance

