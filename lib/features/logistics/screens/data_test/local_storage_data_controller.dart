import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

/// Controller to manage local storage data viewing
class LocalStorageDataController extends GetxController {
  final _dbHelper = DatabaseHelper.instance;

  // Observable state
  final RxString selectedTable = 'a_tblRequest'.obs;
  final RxList<Map<String, dynamic>> tableData = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  /// All available tables in the database
  final List<String> availableTables = [
    'a_tblRequest',
    'a_tblRequestDocumentReference',
    'a_tblRequestReceiverSignature',
    'a_tblRequestImage',
    'a_tblRequestRemarks',
    'a_tblRequestPickUp',
    'a_tblRequestAirSea',
    'a_tblRequestPullOutReturnPickUp',
    'ACCMST_',
    'a_tblMobile',
    'Users',
    'CNTMST',
    'a_tblItemCategory',
    'a_tblFormCategory',
    'a_tblLocationAlternative',
    'a_tblClientContactPerson',
    'a_tblRequestBackload',
    'a_tblCollectionItems',
    'a_tblCollectionHistory',
    'a_tblCollectionPending',
    'a_tblCollectionActivity',
    'a_tblCollectionAdvance',
    'a_tblCollectionAccountHistory',
    'a_tblCollectionTarget'
  ];

  @override
  void onInit() {
    super.onInit();
    loadTableData();
  }

  /// Select a table and load its data
  void selectTable(String tableName) {
    selectedTable.value = tableName;
    loadTableData();
  }

  /// Load data from the selected table
  Future<void> loadTableData() async {
    try {
      isLoading.value = true;
      tableData.clear();

      final db = await _dbHelper.database;
      final result = await db.query(selectedTable.value);

      tableData.addAll(result);
      logDebug('Loaded ${result.length} rows from ${selectedTable.value}');
    } catch (e) {
      logDebug('Error loading table data: $e');
      BLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load data from ${selectedTable.value}: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get column names for the selected table
  Future<List<String>> getColumnNames() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('PRAGMA table_info(${selectedTable.value})');
      return result.map((col) => col['name'] as String).toList();
    } catch (e) {
      logDebug('Error getting column names: $e');
      return [];
    }
  }

  /// Delete a row from the table (for testing purposes)
  Future<void> deleteRow(Map<String, dynamic> row) async {
    try {
      final db = await _dbHelper.database;

      // Find primary key column
      final tableInfo = await db.rawQuery('PRAGMA table_info(${selectedTable.value})');
      final primaryKey = tableInfo.firstWhereOrNull((col) => col['pk'] == 1);

      if (primaryKey != null) {
        final pkName = primaryKey['name'] as String;
        final pkValue = row[pkName];

        await db.delete(
          selectedTable.value,
          where: '$pkName = ?',
          whereArgs: [pkValue],
        );

        BLoaders.successSnackBar(
          title: 'Success',
          message: 'Row deleted successfully',
        );

        loadTableData();
      } else {
        BLoaders.errorSnackBar(
          title: 'Error',
          message: 'Cannot delete: No primary key found',
        );
      }
    } catch (e) {
      logDebug('Error deleting row: $e');
      BLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete row: $e',
      );
    }
  }

  /// Clear all data from the selected table
  Future<void> clearTable() async {
    try {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirm Clear'),
          content: Text('Are you sure you want to clear all data from ${selectedTable.value}?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final db = await _dbHelper.database;
        await db.delete(selectedTable.value);

        BLoaders.successSnackBar(
          title: 'Success',
          message: 'Table cleared successfully',
        );

        loadTableData();
      }
    } catch (e) {
      logDebug('Error clearing table: $e');
      BLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to clear table: $e',
      );
    }
  }

  /// Get table statistics
  Future<Map<String, dynamic>> getTableStats() async {
    try {
      final db = await _dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${selectedTable.value}'),
      );

      return {
        'rowCount': count ?? 0,
        'tableName': selectedTable.value,
      };
    } catch (e) {
      logDebug('Error getting table stats: $e');
      return {'error': e.toString()};
    }
  }
}

