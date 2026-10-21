import 'dart:io';

import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/delivery_document_scan_result.dart';

/// Reads one photo of a delivery document on the device: client, document
/// references and items (Standard Delivery one-scan, plan §4.1). No network.
abstract class IDeliveryDocumentScanService {
  Future<Result<DeliveryDocumentScanResult>> scan(File image);

  /// Frees the cached client index (the form was left).
  void clearCache();

  /// The OCR lines of the last scan (the pass that was used), for the
  /// developer "Dump OCR lines" tool. Empty before the first scan.
  List<OcrLine> get lastLines;
}
