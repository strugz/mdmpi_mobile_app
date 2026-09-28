import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_account_history_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_actual_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_activity_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_advance_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/dtos/collection_item_dto.dart';
import 'package:mdmpi_mobile_app/features/collection/mappers/collection_mapper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// Everything one `GET /api4/Collection/workspace` call returns, already shaped
/// for the device's SQLite tables.
class CollectionWorkspace {
  final List<CollectionItemModel> items;
  final List<CollectionAdvanceRecord> advances;

  /// Deposits (as type 'Deposit') plus CWT Pick-up / Reconciliation activities.
  final List<CollectionActivityRecord> activities;
  final List<CollectionAccountHistoryRecord> accountHistory;

  /// yyyy-MM -> target amount
  final Map<String, double> targets;

  /// Actual Collection the office posted for this collector (revisions list
  /// item 11), last 12 months.
  final List<CollectionActualRecord> actualCollections;

  /// Whether the server sent `ActualCollections` at all. An older server
  /// leaves it out, and that must not read as "the office posted nothing":
  /// only a list that was sent (even an empty one) replaces the local copy.
  final bool hasActualCollections;

  const CollectionWorkspace({
    required this.items,
    required this.advances,
    required this.activities,
    required this.accountHistory,
    required this.targets,
    this.actualCollections = const [],
    this.hasActualCollections = false,
  });
}

/// Pure JSON -> records translation for the workspace payload. Kept free of
/// I/O so it can be unit-tested; the repository persists the result.
///
/// Keys are PascalCase (the API pins them), but camelCase is tolerated.
class CollectionWorkspaceParser {
  const CollectionWorkspaceParser._();

  static CollectionWorkspace parse(Map<String, dynamic> json) {
    final items = _list(json, 'Items')
        .map((e) => CollectionItemDto.fromJson(_map(e)))
        .toList();

    return CollectionWorkspace(
      items: CollectionMapper.toDomainModels(items),
      advances: _list(json, 'Advances')
          .map(_map)
          .map(_advance)
          .whereType<CollectionAdvanceRecord>()
          .toList(),
      activities: [
        ..._list(json, 'Deposits').map(_map).map(_deposit),
        ..._list(json, 'Activities').map(_map).map(_activity),
      ],
      accountHistory:
          _list(json, 'AccountHistory').map(_map).map(_history).toList(),
      targets: {
        for (final t in _list(json, 'Targets').map(_map))
          _str(t, 'YearMonth'): _num(t, 'TargetAmount'),
      }..removeWhere((k, _) => k.isEmpty),
      actualCollections: _list(json, 'ActualCollections')
          .whereType<Map>()
          .map(_map)
          .map(_actual)
          .whereType<CollectionActualRecord>()
          .toList(),
      hasActualCollections: _pick(json, 'ActualCollections') is List,
    );
  }

  // --- element mappers --------------------------------------------------------

  static CollectionAdvanceRecord? _advance(Map<String, dynamic> m) {
    final ref = _str(m, 'ExternalRef');
    if (ref.isEmpty) return null;
    return CollectionAdvanceRecord(
      externalRef: ref,
      clientId: _str(m, 'ClientCode'),
      clientName: _str(m, 'ClientName'),
      // What is still available to assign — the server has already netted off
      // any allocations.
      amount: m.containsKey('Unallocated') || m.containsKey('unallocated')
          ? _num(m, 'Unallocated')
          : _num(m, 'Amount'),
      date: _str(m, 'Date'),
      remarks: _str(m, 'Remarks'),
      collectorName: _str(m, 'CollectorCode'),
    );
  }

  static CollectionActivityRecord _deposit(Map<String, dynamic> m) =>
      CollectionActivityRecord(
        type: 'Deposit',
        clientId: _str(m, 'ClientCode'),
        clientName: _str(m, 'ClientName'),
        date: _str(m, 'Date'),
        amount: _num(m, 'Amount'),
        bankName: _strOrNull(m, 'BankName'),
        checkNumber: _strOrNull(m, 'ReferenceNo'),
        remarks: _str(m, 'Remarks'),
        collectorName: _str(m, 'CollectorCode'),
        localRef: 'SRV-DEP-${_str(m, 'DepositId')}',
      );

  static CollectionActivityRecord _activity(Map<String, dynamic> m) =>
      CollectionActivityRecord(
        type: _str(m, 'Type'),
        clientId: _str(m, 'ClientCode'),
        clientName: _str(m, 'ClientName'),
        date: _str(m, 'Date'),
        remarks: _str(m, 'Remarks'),
        collectorName: _str(m, 'CollectorCode'),
        localRef: 'SRV-ACT-${_str(m, 'ActivityId')}',
      );

  /// Null for a row that cannot be kept: no usable id (it is the primary key)
  /// or no yyyy-MM-dd date (the month it belongs to).
  static CollectionActualRecord? _actual(Map<String, dynamic> m) {
    final id = int.tryParse(_str(m, 'ActualId').trim()) ??
        double.tryParse(_str(m, 'ActualId').trim())?.toInt();
    if (id == null || id <= 0) return null;
    final raw = _str(m, 'CollectionDate').trim();
    // The date is yyyy-MM-dd; tolerate a server that sends a full timestamp.
    final date = raw.length >= 10 ? raw.substring(0, 10) : '';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) return null;
    return CollectionActualRecord(
      actualId: id,
      collectionDate: date,
      amount: _num(m, 'Amount'),
      referenceNo: _str(m, 'ReferenceNo').trim(),
      remarks: _str(m, 'Remarks').trim(),
      postedBy: _str(m, 'PostedBy'),
      createdAt: _str(m, 'CreatedAt'),
      updatedAt: _strOrNull(m, 'UpdatedAt'),
      updatedBy: _strOrNull(m, 'UpdatedBy'),
    );
  }

  static CollectionAccountHistoryRecord _history(Map<String, dynamic> m) =>
      CollectionAccountHistoryRecord(
        clientId: _str(m, 'ClientCode'),
        date: _str(m, 'Date'),
        reason: _str(m, 'Status'),
        remarks: _str(m, 'Remarks'),
        collectorName: _str(m, 'CollectorName'),
      );

  // --- tolerant accessors -----------------------------------------------------

  static dynamic _pick(Map<String, dynamic> m, String key) {
    if (m.containsKey(key)) return m[key];
    final camel = key[0].toLowerCase() + key.substring(1);
    return m[camel];
  }

  static List<dynamic> _list(Map<String, dynamic> m, String key) {
    final v = _pick(m, key);
    return v is List ? v : const [];
  }

  static Map<String, dynamic> _map(dynamic e) =>
      e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);

  static String _str(Map<String, dynamic> m, String key) =>
      (_pick(m, key) ?? '').toString();

  static String? _strOrNull(Map<String, dynamic> m, String key) {
    final v = _pick(m, key);
    return v == null ? null : v.toString();
  }

  static double _num(Map<String, dynamic> m, String key) {
    final v = _pick(m, key);
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
