---
description: Audit or inspect the local SQLite layer for a table, DAO, or model
argument-hint: <table|DaoClass|Model> [--images]
allowed-tools: Bash(dart run bin/inspect_db_images.dart:*)
---

Local database task: `$ARGUMENTS`.

- If `--images` is present, run `dart run bin/inspect_db_images.dart` and summarise the output.
- Otherwise launch the `db-schema-auditor` agent with the given table/DAO/model and relay its checklist.

Remind the user that the in-app Local Storage Data Viewer (Settings > Developer Tools) shows live table contents on a device, and that it must stay out of production flows.
