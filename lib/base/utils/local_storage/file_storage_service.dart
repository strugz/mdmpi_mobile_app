// FileStorageService.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class FileStorageService {
  Future<String> saveImage(Uint8List imageBytes, String requestId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dirPath = '${appDocDir.path}/MDMPIAPP/Deliveryshots';
    await Directory(dirPath).create(recursive: true);
    final filePath = '$dirPath/$requestId.jpg';
    await File(filePath).writeAsBytes(imageBytes);
    return base64Encode(imageBytes);
  }
}