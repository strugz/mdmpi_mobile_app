import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// Google's on-device document scanner (ML Kit, Android). It finds the
/// paper's edges, crops, corrects the perspective and flattens a bent page
/// before anything reads it, so the text comes out in straight rows. No
/// network, no AI service: the scanning runs in Google Play services.
///
/// Shared by the Collection voucher scan and the Logistics one-scan.
class BDocumentScanner {
  BDocumentScanner._();

  /// The scanned pages as JPEG files. Empty when the user cancels. Null
  /// when the scanner cannot run here (not Android, no Google Play
  /// services, or its module not downloaded yet and no connection): the
  /// caller then falls back to the plain camera.
  ///
  /// [galleryImport] lets the user pick a photo from the gallery inside the
  /// scanner, which then crops and flattens it the same way.
  static Future<List<File>?> scan({
    int pageLimit = 1,
    bool galleryImport = false,
  }) async {
    if (!GetPlatform.isAndroid) return null;
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: pageLimit,
        isGalleryImport: galleryImport,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      return [for (final path in result.images ?? const <String>[]) File(path)];
    } on PlatformException catch (e) {
      if ((e.message ?? '').toLowerCase().contains('cancel')) return const [];
      logDebug('BDocumentScanner: unavailable: ${e.message}');
      return null;
    } catch (e) {
      logDebug('BDocumentScanner: failed: $e');
      return null;
    } finally {
      scanner.close().catchError((_) {});
    }
  }
}
