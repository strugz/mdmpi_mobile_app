# Copilot Custom Instructions (mdmpi_mobile_app)

**Platform Note:** Always assume that all code, scripts, and guidance must cater to both Windows and Android app targets. All workflows, integrations, and platform-specific logic should be compatible with both environments unless explicitly stated otherwise.

## Architecture

* Use **GetX** (controllers + Rx). No Riverpod.
* Keep UI pure: no business/data logic in `build`.
* Controllers call repositories (and services where they exist); DI via `Get.lazyPut(fenix: true)` and `Get.find()`.

### Firebase guard in GeneralBindings

All Firestore-backed repositories are wrapped in `if (Firebase.apps.isNotEmpty) { ... }` in `GeneralBindings`. On desktop platforms without FlutterFire configuration, these registrations are skipped to avoid runtime errors. Repositories that use REST + local DB only (e.g., `BackLoadRepository`) are registered **outside** the guard so they work on all targets. See `lib/bindings/general_bindings.dart`.

### Platform initialization helper

`lib/base/utils/platform_init.dart` centralizes early-start concerns used by `main.dart`: sqflite FFI initialization on desktop, conditional Firebase initialization, eager `NotificationService` init, and eager registration of `AuthenticationRepository` via `Get.put` when Firebase is available. Inspect `initPlatform(...)` when auditing early/eager registrations and desktop vs mobile platform behavior.

### Top-level folder layout

```
lib/
  app.dart              # GetMaterialApp, initialBinding: GeneralBindings
  app_router.dart       # Department-based post-auth routing
  main.dart             # Entry point, Firebase init, early service registration
  navigation_menu.dart  # Bottom-tab shell (CurvedNavigationBar)
  base/utils/           # Framework utilities (see below)
  bindings/             # GetX Bindings (GeneralBindings, RequestBindings)
  common/               # Cross-feature controllers, services, widgets, styles, utils
  data/                 # Shared data layer (repositories, models, controllers, local DB, services)
  debug/                # Dev-only DB inspection / reset utilities
  features/             # Feature modules
```

### `lib/base/utils/` — framework utilities

```
constants/    # BColors, BSizes, BTexts, BImages, ApiConstants, enums
devices/      # DeviceUtility
exceptions/   # Typed exception classes (Firebase, format, platform)
formatters/   # BFormatter
helpers/      # BHelperFunctions, NetworkManager, MapHelper, TextFormatters, etc.
http/         # BHttpHelper (static HTTP client)
image_utils/  # Base64 ↔ image conversion
local_storage/# FileStorageService, TextStorageService
logging/      # BloggerHelper (structured Logger wrapper)
logger.dart   # logDebug() — simple debugPrint wrapper
paths/        # Path utilities
popups/       # FullScreenLoader, Loaders, Shimmer, SignatureCaptureDialog, PopUpMenuButton
result.dart   # Result<T> sealed class (Success / Failure)
routes/       # BRoutes (route constants), AppRoutes (GetPage list)
test/         # Test-only JSON fixtures
theme/        # BAppTheme, custom_themes/
validators/   # BValidator
```

### `lib/common/` — cross-feature shared code

```
controllers/          # Shared controllers (CameraHandlerController, AutocompleteController)
services/
  abstracts/          # Interfaces: IPermissionService, INotificationService, ICameraService,
                      #   ITextRecognitionService, ITextExtractor, IMapsService, IPlacesService,
                      #   ILocationTrackingService, ILocationAlternativeService,
                      #   IDeliveryRequestController (controller interface), IFeatureToggleService, IAiService
  implementations/    # Concrete impls: PermissionService, NotificationService, FlutterCameraService,
                      #   GoogleMlKitTextRecognizer, MapsService, PlacesService,
                      #   LocationTrackingService, LocationAlternativeService, etc.
styles/               # Shadows, SpacingStyles
utils/                # Signature dialog utility
widgets/              # Shared UI widgets (appbar, buttons, cards, chips, dialogs, dropdowns,
                      #   forms, icons, images, layouts, loaders, modals, scanner, shipment,
                      #   signature, texts, shimmers, etc.)
```

### `lib/data/` — shared data layer

```
controllers/          # NavigationController, ClientController
  app_data/           # MobileController, UserInitialController, UserMdmpiController
local/
  dao/                # SQLite DAOs per entity (air_sea, pick_up, pull_out, standard_delivery, common)
  database_helper.dart
  db_schema.dart
models/               # Shared domain models (UserInitialModel, ItemCategoryModel, etc.)
repositories/         # Repositories (extend GetxController, call APIs + local DB directly):
                      #   air_sea/, app_data/, authentication/, backload/, client/, common/,
                      #   delivery_vehicle/, image/, inventory/, pick_up/, pull_out/,
                      #   standard_delivery/, user/
services/             # MessagingController (SMS via telephony)
```

> **Note:** Repositories extend `GetxController` and make API/DB calls directly — there is no separate service layer wrapping HTTP for most features. This is the established pattern.

> **DB schema tables:** `a_tblRequest`, `a_tblRequestDocumentReference`, `a_tblRequestReceiverSignature`, `a_tblRequestImage`, `a_tblRequestRemarks`, `ACCMST_`, `a_tblMobile`, `Users`, `CNTMST`, `a_tblRequestPickUp`, `a_tblItemCategory`, `a_tblFormCategory`, `a_tblRequestAirSea`, `a_tblRequestPullOutReturnPickUp`, `a_tblLocationAlternative`, `a_tblClientContactPerson`, `a_tblRequestBackload`.

> **DAOs by domain:** `dao/standard_delivery/` (`standard_delivery_dao`, `location_alternative_dao`), `dao/air_sea/` (`air_sea_dao`), `dao/pick_up/` (`pick_up_dao`), `dao/pull_out/` (`pull_out_dao`), `dao/common/` (`backload_dao`, `client_contact_person_dao`, `client_dao`, `cntmst_dao`, `document_reference_dao`, `form_category_dao`, `item_category_dao`, `mobile_dao`, `remarks_dao`, `user_dao`).

### `lib/features/` — feature modules

Active domains: `authentication`, `logistics`, `personalization`, `collection`.
Placeholder (empty): `inhouse`, `service`.

#### `features/authentication/` — Clean Architecture variant

```
domain/
  entities/           # AuthUser
  params/             # LoginRequest
  repositories/       # IAuthenticationRepository (abstract)
  usecases/           # LoginWithEmailPasswordUseCase, LoginWithGoogleUseCase
presentation/
  controllers/        # LoginController, SignupController, LoadingScreenController, etc.
  pages/              # login/, signup/, password_configuration/, onboarding/
  widgets/            # AuthHeader, SuccessScreen, VerificationScreen
```

Implementation: `data/repositories/authentication/authentication_repository.dart` (extends GetxController, implements IAuthenticationRepository).

#### `features/logistics/` — primary feature module

```
constants/            # FormCategoryConstants
controllers/          # All logistics controllers (StandardDeliveryController, PullOutController, etc.)
  request/components/ # Request sub-components
dtos/                 # Data transfer objects (air_sea/, pick_up/, pull_out/, standard_delivery/)
helpers/              # DataManagers, FilterManagers, FormStates, ModalConfigs, StatusColorMapper
mappers/              # Model ↔ DTO mappers (AirSeaMapper, PickUpMapper, etc.)
models/               # Logistics domain models
presentation/
  controllers/        # LogisticsOnboardingController
screens/              # UI screens per sub-feature
services/
  abstracts/          # IRequestActionHandler
  implementations/    # Role-specific handlers (HotlineDirectRoleHandler, etc.)
```

#### `features/personalization/`

```
controller/           # UserController, UpdateNameController  ← NOTE: singular "controller" folder
models/               # UserModel
screens/              # address/, profile/, settings/
```

#### `features/collection/`

```
helpers/              # CollectionStatusColors (status colour/icon mapping)
models/               # CollectionItemModel
presentation/
  controllers/        # CollectionOnboardingController, CollectionActivityController
  pages/              # home/, onboarding/, activity/
```

> **Folder-name inconsistency (known):** `personalization/controller/` (singular) vs `logistics/controllers/` (plural) vs `authentication/presentation/controllers/`. For new features, use **plural** `controllers/`. Do not rename existing folders unless explicitly asked.

---

## Naming

* Classes: **PascalCase**; files: **snake_case**; methods/vars: **camelCase**.
* Utility / constant classes use the **`B` prefix**: `BRoutes`, `BColors`, `BTexts`, `BSizes`, `BImages`, `BHelperFunctions`, `BHttpHelper`, `BAppTheme`, `BValidator`, `BFormatter`.
* Interface files: `i_<name>.dart` (e.g., `i_permission_service.dart`). Interface classes: `I<Name>` (e.g., `IPermissionService`).
  * Known exception: `location_alternative_service.dart` in abstracts (missing `i_` file prefix).
* `Result<T>`: `Result.success(value)` / `Result.failure(message)` — sealed class in `base/utils/result.dart`.
---

## Platform / services

* Centralize permissions in `IPermissionService` / `PermissionService` (registered in `main.dart` via `Get.put` **and** in `GeneralBindings` via `Get.lazyPut`).
* Centralize notifications in `INotificationService` / `NotificationService` (same dual registration).
* Keep platform overrides isolated and documented.
* Feature-specific service interfaces go in `features/<domain>/services/abstracts/`; implementations in `features/<domain>/services/implementations/`.

---

## Navigation

* Named routes via `BRoutes` (constants) + `AppRoutes.pages` (GetPage list).
* Bottom tabs handled by `NavigationMenu` using `NavigationController` (instantiated via `Get.put` in the widget).
* Post-auth department routing handled by `AppRouter`.
* **NavigationController details:** The controller stores screen route names and exposes a computed `screens` getter that selects widgets by user department (see `lib/data/controllers/navigation_controller.dart`). When adding or modifying tab behavior, prefer updating `NavigationController.screenRoutes`, `screens`, and `changeScreen` rather than wiring tab logic directly in widgets.
* Use GetX routing for app-level screen transitions; keep raw `Navigator.push` limited to low-level helpers such as `BHelperFunctions.navigateToScreen`.

---

## Style

* Prefer `const` when valid.
* **No `print`** in production code — use `logDebug()` (`base/utils/logger.dart`) for simple debug output or `BloggerHelper` (`base/utils/logging/logger.dart`) for structured logging.
* Add `///` docs for public classes and complex methods.

---

## Reactive UI

* Wrap only minimal subtrees in `Obx`.
* Prefer computed getters in controllers over ad-hoc calculations in `build`.

---

## Dependency Injection

* Register dependencies in `GeneralBindings` using `Get.lazyPut(fenix: true)` as the default.
* Use `Get.put` (with optional `permanent: true`) only for true singletons or early-init services — document why.
* Resolve via `Get.find()` in controllers and widgets.
* **Known legacy pattern (do not replicate):** Some controllers still instantiate repositories inline with `Get.put(UserRepository())`. New code must use `Get.find()` instead.
* Some services (`IPermissionService`, `INotificationService`) are registered early in `main.dart` via `Get.put` before `GeneralBindings` runs. This is intentional for pre-app-start initialization.
* `NavigationController` is instantiated via `Get.put` directly in `NavigationMenu` — acceptable for the bottom-tab shell.
* **Eager registrations in GeneralBindings:** Several core services/controllers are registered eagerly via `Get.put` in `GeneralBindings` (not only in `main.dart`): `Get.put(NetworkManager())`, `Get.put(WebSocketNotificationController())`, `Get.put(MessagingController())`, and `Get.put(UserController(), permanent: true)`. Always inspect `GeneralBindings` for the exact registration style and ordering.
* **Authentication DI:** The project registers the authentication repository via its interface and wires use-cases in `GeneralBindings`:
    * `Get.lazyPut<IAuthenticationRepository>(() => AuthenticationRepository(), fenix: true);`
    * `Get.lazyPut(() => LoginWithEmailPasswordUseCase(...), fenix: true);`
    * `Get.lazyPut(() => LoginWithGoogleUseCase(...), fenix: true);` — resolves `IAuthenticationRepository`, `UserRepository`, and `NetworkManager` via `Get.find()`.
* **Binding exceptions:** Some registrations intentionally differ from the default `fenix: true` pattern. For example `UserRepository` is registered without `fenix` (`Get.lazyPut(() => UserRepository());`). Check `GeneralBindings` before adding new bindings to match existing intent.
* **Developer/debug tools:** For in-app developer tools (such as the Local Storage Data Viewer), it is acceptable to instantiate controllers directly in the widget using `Get.put(...)` rather than registering in `GeneralBindings`.

---

## Quality gates

* After non-trivial edits, ensure `flutter analyze` is clean and run `flutter test` when applicable before finishing.

---

## Environment

* Windows PowerShell is the shell; when showing commands, keep each on its own line; if chaining on one line, use `;`.

---

## Working rules

* Prioritize active/open files and this repo's style.
* Don't change architecture unless explicitly asked.
* Keep answers short and impersonal.
* When asked for your name, respond with `GitHub Copilot`.
* **Before generating any widget, first search the existing utilities and shared widgets in `lib/base/utils` and `lib/common/widgets`. Reuse or extend existing components when applicable.**
* **If no suitable component is found, create a new widget and place it in either `lib/base/utils/popups` (framework-level) or `lib/common/widgets/<category>` (shared UI) depending on its scope and reusability.**
* **Never create inline private utility/formatting methods (e.g. `_formatAmount`, `_formatDate`) inside widgets or screens.** Check `BFormatter` (`lib/base/utils/formatters/formatters.dart`) and other `base/utils/` classes first. If no suitable method exists, add a new `static` method to the appropriate `base/utils/` class (e.g. `BFormatter`, `BHelperFunctions`) so it is reusable project-wide.

### Folder / placement checks

* Before adding business logic, creational code, or new services/controllers, inspect the target folder and nearby files to confirm the correct scope (feature vs common vs data).
* Check these locations first:
    * `lib/features/<domain>/controllers/`
    * `lib/features/<domain>/helpers/` (feature-scoped utilities)
    * `lib/common/controllers/` (cross-feature controllers)
    * `lib/common/services/{abstracts,implementations}/`
    * `lib/features/<domain>/services/{abstracts,implementations}/` (feature-specific)
    * `lib/data/repositories/<entity>/`
    * `lib/data/controllers/`
    * `lib/base/utils/`
    * `lib/bindings/`
* Keep cross-feature interfaces in `common/services/abstracts/`; implementations in `common/services/implementations/` or within the feature when feature-specific.
* When adding controllers or services, register them in `GeneralBindings` (or a route-specific binding) using `Get.lazyPut(fenix: true)` rather than instantiating in widgets.
* If placement is ambiguous, add a short README/TODO in the folder explaining the decision.

### Helpers — feature-scoped utilities

* **Feature-scoped utility classes** (status color/icon mappers, filter managers, form states, data managers, modal configs, etc.) belong in `features/<domain>/helpers/`, **not** inline in widgets or screens.
* Established examples:
    * `features/logistics/helpers/` — `LogisticsStatusColors`, `StandardDeliveryFilterManager`, `PullOutFilterManager`, etc.
    * `features/collection/helpers/` — `CollectionStatusColors` (status colour, icon, and display-text mapping).
* When adding a new utility that is specific to a single domain, create it in `features/<domain>/helpers/<snake_case_name>.dart`.
* If the utility is needed by **multiple** domains, promote it to `lib/base/utils/helpers/` or `lib/common/` instead.
* Never put colour/icon/status mapping logic directly inside widget `build` methods or as private helpers in screen files — extract it into the domain's `helpers/` folder so other screens in the same domain can reuse it.

---

## Documentation

* **Do NOT automatically create `.md` files.** Only create or update documentation when the user explicitly asks for it (e.g., "document this module", "create docs for X").
* Code changes, refactors, bug fixes, and feature implementations do **not** require accompanying `.md` files unless the user requests them.
* When documentation **is** requested:
    * Place all `.md` files in the `docs/` folder, never in the project root.
    * QA checklists live in `qa/` at project root (existing pattern).
    * Organize module-specific docs in `docs/modules/<module-name>/` (e.g., `docs/modules/air-sea/`).
    * Use SCREAMING_SNAKE_CASE for documentation file names (e.g., `AIR_SEA_MODULE_DOCUMENTATION.md`).
    * Include: overview, status flow, architecture, code examples, API details, testing guide, troubleshooting.
    * Keep `docs/README.md` updated with links when adding new module docs.

---

## Feature generation

When implementing a new feature, generate in this order:

1. **Model** — in `data/models/` (shared) or `features/<domain>/models/` (feature-scoped)
2. **DTO + Mapper** — in `features/<domain>/dtos/` and `features/<domain>/mappers/` (if API shape ≠ model shape)
3. **Repository** — in `data/repositories/<entity>/` (extends `GetxController`, handles API + local DB)
4. **Service interface + implementation** — only when cross-cutting or platform-specific logic is needed; place in `common/services/` or `features/<domain>/services/`
5. **Controller** — in `features/<domain>/controllers/`
6. **Binding registration** — in `GeneralBindings` (or route-specific binding)
7. **UI Screen** — in `features/<domain>/screens/` or `features/<domain>/presentation/pages/`
8. **Route registration** — add constant to `BRoutes`, add `GetPage` to `AppRoutes.pages`

Never skip layers that exist for the target domain.
Respect the feature-based folder structure already in use for that domain.

> For `authentication`, follow the Clean Architecture variant: Entity → Interface Repo → Use Case → Controller → UI.

---

## Recently added repositories and controllers

All registered in `GeneralBindings` unless noted:

### Repositories
- `BackLoadRepository` (`data/repositories/app_data/`, REST + local DB, outside Firebase guard)
- `InventoryItemRepository` (`data/repositories/inventory/`, Gemini OCR endpoint)
- `FormCategoryRepository` (`data/repositories/common/`)
- `CancelRemarksRepository` (`data/repositories/app_data/`)
- `UserMDMPIRepository` (`data/repositories/user/`)

### Controllers
- `BackLoadController`, `InventoryItemController`, `ChartController`, `RequestController`, `StockReceiveController`, `HotlineDirectController` — all in `features/logistics/controllers/`.
- `RequestHotlineController` (stub, **not** registered in `GeneralBindings` — do not `Get.find()` it without registering first).
- Additional controllers to inspect: `HomeController`, `DeliveryVehicleController`, `DeliveryLocationController`, `RequestTransportController`, `WebSocketNotificationController`, `WebSocketDispatcherController`, `WebSocketDeliveryController`, and `NavigationController`. Check `GeneralBindings` for registration style before using `Get.find()`.

### Role handlers
- `features/logistics/services/implementations/` contains `hotline_direct_role_handler.dart`, `request_role_handler.dart`, `pick_up_role_handler.dart`, `stock_receive_role_handler.dart` — implementing `IRequestActionHandler`.

---

## Text extraction service

The repository registers an `ITextExtractor` implementation (`DocumentReferenceExtractor`) in `GeneralBindings`:
- `Get.lazyPut<ITextExtractor>(() => DocumentReferenceExtractor(), fenix: true);`
- `CameraHandlerController` / `CameraController` obtain `ICameraService`, `ITextRecognitionService`, and `ITextExtractor` via `Get.find()`.
- Use `Get.find<ITextExtractor>()` when you need the extractor. Implement new extractors under `lib/common/services/abstracts/` and register in `GeneralBindings`.

---

## Local Storage Data Viewer

A developer-only tool for inspecting and managing SQLite database tables, under `lib/features/logistics/screens/data_test/`. Accessible from Settings > Developer Tools and via `/local-storage-viewer`. Must not be exposed in production builds.

---

## AI / LLM packages

Placeholder dependencies in `pubspec.yaml`: `flutter_ai_toolkit: any` and `firebase_ml_model_downloader: any`. Do NOT add API keys to the repo. When integrating a concrete package:
- Pin exact versions (do not leave `any`).
- Run `flutter pub get` and commit the resulting `pubspec.lock`.
- Prefer platform-safe, offline-capable packages for on-device models.

---

## Placeholder service stubs

Empty files, **not** registered in `GeneralBindings`:
- `common/services/abstracts/i_ai_service.dart` and `common/services/implementations/ai_service.dart`
- `common/services/abstracts/i_feature_toggle_service.dart` and `common/services/implementations/feature_toggle_service.dart`
- `common/widgets/feature_guard.dart`

Do NOT register these until they have real implementations.

> **`IDeliveryRequestController`** (`common/services/abstracts/i_delivery_request_controller.dart`) is a fully implemented 142-line interface (not empty). It defines the contract for delivery request controllers; both `StandardDeliveryController` and `HotlineDirectController` implement it.

---

## Empty placeholder files/folders

- `data/repositories/backload/` — empty folder; actual `BackLoadRepository` lives in `data/repositories/app_data/backload_repository.dart`.
- `data/repositories/app_data/sign_up_repository.dart` — empty file; signup logic is in `SignupController` + auth repos.
- `features/collection/domain/` — empty folder; collection does not yet use a domain layer.

---

## Known legacy print() calls

Replace with `logDebug()` or `BloggerHelper` when making changes in these files:
- `lib/data/repositories/inventory/inventory_item_repository.dart`
- `lib/features/logistics/controllers/standard_delivery_controller.dart`
- `lib/features/logistics/controllers/home_controller.dart`
- `lib/features/logistics/helpers/hotline_direct_data_manager.dart`
- `lib/features/logistics/screens/request_forms/widgets/pull_out_form.dart` and `lib/features/logistics/screens/common/b_request_form.dart`
- `lib/features/authentication/domain/usecases/login_with_google_usecase.dart`
- `lib/debug/reset_database.dart` (intentional console utility — safe in debug tool)

---

## Error handling

All async operations must:
- Use `try`/`catch`
- Return typed results (`Result<T>`) or handle failures gracefully
- Avoid throwing raw exceptions to UI
- Controllers expose observable error state (e.g., `RxnString errorMessage`)
- Use exception classes from `base/utils/exceptions/` for typed errors

---

## API integration

* **Repositories** handle API calls directly (via `BHttpHelper` or `http` package) — this is the established pattern.
* Controllers never call HTTP clients directly; they go through repositories.
* Map API responses to models (and through DTOs/mappers where they exist) before exposing to UI.

---

## Performance

* Avoid unnecessary widget rebuilds.
* Prefer `const` widgets.
* Extract reusable widgets when exceeding 80 lines.
* Avoid nested `Obx` unless required.
