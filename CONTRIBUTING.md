# Contributing Guidelines (mdmpi_mobile_app)

This condensed checklist reflects the current architecture and replaces the generic sample instructions.

## Core Principles
- Use GetX for state management (controllers + Rx fields). No Riverpod at this time.
- Keep UI pure: no business logic or data access inside widget `build` methods.
- Favor composition: controllers call repositories/services; widgets observe controllers.

## Constructors & Immutability
- Use `const` for widgets and models when all fields are `final` and no side-effects.
- Skip `const` if runtime values or injected dependencies change across rebuilds.

## Folder & Layering
- UI: `features/<domain>/screens` & `features/<domain>/widgets`
- Controllers: `features/<domain>/controllers` or shared in `data/controllers`
- Repositories/Data: `data/repositories`, local DB in `data/local`
- Services/Abstractions: `common/services/{abstracts,implementations}`
- Bindings: global in `bindings/`; add feature bindings if isolation needed

## State & DI
- Register controllers/repositories via `Get.lazyPut(fenix: true)` unless truly global singletons (`Get.put`).
- Resolve dependencies with `Get.find()` (no manual `new SomeRepository()` inside controllers).

## Navigation
- Use named routes via `BRoutes` + `AppRoutes.pages` except bottom tab switches.
- Bottom nav uses `NavigationController.changeScreen`; deeper transitions use `navigateToScreen` or `Get.toNamed`.

## Naming Conventions
- Classes: PascalCase (`DeliveryVehicleController`)
- Files: snake_case (`delivery_vehicle_controller.dart`)
- Variables/methods: camelCase (`selectedIndex`, `fetchVehicles`) 
- Constants: grouped PascalCase (`BColors.primary`)
- Avoid cryptic abbreviations; be explicit.

## Comments & Docs
- Every public class: `///` one-line purpose.
- Complex methods: brief doc incl. side-effects & error behavior.
- Use `/// TODO:` with context (NO orphan commented blocks).

## Logging & Errors
- Use `logDebug()` not `print`.
- Catch and log initialization errors (Firebase, DB, permissions). Surface user-impacting errors via UI (snackbar/dialog) from controllers.

## Permissions & Platform
- Centralize permission logic in `IPermissionService`/`PermissionService` (currently partly in `main.dart`).
- Centralize notifications in `INotificationService`/`NotificationService`.
- Keep platform overrides (e.g. `MyHttpOverrides`) isolated & documented.

## Data & Repositories
- Repositories handle mapping & remote/local coordination. No widget/UI dependencies.
- Keep role/authorization branching out of widgets; put in controllers/services.

## Reactive UI Performance
- Wrap only minimal subtrees in `Obx`.
- Prefer computed getters in controllers over ad-hoc calculations in `build`.

## Notifications & Messaging
- Consider extracting notification setup into `NotificationService` as features grow.
- WebSocket controllers own connection lifecycle & expose reactive fields/events.

## Testing
- Unit: repositories (mapping), controllers (logic), utilities (extractors).
- Widget: navigation menu, forms, reactive displays.
- Integration (future): permission flow, notification tap, WebSocket events.
- Mirror feature structure under `test/` with `_test.dart` suffix.

## Security
- Use `.env` for secrets; never commit real credentials. Provide sample placeholders when needed.

## Migration Notes
- No Riverpod at this time. If reconsidered later, document via an ADR and run a spike before introducing providers alongside GetX; deprecate controllers after parity & tests.

## Style Checklist Before Commit
- [ ] No `print` calls.
- [ ] Added/updated doc comments for new public classes/methods.
- [ ] Widgets use `const` where valid.
- [ ] No business/data logic in `build` methods.
- [ ] Dependencies resolved via DI (no inline new repository instantiation).
- [ ] Navigation uses route constants.

# Copilot agent rules

The authoritative agent rules live in `/.github/copilot-instructions.md`. Read and follow that file for architecture, naming, navigation, and style guidelines.

Copilot setup (Android Studio on Windows):
1. Settings > Tools > GitHub Copilot > Chat.
2. Enable Project Copilot Instructions.
3. Enable Instruction Files and point to `/.github/copilot-instructions.md`.

Change management:
- If the rules change, update both `/.github/copilot-instructions.md` and this `CONTRIBUTING.md` note to stay in sync.

Following this keeps the project consistent, testable, and easier to evolve.
