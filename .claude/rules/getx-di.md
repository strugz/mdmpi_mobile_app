---
paths:
  - "lib/bindings/**"
  - "lib/features/**/controllers/**"
  - "lib/features/**/controller/**"
  - "lib/data/controllers/**"
  - "lib/common/controllers/**"
---

# GetX state management & dependency injection

- All DI lives in `lib/bindings/app/general_bindings.dart`. **Registration order matters**:
  repositories before the controllers that use them. Never move or rename `GeneralBindings`.
- Register with `Get.lazyPut(() => X(), fenix: true)`. Resolve with `Get.find<X>()`.
  `Get.put(..., permanent: true)` only for justified singletons (`UserController` is the precedent).
- Firestore-backed repos go **inside** the `if (Firebase.apps.isNotEmpty) { ... }` guard.
  REST + SQLite repos (e.g. `BackLoadRepository`) go **outside** it so desktop works without FlutterFire.
- Never instantiate a repository inside a controller. Never `Get.put` a repo inline in a widget.
  Exception: developer-only tools (Local Storage Data Viewer, Signature Outbox) may `Get.put`
  their own controller in-widget.
- Prefer constructor injection resolved via `Get.find()` at registration time
  (see the `CameraHandlerController` registration) over `Get.find()` calls scattered inside methods.
- Interfaces: register against the abstraction (`Get.lazyPut<ITextExtractor>(...)`); implement under
  `lib/common/services/abstracts/` + `implementations/`.
- Do not register the empty placeholder stubs (`IAiService`, `IFeatureToggleService`, `FeatureGuard`)
  until they have real implementations.
- Auth controllers stay lazy (`fenix: true`) so Firebase is not touched at desktop startup.
- Controllers: no widget code, no stored `BuildContext`; expose `Rx`/`RxList` state and keep async
  work returning `Result<T>`.
