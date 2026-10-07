---
description: Add a named route (BRoutes constant + GetPage) for an existing page widget
argument-hint: <PageWidget> </kebab-path> [ArgumentsType]
---

Wire a route for `$ARGUMENTS`.

1. Confirm the page widget exists (`grep -rn "class <PageWidget>" lib`). If not, stop and say so.
2. Add `static const <camelName> = '</kebab-path>';` to `BRoutes` in `lib/base/utils/routes/routes.dart`, alphabetically near related routes.
3. Add a `GetPage(name: BRoutes.<camelName>, page: () => const <PageWidget>())` to `AppRoutes.pages` in `lib/base/utils/routes/app_routes.dart`. If an arguments type was given, read it from `Get.arguments` in the page builder and add a doc comment stating the expected type.
4. If the page needs a controller that is not yet in `GeneralBindings`, say so and stop; do not `Get.put` it in the page.
5. Run `flutter analyze`.

Report the two edits as `path:line`. Do not commit.
