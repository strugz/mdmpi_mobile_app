import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/local_storage/text_storage_service.dart';
import 'package:mdmpi_mobile_app/base/utils/paths/path.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

import '../../base/utils/image_utils/image_conversion_base_64_to_string.dart';
import '../services/abstracts/i_camera_service.dart';
import '../services/abstracts/i_text_extractor.dart';
import '../services/abstracts/i_text_recognition_service.dart';

class CameraHandlerController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static CameraHandlerController get instance => Get.find();

  final ICameraService _cameraService;
  final ITextRecognitionService _textRecognitionService;
  final ITextExtractor _textExtractor;
  final TextStorageService _textStorageService = TextStorageService();
  final StandardDeliveryController requestController =
      Get.find<StandardDeliveryController>();
  late AnimationController _flashAnimController;
  late Animation<double> flashOpacity;
  Future<void>? _cameraInitializationFuture;

  /// Maximum proof-of-delivery photos per request.
  static const int maxProofPhotos = 3;

  final imageProofPath = RxString('');

  /// Proof photo paths for the request in [proofPhotosRequestId], slot order.
  /// Slot 1 keeps the legacy `{requestId}.jpg` name; slots 2-3 use
  /// `{requestId}_2.jpg` / `{requestId}_3.jpg`.
  final imageProofPaths = RxList<String>();
  String proofPhotosRequestId = '';

  final recognizedText = Rx<String>('');
  RxBool isProcessing = false.obs;
  RxBool isCameraLoading = true.obs;
  RxBool isFlashing = false.obs;

  CameraHandlerController({
    required ICameraService cameraService,
    required ITextRecognitionService textRecognitionService,
    required ITextExtractor textExtractor,
  })  : _cameraService = cameraService,
        _textRecognitionService = textRecognitionService,
        _textExtractor = textExtractor;

  IPermissionService get _permissionService => Get.find<IPermissionService>();

  @override
  void onInit() {
    super.onInit();
    _flashAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 1),
    ]).animate(_flashAnimController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          isFlashing.value = false;
        }
      });
  }

  @override
  void onClose() {
    _flashAnimController.dispose();
    _cameraService.dispose();
    _textRecognitionService.close();
    super.onClose();
  }

  /// Initializes the camera only when a preview/capture flow actually needs it.
  Future<void> ensureCameraReady() async {
    final permission = await _permissionService.requireForFeature(
      PermissionType.camera,
      featureName: 'Camera',
    );
    if (!permission.granted) {
      isCameraLoading.value = false;
      return;
    }

    if (_cameraService.isInitialized) {
      isCameraLoading.value = false;
      return;
    }

    if (_cameraInitializationFuture != null) {
      await _cameraInitializationFuture;
      return;
    }

    isCameraLoading.value = true;
    _cameraInitializationFuture = _initializeCamera();

    try {
      await _cameraInitializationFuture;
    } finally {
      _cameraInitializationFuture = null;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      logDebug('Camera initialized successfully (via service in controller)');
    } catch (e) {
      logDebug('Error initializing camera (via service in controller): $e');
    } finally {
      isCameraLoading.value = false;
    }
  }

  /// --- Scan text from the camera preview and update the recognizedText variable ---
  Future<void> scanText(TextEditingController controller) async {
    if (isProcessing.value) {
      return;
    }

    await ensureCameraReady();

    if (!_cameraService.isInitialized) {
      return;
    }
    isProcessing.value = true;
    recognizedText.value = 'Processing...';

    try {
      final XFile? imageFile = await _cameraService.takePicture();
      if (imageFile == null) {
        recognizedText.value = 'Failed to capture image.';
        isProcessing.value = false;
        return;
      }

      final inputImage = InputImage.fromFile(File(imageFile.path));
      final String rawRecognizedText =
          await _textRecognitionService.processImage(inputImage);

      final List<String> extractedMatches =
          _textExtractor.extractPatterns(rawRecognizedText);

      if (extractedMatches.isNotEmpty) {
        scannedTextValidation(extractedMatches, controller);
      } else {
        // Handle case where no patterns were matched
        recognizedText.value = 'No relevant information found.';
      }
      Get.back(); // Consider if Get.back() should be conditional
    } catch (e) {
      logDebug('Error recognizing text: $e');
      recognizedText.value = 'Error processing text.';
    } finally {
      isProcessing.value = false;
    }
  }

  /// Scans text and populates a single field with the first matched pattern.
  /// Used for single-field scenarios like waybill numbers, tracking codes, etc.
  Future<void> scanSingleField(TextEditingController controller) async {
    if (isProcessing.value) {
      return;
    }

    await ensureCameraReady();

    if (!_cameraService.isInitialized) {
      return;
    }
    isProcessing.value = true;
    recognizedText.value = 'Processing...';

    try {
      final XFile? imageFile = await _cameraService.takePicture();
      if (imageFile == null) {
        recognizedText.value = 'Failed to capture image.';
        isProcessing.value = false;
        return;
      }

      final inputImage = InputImage.fromFile(File(imageFile.path));
      final String rawRecognizedText =
          await _textRecognitionService.processImage(inputImage);

      final List<String> extractedMatches =
          _textExtractor.extractPatterns(rawRecognizedText);

      if (extractedMatches.isNotEmpty) {
        // Take the first matched pattern and populate the field
        controller.text = extractedMatches.first;
        recognizedText.value = 'Scanned: ${extractedMatches.first}';
        Get.back(); // Return to previous screen
      } else {
        recognizedText.value = 'No relevant information found.';
        BLoaders.warningSnackBar(
          title: 'No Text Found',
          message: 'Could not detect any text. Please try again.',
        );
      }
    } catch (e) {
      logDebug('Error recognizing text: $e');
      recognizedText.value = 'Error processing text.';
      BLoaders.errorSnackBar(
        title: 'Scan Error',
        message: 'Failed to process image. Please try again.',
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> scannedTextValidation(List<String> strValidations,
      TextEditingController displayController) async {
    List<bool> isDuplicate = [];

    for (int i = 0; i < strValidations.length; i++) {
      bool containsValidation = requestController
          .formState.documentReferenceControllers
          .any((controller) => controller.text == strValidations[i]);
      isDuplicate.add(containsValidation);

      if (containsValidation == false) {
        if (requestController
            .formState.documentReferenceControllers.last.text.isEmpty) {
          requestController.formState.documentReferenceControllers.last.text =
              strValidations[i];
        } else {
          requestController.addDocumentReferenceField();
          requestController.formState.documentReferenceControllers.last.text =
              strValidations[i];
        }
      }
    }
  }

  /// --- Take Picture and Save to the device ---
  Future<void> takePicture(String pictureName) async {
    if (isProcessing.value) {
      return;
    }

    await ensureCameraReady();

    if (!_cameraService.isInitialized) {
      return;
    }

    try {
      final storagePermission = await _permissionService.requireForFeature(
        PermissionType.storage,
        featureName: 'Proof photo',
      );
      if (!storagePermission.granted) {
        return;
      }

      final XFile? imageFile = await _cameraService.takePicture();

      imageProofPath.value =
          await BImageHelperFunctions.saveImage(imageFile, pictureName);

      if (imageProofPath.value.isNotEmpty) {
        await _textStorageService.saveText(
            'proofImagePath', imageProofPath.value);
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> takePictureWithAnimation(String requestId) async {
    isFlashing.value = true;
    _flashAnimController.forward(from: 0.0);
    await takePicture(requestId);
  }

  /// File name (without extension) for a proof photo slot (1-based).
  /// Slot 1 keeps the legacy `{requestId}` name so existing readers
  /// (validation, upload, display) continue to work unchanged.
  static String proofFileName(String requestId, int slot) =>
      slot <= 1 ? requestId : '${requestId}_$slot';

  /// Reload [imageProofPaths] from disk for the given request.
  /// Idempotent; call when a proof capture UI is shown so the list
  /// reflects the current request instead of a previously opened one.
  Future<void> syncProofPhotos(String requestId) async {
    proofPhotosRequestId = requestId;
    final found = <String>[];
    for (int slot = 1; slot <= maxProofPhotos; slot++) {
      final path =
          '${BPaths.deliveryShots}/${proofFileName(requestId, slot)}.jpg';
      if (await File(path).exists()) {
        found.add(path);
      }
    }
    imageProofPaths.assignAll(found);
    _mirrorFirstProofPhoto();
  }

  /// Save an already-captured photo file (e.g. the one the user just
  /// confirmed on the review screen) into the next free proof slot
  /// (max [maxProofPhotos]). Does NOT take a new picture — re-capturing on
  /// confirm returns a stale camera frame while the review screen covers
  /// the preview, producing identical photos.
  Future<void> addProofPictureFromFile(
      String requestId, String sourcePath) async {
    if (proofPhotosRequestId != requestId) {
      await syncProofPhotos(requestId);
    }
    if (imageProofPaths.length >= maxProofPhotos) {
      BLoaders.warningSnackBar(
        title: 'Photo Limit',
        message: 'You can attach up to $maxProofPhotos proof photos.',
      );
      return;
    }

    try {
      final storagePermission = await _permissionService.requireForFeature(
        PermissionType.storage,
        featureName: 'Proof photo',
      );
      if (!storagePermission.granted) return;

      final source = File(sourcePath);
      if (!await source.exists()) {
        BLoaders.errorSnackBar(
          title: 'Error',
          message: 'Captured photo file not found.',
        );
        return;
      }

      final slot = imageProofPaths.length + 1;
      await Directory(BPaths.deliveryShots).create(recursive: true);
      final targetPath =
          '${BPaths.deliveryShots}/${proofFileName(requestId, slot)}.jpg';
      await source.copy(targetPath);

      imageProofPaths.add(targetPath);
      await _mirrorFirstProofPhoto();
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  /// Remove the proof photo at [index] and compact the remaining photos
  /// down into the freed slots so slot 1 is always occupied first.
  Future<void> removeProofPhoto(String requestId, int index) async {
    if (index < 0 || index >= imageProofPaths.length) return;

    try {
      final removed = File(imageProofPaths[index]);
      if (await removed.exists()) {
        await removed.delete();
      }

      // Shift later photos down one slot on disk.
      for (int i = index + 1; i < imageProofPaths.length; i++) {
        final source = File(imageProofPaths[i]);
        final targetPath =
            '${BPaths.deliveryShots}/${proofFileName(requestId, i)}.jpg';
        if (await source.exists()) {
          await source.rename(targetPath);
        }
      }
      await syncProofPhotos(requestId);
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  /// Keep the legacy single-photo state pointing at slot 1 so existing
  /// consumers (action button validation, transport controller fallback)
  /// stay consistent with the multi-photo list.
  Future<void> _mirrorFirstProofPhoto() async {
    final first = imageProofPaths.isNotEmpty ? imageProofPaths.first : '';
    imageProofPath.value = first;
    if (first.isNotEmpty) {
      await _textStorageService.saveText('proofImagePath', first);
    }
  }

  /// --- Take Picture and Return Path (without saving) ---
  /// Used for photo review screens where user can confirm/retake
  Future<String?> takePictureForReview() async {
    if (isProcessing.value) {
      return null;
    }

    await ensureCameraReady();

    if (!_cameraService.isInitialized) {
      return null;
    }

    try {
      logDebug('📸 Taking picture for review...');
      final XFile? imageFile = await _cameraService.takePicture();

      if (imageFile == null) {
        logDebug('❌ Failed to capture image');
        return null;
      }

      logDebug('✅ Picture captured: ${imageFile.path}');
      return imageFile.path;
    } catch (e) {
      logDebug('❌ Error taking picture: $e');
      BLoaders.errorSnackBar(title: 'Capture Error', message: e.toString());
      return null;
    }
  }

  /// --- Take Picture with Flash Animation for Review ---
  Future<String?> takePictureForReviewWithAnimation() async {
    isFlashing.value = true;
    _flashAnimController.forward(from: 0.0);
    return await takePictureForReview();
  }

  /// --- Pause the camera preview to release resources ---
  Future<void> pausePreview() async {
    await _cameraService.pausePreview();
  }

  /// --- Resume the camera preview ---
  Future<void> resumePreview() async {
    if (!_cameraService.isInitialized) {
      await ensureCameraReady();
    }

    await _cameraService.resumePreview();
  }

  /// --- Stop flash animation ---
  void stopFlashAnimation() {
    _flashAnimController.stop();
    isFlashing.value = false;
  }

  Widget? getCameraPreviewWidget() {
    if (_cameraService.isInitialized) {
      final nativeController =
          _cameraService.getNativeCameraControllerInstance();
      if (nativeController != null &&
          nativeController is CameraController &&
          nativeController.value.isInitialized) {
        return CameraPreview(nativeController);
      }
    }
    return null;
  }
}
