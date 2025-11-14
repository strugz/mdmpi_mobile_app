# Copilot Custom Instructions (Project)

- Architecture:
    - Use GetX (controllers + Rx). No Riverpod.
    - Keep UI pure: no business/data logic in `build`.
    - Controllers call repositories/services; DI via `Get.lazyPut(fenix: true)` and `Get.find()`.
    - Folder layout: `features/<domain>`, controllers in `features/.../controllers`, services in `common/services/{abstracts,implementations}`, bindings in `bindings/`.

- Naming:
    - Classes: PascalCase; files: snake_case; methods/vars: camelCase; constants grouped PascalCase.

- Platform/services:
    - Centralize permissions in `IPermissionService`/`PermissionService`.
    - Centralize notifications in `INotificationService`/`NotificationService`.
    - Keep platform overrides isolated and documented.

- Navigation:
    - Named routes via `BRoutes` + `AppRoutes.pages`, except bottom tabs.

- Style:
    - Prefer `const` when valid; no `print`, use `logDebug()`.
    - Add `///` docs for public classes and complex methods.

- Reactive UI:
    - Wrap only minimal subtrees in `Obx`; prefer computed getters in controllers over ad-hoc calculations in `build`.

- Dependency Injection:
    - Do not instantiate repositories/services inside controllers or widgets; resolve via `Get.find()`.
    - Register in bindings using `Get.lazyPut(fenix: true)` (or `Get.put` for true singletons).

- Quality gates:
    - After non-trivial edits, ensure `flutter analyze` is clean and run `flutter test` when applicable before finishing.

- Environment:
    - Windows PowerShell is the shell; when showing commands, keep each on its own line; if chaining on one line, use `;`.

- Working rules:
    - Prioritize active/open files and this repo’s style.
    - Don’t change architecture unless explicitly asked.
    - Keep answers short and impersonal.
    - When asked for your name, respond with `GitHub Copilot`.
