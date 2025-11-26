# Copilot Custom Instructions (mdmpi_mobile_app)

* Architecture:

    * Use GetX (controllers + Rx). No Riverpod.
    * Keep UI pure: no business/data logic in `build`.
    * Controllers call repositories/services; DI via `Get.lazyPut(fenix: true)` and `Get.find()`.
    * Folder layout: `features/<domain>`, controllers in `features/.../controllers`, services in `common/services/{abstracts,implementations}`, bindings in `bindings/`.

* Naming:

    * Classes: PascalCase; files: snake_case; methods/vars: camelCase; constants grouped PascalCase.

* Platform/services:

    * Centralize permissions in `IPermissionService`/`PermissionService`.
    * Centralize notifications in `INotificationService`/`NotificationService`.
    * Keep platform overrides isolated and documented.

* Navigation:

    * Named routes via `BRoutes` + `AppRoutes.pages`, except bottom tabs.

* Style:

    * Prefer `const` when valid; no `print`, use `logDebug()`.
    * Add `///` docs for public classes and complex methods.

* Reactive UI:

    * Wrap only minimal subtrees in `Obx`; prefer computed getters in controllers over ad-hoc calculations in `build`.

* Dependency Injection:

    * Do not instantiate repositories/services inside controllers or widgets; resolve via `Get.find()`.
    * Register in bindings using `Get.lazyPut(fenix: true)` (or `Get.put` for true singletons).

* Quality gates:

    * After non-trivial edits, ensure `flutter analyze` is clean and run `flutter test` when applicable before finishing.

* Environment:

    * Windows PowerShell is the shell; when showing commands, keep each on its own line; if chaining on one line, use `;`.

* Working rules:

    * Prioritize active/open files and this repo’s style.
    * Don’t change architecture unless explicitly asked.
    * Keep answers short and impersonal.
    * When asked for your name, respond with `GitHub Copilot`.
    * **Before generating any widget, first search the existing utilities and shared widgets in `lib/base/utils` and `lib/common`. Reuse or extend existing components when applicable.**
    * **If no suitable component is found, create a new widget and place it in either `lib/base/utils` or `lib/common` depending on its scope and reusability.**

    * **Folder / placement checks (new):**
        * Before adding business logic, creational code, or new services/controllers, inspect the target folder and nearby files to confirm the correct scope (feature vs common). Check `lib/features/<domain>/controllers`, `lib/common/services/{abstracts,implementations}`, `lib/base/utils`, and `lib/bindings` first.
        * Favor creational patterns for constructing objects/services: use Factory or Abstract Factory for reusable creation logic; prefer Builders for complex object assembly; use Singleton only when justified and register singletons via `Get.put` (document why). Keep interfaces (abstracts) in `common/services/abstracts` and implementations in `common/services/implementations` or within the feature when feature-specific.
        * When adding controllers or services, register them in the appropriate `Binding` using `Get.lazyPut(fenix: true)` (or `Get.put` for true singletons) rather than instantiating in widgets.
        * If placement is ambiguous, add a short README/TODO in the folder explaining the decision and include a link to this guideline.
