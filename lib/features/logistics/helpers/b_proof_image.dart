import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/paths/path.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';

/// Helper responsible for loading request proof images.
///
/// Follows a simple separation:
/// - Checks local files and local DB first (fast, offline-friendly)
/// - If missing and fetchIfMissing==true, fetches from API and persists locally
class BProofImage {
  BProofImage._();

  static final BProofImage instance = BProofImage._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Resolve ImageRepository lazily to avoid Get.find at module init time
  ImageRepository? get _imageRepoOrNull {
    if (Get.isRegistered<ImageRepository>()) return Get.find<ImageRepository>();
    return null;
  }

  Future<bool> _requireStoragePermission(String featureName) async {
    if (!Get.isRegistered<IPermissionService>()) return true;

    final permission = await Get.find<IPermissionService>().requireForFeature(
      PermissionType.storage,
      featureName: featureName,
    );
    return permission.granted;
  }

  String _buildFileName(String requestId, {String type = 'Proof'}) {
    if (type == 'Provincial_PickUp_Proof') {
      return '${requestId}_provincial_pick_up.jpg';
    }
    // Extra proof photos (Proof_2, Proof_3) live beside the legacy slot-1
    // file as {requestId}_2.jpg / {requestId}_3.jpg.
    final extraSlot = RegExp(r'^Proof_(\d+)$').firstMatch(type);
    if (extraSlot != null) {
      return '${requestId}_${extraSlot.group(1)}.jpg';
    }
    return '$requestId.jpg';
  }

  String _buildFilePath(String requestId, {String type = 'Proof'}) {
    return p.join(BPaths.deliveryShots, _buildFileName(requestId, type: type));
  }

  Future<String?> _findExistingLocalFilePath(
    String requestId, {
    String type = 'Proof',
  }) async {
    final primaryPath = _buildFilePath(requestId, type: type);
    if (await File(primaryPath).exists()) {
      return primaryPath;
    }

    if (type == 'Provincial_PickUp_Proof') {
      final legacyPath = _buildFilePath(requestId);
      if (await File(legacyPath).exists()) {
        return legacyPath;
      }
    }

    return null;
  }

  Future<String?> _persistBytesToLocalFile(
    Uint8List bytes,
    String requestId, {
    String type = 'Proof',
  }) async {
    if (bytes.isEmpty || requestId.isEmpty) return null;

    final storageGranted =
        await _requireStoragePermission('Proof image storage');
    if (!storageGranted) return null;

    final dirPath = BPaths.deliveryShots;
    final filePath = _buildFilePath(requestId, type: type);

    try {
      final dir = Directory(dirPath);
      await dir.create(recursive: true);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return filePath;
    } catch (e, st) {
      logDebug(
          'BProofImage._persistBytesToLocalFile failed for $requestId: $e\n$st');
      return null;
    }
  }

  Future<void> _saveBytesToDb(Uint8List bytes, String requestId) async {
    if (bytes.isEmpty || requestId.isEmpty) return;

    try {
      final base64Str = base64Encode(bytes);
      await _db.saveRequestMedia(requestID: requestId, image: base64Str);
    } catch (e, st) {
      logDebug(
          'BProofImage: failed to save image to DB for $requestId: $e\n$st');
    }
  }

  /// Load image bytes for the given request id.
  /// Returns bytes from local DB if present; otherwise, if [fetchIfMissing]
  /// is true, attempts to fetch from the API and stores the result in DB.
  Future<Uint8List?> loadRequestImageBytes(
      String requestId, String apiController,
      {bool fetchIfMissing = false, String type = 'Proof'}) async {
    if (requestId.isEmpty || apiController.isEmpty) {
      logDebug(
          'BProofImage.loadRequestImageBytes: invalid requestId/apiController');
      return null;
    }

    try {
      final storageGranted =
          await _requireStoragePermission('Proof image storage');
      if (!storageGranted) return null;

      final existingLocalPath =
          await _findExistingLocalFilePath(requestId, type: type);
      if (existingLocalPath != null) {
        final localBytes = await File(existingLocalPath).readAsBytes();
        if (localBytes.isNotEmpty) return localBytes;
      }
    } catch (e, st) {
      logDebug(
          'BProofImage: failed to read local file for $requestId: $e\n$st');
    }

    try {
      // The local DB row only ever holds the slot-1 'Proof' image, so the
      // fallback must not answer for other types (e.g. Proof_2, Proof_3).
      if (type == 'Proof') {
        final local = await _db.loadSavedRequestImageBytes(requestId);
        if (local != null && local.isNotEmpty) return local;
      }
    } catch (e, st) {
      logDebug(
          'BProofImage: failed to read local image for $requestId: $e\n$st');
    }

    if (!fetchIfMissing) return null;

    final repo = _imageRepoOrNull;
    if (repo == null) {
      logDebug(
          'BProofImage: ImageRepository not registered; skipping network fetch for $requestId');
      return null;
    }

    try {
      final bytes = await repo.getFileFromApi(
        endpoint: '/api4/$apiController/image',
        queryParameters: {'requestid': requestId, 'type': type},
        showErrorSnackbar: false,
      );
      if (bytes.isNotEmpty) {
        // Same single-row constraint: only the 'Proof' type may be cached
        // in the DB, or an extra photo would overwrite the slot-1 image.
        if (type == 'Proof') {
          await _saveBytesToDb(bytes, requestId);
        }
        return bytes;
      } else {
        logDebug('BProofImage: API returned empty bytes for $requestId');
      }
    } catch (e, st) {
      logDebug('BProofImage: API fetch error for $requestId: $e\n$st');
      return null;
    }

    return null;
  }

  /// Fetches image bytes from API and saves the file to the local filesystem
  /// using the project's fixed delivery shots directory (BPaths.deliveryShots).
  /// Returns the absolute file path on success, or null on failure.
  Future<String?> fetchAndSaveImageToLocalFile(
    String requestId,
    String apiController, {
    String type = 'Proof',
  }) async {
    if (requestId.isEmpty || apiController.isEmpty) {
      logDebug(
          'BProofImage.fetchAndSaveImageToLocalFile: invalid requestId/apiController');
      return null;
    }

    final repo = _imageRepoOrNull;
    if (repo == null) {
      logDebug(
          'BProofImage: ImageRepository not registered; cannot fetch image for $requestId');
      return null;
    }

    try {
      final bytes = await repo.getFileFromApi(
        endpoint: '/api4/$apiController/image',
        queryParameters: {'requestid': requestId, 'type': type},
        showErrorSnackbar: false,
      );

      if (bytes.isEmpty) {
        logDebug(
            'BProofImage.fetchAndSaveImageToLocalFile: API returned empty for $requestId');
        return null;
      }

      return _persistBytesToLocalFile(bytes, requestId, type: type);
    } catch (e, st) {
      logDebug(
          'BProofImage.fetchAndSaveImageToLocalFile error for $requestId: $e\n$st');
      return null;
    }
  }
}
