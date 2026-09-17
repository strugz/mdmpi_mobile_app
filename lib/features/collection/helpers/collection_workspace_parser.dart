import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_account_history_dao.dart';
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

  const CollectionWorkspace({
    required this.items,
    required this.advances,
    required this.activities,
    required this.accountHistory,
    required this.targets,
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
