import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';

/// Debug entrypoint: prints all form categories in the database
/// Run with:
///   flutter run -t lib/debug/inspect_form_categories.dart -d <deviceId>

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final helper = DatabaseHelper.instance;
    final dao = await helper.formCategoryDao;

    final categories = await dao.getAll();

    print('=== Form Categories Inspection ===');
    print('Total form categories: ${categories.length}');
    for (var category in categories) {
      print('ID: ${category.id}, Name: ${category.name}');
    }
    print('=== Inspection Complete ===');
  } catch (e, st) {
    print('Error inspecting form categories: $e');
    print(st);
  } finally {
    exit(0);
  }
}

