# mdmpi_mobile_app

Multi-department mobile application built with **Flutter** and **GetX**, covering the
Logistics, Collection, Service and InHouse departments with role-based routing and
feature modules.

| | |
|---|---|
| **Version** | `1.1.102` (see `pubspec.yaml`) |
| **Dart SDK** | `^3.6.0` |
| **Targets** | Android and Windows desktop — every change must work on both unless stated otherwise |
| **State / DI / routing** | GetX |
| **Local persistence** | SQLite (`sqflite`, `sqflite_common_ffi` on desktop) |

---

## Prerequisites

- **Flutter SDK** on a channel providing Dart `^3.6.0`.
- **JDK 21 (Temurin)** pinned for Gradle. Android Studio's bundled Java 25 breaks
  Gradle 8.14.3, so point Flutter at Temurin 21 explicitly:

  ```powershell
  flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
  ```

  Adjust the path to whichever Temurin 21 build is installed.

- **Android SDK** with a device or emulator, for Android builds.
- **Visual Studio** with the "Desktop development with C++" workload, for Windows builds.
- **`.env`** — copy `.env.example` and fill it in. It is git-ignored and loaded in
  `main.dart`:

  ```powershell
  Copy-Item .env.example .env
  ```

  Keys: `API_URL`, `API4_URL`, `API_KEY`, `AI_TOOLKIT_GOOGLE_URL`, `AI_TOOLKIT_MODEL`,
  `AI_TOOLKIT_API_KEY`, `AI_TOOLKIT_AUTH_TYPE`, `AI_TOOLKIT_PROVIDER`, `AI_PROMPT`,
  `USE_GOOGLE_GENERATIVE`. Never commit secrets.

## Getting started

```powershell
flutter pub get
flutter run -d windows   # or: flutter run -d <android-device-id>
```

The shell used across this project is **PowerShell** — chain commands with `;`, not `&&`.

---

## Commands

| Command | Purpose |
|---|---|
| `flutter pub get` | Restore dependencies |
| `flutter analyze` | Static analysis — must pass before submitting |
| `flutter test` | Unit and widget tests (`test/*_test.dart`) |
| `flutter run` | Local development run |
| `.\build_apk.ps1` | Bump the build number and build the release APK (see below) |
| `dart run bin/generate_module_qa.dart --name "Name" --area Logistics --routes "/route"` | Scaffold a QA checklist under `qa/` |
| `dart run bin/inspect_db_images.dart` | Inspect images stored in the local SQLite database |
| `dart run bin/check_mapper.dart` | Check DTO/mapper wiring |
| `dart run tool/bump_build_number.dart` | Bump the `+n` build suffix in `pubspec.yaml` (normally invoked by `build_apk.ps1`) |

---

## Build and release

### Android APK

Use the build script rather than calling Flutter directly — it bumps the build number
and applies the Gradle workaround this project needs:

```powershell
.\build_apk.ps1
```

Extra arguments pass through to `flutter build apk`, e.g. `.\build_apk.ps1 --split-per-abi`.

The script runs `tool/bump_build_number.dart`, sets
`JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Users\Public` (without it the Gradle
daemon fails to start), then builds.

**Versioning.** `android/app/build.gradle` reads `versionCode` and `versionName` from the
`version: x.y.z+n` line in `pubspec.yaml` — `n` becomes `versionCode`, `x.y.z` becomes
`versionName`. Keep the `+n` suffix present: the bump tool matches on it and exits with an
error if it is missing. Never lower `n`, or installed devices see a version downgrade.

Any Gradle command run by hand needs the same workaround:

```powershell
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=C:\Users\Public'
```

### Windows desktop

`flutter build windows` needs `TRACKFILEACCESS=false` to get past MAX_PATH / FileTracker
limits:

```powershell
$env:TRACKFILEACCESS = 'false'; flutter build windows
```

The Windows release build has further pre-existing issues, so gate Dart-side work on
`flutter analyze` plus `flutter test` rather than on a green Windows build.

### Distribution

Release APKs are dropped on `\\192.168.4.118\Forms\MDMPIAPP` for the branches to pick up.

---

## API Environments

This application uses separate backends depending on the API route:

- `mdmpi_mobile_app` is the Flutter client in this repository.
- The sibling `MDMPI.App` ASP.NET repository implements `/api4/*` endpoints. This backend
  and its `/api4/*` routes are currently intended only for production testing.
- `/api3/*` endpoints and all API integrations outside `/api4/*` continue to use the
  existing live production backend.
- Firebase Authentication and other external integrations also remain connected to their
  live services.

Do not redirect `/api3/*` or other non-`/api4/*` traffic to `MDMPI.App`. When changing API
configuration, preserve this routing boundary unless the backend deployment strategy is
explicitly changed.

### Full-stack workspace

Open `../MDMPI.FullStack.code-workspace` to work with the Flutter client and the sibling
`MDMPI.App` repository together. The workspace includes tasks for Flutter package restore,
analysis and tests, plus ASP.NET build, tests and local startup.

Debug Flutter runs use `API4_URL_WINDOWS=http://localhost:5177` on Windows and
`API4_URL_ANDROID=http://10.0.2.2:5177` on the Android emulator. Release builds ignore
these local overrides. The overrides affect only locally implemented `/api4/*` routes;
`/api3/*`, `/api4/CNTMST/initial` (not currently implemented by the local `MDMPI.App`
source), and all other integrations continue using `API_URL` and their live services.

The local ASP.NET task prompts for production-database approval. Enter `true` only when
production testing is intentional and the machine has LAN/VPN access to the production SQL
Server and PostgreSQL services. `MDMPI.App` refuses to start in Development unless
`ALLOW_PRODUCTION_DB=true` is explicitly supplied, and it does not redirect or implement
`/api3/*` traffic.

---

## Project structure

```
lib/
  main.dart              # Entry point — .env load, platform bootstrap, Firebase
  app.dart               # Root widget and theming
  app_router.dart        # Department-based post-auth routing
  navigation_menu.dart   # Bottom navigation shell
  base/                  # Utils, theme, constants, routes (BRoutes / AppRoutes)
  bindings/app/          # GeneralBindings — app-wide DI (registration order matters)
  common/                # Shared widgets and service abstractions/implementations
  data/
    local/               # SQLite: database_helper.dart, db_schema.dart, dao/
    repositories/        # Remote/local data access by context
    services/            # Cross-cutting services (messaging, SMS, WebSocket)
  features/
    logistics/           # Controllers, screens, helpers, models
    collection/
    authentication/
    personalization/
  debug/                 # Developer-only surfaces
android/  windows/       # Platform projects
bin/  tool/              # Dart CLI utilities and build tooling
docs/  qa/               # Documentation and QA checklists
test/                    # Unit and widget tests
```

Early platform bootstrap lives in `lib/main.dart` and `lib/base/utils/platform_init.dart`
(sqflite FFI on desktop, conditional Firebase init). Firestore-backed repositories are
registered behind a `Firebase.apps.isNotEmpty` guard so Windows works without FlutterFire.

---

## Conventions

**[AGENTS.md](AGENTS.md) is the authoritative playbook** for working in this repository —
read it before non-trivial work. [CLAUDE.md](CLAUDE.md) is the Claude Code entry point and
`.github/copilot-instructions.md` carries the same conventions for Copilot. When
conventions change, update `AGENTS.md` first.

The short version:

- **New feature order:** Model → DTO/Mapper → Repository → Service → Controller → Binding
  (in `GeneralBindings`) → UI → Route (`BRoutes` + `AppRoutes.pages`).
- Register with `Get.lazyPut(..., fenix: true)`; resolve with `Get.find()`. Never
  instantiate repositories inside controllers. Never move or rename `GeneralBindings`.
- No `print()` — use `logDebug()` (`lib/base/utils/logger.dart`) or `BloggerHelper`.
- Async operations return `Result<T>` (`lib/base/utils/result.dart`) rather than throwing.
- No business logic in widget `build`; wrap only the minimal subtree in `Obx`.
- Utility classes take the `B` prefix (`BRoutes`, `BFormatter`, `BHttpHelper`).
- Files `snake_case`, classes `PascalCase`, variables and methods `camelCase`.
- Public classes get a `///` doc comment; non-trivial methods document side-effects and
  error conditions.
- Tests use the `_test.dart` suffix under `test/`.

### Pre-submit checklist

- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] No stray `print` statements.
- [ ] Business logic is out of `build` methods.
- [ ] Navigation uses route names from `BRoutes`.
- [ ] Controllers resolve dependencies via `Get.find()`.
- [ ] Change works on both Android and Windows.

---

## Developer-only tools

Reachable under **Settings > Developer Tools**. Keep them out of production UI:

| Tool | Route |
|---|---|
| Local Storage Data Viewer | `/local-storage-viewer` |
| Signature Outbox | `/signature-outbox` |

---

## Documentation

Full index: **[docs/README.md](docs/README.md)**. Application guides (user, role manual,
admin, developer) live in [`docs/application/`](docs/application/).

### Logistics modules

| Module | Status | Docs |
|---|---|---|
| Air / Sea / Land (base and HD tabs) | Active | [docs/modules/air-sea/](docs/modules/air-sea/) |
| Standard Delivery | Active | [docs/modules/standard-delivery/](docs/modules/standard-delivery/) |
| Hotline Direct | Active | [docs/modules/hotline-direct/](docs/modules/hotline-direct/) |
| Pick Up | Active | [docs/modules/pick-up/](docs/modules/pick-up/) |
| Pull Out / Return | Active | [docs/modules/pull-out/](docs/modules/pull-out/) |
| Stock Receive | Active | [docs/modules/stock-receive/](docs/modules/stock-receive/) |
| Inventory Item | Active | [docs/modules/inventory_item/](docs/modules/inventory_item/) |
| Request Forms (scanner rollout) | Active | [docs/modules/request-forms/](docs/modules/request-forms/) |
| BackLoad | Planned | [docs/modules/backload/](docs/modules/backload/) |

### Cross-cutting

| Module | Status | Docs |
|---|---|---|
| Authentication | Active | [docs/modules/authentication/](docs/modules/authentication/) |
| Personalization | Active | [docs/modules/personalization/](docs/modules/personalization/) |

### Collection

| Module | Status | Docs |
|---|---|---|
| Collection | Active | [docs/modules/collection/](docs/modules/collection/) |

### Other references

- [Post-demo revisions TO DO](docs/POST_DEMO_REVISIONS_TODO.md)
- [WebSocket disconnect handling](docs/WEBSOCKET_DISCONNECT_HANDLING.md)
- QA checklists: [`qa/`](qa/) — generated via `bin/generate_module_qa.dart`
- New documentation goes in `docs/` unless stated otherwise.
