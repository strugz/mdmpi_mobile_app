
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
- **Firebase guard in GeneralBindings:** All Firestore-backed repositories are wrapped in `if (Firebase.apps.isNotEmpty) { ... }`. On desktop platforms without FlutterFire configuration, these registrations are skipped to avoid runtime errors. Repositories that use REST + local DB only (e.g., `BackLoadRepository`) are registered **outside** the guard so they work on all targets. See `lib/bindings/general_bindings.dart` lines 120–159.
- Early/ eager registration: some platform services are registered in `lib/main.dart` using `Get.put(...)` before bindings run (notably `PermissionService`, `NotificationService`, and `AuthenticationRepository` after Firebase init). See `lib/main.dart`.
- Navigation: Named routes via `BRoutes` + `AppRoutes.pages` (under `lib/base/utils/routes`). Department-specific post-auth routing is handled by `lib/app_router.dart`.

 - Text extraction service: The repository now registers an `ITextExtractor` implementation (`DocumentReferenceExtractor`) in `GeneralBindings` and composes it into camera-related controllers. Camera/text composition example:
   - `lib/bindings/general_bindings.dart` registers `Get.lazyPut<ITextExtractor>(() => DocumentReferenceExtractor(), fenix: true);`
   - `CameraHandlerController` / `CameraController` instances obtain `ICameraService`, `ITextRecognitionService`, and `ITextExtractor` via `Get.find()` (see `CameraHandlerController` registration in `GeneralBindings`).
   - Use `Get.find<ITextExtractor>()` in controllers/widgets when you need the extractor. Implement new extractors under `lib/common/services/abstracts/` and register them in `GeneralBindings` following the existing pattern.

- **Local Storage Data Viewer:** A developer-only tool for inspecting and managing SQLite database tables is available under `lib/features/logistics/screens/data_test/`. It is accessible from the Settings screen ("Developer Tools" section) and via the `/local-storage-viewer` route. This tool is for debugging and should not be exposed in production builds. See the feature's `README.md` for details.

- Platform initialization helper: `lib/base/utils/platform_init.dart` centralizes several early-start concerns used by `main.dart` (sqflite FFI initialization on desktop, conditional Firebase initialization, eager NotificationService init, and eager registration of `AuthenticationRepository` via `Get.put` when Firebase is available). Inspect `initPlatform(...)` when auditing early/eager registrations and desktop vs mobile platform behavior.

- Note: several core services/controllers are registered eagerly via `Get.put` in `lib/bindings/general_bindings.dart` (not only in `main.dart`). Examples: `Get.put(NetworkManager())`, `Get.put(WebSocketNotificationController())`, `Get.put(MessagingController())`, and `Get.put(UserController(), permanent: true)`. Always inspect `GeneralBindings` for the exact registration style and ordering used by the app.

- Recently added repositories and controllers (all registered in `GeneralBindings`):
  - **Repositories:** `BackLoadRepository` (`data/repositories/app_data/`, REST + local DB, outside Firebase guard), `InventoryItemRepository` (`data/repositories/inventory/`, Gemini OCR endpoint), `FormCategoryRepository` (`data/repositories/common/`), `CancelRemarksRepository` (`data/repositories/app_data/`), `UserMDMPIRepository` (`data/repositories/user/`).
  - **Controllers:** `BackLoadController`, `InventoryItemController`, `ChartController`, `RequestController`, `StockReceiveController`, `HotlineDirectController`, `RequestHotlineController` (stub). All in `features/logistics/controllers/`.
  - **Role handlers:** `features/logistics/services/implementations/` now contains `hotline_direct_role_handler.dart`, `request_role_handler.dart`, `pick_up_role_handler.dart`, `stock_receive_role_handler.dart` — implementing `IRequestActionHandler`.

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

- Binding exceptions: some registrations intentionally differ from the default `fenix: true` pattern. For example `UserRepository` is registered without `fenix` in `GeneralBindings` (`Get.lazyPut(() => UserRepository());`). Check `lib/bindings/general_bindings.dart` before adding new bindings to match existing intent.

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
  - Recent tables: `a_tblRequestBackload` (back-load entries), `a_tblClientContactPerson` (autocomplete), `a_tblLocationAlternative` (alternative delivery locations).
  - Recent DAOs: `data/local/dao/common/backload_dao.dart`, `data/local/dao/common/client_contact_person_dao.dart`.

- Platform init & sqflite FFI: `lib/base/utils/platform_init.dart` — shows `ensureSqfliteFfiInitialized()`, conditional Firebase init, and the code path that registers `AuthenticationRepository` when Firebase is present.

 - Text extraction & camera examples:
   - `lib/common/services/abstracts/i_text_extractor.dart` (interface + `DocumentReferenceExtractor` implementation)
   - `lib/common/controllers/camera_controller.dart` (camera controller usage)
   - `lib/common/widgets/scanner/simple_text_scanner.dart` (example widget that resolves `ITextExtractor`)

- Local Storage Data Viewer: `lib/features/logistics/screens/data_test/local_storage_data_viewer.dart`, `local_storage_data_controller.dart`, and documentation in the same folder (`README.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_SUMMARY.md`).

- Module documentation: `docs/modules/backload/BACKLOAD_MODULE_DOCUMENTATION.md`, `docs/modules/inventory_item/INVENTORY_ITEM_MODULE_DOCUMENTATION.md`. See `docs/README.md` for the full module index.

- Routes: `lib/base/utils/routes/routes.dart` (`BRoutes`) and `lib/base/utils/routes/app_routes.dart` (`AppRoutes.pages`). Note: `BRoutes.backLoad` (`'/back-load'`) and `BRoutes.pullOutForm` (`'/pull-out-form'`) are defined but `backLoad` does **not** yet have a `GetPage` in `AppRoutes.pages`.

- Routes: `lib/base/utils/routes/routes.dart` (`BRoutes`) and `lib/base/utils/routes/app_routes.dart` (`AppRoutes.pages`). `BRoutes.backLoad` (`'/back-load'`) and `BRoutes.pullOutForm` (`'/pull-out-form'`) are defined — `backLoad` now has a corresponding `GetPage` in `AppRoutes.pages` which constructs `BackLoadTransactionPage` and expects a `StandardDeliveryModel` via `Get.arguments` (see `lib/base/utils/routes/app_routes.dart`, lines ~41-48).
Developer workflows & scripts
-----------------------------
- Standard local dev: `flutter pub get` ; `flutter run` (use PowerShell on Windows; chain with `;` if needed).
- Analysis & tests: `flutter analyze` ; `flutter test`.
- Repo-specific generators:
  - `dart run bin/generate_module_qa.dart --name "Name" --area Logistics --routes "/route"` (creates docs/modules/<slug>/README.md and test CSVs)
  - `dart run bin/inspect_db_images.dart` (inspects DB images/signatures)
  - `dart run bin/check_mapper.dart` (small utility stub present in `bin/` — currently empty; available for future mapper checks)

- In-app DB inspection: Open the app, go to Settings > Developer Tools > Local Storage Viewer to inspect and manage local database tables. For direct navigation in development, use `Get.to(() => const LocalStorageDataViewer())`.

Integration & external deps to be aware of
----------------------------------------
- Firebase (core/auth/firestore/storage) — initialized in `lib/main.dart` using `firebase_options.dart`.
- Permissions & platform services: `permission_handler`, `location`, `google_maps_flutter`, `google_mlkit_text_recognition` — wrappers live under `lib/common/services/`.
- WebSockets: uses `web_socket_channel` and controllers such as `WebSocketNotificationController` registered early in bindings.

- Note: recent dependency maintenance updated minor package versions (see `pubspec.lock`). When changing dependencies, run `flutter pub get` and commit the updated lockfile. Example packages that have received minor bumps in recent workspace tasks include `dio`, `uuid`, and platform adapters.

- Documentation cleanup: `.github/copilot-instructions.md` received minor formatting cleanup (no functional changes). Read it first for AI-specific guidance.

- AI / LLM packages in `pubspec.yaml`:
  - The repository currently includes placeholder dependencies for AI/LLM integration (see `pubspec.yaml`): `flutter_ai_toolkit: any` and `firebase_ml_model_downloader: any`.
  - These are intentional placeholders. Do NOT add API keys or provider credentials to the repo. When integrating a concrete LLM or on-device model package:
    - Pin exact package versions in `pubspec.yaml` (do not leave `any`).
    - Run `flutter pub get` and commit the resulting `pubspec.lock`.
    - Prefer platform-safe, offline-capable packages for on-device models; use `firebase_ml_model_downloader` only if you understand Firebase model hosting and licensing implications.
    - Add integration tests where applicable and document the chosen package in `docs/` when requested.

- Placeholder service stubs (empty files, **not** registered in `GeneralBindings`):
  - `common/services/abstracts/i_ai_service.dart` and `common/services/implementations/ai_service.dart` — AI service interface/impl (empty).
  - `common/services/abstracts/i_feature_toggle_service.dart` and `common/services/implementations/feature_toggle_service.dart` — feature toggle (empty).
  - `common/widgets/feature_guard.dart` — empty placeholder widget.
  - These files exist as scaffolding for future features. Do NOT register them in `GeneralBindings` until they have real implementations.

- `IDeliveryRequestController` (`common/services/abstracts/i_delivery_request_controller.dart`) is a fully implemented 142-line interface (not empty). It defines the contract for delivery request controllers; both `StandardDeliveryController` and `HotlineDirectController` implement it.

What NOT to change / common pitfalls
-----------------------------------
- Do not move or rename `GeneralBindings` or migrate DI to a different pattern — bindings ordering is relied upon.
- Avoid registering repositories inline in controllers with `Get.put(...)`. Use `Get.find()` and register in `GeneralBindings` instead.
- Avoid `print` statements and in-widget business logic.

- Do not expose the Local Storage Data Viewer to production users; it is for development/debugging only.

- NOTE: There are a few legacy `print()` calls still present in the codebase (used for quick debugging). Replace these with `logDebug()` or `BloggerHelper` when making changes. Notable instances include:
  - `lib/data/repositories/inventory/inventory_item_repository.dart` (debug `print("HeHim: ...")` in Gemini integration)
  - `lib/features/logistics/controllers/standard_delivery_controller.dart` (debug prints when handling API results)
  - `lib/features/logistics/screens/request_forms/widgets/pull_out_form.dart` and `lib/features/logistics/screens/common/b_request_form.dart` (UI debug prints)
  - `lib/debug/reset_database.dart` (intentional console utility — safe in debug tool)

  When replacing prints, prefer `logDebug()` from `lib/base/utils/logger.dart` for simple messages and `BloggerHelper` for structured logs.

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

- `.github/copilot-instructions.md` — project-specific AI guidelines (read first). The file is present in the repository at `.github/copilot-instructions.md` and contains the authoritative, project-specific coding conventions and folder layout; read it before making changes.
- `lib/bindings/general_bindings.dart` — DI and registration order
- `lib/main.dart` — early initializers and platform registration
- `lib/base/utils/result.dart` and `lib/base/utils/logger.dart` — error & logging APIs

Agent integration (use the platform-provided subagents)
-----------------------------------------------------
- The environment exposes a small set of specialized subagents. When a task matches a subagent's role (for example: research, plan, or outline), prefer delegating using the `run_subagent` tool.
- Available example: `Plan` — use `run_subagent(agentName: "Plan", task: "<detailed task...>")` to produce step-by-step research or implementation plans before making changes. This helps with multi-step refactors, large edits, or complex design decisions.
- Example usage pattern: for multi-step work, first call the `Plan` agent to produce an ordered checklist, then proceed to make edits and tests following that checklist.

Note: In this workspace the only provided subagent is named exactly `Plan`. When calling `run_subagent` you must use the exact `agentName` string `"Plan"`.

End of guidance

