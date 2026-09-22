---
paths:
  - "lib/data/**"
  - "lib/features/**/models/**"
  - "lib/features/**/dtos/**"
  - "lib/features/**/mappers/**"
---

# Data layer: models, DTOs, mappers, repositories, SQLite

- Feature order: **Model → DTO/Mapper → Repository → Service → Controller → Binding → UI → Route.**
  Do not jump to the controller before the repository exists.
- Async repository/DAO methods return `Result<T>` (`lib/base/utils/result.dart`). Do not throw raw
  exceptions across the repository boundary; wrap and return a failure.
- Repositories extend `GetxController` and are registered in `GeneralBindings` (see the getx-di rule).
- SQLite: schema in `lib/data/local/db_schema.dart`, access via `lib/data/local/database_helper.dart`,
  queries in a domain DAO under `lib/data/local/dao/<domain>/`. Adding a table or column means:
  1. update `db_schema.dart` and the migration path,
  2. add or extend the DAO,
  3. add a DAO test under `test/`,
  4. confirm the Local Storage Data Viewer still lists the table.
- Desktop uses sqflite FFI (initialised in `platform_init.dart`). Never call platform-only DB APIs.
- Mappers are pure: JSON/row in, model out. Put parsing edge cases in a `*_mapper_test.dart`.
- Legacy server records may be incomplete (e.g. `cntmst` rows without `CNTSTS`). Parse defensively;
  never assume a key exists.
- Never commit `.env`; read keys through the existing env loading in `main.dart`.
