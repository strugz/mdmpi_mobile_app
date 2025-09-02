import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';

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
  final RequestController requestController = Get.find<RequestController>();
  late AnimationController _flashAnimController;
  late Animation<double> flashOpacity;

  final imageProofPath = RxString('');
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

  @override
  void onInit() {
    super.onInit();
    _initializeAndPreparePreview();

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
    _cameraService.dispose();
    _textRecognitionService.close();
    super.onClose();
  }

  /// --- Initialize the camera and prepare the preview ---
  Future<void> _initializeAndPreparePreview() async {
    isCameraLoading.value = true;
    try {
      await _cameraService.initialize();
      print('Camera initialized successfully (via service in controller)');
    } catch (e) {
      print('Error initializing camera (via service in controller): $e');
    }
    isCameraLoading.value = false;
  }

  /// --- Scan text from the camera preview and update the recognizedText variable ---
  Future<void> scanText(TextEditingController controller) async {
    if (!_cameraService.isInitialized || isProcessing.value) {
      // isProcessing could also come from cameraService
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
      print('Error recognizing text: $e');
      recognizedText.value = 'Error processing text.';
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
    if (!_cameraService.isInitialized || isProcessing.value) {
      // isProcessing could also come from cameraService
      return;
    }

    try {
      final XFile? imageFile = await _cameraService.takePicture();

      imageProofPath.value =
          await BImageHelperFunctions.saveImage(imageFile, pictureName);
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> takePictureWithAnimation(String requestId) async {
    isFlashing.value = true;
    _flashAnimController.forward(from: 0.0);
    await takePicture(requestId); // Your existing takePicture logic
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
