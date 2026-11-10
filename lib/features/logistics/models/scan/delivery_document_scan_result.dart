import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/client_match_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scanned_client_header.dart';

/// Everything one photo of a delivery document gave (plan §4.1): client,
/// document references and items, all from the same on-device OCR pass.
class DeliveryDocumentScanResult {
  const DeliveryDocumentScanResult({
    required this.header,
    required this.match,
    required this.references,
    required this.items,
    this.warnings = const [],
    this.retryRotation,
    this.documentType = DeliveryDocumentType.unknown,
  });

  /// What the document is, from its printed title.
  final DeliveryDocumentType documentType;

  final ScannedClientHeader header;
  final ClientMatchResult match;

  /// In the form's label style (`SINo.:700014535`), de-duplicated.
  final List<String> references;

  final ItemTableReading items;

  /// Messages for the review sheet ("Couldn't read …").
  final List<String> warnings;

  /// The rotation the retry pass used, or null when there was no retry.
  final int? retryRotation;

  /// No client label, no reference and no item table: worth a retake.
  bool get foundNothing => isEmptyReading(header, references, items);

  static bool isEmptyReading(ScannedClientHeader header,
          List<String> references, ItemTableReading items) =>
      !header.hasLabel && references.isEmpty && !items.headerFound;
}
