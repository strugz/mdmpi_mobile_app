# mdmpi_mobile_app

A new Flutter project.

## Getting Started

---

## Project Guidelines (Tailored to Current Codebase)

These replace the earlier generic sample instructions and reflect the actual patterns used (GetX, controllers, repositories, bindings).

### 1. Constructors & Immutability

- Prefer `const` constructors for `StatelessWidget`/`StatefulWidget` and simple model classes when all fields are `final` and there is no side-effect in the constructor.
- Avoid `const` if the widget depends on runtime data that can change (e.g. values from reactive `Rx` vars passed directly).

### 2. State Management (GetX)

- Use GetX Controllers (`extends GetxController`) with `Rx<T>` fields for reactive state.
- Keep business logic (transformations, network calls, persistence) inside Controllers, Repositories, or Services—not inside widget `build` methods.
- Expose only the minimal reactive fields. Prefer wrapping complex logic in methods instead of leaking multiple `Rx` members.
- Use `Get.lazyPut` with `fenix: true` for controllers that may be disposed and re-created. Use `Get.put` only for eagerly needed singletons (e.g. `AuthenticationRepository`).

### 3. Layering & Folder Structure

- UI/Presentation: under `features/<domain>/screens` and `features/<domain>/widgets`.
- Controllers: `features/<domain>/controllers` OR shared ones under `data/controllers` when cross-domain.
- Data Access: `data/repositories/<context>` and local DB helpers/services under `data/local`.
- Common Services & Abstractions: `common/services/abstracts` & `common/services/implementations`.
- Bindings: Central app-wide registrations in `bindings/` (e.g. `GeneralBindings`). Feature-specific bindings can be added if a module grows.

### 4. Navigation

- Prefer named routes via `BRoutes` + `AppRoutes.pages` for screen transitions outside bottom navigation tab switches.
- Bottom navigation uses `NavigationController`; `changeScreen` swaps tab body; `navigateToScreen` pushes route when a full transition/stack is desired.
- Avoid mixing `Get.to` and `Navigator.push` directly—use GetX uniformly.

### 5. Separation of Concerns

- Widgets should remain as lean as possible: gather controller via `Get.find<Controller>()` or parameter injection and render state using `Obx`.
- Heavy computations, permission checks, DB or Firestore queries belong in controllers or repositories.
- Keep mapping/parsing logic in repositories or dedicated mapper helpers (test these in `/test`).

### 6. Naming Conventions

- Classes: PascalCase (e.g. `StandardDeliveryController`).
- Variables, methods, function parameters: camelCase.
- Files: snake_case (e.g. `standard_delivery_controller.dart`).
- Reactive fields: descriptive nouns (e.g. `selectedIndex`)—avoid abbreviations; no need to suffix with `Rx` unless needed for clarity in complex controllers.
- Constants: PascalCase with an identifying prefix where grouped (e.g. `BColors.primary`, `BAppTheme.lightTheme`).

### 7. Comments & Documentation

- Each public class: a brief `///` doc comment describing role and responsibility.
- Non-trivial methods: a short summary, note on side-effects (network call, DB write) and error conditions.
- Use `/// TODO:` with context or issue ID for deferred work; avoid leaving unexplained commented code blocks.

### 8. Logging & Error Handling

- Use `logDebug(message)` instead of `print` to ensure logs are suppressed in release.
- Wrap initialization (Firebase, DB, permissions) in `try/catch` with meaningful debug log messages.
- User-facing errors should surface through UI (snackbars, dialogs) from controller methods—centralize style for these.

### 9. Permissions & Platform Services

- Centralize permission request logic (currently partially in `main.dart`) into a service or controller when it grows further.
- Keep platform-specific overrides (e.g. `MyHttpOverrides`) isolated and documented.

### 10. Notifications & Messaging

- Local notifications initialization lives in `main.dart`; if expanded, move to a `NotificationService` with init + show APIs.
- WebSocket and messaging controllers should encapsulate connection lifecycle; expose clean reactive streams or events.

### 11. Repositories & Data Access

- Repositories abstract remote/local data sources; they should not depend on widgets.
- Handle serialization/deserialization and mapping between raw responses and domain models inside repositories or dedicated mapper utilities.
- Avoid placing business decisions (branching on user roles) in the UI; keep them in controllers/services.

### 12. Reactive Updates & Performance

- Use `Obx` only around the widget subtree that truly needs updating; avoid wrapping entire large screens if only a small portion changes.
- Prefer derived/computed properties inside controllers instead of computing them repeatedly in `build`.

### 13. Testing Strategy

- Unit Tests: repositories (data mapping, transformations), controllers (logic without UI), utilities (e.g. extractors).
- Widget Tests: critical screens (forms, navigation menu) focusing on reactive updates.
- Integration (future): permission flows, notification taps, WebSocket event handling.
- Name tests with `_test.dart` suffix and keep them in parallel folder structure under `test/`.

### 14. Dependency Injection Rules

- Register interfaces with concrete implementations (`ICameraService` → `FlutterCameraService`) in a binding before first use.
- Do not manually instantiate repositories inside controllers—resolve them with `Get.find()` to uphold inversion of control.

### 15. Security & Secrets

- Environment variables via `.env` loaded early in `main.dart`; never commit secrets—use placeholders in example configs.

### 16. Migration & Future Improvements

- If transitioning to a different state management solution (e.g. Riverpod), do it module-by-module: introduce providers parallel to existing controllers, then deprecate controllers after parity.
- Consider extracting permission logic into `PermissionService` and notification logic into `NotificationService` for clearer testability.

### 17. Code Style Consistency Checklist

- [ ] No stray `print` statements.
- [ ] Public classes have doc comments.
- [ ] Widgets use `const` where eligible (no mutable fields, no runtime-only params).
- [ ] Business logic is not embedded in `build` methods.
- [ ] Navigation uses route names from `BRoutes` when leaving current tab context.
- [ ] Controllers obtain dependencies through GetX DI (no `new Repository()` inline).

Adhering to these guidelines will keep the architecture consistent and maintainable as the project grows.

---

## Module Documentation

### Logistics Module

#### Air/Sea Module
Complete documentation for the Air/Sea logistics request management system.

📄 **[Air/Sea Module Documentation](docs/modules/air-sea/AIR_SEA_MODULE_DOCUMENTATION.md)**

**Topics Covered**:
- Complete status flow and lifecycle
- Role-based access control (Request, Release, Courier, Viewer)
- Data model and field usage
- GetX architecture implementation
- Feature implementations:
  - Item Packed dual-path selection (Endorsed to Guard / Received)
  - Waybill number input
  - Digital signature capture
  - Proof image documentation
  - Dispatch information management
  - Drop-off confirmation workflow
- UI components and widget hierarchy
- API integration and endpoints
- Testing guide and scenarios
- Troubleshooting common issues
- Performance optimization tips

**Status**: ✅ Production Ready | **Version**: 2.0 | **Last Updated**: December 17, 2025

---

