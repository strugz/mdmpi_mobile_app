import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';

/// The customer block read off a scanned delivery document
/// (Standard Delivery one-scan, plan §4.3).
///
/// Every field is optional: a document may have no customer block at all
/// (Materials Issuance Slip, Goods Issue), or OCR may miss part of it.
class ScannedClientHeader {
  const ScannedClientHeader({
    this.label,
    this.prefix,
    this.name,
    this.address,
    this.rawLines = const [],
    this.nameCandidates = const [],
  });

  /// When no name was read under a label: the header rows that could be
  /// the name, most likely first (a row starting with a code such as
  /// `DLR-190`, then the rest top to bottom), prefix removed. The scan
  /// matches each against the client list and takes the one that matches.
  final List<String> nameCandidates;

  /// This header with [name] filled in from [nameCandidates].
  ScannedClientHeader withName(String name) => ScannedClientHeader(
        label: label,
        prefix: prefix,
        name: name,
        address: address,
        rawLines: rawLines,
        nameCandidates: nameCandidates,
      );

  /// Nothing read: no customer label on the page.
  static const empty = ScannedClientHeader();

  /// The label the name was found under, as printed (`Business Partner:`,
  /// `DELIVERED TO:`), for logging.
  final String? label;

  /// A code printed before the name, such as `NCR-414` or `DLR-190`. It is
  /// **not** the client code (`ACCMSC`): kept for logging, never matched.
  final String? prefix;

  /// The customer name as printed, prefix removed.
  final String? name;

  /// The customer address as printed, rows joined by a space.
  final String? address;

  /// The OCR lines the label, name and address were read from.
  final List<OcrLine> rawLines;

  /// Whether a customer label was found, even if no name followed it.
  /// The one-scan rotation retry runs only when this is false and no
  /// document reference was found (§4.1).
  bool get hasLabel => label != null;

  bool get hasName => name != null && name!.isNotEmpty;

  @override
  String toString() =>
      'ScannedClientHeader(label: $label, prefix: $prefix, name: $name, '
      'address: $address)';
}
