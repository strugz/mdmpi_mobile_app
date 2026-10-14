import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:path/path.dart' as p;

/// Gets voucher pages as files; empty when the collector backs out.
typedef VoucherFilePick = Future<List<File>> Function();

/// Pages to read, and whether the AI reads them (Scan with AI, a gallery
/// image or a file) or the phone does (Scan with camera).
typedef VoucherPages = ({List<File> pages, bool useAi});

/// What the account list's Scan asks for.
typedef VoucherPagesPick = Future<VoucherPages> Function();

/// Starts the document scanner; null when it cannot run here (the caller
/// falls back to the plain camera), empty when the collector cancels.
typedef DocumentScan = Future<List<File>?> Function();

/// The ways to get voucher pages, as in the Logistics inventory scanner: the
/// camera, or an attached image or PDF.
class BVoucherFilePicker {
  BVoucherFilePicker._();

  /// Pages one scanning session may hold (a long remittance list).
  static const int maxPages = 5;

  /// The camera through Google's document scanner (Android): it finds the
  /// paper's edges, crops, straightens and cleans each page on the phone, and
  /// takes up to [maxPages] pages. Where it cannot start (no Google Play
  /// services, or its module not downloaded yet and no connection), a plain
  /// photo instead.
  static Future<List<File>> takePhoto({DocumentScan? scan}) async {
    if (scan != null || GetPlatform.isAndroid) {
      final pages = await (scan ?? _scanDocument)();
      if (pages != null) return pages;
    }
    final photo = await _plainPhoto();
    return photo == null ? const [] : [photo];
  }

  static Future<List<File>?> _scanDocument() async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: maxPages,
        isGalleryImport: false,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      return [for (final path in result.images ?? const <String>[]) File(path)];
    } on PlatformException catch (e) {
      if ((e.message ?? '').toLowerCase().contains('cancel')) return const [];
      logDebug('BVoucherFilePicker: document scanner unavailable: '
          '${e.message}; using the camera');
      return null;
    } catch (e) {
      logDebug('BVoucherFilePicker: document scanner failed: $e; '
          'using the camera');
      return null;
    } finally {
      scanner.close().catchError((_) {});
    }
  }

  /// A photo, sharp enough for small print.
  static Future<File?> _plainPhoto() async {
    if (Get.isRegistered<IPermissionService>()) {
      final permission = await Get.find<IPermissionService>().requireForFeature(
          PermissionType.camera,
          featureName: 'Voucher scan');
      if (!permission.granted) return null;
    }
    final picked = await ImagePicker().pickImage(
        source: ImageSource.camera, imageQuality: 90, maxWidth: 2400);
    return picked == null ? null : File(picked.path);
  }

  /// An image from the gallery, or an image or PDF from the files, read by
  /// the AI (falling back to the phone).
  static Future<List<File>> attach() async =>
      (await choose(camera: false)).pages;

  /// Asks how to scan: the camera read on the phone (works offline), the
  /// camera read by the AI ([camera] only for both), the gallery, or a file
  /// (image or PDF). No pages when the collector backs out.
  static Future<VoucherPages> choose({required bool camera}) async {
    final choice = await Get.bottomSheet<String>(
      SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Scan a voucher or Sales Invoice'),
              subtitle: Text('Its SI numbers are selected in the list'),
            ),
            if (camera) ...[
              ListTile(
                key: const ValueKey('voucher-source-camera'),
                leading: const Icon(Iconsax.scan),
                title: const Text('Scan with camera'),
                subtitle: const Text('Read on the phone, works without '
                    'internet; up to $maxPages pages'),
                onTap: () => Get.back(result: 'camera'),
              ),
              ListTile(
                key: const ValueKey('voucher-source-ai'),
                leading: const Icon(Iconsax.magic_star),
                title: const Text('Scan with AI'),
                subtitle: const Text('Most accurate, needs internet; up to '
                    '$maxPages pages'),
                onTap: () => Get.back(result: 'ai'),
              ),
            ],
            ListTile(
              key: const ValueKey('voucher-source-gallery'),
              leading: const Icon(Iconsax.image),
              title: const Text('Pick image from gallery'),
              onTap: () => Get.back(result: 'gallery'),
            ),
            ListTile(
              key: const ValueKey('voucher-source-file'),
              leading: const Icon(Iconsax.folder_2),
              title: const Text('Pick a file (image or PDF)'),
              onTap: () => Get.back(result: 'file'),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(Get.context!).colorScheme.surface,
    );
    return switch (choice) {
      'camera' => (pages: await takePhoto(), useAi: false),
      'ai' => (pages: await takePhoto(), useAi: true),
      'gallery' => (pages: await _gallery(), useAi: true),
      'file' => (pages: await _file(), useAi: true),
      _ => (pages: const <File>[], useAi: true),
    };
  }

  static Future<List<File>> _gallery() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    return picked == null ? const [] : [File(picked.path)];
  }

  static Future<List<File>> _file() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    final picked = result?.files.singleOrNull;
    if (picked == null) return const [];
    if (picked.path != null) return [File(picked.path!)];
    if (picked.bytes == null) return const [];
    // Some providers hand over bytes only: keep them in the temp folder.
    final file = File(p.join(Directory.systemTemp.path, picked.name));
    await file.writeAsBytes(picked.bytes!, flush: true);
    return [file];
  }
}
