---
paths:
  - "lib/features/**/screens/**"
  - "lib/features/**/presentation/pages/**"
  - "lib/features/**/presentation/widgets/**"
  - "lib/features/**/widgets/**"
  - "lib/common/widgets/**"
  - "lib/navigation_menu.dart"
---

# UI & widgets

- No business logic in `build`. Controllers own logic; widgets wrap the **minimal** subtree in `Obx`.
- Bottom-anchored widgets (Android is edge-to-edge):
  - Pad for the navigation bar **once**, at the outermost bottom widget, with `SafeArea(top: false)`
    or `BDevicesUtils.systemBottomInset(context)`. Never wrap a whole `Scaffold`.
  - Pad for the keyboard with `viewInsets` **once** (`Scaffold` already handles `bottomNavigationBar`;
    sheet presenters add it themselves).
  - Never add both together. Never use `viewInsets.bottom > 0` to detect gesture navigation.
    `test/common/widgets/bottom_inset_test.dart` fails on that pattern.
- Reuse before creating: chips in `lib/common/widgets/chips/`, form fields in `lib/common/widgets/form/`,
  formatters in `BFormatter`, status colours via `StatusColorMapper`, logistics helpers in
  `features/logistics/helpers/` (`*DataManager`, `*FilterManager`, `*FormState`, `*ModalConfig`).
- Navigation: `Get.toNamed(BRoutes.x)`. Raw `Navigator.push` only inside low-level helpers.
- Bottom tabs: change `NavigationController.screenRoutes` / `screens` / `changeScreen`, not the widget.
- Developer tools (Local Storage Data Viewer, Signature Outbox) stay under Settings > Developer Tools
  and out of production flows.
- Every screen must render in a Windows window and on an Android phone; check text overflow and
  keyboard behaviour on both when touching forms.
- Widget tests go under `test/features/<domain>/`, mirroring the source path.
