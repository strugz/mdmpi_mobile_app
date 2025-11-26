import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:mdmpi_mobile_app/base/utils/paths/path.dart';

import '../constants/text_string.dart';

class BImageHelperFunctions {
  /// Convert base64 string to image and save to device
  static Future<File?> convertBase64ToImageAndSave(
      String base64String, String fileNameWithoutExtension) async {
    try {
      // Check if the file already exists (optional, depends on your logic)
      final File imageFile =
          File('${BPaths.deliveryShots}/$fileNameWithoutExtension.jpg');

      if (await imageFile.exists()) {
        return imageFile;
      }

      if (base64String.isEmpty) {
        return null;
      }

      final String actualBase64 = base64String.startsWith('data:image')
          ? base64String.split(',').last
          : base64String;

      final Uint8List imageBytes = base64Decode(actualBase64);

      final deliveryShotsDir = Directory(
          BPaths.deliveryShots); // Consider making this path configurable

      // Ensure the directory exists
      if (!await deliveryShotsDir.exists()) {
        await deliveryShotsDir.create(recursive: true);
      }

      final String imageFilePath =
          '${deliveryShotsDir.path}/$fileNameWithoutExtension.jpg';
      final File newImageFile = File(imageFilePath);

      await newImageFile.writeAsBytes(imageBytes);
      return newImageFile;
    } catch (e) {
      return null;
    }
  }

  /// Get delivery image as base64 string
  static Future<String?> getDeliveryImageAsBase64(
      String newStatus, String requestId) async {
    String? imageBase64;
    if (newStatus == BTexts.statusDoneDelivery || newStatus == BTexts.statusTakenOut) {
      const deliveryShotsDirPath = BPaths.deliveryShots;

      await Directory(deliveryShotsDirPath).create(recursive: true);

      final imageFilePath =
          '$deliveryShotsDirPath/$requestId.jpg';
      final imageFile = File(imageFilePath);
      if (await imageFile.exists()) {
        final imageBytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }
    }
    return imageBase64;
  }

  static Future<String> saveImage(XFile? imageFile, String pictureName) async {
    if (imageFile == null) return "";

    try {
      final deliveryShotsDir = Directory(BPaths.deliveryShots);

      if (!await deliveryShotsDir.exists()) {
        await deliveryShotsDir.create(recursive: true);
      }
      final filePath = '${deliveryShotsDir.path}/$pictureName.jpg';

      await imageFile.saveTo(filePath);

      return filePath;
    } catch (e) {
      return "";
    }
  }
}
