---
paths:
  - "lib/base/utils/routes/**"
  - "lib/app_router.dart"
  - "lib/app.dart"
---

# Routing

- Add the constant to `BRoutes` (`routes.dart`) **and** a `GetPage` to `AppRoutes.pages`
  (`app_routes.dart`). One without the other is a bug.
- Route names are kebab-case paths (`'/back-load'`, `'/signature-outbox'`).
- Pages that need an argument read it from `Get.arguments`; document the expected type in a
  doc comment on the `GetPage`.
- Post-auth department routing lives in `lib/app_router.dart`. It reads `UserController.user.department`,
  then falls back to `GetStorage` key `CurrentUser` (legacy `UserDepartment`). Onboarding flags:
  `LogisticsOnboardingComplete`, `CollectionOnboardingComplete`, `ServiceOnboardingComplete`,
  `InHouseOnboardingComplete`. Keep new departments consistent with this pattern.
- Per-route bindings (e.g. `RequestBindings`) are placeholders; controllers are registered centrally.
