---
description: Generate the QA checklist and module doc for a module via bin/generate_module_qa.dart
argument-hint: "<Module Name>" <Area> "/route[,/route2]"
allowed-tools: Bash(dart run bin/generate_module_qa.dart:*)
---

Generate QA material for `$ARGUMENTS`.

Arguments map to: `--name "<Module Name>" --area <Area> --routes "<routes>"`. Area is one of Logistics, Collection, Service, InHouse, Common.

1. Run:
   ```
   dart run bin/generate_module_qa.dart --name "<Module Name>" --area <Area> --routes "<routes>"
   ```
2. List the files it created (under `docs/modules/<slug>/` and `qa/`).
3. Open the generated checklist and add module-specific cases the generator cannot know: platform differences (Android vs Windows), offline/SQLite behaviour, API prefix used, bottom-inset/keyboard behaviour for forms.
4. Ensure `docs/README.md` has an index entry for the module.

Do not commit.
