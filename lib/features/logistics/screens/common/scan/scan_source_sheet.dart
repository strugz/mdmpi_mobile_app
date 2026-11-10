import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_document_scan_controller.dart';

/// Where a one-scan page comes from (Home > Scan Document). On Android the
/// document scanner comes first: it flattens a bent or tilted page before
/// the phone reads it, which reads far better than a plain photo.
class ScanSourceSheet {
  ScanSourceSheet._();

  static Future<DocumentScanSource?> show(BuildContext context,
      {bool? scannerAvailable}) {
    final scanner = scannerAvailable ?? GetPlatform.isAndroid;
    return showModalBottomSheet<DocumentScanSource>(
      context: context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Scan a delivery document'),
              subtitle: Text(
                  'One page of the SI, DR, SIS, GI or slip fills the client, '
                  'references and items. You check everything before it is applied.'),
            ),
            if (scanner)
              ListTile(
                key: const ValueKey('scan-source-scanner'),
                leading: const Icon(Iconsax.scan),
                title: const Text('Scan document'),
                subtitle: const Text('Recommended. Finds the page edges and '
                    'flattens it; you can also import a photo there.'),
                onTap: () => Navigator.of(ctx).pop(DocumentScanSource.scanner),
              ),
            ListTile(
              key: const ValueKey('scan-source-camera'),
              leading: const Icon(Iconsax.camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(DocumentScanSource.camera),
            ),
            ListTile(
              key: const ValueKey('scan-source-gallery'),
              leading: const Icon(Iconsax.gallery),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.of(ctx).pop(DocumentScanSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Gets the page from [source]; shows why when it fails.
  static Future<File?> pickFile(
      DeliveryDocumentScanController scan, DocumentScanSource source) async {
    final file = await scan.pickPage(source);
    if (file == null) {
      final error = scan.error.value;
      if (error != null) BLoaders.errorSnackBar(title: 'Scan', message: error);
    }
    return file;
  }
}
