import 'dart:io';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';

Future<void> main() async {
  try {
    final helper = DatabaseHelper.instance;
    // Ensure DB initialized
    await helper.database;
    print('Database path opened.');

    final imgs = await helper.requestDao.then((d) => d.getAllRequestImages());

    print('Request images count: ${imgs.length}');
    for (var row in imgs) {
      print(
          'Image row: RequestID=${row['RequestID']}, length=${(row['RequestImage'] as String?)?.length ?? 0}');
    }
  } catch (e) {
    print('Error while inspecting DB: $e');
    exit(1);
  }
}
