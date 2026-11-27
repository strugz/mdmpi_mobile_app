/// One known item (code, description, unit) and how often it was used: a
/// row of `SCAN_ITEM_VOCAB_`, filled from the server's past requests and
/// from items the user confirmed on a scan.
class ScanVocabEntry {
  const ScanVocabEntry({
    required this.itemCode,
    required this.description,
    required this.unit,
    this.uses = 1,
  });

  final String itemCode;
  final String description;
  final String unit;
  final int uses;

  /// Upper-case code and description with spaces collapsed, so the same item
  /// from the server and from a confirmed scan is one row.
  String get key =>
      '${itemCode.trim().toUpperCase()}|'
      '${description.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ')}';

  /// `GET /api4/Item/vocabulary` row.
  factory ScanVocabEntry.fromApi(Map<String, dynamic> json) => ScanVocabEntry(
        itemCode: (json['ItemCode'] ?? '').toString().trim(),
        description: (json['Description'] ?? '').toString().trim(),
        unit: (json['Unit'] ?? '').toString().trim(),
        uses: int.tryParse('${json['Uses'] ?? 1}') ?? 1,
      );

  factory ScanVocabEntry.fromRow(Map<String, Object?> row) => ScanVocabEntry(
        itemCode: (row['ITEM_CODE'] ?? '').toString(),
        description: (row['DESCRIPTION'] ?? '').toString(),
        unit: (row['UNIT'] ?? '').toString(),
        uses: (row['USES'] as int?) ?? 1,
      );
}
