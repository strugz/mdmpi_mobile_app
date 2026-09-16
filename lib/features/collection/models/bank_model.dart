/// A bank from the company bank list (`/api2/DRPMST/banklist`).
///
/// Collectors used to type the bank on a check by hand, so the same bank
/// arrived as "BPI", "B.P.I." and "Bank of the Philippine Islands" depending
/// on who recorded it. Picking from this list means the name that reaches the
/// server is the one the company uses.
class BankModel {
  const BankModel({required this.id, required this.code, required this.name});

  final String id;

  /// Short code, e.g. BPI. Useful for searching and for a compact chip.
  final String code;

  /// Full name as the company writes it, e.g. Bank of the Philippine Islands.
  final String name;

  factory BankModel.fromJson(Map<String, dynamic> json) => BankModel(
        id: (json['mid'] ?? '').toString(),
        code: (json['bankcode'] ?? '').toString().trim(),
        name: (json['bank'] ?? '').toString().trim(),
      );

  Map<String, dynamic> toDbMap() => {'mid': id, 'bankcode': code, 'bank': name};

  factory BankModel.fromDbMap(Map<String, Object?> row) => BankModel(
        id: (row['mid'] ?? '').toString(),
        code: (row['bankcode'] ?? '').toString(),
        name: (row['bank'] ?? '').toString(),
      );

  /// What gets recorded against a collection, and what is shown in the field.
  ///
  /// The code, because that is what the company's own records key on and it
  /// fits a field next to a check number. The full name is still what the
  /// picker lists and searches, so nobody has to know the code to find it.
  String get label => code.isNotEmpty ? code : name;

  /// True when [query] matches the code or any part of the name, so typing
  /// "bpi" and typing "philippine" both find the same bank.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return code.toLowerCase().contains(q) || name.toLowerCase().contains(q);
  }

  @override
  bool operator ==(Object other) => other is BankModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
