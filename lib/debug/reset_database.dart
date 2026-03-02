import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';

/// Debug utility to delete and recreate the local database.
/// This is useful when database schema changes and you need a fresh start.
///
/// Run with:
///   flutter run -t lib/debug/reset_database.dart -d <deviceId>
///
/// WARNING: This will delete ALL local data!

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('=== Database Reset Utility ===');
    print('WARNING: This will delete ALL local data!');
    print('');

    final helper = DatabaseHelper.instance;

    print('Step 1: Deleting existing database...');
    await helper.deleteDatabase();
    print('✓ Database deleted successfully');

    print('');
    print('Step 2: Recreating database with latest schema...');
    final db = await helper.database;
    print('✓ Database recreated at version 5');

    print('');
    print('Step 3: Verifying Air/Sea table schema...');
    final tables = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name='a_tblRequestAirSea'"
    );

    if (tables.isNotEmpty) {
      print('✓ Air/Sea table exists');
      print('Schema: ${tables.first['sql']}');

      // Check for required columns
      final columns = await db.rawQuery('PRAGMA table_info(a_tblRequestAirSea)');
      print('');
      print('Columns (${columns.length}):');
      for (var col in columns) {
        print('  - ${col['name']} (${col['type']})');
      }

      final requiredColumns = ['WaybillNumber', 'ReceivedAt', 'ReceivedBy', 'EndorsedTo', 'EndorsedAt', 'EndorsedBy'];
      final columnNames = columns.map((c) => c['name'] as String).toList();

      print('');
      print('Checking required columns:');
      for (var reqCol in requiredColumns) {
        final exists = columnNames.contains(reqCol);
        print('  ${exists ? "✓" : "✗"} $reqCol');
      }
    } else {
      print('✗ Air/Sea table not found!');
    }

    print('');
    print('=== Database Reset Complete ===');
    print('You can now restart your app normally.');

  } catch (e, st) {
    print('');
    print('✗ Error during database reset: $e');
    print(st);
  } finally {
    // Wait a moment for the output to be flushed
    await Future.delayed(const Duration(seconds: 1));
    exit(0);
  }
}

