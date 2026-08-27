import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';

/// Uploads proof images and records retryable failures in the image outbox.
class ProofImageOutboxUploader {
  ProofImageOutboxUploader._();

  static final ProofImageOutboxUploader instance = ProofImageOutboxUploader._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<bool> uploadOrQueue({
    required String requestId,
    required String imageLookupKey,
    required String base64Image,
    required String type,
    String uploadFailureMessage =
        'Image proof could not be uploaded. It will be synced when connection is available.',
    String offlineMessage =
        'Image saved locally. It will be uploaded when internet connection is available.',
    bool showOfflineWarning = true,
  }) async {
    if (requestId.isEmpty || type.isEmpty || base64Image.isEmpty) {
      logDebug(
        'ProofImageOutboxUploader: skipped invalid outbox item requestId=$requestId type=$type',
      );
      return false;
    }

    final normalizedLookupKey =
        imageLookupKey.trim().isEmpty ? requestId : imageLookupKey.trim();
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      await _queueImage(
        requestId: requestId,
        imageLookupKey: normalizedLookupKey,
        base64Image: base64Image,
        type: type,
        apiStatus: 'Pending',
      );
      if (showOfflineWarning) {
        BLoaders.warningSnackBar(title: 'No Internet', message: offlineMessage);
      }
      return false;
    }

    try {
      final result = await ImageRepository.instance.uploadFile(
        requestId: requestId,
        base64Image: base64Image,
        type: type,
        showFeedback: false,
      );

      if (result.isSuccess) {
        return true;
      }

      await _queueImage(
        requestId: requestId,
        imageLookupKey: normalizedLookupKey,
        base64Image: base64Image,
        type: type,
        apiStatus: 'Failed',
      );
      BLoaders.warningSnackBar(
        title: 'Upload Failed',
        message: uploadFailureMessage,
      );
      logDebug(
        'ProofImageOutboxUploader: queued failed upload requestId=$requestId type=$type error=${result.error}',
      );
      return false;
    } catch (e, st) {
      await _queueImage(
        requestId: requestId,
        imageLookupKey: normalizedLookupKey,
        base64Image: base64Image,
        type: type,
        apiStatus: 'Failed',
      );
      BLoaders.warningSnackBar(
        title: 'Upload Failed',
        message: uploadFailureMessage,
      );
      logDebug(
        'ProofImageOutboxUploader: queued upload exception requestId=$requestId type=$type error=$e\n$st',
      );
      return false;
    }
  }

  Future<void> queueOnly({
    required String requestId,
    required String imageLookupKey,
    required String base64Image,
    required String type,
    String apiStatus = 'Pending',
  }) {
    return _queueImage(
      requestId: requestId,
      imageLookupKey:
          imageLookupKey.trim().isEmpty ? requestId : imageLookupKey,
      base64Image: base64Image,
      type: type,
      apiStatus: apiStatus,
    );
  }

  Future<void> _queueImage({
    required String requestId,
    required String imageLookupKey,
    required String base64Image,
    required String type,
    required String apiStatus,
  }) {
    return _dbHelper.insertImageOutboxItem(
      requestId: requestId,
      imageType: type,
      imageLookupKey: imageLookupKey,
      imageBase64: base64Image,
      apiStatus: apiStatus,
    );
  }
}
