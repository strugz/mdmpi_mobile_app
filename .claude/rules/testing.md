---
paths:
  - "test/**"
---

# Tests

- Files end in `_test.dart` and mirror the source path (`test/features/collection/...` for
  `lib/features/collection/...`). Fixtures live in `test/fixtures/`.
- DAO tests run against sqflite FFI in-memory DBs; never depend on a device.
- Mapper tests must cover: happy path, missing keys, null/empty strings, legacy field names.
- Widget tests: pump inside a `GetMaterialApp`, register needed controllers with `Get.put` in
  `setUp`, and call `Get.reset()` in `tearDown`.
- `test/common/widgets/bottom_inset_test.dart` is a guard rail. If it fails after a UI change,
  fix the widget, not the test.
- Run the narrowest target first (`flutter test test/path/x_test.dart`), then the full suite.
