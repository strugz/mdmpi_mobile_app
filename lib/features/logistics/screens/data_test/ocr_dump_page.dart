import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_line_dump.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/i_delivery_document_scan_service.dart';
import 'package:path_provider/path_provider.dart';

/// Developer tool (Settings > Developer Tools, Android): reads a document
/// photo with the phone's OCR and saves the lines with their positions as a
/// JSON fixture for the Standard Delivery one-scan tests (plan §6). Copy the
/// files into `test/fixtures/one_scan/` on the PC; that folder is
/// git-ignored because the documents carry customer data.
class OcrDumpController extends GetxController {
  final RxBool busy = false.obs;
  final RxList<String> saved = <String>[].obs;
  final RxnString error = RxnString();

  /// Photos from the gallery, each read and saved.
  Future<void> dumpFromGallery() async {
    final picked = await ImagePicker().pickMultiImage();
    await _dumpFiles(picked);
  }

  /// A photo taken now, the same way Scan Document takes it.
  Future<void> dumpFromCamera() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 90);
    await _dumpFiles([if (picked != null) picked]);
  }

  /// Exactly what the last Scan Document read, without reading again: the
  /// one to send when a scan came out wrong.
  Future<void> dumpLastScan() async {
    error.value = null;
    final lines = Get.find<IDeliveryDocumentScanService>().lastLines;
    if (lines.isEmpty) {
      error.value = 'No scan yet. Use Scan Document first.';
      return;
    }
    busy.value = true;
    try {
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-');
      await _save(lines, 'last_scan_$stamp', 'last in-app scan');
    } catch (e) {
      error.value = 'Dump failed: $e';
    } finally {
      busy.value = false;
    }
  }

  Future<void> _dumpFiles(List<XFile> picked) async {
    error.value = null;
    if (picked.isEmpty) return;
    busy.value = true;
    try {
      final ocr = Get.find<ITextRecognitionService>();
      for (final image in picked) {
        final lines =
            await ocr.processImageLines(InputImage.fromFilePath(image.path));
        final name = image.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        await _save(lines, name, image.name);
      }
    } catch (e) {
      error.value = 'Dump failed: $e';
    } finally {
      busy.value = false;
    }
  }

  Future<void> _save(List<OcrLine> lines, String name, String source) async {
    final dir = await _outputDir();
    final file = File('${dir.path}${Platform.pathSeparator}$name.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ')
        .convert(OcrLineDump.toJson(lines, source: source)));
    saved.insert(0, '${file.path} (${lines.length} lines)');
    logDebug('[OneScan] dumped ${lines.length} OCR lines to ${file.path}');
  }

  /// `MDMPIAPP/one_scan_fixtures` on the phone's storage, like the app's
  /// other exports; the app documents folder when that is not writable.
  static Future<Directory> _outputDir() async {
    final shared = Directory('/storage/emulated/0/MDMPIAPP/one_scan_fixtures');
    try {
      await shared.create(recursive: true);
      return shared;
    } catch (_) {
      final docs = await getApplicationDocumentsDirectory();
      return Directory('${docs.path}${Platform.pathSeparator}one_scan_fixtures')
          .create(recursive: true);
    }
  }
}

class OcrDumpPage extends StatelessWidget {
  const OcrDumpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OcrDumpController());
    return Scaffold(
      appBar: const BAppBar(title: Text('Dump OCR lines'), showBackArrow: true),
      body: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Save what a scan read as JSON (text + positions) for '
                'the one-scan tests. When a Scan Document came out wrong, tap '
                '"Save the last scan" right after it. The files hold customer '
                'data: keep them off Git.'),
            const SizedBox(height: BSizes.md),
            Obx(() {
              final busy = controller.busy.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: busy ? null : controller.dumpLastScan,
                    child: Text(busy ? 'Reading…' : 'Save the last scan'),
                  ),
                  const SizedBox(height: BSizes.sm),
                  OutlinedButton(
                    onPressed: busy ? null : controller.dumpFromCamera,
                    child: const Text('Take a photo and dump'),
                  ),
                  const SizedBox(height: BSizes.sm),
                  OutlinedButton(
                    onPressed: busy ? null : controller.dumpFromGallery,
                    child: const Text('Pick photos and dump'),
                  ),
                ],
              );
            }),
            Obx(() => controller.error.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: BSizes.sm),
                    child: Text(controller.error.value!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  )),
            const SizedBox(height: BSizes.md),
            Expanded(
              child: Obx(() => ListView(
                    children: [
                      for (final path in controller.saved)
                        ListTile(dense: true, title: SelectableText(path)),
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
