
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

-Important architectural notes
----------------------------
- State & DI: GetX is used everywhere. Repositories extend `GetxController` and are registered in `lib/bindings/app/general_bindings.dart` via `Get.lazyPut(..., fenix: true)`.
-  - Example: `Get.lazyPut(() => RoleRepository(), fenix: true);`
-  - Controllers resolve deps with `Get.find()` — do not instantiate repos inside controllers.
 - **Firebase guard in GeneralBindings:** All Firestore-backed repositories are wrapped in `if (Firebase.apps.isNotEmpty) { ... }`. On desktop platforms without FlutterFire configuration, these registrations are skipped to avoid runtime errors. Repositories that use REST + local DB only (e.g., `BackLoadRepository`) are registered **outside** the guard so they work on all targets. See `lib/bindings/app/general_bindings.dart`.
- Early/ eager registration: some platform services are registered in `lib/main.dart` using `Get.put(...)` before bindings run (notably `PermissionService`, `NotificationService`, and `AuthenticationRepository` after Firebase init). See `lib/main.dart`.
- Navigation: Named routes via `BRoutes` + `AppRoutes.pages` (under `lib/base/utils/routes`). Department-specific post-auth routing is handled by `lib/app_router.dart`. Use GetX routing for app-level screen transitions; keep raw `Navigator.push` limited to low-level helpers such as `BHelperFunctions.navigateToScreen`.
- AppRouter cold-start routing now depends on cached user state as well as live controller state: `lib/app_router.dart` first reads `UserController.user.department`, then falls back to `GetStorage` key `CurrentUser` (with legacy `UserDepartment` as a migration fallback). Department onboarding completion flags currently stored in `GetStorage` are `LogisticsOnboardingComplete`, `CollectionOnboardingComplete`, `ServiceOnboardingComplete`, and `InHouseOnboardingComplete`. See also `lib/features/personalization/controller/user_controller.dart` for the `CurrentUser` cache writer.
- Startup/platform bootstrap in `lib/main.dart` is now explicitly platform-aware: Android requests `storage`, `location`, `camera`, and `sms`, while desktop/web requests only `location` and `camera`; after permission grant it creates the `MDMPIAPP` folder under `/storage/emulated/0/MDMPIAPP` on Android or the app documents directory on desktop. Keep new permission/file-storage flows aligned with this split.

 - NavigationController / NavigationMenu updates: The bottom-tab shell (`lib/navigation_menu.dart`) instantiates `NavigationController` via `Get.put(NavigationController())` (acceptable for the shell). The controller now stores screen route names and exposes a computed `screens` getter that selects widgets by user department (see `lib/data/controllers/navigation_controller.dart`). When adding or modifying tab behavior prefer updating `NavigationController.screenRoutes`, `screens`, and `changeScreen` rather than wiring tab logic directly in widgets.

  - Text extraction service: The repository now registers an `ITextExtractor` implementation (`DocumentReferenceExtractor`) in `GeneralBindings` and composes it into camera-related controllers. Camera/text composition example:
    - `lib/bindings/app/general_bindings.dart` registers `Get.lazyPut<ITextExtractor>(() => DocumentReferenceExtractor(), fenix: true);`
    - `CameraHandlerController` / `CameraController` instances obtain `ICameraService`, `ITextRecognitionService`, and `ITextExtractor` via `Get.find()` (see `CameraHandlerController` registration in `GeneralBindings`).
    - Use `Get.find<ITextExtractor>()` in controllers/widgets when you need the extractor. Implement new extractors under `lib/common/services/abstracts/` and register them in `GeneralBindings` following the existing pattern.

- **Local Storage Data Viewer:** A developer-only tool for inspecting and managing SQLite database tables is available under `lib/features/logistics/screens/data_test/`. It is accessible from the Settings screen ("Developer Tools" section) and via the `/local-storage-viewer` route. This tool is for debugging and should not be exposed in production builds. See the feature's `README.md` for details.

- **Signature Outbox (developer tool):** A developer-facing tool for reviewing/retrying pending receiver signature uploads is available from Settings > Developer Tools and via `/signature-outbox` (`BRoutes.signatureOutbox`). Its page (`lib/features/personalization/screens/settings/signature_outbox_page.dart`) instantiates `SignatureOutboxController` in-widget via `Get.put(...)` when needed; keep this debug-facing flow hidden from production users.

- Platform initialization helper: `lib/base/utils/platform_init.dart` centralizes several early-start concerns used by `main.dart` (sqflite FFI initialization on desktop, conditional Firebase initialization, eager NotificationService init, and eager registration of `AuthenticationRepository` via `Get.put` when Firebase is available). Inspect `initPlatform(...)` when auditing early/eager registrations and desktop vs mobile platform behavior.

 - Note: several core services/controllers are registered eagerly via `Get.put` in `lib/bindings/app/general_bindings.dart` (not only in `main.dart`). Examples: `Get.put(NetworkManager())`, `Get.put(WebSocketNotificationController())`, `Get.put(MessagingController())`, and `Get.put(UserController(), permanent: true)`. Always inspect `GeneralBindings` for the exact registration style and ordering used by the app.
- Delivery-location integrations are also DI-managed in `GeneralBindings`: `ILocationAlternativeService`, `IMapsService`, `IPlacesService`, and `ILocationTrackingService` are lazy-registered there. When touching map/location flows, resolve these abstractions with `Get.find()` instead of calling geolocation/maps APIs directly from widgets or controllers.

- Recently added repositories and controllers (all registered in `GeneralBindings`):
  - **Repositories:** `BackLoadRepository` (`data/repositories/app_data/`, REST + local DB, outside Firebase guard), `InventoryItemRepository` (`data/repositories/inventory/`, Gemini OCR endpoint), `FormCategoryRepository` (`data/repositories/common/`), `CancelRemarksRepository` (`data/repositories/app_data/`), `UserMDMPIRepository` (`data/repositories/user/`), `ContactRepository` (`data/repositories/common/`, local contact-directory data via SQLite).
  - **Controllers:** `BackLoadController`, `InventoryItemController`, `ChartController`, `RequestController`, `StockReceiveController`, `HotlineDirectController`. All in `features/logistics/controllers/`.
    - `ContactDirectoryController` (`features/personalization/controller/`) is registered in `GeneralBindings` and depends on `ContactRepository`.
    - `RequestHotlineController` (stub, **not** registered in `GeneralBindings` — do not `Get.find()` it without registering first).
    - `SignatureOutboxController` (`features/personalization/controller/`) is used by the Signature Outbox developer tool and is instantiated from the page/widget layer (not centrally registered in `GeneralBindings`).
    - Additional controllers (present but not previously listed) that agents should inspect: `HomeController`, `DeliveryVehicleController`, `DeliveryLocationController`, `RequestTransportController`, `WebSocketNotificationController`, `WebSocketDispatcherController`, `WebSocketDeliveryController`, and `NavigationController` (`lib/data/controllers/navigation_controller.dart`). These are registered either in `GeneralBindings` or instantiated in-place for developer tools / UI shells — check `lib/bindings/general_bindings.dart` for registration style (fenix/permanent/eager) before using `Get.find()`.
  - **Role handlers:** `features/logistics/services/implementations/` now contains `hotline_direct_role_handler.dart`, `request_role_handler.dart`, `pick_up_role_handler.dart`, `stock_receive_role_handler.dart` — implementing `IRequestActionHandler`.

Conventions & patterns to follow (concrete)
-----------------------------------------
- Folder layout: See top-level map in `.github/copilot-instructions.md` and `README.md`. New artifacts follow the feature-generation order: Model → DTO/Mapper → Repository → Service (if cross-cutting) → Controller → Binding → UI → Route.
- Naming: files use snake_case, classes use PascalCase. Utility classes use the `B` prefix (e.g., `BAppTheme`, `BHttpHelper`, `BRoutes`).
- Logging: do NOT use `print`. Use `logDebug()` (`lib/base/utils/logger.dart`) or `BloggerHelper` (`lib/base/utils/logging/`).
- Error/result handling: Async operations should return `Result<T>` (see `lib/base/utils/result.dart`) rather than throwing raw exceptions.
- UI: Keep business/data logic out of widget `build`. Use controllers for logic and `Obx` to observe minimal subtrees.

- Prefer domain-specific helpers and global formatters instead of private utility methods inside widgets. Logistics helpers live in `features/logistics/helpers/` (e.g., `StatusColorMapper`, `*DataManager`, `*FilterManager`, `*FormState`, `*ModalConfig`). Shared formatters are in `BFormatter` (`lib/base/utils/formatters/formatters.dart`) — e.g., `formatDate2`, `formatDateWithAmPm`, `formatIntegerNoDecimal`, `normalizeToIsoDatetime`. Reusable chip widgets are in `lib/common/widgets/chips/` (`BSimpleChip`, `ChoiceChip`, `StatusChip`).

- **Developer/debug tools:** For in-app developer tools (such as the Local Storage Data Viewer), it is acceptable to instantiate controllers directly in the widget using `Get.put(...)` rather than registering in `GeneralBindings`. See `local_storage_data_viewer.dart` for an example. These tools must remain hidden from production users.

DI / registration gotchas
------------------------
- Repositories are expected to be registered before controllers that use them. `GeneralBindings` lists this ordering explicitly.
- Many services are registered with `fenix: true` so they are recreated as needed; only use `Get.put(..., permanent: true)` for singletons with clear justification (the project already uses `Get.put(UserController(), permanent: true)` in `GeneralBindings`).

-- Authentication DI note: the project registers the authentication repository via its interface and wires use-cases in `GeneralBindings`. See `lib/bindings/app/general_bindings.dart` for examples:
  - `Get.lazyPut<IAuthenticationRepository>(() => AuthenticationRepository(), fenix: true);`
  - `Get.lazyPut(() => LoginWithEmailPasswordUseCase(...), fenix: true);`
  - `Get.lazyPut(() => LoginWithGoogleUseCase(...), fenix: true);` — resolves `IAuthenticationRepository`, `UserRepository`, and `NetworkManager` via `Get.find()`.

  - Note: the `LoginWithEmailPasswordUseCase` is constructed with a `GetStorage()` instance for local caching (see `lib/bindings/app/general_bindings.dart` where `GetStorage()` is passed into the usecase). Agents should be aware that some use-cases expect `GetStorage` to be available at construction time.

-- Binding exceptions: some registrations intentionally differ from the default `fenix: true` pattern. For example `UserRepository` is registered without `fenix` in `GeneralBindings` (`Get.lazyPut(() => UserRepository());`). Check `lib/bindings/app/general_bindings.dart` before adding new bindings to match existing intent.

  - Implementation note: `SignupController` is intentionally lazy-registered (`fenix: true`) to avoid instantiating Firebase-backed repositories during app startup on platforms where Firebase is not initialized. Keep this pattern when adding new auth-related controllers to avoid unexpected Firebase initializations on desktop.

  - `UserController()` is registered via `Get.put(..., permanent: true)` in both the Firebase and non-Firebase branches of `GeneralBindings` — expect it to be available and treated as a long-lived singleton.

Where to look for examples (key files)
-------------------------------------
- DI & ordering: `lib/bindings/app/general_bindings.dart` (the canonical registration list)
  - See `lib/bindings/app/general_bindings.dart` for additional wiring examples agents should reuse:
    - The `CameraHandlerController` is constructed with explicit dependencies resolved via `Get.find()` (ICameraService, ITextRecognitionService, ITextExtractor) — review its registration to mirror constructor injection when creating similar controllers.
    - `GetStorage()` is provided directly into the `LoginWithEmailPasswordUseCase` at registration time; use the same pattern for use-cases that require lightweight local storage access.
- App start & early services: `lib/main.dart` (Firebase init, permission/notification registration, HttpOverrides)
- Router & department logic: `lib/app_router.dart`
- App entry & bindings usage: `lib/app.dart`
- Result type: `lib/base/utils/result.dart`
- Logger wrapper: `lib/base/utils/logger.dart`
- Routes constants and GetPage list: `lib/base/utils/routes/` (BRoutes/AppRoutes)
- Feature QA tooling: `bin/generate_module_qa.dart` and `lib/features/logistics/screens/data_test/IMPLEMENTATION_SUMMARY.md`
- DB helper & schema: `lib/data/local/database_helper.dart` and `lib/data/local/db_schema.dart`
  - Tables: `a_tblRequest`, `a_tblRequestDocumentReference`, `a_tblRequestReceiverSignature`, `a_tblRequestImage`, `a_tblRequestRemarks`, `ACCMST_`, `a_tblMobile`, `Users`, `CNTMST`, `a_tblRequestPickUp`, `a_tblItemCategory`, `a_tblFormCategory`, `a_tblRequestAirSea`, `a_tblRequestPullOutReturnPickUp`, `a_tblLocationAlternative`, `a_tblClientContactPerson`, `a_tblRequestBackload`, `contacts`.
  - DAOs by domain: `dao/standard_delivery/` (`standard_delivery_dao`, `location_alternative_dao`), `dao/air_sea/` (`air_sea_dao`), `dao/pick_up/` (`pick_up_dao`), `dao/pull_out/` (`pull_out_dao`), `dao/common/` (`backload_dao`, `client_contact_person_dao`, `client_dao`, `cntmst_dao`, `contact_dao`, `document_reference_dao`, `form_category_dao`, `item_category_dao`, `mobile_dao`, `remarks_dao`, `signature_dao`, `user_dao`).

- Platform init & sqflite FFI: `lib/base/utils/platform_init.dart` — shows `ensureSqfliteFfiInitialized()`, conditional Firebase init, and the code path that registers `AuthenticationRepository` when Firebase is present.

 - Text extraction & camera examples:
   - `lib/common/services/abstracts/i_text_extractor.dart` (interface + `DocumentReferenceExtractor` implementation)
   - `lib/common/controllers/camera_controller.dart` (camera controller usage)
   - `lib/common/widgets/scanner/simple_text_scanner.dart` (example widget that resolves `ITextExtractor`)

- Local Storage Data Viewer: `lib/features/logistics/screens/data_test/local_storage_data_viewer.dart`, `local_storage_data_controller.dart`, and documentation in the same folder (`README.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_SUMMARY.md`).

- Module documentation: keep `docs/README.md` as the live module-doc index. BackLoad has `docs/modules/backload/BACKLOAD_MODULE_DOCUMENTATION.md`, even though the index still marks BackLoad as Planned. Inventory Item has `docs/modules/inventory_item/INVENTORY_ITEM_MODULE_DOCUMENTATION.md`. Additional module READMEs exist under `docs/modules/` for: air-sea, authentication, collection, hotline-direct, personalization, pick-up, pull-out, standard-delivery, stock-receive. Cross-module rollout planning docs also exist in `docs/modules/request-forms/` (for example `INVENTORY_SCANNER_ROLLOUT_PLAN.md`). `docs/modules/advanced_filter/` is an empty scaffold.

- Routes: `lib/base/utils/routes/routes.dart` (`BRoutes`) and `lib/base/utils/routes/app_routes.dart` (`AppRoutes.pages`). `BRoutes.backLoad` (`'/back-load'`) and `BRoutes.pullOutForm` (`'/pull-out-form'`) are defined — `backLoad` has a corresponding `GetPage` in `AppRoutes.pages` which constructs `BackLoadTransactionPage` and expects a `StandardDeliveryModel` via `Get.arguments`. `BRoutes.signatureOutbox` (`'/signature-outbox'`) maps to `SignatureOutboxPage` for developer troubleshooting of pending signature uploads. The request route (`BRoutes.request`) uses `RequestBindings` (currently an empty placeholder — controllers are registered centrally in `GeneralBindings`).
Developer workflows & scripts
-----------------------------
- Standard local dev: `flutter pub get` ; `flutter run` (use PowerShell on Windows; chain with `;` if needed).
- Analysis & tests: `flutter analyze` ; `flutter test`.
- Repo-specific generators:
  - `dart run bin/generate_module_qa.dart --name "Name" --area Logistics --routes "/route"` (creates docs/modules/<slug>/README.md and test CSVs)
  - `dart run bin/inspect_db_images.dart` (inspects DB images/signatures)
  - `dart run bin/check_mapper.dart` (small utility stub present in `bin/` — currently empty; available for future mapper checks)
- Tests live under `test/` and use the `_test.dart` suffix.

- In-app DB inspection: Open the app, go to Settings > Developer Tools > Local Storage Viewer to inspect and manage local database tables. For direct navigation in development, use `Get.to(() => const LocalStorageDataViewer())`.
- Although `BRoutes.localStorageViewer` exists, the feature README currently recommends direct widget navigation (`Get.to(() => const LocalStorageDataViewer())`) during development to avoid auth-redirect edge cases.

Integration & external deps to be aware of
----------------------------------------
- Firebase (core/auth/firestore/storage) — initialized in `lib/main.dart` using `firebase_options.dart`.
- Permissions & platform services: `permission_handler`, `location`, `google_maps_flutter`, `google_mlkit_text_recognition` — wrappers live under `lib/common/services/`.
  - Note: a small backward-compatible helper exists at `lib/notification.dart` (`ShowLocalNotification`) which delegates to `INotificationService`. Prefer resolving `INotificationService` directly via `Get.find<INotificationService>()` in new code; use the wrapper only when updating legacy callers.
- WebSockets: uses `web_socket_channel` and controllers such as `WebSocketNotificationController` registered early in bindings.
- Environment variables are loaded from `.env` in `main.dart`; never commit secrets or API keys.
- Inventory OCR / AI is no longer just placeholder scaffolding: `lib/data/repositories/inventory/inventory_item_repository.dart` provides both backend OCR (`analyzeFile()` → `/api4/Gemini/analyze-file`) and direct Gemini calls (`analyzeFileWithGemini()`). The direct path reads `.env` keys `AI_TOOLKIT_MODEL`, `AI_TOOLKIT_API_KEY`, and optional `AI_PROMPT` (with fallbacks to `AI_MODEL` / `API_KEY`), and `StandardDeliveryController` invokes both repository methods for scanned inventory intake.
- Maps/places credentials are mixed today: `MapsService` reads `API_KEY` from `.env`, but `lib/common/services/implementations/places_service.dart` still contains a hardcoded RapidAPI key/TODO. Treat that file as legacy debt and do not copy its key-management pattern into new code.

- Note: recent dependency maintenance updated minor package versions (see `pubspec.lock`). When changing dependencies, run `flutter pub get` and commit the updated lockfile. Example packages that have received minor bumps in recent workspace tasks include `dio`, `uuid`, and platform adapters.

- Documentation cleanup: `.github/copilot-instructions.md` received minor formatting cleanup (no functional changes). Read it first for AI-specific guidance.

- AI / LLM packages in `pubspec.yaml`:
  - The repository currently includes placeholder dependencies for AI/LLM integration (see `pubspec.yaml`): `flutter_ai_toolkit: any` and `firebase_ml_model_downloader: any`.
  - Current concrete AI usage bypasses the empty `IAiService` scaffold: inventory extraction is wired directly in `InventoryItemRepository`, and the placeholder service files remain unregistered.
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

- Empty placeholder files/folders (exist as scaffolding, not real implementations):
  - `data/repositories/backload/` — empty folder; the actual `BackLoadRepository` lives in `data/repositories/app_data/backload_repository.dart`.
  - `data/repositories/app_data/sign_up_repository.dart` — empty file; signup logic is in `SignupController` + auth repos.
  - `features/collection/domain/` — empty folder; collection does not yet use a domain layer.

What NOT to change / common pitfalls
-----------------------------------
- Do not move or rename `GeneralBindings` or migrate DI to a different pattern — bindings ordering is relied upon.
- Avoid registering repositories inline in controllers with `Get.put(...)`. Use `Get.find()` and register in `GeneralBindings` instead.
- Avoid `print` statements and in-widget business logic.

- Do not expose the Local Storage Data Viewer to production users; it is for development/debugging only.
- Do not expose the Signature Outbox developer page to production users; it is for development/debugging only.

-- NOTE: Most legacy `print()` debug calls referenced previously have been removed or refactored. Current `print()` occurrences discovered in the repository (intended or dev-only tools) are:
  - `bin/inspect_db_images.dart` — development DB/image inspection utility (prints are expected)
  - `tool/check_braces.dart` — tooling utility (prints are expected)
  - `lib/common/widgets/form/b_autocomplete_text_field.dart` — a remaining in-widget debug print around the contact-person save flow (file: line ~193); consider replacing with `logDebug()` or structured logging when fixing related behavior.

  When replacing prints, prefer `logDebug()` from `lib/base/utils/logger.dart` for simple messages and `BloggerHelper` for structured logs.

How to contribute code changes as an agent
----------------------------------------
1. Search for existing shared utilities before adding new widgets: `lib/base/utils/` and `lib/common/widgets/`.
2. Follow the feature-generation order; add a binding entry in `lib/bindings/app/general_bindings.dart`.
3. Use `Get.lazyPut(..., fenix: true)` for new controllers/repositories unless you have a reason for eager `Get.put`.
4. Update `BRoutes` and `AppRoutes.pages` for new screens.
5. Run `flutter analyze` and `flutter test` (where applicable) before submitting changes.

Notes about documentation placement
---------------------------------
The project normally keeps docs in `docs/`. This `AGENTS.md` was created at the project root per the current request; future `.md` files should go into `docs/` unless a different location is explicitly requested.

Contact points in repo (where agents should look first)
-----------------------------------------------------
- `.github/copilot-instructions.md` — project-specific AI guidelines (read first). The file is present in the repository and contains the authoritative coding conventions and folder layout.
- `lib/bindings/app/general_bindings.dart` — DI and registration order
- `lib/main.dart` — early initializers and platform registration
- `lib/base/utils/result.dart` and `lib/base/utils/logger.dart` — error & logging APIs

Agent integration (use the platform-provided subagents)
-----------------------------------------------------
- The environment exposes a small set of specialized subagents. When a task matches a subagent's role (for example: research, search, plan, or outline), prefer delegating using the `run_subagent` tool so the heavy discovery work runs isolated from the main agent.

- Available subagents (exact names):
  - `Plan` — Use `run_subagent(agentName: "Plan", task: "<detailed task...>")` to produce step-by-step research or implementation plans before making changes. Best for multi-step refactors, design, and checklists.
  - `Search` — Use `run_subagent(agentName: "Search", task: "<what to find...>")` when you need to locate code, files, or symbols but don't know where they live. The Search agent will run repository-wide grep/file searches and read files to return concise pointers and candidate snippets.

- Example usage pattern: for multi-step work, first call the `Plan` agent to produce an ordered checklist; for discovery tasks, call the `Search` agent to locate relevant files and code snippets. Prefer delegating these tasks instead of doing large repository scans in the main agent thread.

Note: In this workspace the provided subagents include `Plan` and `Search`. When calling `run_subagent` you must use the exact `agentName` string (for example `"Plan"` or `"Search"`).

End of guidance

