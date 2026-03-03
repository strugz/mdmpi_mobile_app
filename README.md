# mdmpi_mobile_app

Multi-department mobile application built with **Flutter** and **GetX**. Supports Logistics, Collection, Service, and InHouse departments with role-based routing and feature modules.

## Getting Started

```bash
flutter pub get
flutter run
```

---

## Project Guidelines

Patterns and conventions used across this codebase (GetX, controllers, repositories, bindings).

### 1. State Management & Dependency Injection (GetX)

- Use `GetxController` with `Rx<T>` fields for reactive state.
- Keep business logic in Controllers, Repositories, or Services — never in widget `build` methods.
- Expose only minimal reactive fields; prefer computed getters over ad-hoc calculations in `build`.
- Wrap only the minimal widget subtree in `Obx`; avoid wrapping entire screens.
- Register dependencies in `GeneralBindings` using `Get.lazyPut(fenix: true)`. Use `Get.put` only for eagerly needed singletons (e.g. `AuthenticationRepository`) — document why.
- Resolve via `Get.find<T>()` — never manually instantiate repositories in controllers.
- Prefer `const` constructors when all fields are `final` and there are no side-effects.

### 2. Layering & Folder Structure

- **UI/Presentation:** `features/<domain>/screens` and `features/<domain>/widgets`.
- **Controllers:** `features/<domain>/controllers` or `data/controllers` (cross-domain).
- **Data Access:** `data/repositories/<context>` and `data/local`.
- **Common Services:** `common/services/abstracts` & `common/services/implementations`.
- **Bindings:** `bindings/` (app-wide). Feature-specific bindings when a module grows.
- Widgets stay lean — gather controller via `Get.find()`, render with `Obx`.
- Mapping/parsing logic belongs in repositories or dedicated mapper helpers.

### 3. Navigation

- Named routes via `BRoutes` + `AppRoutes.pages` for screen transitions.
- Bottom navigation uses `NavigationController` (`changeScreen` for tab swap, `navigateToScreen` for route push).
- Use GetX navigation uniformly — avoid mixing `Get.to` with `Navigator.push`.

### 4. Naming Conventions

- Classes: `PascalCase` · Files: `snake_case` · Variables/methods: `camelCase`.
- Constants: grouped with prefix (`BColors.primary`, `BAppTheme.lightTheme`).
- Reactive fields: descriptive nouns (`selectedIndex`) — no `Rx` suffix unless needed for clarity.

### 5. Logging & Error Handling

- Use `logDebug()` or `BloggerHelper` — no `print` in production code.
- Wrap async/init logic in `try/catch`; return `Result<T>` or expose observable error state.
- Surface user-facing errors via snackbars/dialogs from controller methods.

### 6. Platform Services

- Permissions are centralized in `IPermissionService` / `PermissionService`.
- Notifications are centralized in `INotificationService` / `NotificationService`.
- Keep platform-specific overrides (e.g. `MyHttpOverrides`) isolated and documented.

### 7. Repositories & Data Access

- Repositories abstract remote/local data sources and must not depend on widgets.
- Repositories handle API calls directly (via `BHttpHelper` or `http` package).
- Map API responses through DTOs/mappers to domain models before exposing to controllers.

### 8. Comments & Documentation

- Each public class: brief `///` doc comment.
- Non-trivial methods: summary, side-effects, error conditions.
- Use `/// TODO:` with context or issue ID for deferred work.

### 9. Testing Strategy

- **Unit:** repositories, controllers, utilities.
- **Widget:** critical screens and reactive updates.
- **Integration (future):** permission flows, notification taps, WebSocket events.
- Tests use `_test.dart` suffix under `test/`.

### 10. Security

- Environment variables via `.env` loaded in `main.dart`; never commit secrets.

### Code Style Checklist

- [ ] No stray `print` statements.
- [ ] Public classes have doc comments.
- [ ] Widgets use `const` where eligible.
- [ ] Business logic is not in `build` methods.
- [ ] Navigation uses route names from `BRoutes`.
- [ ] Controllers resolve dependencies via `Get.find()`.

---

## Module Documentation

Module-level documentation is maintained in the [`docs/`](docs/README.md) folder. See the **[Documentation Index](docs/README.md)** for the full module list, relationships, and conventions.

### Logistics

| Module | Status |
|---|---|
| [Air & Sea](docs/modules/air-sea/) | Active |
| [Standard Delivery](docs/modules/standard-delivery/) | Active |
| [Pick Up](docs/modules/pick-up/) | Active |
| [Pull Out](docs/modules/pull-out/) | Active |
| [Hotline Direct](docs/modules/hotline-direct/) | Active |
| [Stock Receive](docs/modules/stock-receive/) | Active |

### Cross-cutting

| Module | Status |
|---|---|
| [Authentication](docs/modules/authentication/) | Active |
| [Personalization](docs/modules/personalization/) | Active |

### Collection

| Module | Status |
|---|---|
| [Collection](docs/modules/collection/) | Early Dev |

QA checklists are in the [`qa/`](qa/) folder.

---

