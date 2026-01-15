import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';

/// Service responsible for loading request images (proof images).
/// Follows a simple clean separation:
/// - Checks local DB first (fast, offline-friendly)
/// - If missing and fetchIfMissing==true, fetches from API and persists locally
class BProofImage {
  BProofImage._();

  static final BProofImage instance = BProofImage._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImageRepository _imageRepo = Get.find<ImageRepository>();

  /// Load image bytes for the given request id.
  /// Returns bytes from local DB if present; otherwise, if [fetchIfMissing]
  /// is true, attempts to fetch from the API and stores the result in DB.
  Future<Uint8List?> loadRequestImageBytes(String requestId,String apiController,
      {bool fetchIfMissing = false}) async {

    final local = await _db.loadSavedRequestImageBytes(requestId);
    if (local != null && local.isNotEmpty) return local;
    if (!fetchIfMissing) return null;

    try {
      final bytes = await _imageRepo.getFileFromApi(
        endpoint: '/api4/$apiController/image',
        queryParameters: {'requestid': requestId, 'type': 'Proof'},
      );
      if (bytes.isNotEmpty) {
        // Save as base64 to DB for future use
        try {
          final base64Str = base64Encode(bytes);
          await _db.saveRequestMedia(requestID: requestId, image: base64Str);
        } catch (_) {
          // ignore DB save errors; still return bytes
        }
        return bytes;
      }
    } catch (e) {
      // propagate or swallow? For UI we return null on error
      return null;
    }

    return null;
  }
}
