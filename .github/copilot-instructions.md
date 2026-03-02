# Copilot Custom Instructions (mdmpi_mobile_app)

## Architecture

* Use **GetX** (controllers + Rx). No Riverpod.
* Keep UI pure: no business/data logic in `build`.
* Controllers call repositories (and services where they exist); DI via `Get.lazyPut(fenix: true)` and `Get.find()`.

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
                      #   air_sea/, app_data/, authentication/, client/, common/,
                      #   delivery_vehicle/, image/, pick_up/, pull_out/,
                      #   standard_delivery/, user/
services/             # MessagingController (SMS via telephony)
```

> **Note:** Repositories extend `GetxController` and make API/DB calls directly — there is no separate service layer wrapping HTTP for most features. This is the established pattern.

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
presentation/
  controllers/        # CollectionOnboardingController
  pages/              # home/, onboarding/
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

### Folder / placement checks

* Before adding business logic, creational code, or new services/controllers, inspect the target folder and nearby files to confirm the correct scope (feature vs common vs data).
* Check these locations first:
    * `lib/features/<domain>/controllers/`
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
