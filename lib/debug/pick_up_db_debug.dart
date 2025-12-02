import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/pick_up/pick_up_repository.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// Debug utility to check pick-up local database status.
///
/// Usage:
/// 1. In your app, call: PickUpDbDebug.checkLocalDb()
/// 2. Or add a button in debug builds: PickUpDbDebug.showDebugDialog(context)
class PickUpDbDebug {
  /// Check and print local DB information to console.
  static Future<void> checkLocalDb() async {
    try {
      final repo = Get.find<PickUpRepository>();
      await repo.printLocalDbInfo();
    } catch (e) {
      logDebug('Error: PickUpRepository not initialized yet. Error: $e');
    }
  }

  /// Get local DB statistics as a formatted string.
  static Future<String> getLocalDbStats() async {
    try {
      final repo = Get.find<PickUpRepository>();

      final hasData = await repo.hasLocalData();
      final count = await repo.getLocalDataCount();
      final pickUps = await repo.getLocalPickUps();

      final buffer = StringBuffer();
      buffer.writeln('📊 Pick-Up Local DB Status\n');
      buffer.writeln('Has data: ${hasData ? "✅ Yes" : "❌ No"}');
      buffer.writeln('Total records: $count\n');

      if (pickUps.isNotEmpty) {
        buffer.writeln('First record:');
        buffer.writeln('  ID: ${pickUps.first.id}');
        buffer.writeln('  Status: ${pickUps.first.status}');
        buffer.writeln('  Client: ${pickUps.first.client.name}');
        buffer.writeln('  Category: ${pickUps.first.itemCategory.name}\n');

        buffer.writeln('Last record:');
        buffer.writeln('  ID: ${pickUps.last.id}');
        buffer.writeln('  Status: ${pickUps.last.status}\n');

        final statusMap = <String, int>{};
        for (final p in pickUps) {
          statusMap[p.status] = (statusMap[p.status] ?? 0) + 1;
        }

        buffer.writeln('Status breakdown:');
        statusMap.forEach((status, count) {
          buffer.writeln('  • $status: $count');
        });
      } else {
        buffer.writeln('No records in local database.');
      }

      return buffer.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Show a dialog with local DB information (useful for debugging).
  static Future<void> showDebugDialog(BuildContext context) async {
    final stats = await getLocalDbStats();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick-Up Local DB Debug'),
        content: SingleChildScrollView(
          child: Text(
            stats,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await checkLocalDb(); // Also print to console
            },
            child: const Text('Print to Console'),
          ),
          TextButton(
            onPressed: () async {
              final repo = Get.find<PickUpRepository>();
              await repo.clearLocalData();
              Navigator.of(context).pop();
              Get.snackbar(
                'Cleared',
                'Local DB data has been cleared',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Clear DB'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Quick check: returns true if local DB has data.
  static Future<bool> hasData() async {
    try {
      final repo = Get.find<PickUpRepository>();
      return await repo.hasLocalData();
    } catch (e) {
      logDebug('Error checking local DB: $e');
      return false;
    }
  }

  /// Quick check: returns count of records.
  static Future<int> getCount() async {
    try {
      final repo = Get.find<PickUpRepository>();
      return await repo.getLocalDataCount();
    } catch (e) {
      logDebug('Error getting count: $e');
      return 0;
    }
  }
}

