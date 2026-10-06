/// The Head's team feed (Collection TODO items 21–22), as
/// `GET /api4/Collection/team/engagements` returns it: everyone who has ever
/// uploaded, and each engagement, deposit and CWT pick-up in a date window.
///
/// Online only: a collector's unsent outbox is not here until they Upload All.
class TeamActivityFeed {
  const TeamActivityFeed({
    required this.from,
    required this.to,
    this.collectors = const [],
    this.engagements = const [],
  });

  /// `yyyy-MM-dd`, inclusive.
  final String from;
  final String to;

  /// By name; the picker's list.
  final List<TeamCollector> collectors;

  /// Newest first.
  final List<TeamEngagement> engagements;

  static const empty = TeamActivityFeed(from: '', to: '');

  /// Tolerant of the backend's PascalCase keys and camelCase alike.
  factory TeamActivityFeed.fromJson(Map<String, dynamic> json) {
    return TeamActivityFeed(
      from: _str(_pick(json, 'From')),
      to: _str(_pick(json, 'To')),
      collectors: _list(_pick(json, 'Collectors'))
          .map(TeamCollector.fromJson)
          .where((c) => c.code.isNotEmpty)
          .toList(),
      engagements:
          _list(_pick(json, 'Engagements')).map(TeamEngagement.fromJson).toList(),
    );
  }
}

class TeamCollector {
  const TeamCollector({required this.code, required this.name});

  final String code;

  /// The latest name the code uploaded under; the code when none.
  final String name;

  factory TeamCollector.fromJson(Map<String, dynamic> json) {
    final code = _str(_pick(json, 'Code')).trim();
    final name = _str(_pick(json, 'Name')).trim();
    return TeamCollector(code: code, name: name.isEmpty ? code : name);
  }

  @override
  bool operator ==(Object other) =>
      other is TeamCollector && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'TeamCollector($code, $name)';
}

/// One thing a collector did. [kind] is `Engagement` (per invoice or per
/// account: Field / Batch / Office / Reconciliation / Deferred), `Deposit`
/// or `Activity` (CWT Pick-up).
class TeamEngagement {
  const TeamEngagement({
    required this.kind,
    required this.id,
    required this.collectorCode,
    this.collectorName = '',
    this.clientCode = '',
    this.clientName = '',
    this.documentId = '',
    this.activityType = '',
    this.status = '',
    this.amount = 0,
    this.date = '',
    this.remarks = '',
    this.purposeOfVisit,
    this.bankName,
    this.referenceNo,
  });

  final String kind;
  final int id;
  final String collectorCode;
  final String collectorName;
  final String clientCode;
  final String clientName;
  final String documentId;
  final String activityType;

  /// The outcome (Collected, Partial Payment, …) or the defer reason; '' for
  /// a deposit or CWT pick-up.
  final String status;
  final double amount;

  /// `yyyy-MM-dd`; '' when the upload carried no date.
  final String date;
  final String remarks;
  final String? purposeOfVisit;
  final String? bankName;
  final String? referenceNo;

  bool get isDeposit => kind == 'Deposit';
  bool get isDeferred => activityType == 'Deferred';

  /// The name to show for who did it: the uploaded name, else the code.
  String get collectorLabel =>
      collectorName.trim().isNotEmpty ? collectorName.trim() : collectorCode;

  /// What the card calls it: the outcome for an engagement, the activity
  /// type otherwise ("Deposit", "CWT Pick-up").
  String get statusLabel => status.trim().isNotEmpty ? status : activityType;

  /// Unique across kinds, for widget keys and de-duplication.
  String get key => '$kind:$id';

  factory TeamEngagement.fromJson(Map<String, dynamic> json) {
    return TeamEngagement(
      kind: _str(_pick(json, 'Kind')),
      id: _num(_pick(json, 'Id')).toInt(),
      collectorCode: _str(_pick(json, 'CollectorCode')).trim(),
      collectorName: _str(_pick(json, 'CollectorName')),
      clientCode: _str(_pick(json, 'ClientCode')),
      clientName: _str(_pick(json, 'ClientName')),
      documentId: _str(_pick(json, 'DocumentId')),
      activityType: _str(_pick(json, 'ActivityType')),
      status: _str(_pick(json, 'Status')),
      amount: _num(_pick(json, 'Amount')),
      date: _str(_pick(json, 'Date')),
      remarks: _str(_pick(json, 'Remarks')),
      purposeOfVisit: _strOrNull(_pick(json, 'PurposeOfVisit')),
      bankName: _strOrNull(_pick(json, 'BankName')),
      referenceNo: _strOrNull(_pick(json, 'ReferenceNo')),
    );
  }
}

// --- tolerant JSON helpers (same idea as CollectionWorkspaceParser) ---

dynamic _pick(Map<String, dynamic> json, String pascal) {
  if (json.containsKey(pascal)) return json[pascal];
  final camel = pascal[0].toLowerCase() + pascal.substring(1);
  return json[camel];
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final e in value)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

String _str(dynamic value) => value == null ? '' : value.toString();

String? _strOrNull(dynamic value) {
  final s = _str(value).trim();
  return s.isEmpty ? null : s;
}

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(_str(value)) ?? 0;
}
