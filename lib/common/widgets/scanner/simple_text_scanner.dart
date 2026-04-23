import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';

/// Minimal scanner: capture an image, run OCR, extract patterns, return matches.
/// Returns `List<String>?` via `Get.back(result: matches)`. Returns `null` if user cancelled.
class SimpleTextScanner extends StatefulWidget {
  const SimpleTextScanner({super.key});

  @override
  State<SimpleTextScanner> createState() => _SimpleTextScannerState();
}

class _SimpleTextScannerState extends State<SimpleTextScanner> {
  final RxBool _isProcessing = false.obs;
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureAndAnalyze() async {
    try {
      _isProcessing.value = true;

      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (picked == null) {
        // User cancelled - propagate null
        Get.back(result: null);
        return;
      }

      final file = File(picked.path);

      // Resolve services from DI
      final ITextRecognitionService textRecognition =
          Get.find<ITextRecognitionService>();
      final ITextExtractor extractor = Get.find<ITextExtractor>();

      final InputImage inputImage = InputImage.fromFile(file);
      final String rawText = await textRecognition.processImage(inputImage);

      final RegExp inventoryHeader = RegExp(r'inventory\s*transfer', caseSensitive: false);
      final String filteredRawText = rawText
          .split(RegExp(r'\r?\n'))
          .where((line) => !inventoryHeader.hasMatch(line))
          .join('\n');
      final List<String> matches = extractor.extractPatterns(filteredRawText);

      Get.back(result: matches);
    } catch (e) {
      try {
        // Use existing logger if available; avoid print
        // logDebug('SimpleTextScanner error: $e\n$st');
      } catch (_) {}
      // Return empty list as fallback
      Get.back(result: <String>[]);
    } finally {
      _isProcessing.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    // Start capture immediately on screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndAnalyze());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Document')),
      body: Center(
        child: Obx(() {
          if (_isProcessing.value) {
            return const CircularProgressIndicator();
          } else {
            return ElevatedButton(
              onPressed: _captureAndAnalyze,
              child: const Text('Capture & Analyze'),
            );
          }
        }),
      ),
    );
  }
}
