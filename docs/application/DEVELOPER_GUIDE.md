# Logistics Developer Guide

This guide summarizes how to build, test, and extend the Logistics area of the MDMPI Mobile App. It complements `.github/copilot-instructions.md`, `AGENTS.md`, and the Logistics module documentation under `docs/modules/`.

## Quick Start

Run commands from the project root:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Use PowerShell on Windows. Keep Logistics workflows compatible with both Windows and Android unless a change is explicitly platform-specific.

Useful repo scripts:

```powershell
dart run bin/generate_module_qa.dart --name "My Module" --area Logistics --routes "/route"
dart run bin/inspect_db_images.dart
dart run bin/check_mapper.dart
```

## Logistics Architecture

The app uses Flutter and GetX for state management, routing, and dependency resolution. Logistics is the primary feature area under `lib/features/logistics/`.

Important Logistics entry points:

- `lib/features/logistics/controllers/`: Logistics controllers.
- `lib/features/logistics/screens/`: Logistics screens, request lists, request forms, location, onboarding, and support views.
- `lib/features/logistics/helpers/`: data managers, filter managers, form state, modal config, and status mapping.
- `lib/features/logistics/mappers/`: DTO/model mapping.
- `lib/features/logistics/models/`: Logistics domain models.
- `lib/features/logistics/dtos/`: request DTOs by category.
- `lib/data/repositories/`: Logistics repositories and shared app-data repositories.
- `lib/data/local/dao/`: SQLite DAOs used by Logistics.
- `lib/bindings/app/general_bindings.dart`: canonical dependency registration.
- `lib/base/utils/routes/app_routes.dart`: Logistics route and form page registration.

Follow the established feature order:

```text
Model -> DTO/Mapper -> Repository -> Service (if cross-cutting) -> Controller -> Binding -> UI -> Route
```

## Logistics Request Modules

The Request screen loads form categories through `RequestController` and maps each category to its controller, list widget, filters, and form.

Supported categories:

- Standard Delivery
- Pull Out / Return
- Pick Up
- Air / Sea / Land
- Hotline Direct
- Stock Receive

BackLoad is routed separately through `/back-load` and expects a `StandardDeliveryModel` via `Get.arguments`.

Category reuse:

- Hotline Direct reuses Standard Delivery form/data patterns.
- Stock Receive reuses Pull Out / Return form/data patterns.

## Key Controllers

Important Logistics controllers include:

- `RequestController`
- `StandardDeliveryController`
- `PullOutController`
- `PickUpController`
- `AirSeaController`
- `HotlineDirectController`
- `StockReceiveController`
- `BackLoadController`
- `DeliveryLocationController`
- `RequestTransportController`
- `WebSocketDeliveryController`
- `WebSocketDispatcherController`
- `RiderRealtimeTrackingController`

Resolve dependencies with `Get.find()` after registration. Do not instantiate repositories inside controllers.

## GetX and Dependency Injection

Use GetX consistently:

- Controllers extend `GetxController`.
- Repositories commonly extend `GetxController`.
- Register shared dependencies in `GeneralBindings`.
- Prefer `Get.lazyPut(..., fenix: true)` unless the codebase already uses a different pattern.
- Use `Get.put(..., permanent: true)` only for true singletons with clear lifecycle intent.

Important Logistics DI details:

- `BackLoadRepository` is REST/local DB based and registered outside the Firebase guard.
- Firestore-backed repositories stay inside the Firebase guard.
- `UserController` is permanent and is consumed by Logistics flows for user/request metadata.
- Delivery-location integrations are DI-managed: `ILocationAlternativeService`, `IMapsService`, `IPlacesService`, and `ILocationTrackingService`.
- `ITextExtractor` is registered centrally and used by camera/text-recognition flows.
- Developer/debug pages such as outboxes may instantiate controllers in-widget when intentionally isolated.

## Routing and Navigation

Use named routes for app-level navigation:

- Route constants: `lib/base/utils/routes/routes.dart`
- GetPage list: `lib/base/utils/routes/app_routes.dart`
- Department routing: `lib/app_router.dart`
- Bottom tab behavior: `lib/data/controllers/navigation_controller.dart`

Logistics-relevant routes include:

- `/`
- `/settings`
- `/request`
- `/location`
- `/pull-out-form`
- `/local-storage-viewer`
- `/signature-outbox`
- `/image-outbox`
- `/back-load`

The bottom navigation for Logistics uses:

- HomeScreen
- RequestScreen
- LocationPageGoogle
- SettingsScreen

When modifying tabs, update `NavigationController.screenRoutes`, `screens`, and `changeScreen` behavior instead of wiring tab logic directly in widgets.

## Department Routing Context

`AppRouter` checks the current/cached user department and onboarding flags. Logistics uses:

- `LogisticsOnboardingComplete`

Collection, Service, and InHouse are shared app concerns but are outside this Logistics guide unless a change touches cross-department routing.

## Data Layer

The Logistics data layer mixes remote APIs and local SQLite:

- Repositories call APIs and local DB helpers.
- SQLite is centralized through `lib/data/local/database_helper.dart`.
- Table definitions live in `lib/data/local/db_schema.dart`.
- DAOs live under `lib/data/local/dao/`.
- DTOs and mappers convert between API payloads, DB records, and domain models.

Logistics-relevant tables include:

- `a_tblRequest`
- `a_tblRequestDocumentReference`
- `a_tblRequestReceiverSignature`
- `a_tblRequestImage`
- `a_tblRequestImageOutbox`
- `a_tblRequestRemarks`
- `a_tblRequestPickUp`
- `a_tblRequestAirSea`
- `a_tblRequestPullOutReturnPickUp`
- `a_tblRequestBackload`
- `ACCMST_`
- `a_tblMobile`
- `Users`
- `CNTMST`
- `contacts`
- `a_tblItemCategory`
- `a_tblFormCategory`
- `a_tblLocationAlternative`
- `a_tblClientContactPerson`

Use DAOs and repository helpers instead of raw SQL in widgets or controllers.

## Platform Notes

Keep Android and Windows behavior in mind:

- Android initialization requests storage, location, camera, and SMS where applicable.
- Desktop/web paths request only supported permissions such as location and camera.
- Android creates the app folder under `/storage/emulated/0/MDMPIAPP`.
- Desktop uses the application documents directory.
- Desktop SQLite requires sqflite FFI initialization.
- Firebase initialization is conditional and may be skipped on desktop when FlutterFire is not configured.

## Logistics Services

Logistics workflows rely on shared services for:

- Permissions
- Notifications
- Camera capture
- ML Kit text recognition
- Text extraction
- Maps and places
- Location alternatives
- Realtime location tracking
- SMS messaging
- WebSocket delivery/dispatcher updates

Resolve registered service abstractions through `Get.find()` instead of calling platform APIs directly from widgets.

## Logging and Errors

Do not add `print` statements.

Use:

- `logDebug()` from `lib/base/utils/logger.dart` for simple debug messages.
- `BloggerHelper` from `lib/base/utils/logging/` for structured logs.
- `Result<T>` from `lib/base/utils/result.dart` for typed async results when appropriate.

Surface user-facing failures through controller-managed UI feedback, snackbars, dialogs, or observable error state.

## Developer and Debug Tools

Logistics support/debug tools include:

- Local Storage Viewer: SQLite table inspection and data management.
- Signature Outbox: pending/failed receiver signature uploads.
- Image Outbox: pending/failed proof image uploads.
- `dart run bin/inspect_db_images.dart`: DB image/signature inspection.
- `dart run bin/generate_module_qa.dart`: module QA docs/checklist generation.

Keep these tools out of normal production user workflows unless intentionally authorized.

## Testing

Before submitting changes, run:

```powershell
flutter analyze
flutter test
```

Add tests based on risk:

- Unit tests for Logistics repositories, mappers, DAOs, controllers, and utilities.
- Widget tests for request lists, forms, filters, and reactive state.
- Integration-style tests for platform services only when the environment supports them.

Tests live under `test/` and use the `_test.dart` suffix.

## Adding or Changing a Logistics Feature

1. Search for shared utilities in `lib/base/utils/`, `lib/common/widgets/`, and `lib/features/logistics/helpers/`.
2. Follow the feature order: Model, DTO/Mapper, Repository, Service if needed, Controller, Binding, UI, Route.
3. Register dependencies in `GeneralBindings` unless the feature is an intentional developer/debug tool.
4. Use `Get.find()` for dependencies.
5. Add route constants to `BRoutes` and page entries to `AppRoutes.pages` when adding screens.
6. Update `RequestController` when a category needs list, filter, form, or controller mapping.
7. Use `logDebug()` or `BloggerHelper`; do not add `print`.
8. Keep Windows and Android compatibility in code and docs.
9. Update Logistics module docs or these application docs when behavior changes.
10. Run analysis and tests.

## Documentation Maintenance

- Logistics application-level docs live in `docs/application/`.
- Logistics module docs live in `docs/modules/`.
- QA checklists live in `qa/`.
- Keep `docs/README.md` as the main documentation index.
- Future Logistics `.md` files should go under `docs/` unless a project-root file is explicitly requested.
