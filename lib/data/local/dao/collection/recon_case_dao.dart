import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';
import 'package:sqflite/sqflite.dart';

/// Reconciliation cases on the phone: the case, its invoices and its activity
/// log (db_schema.dart, ensureReconciliationTables).
///
/// The three are written together, in one transaction, so a case is never
/// stored without its invoices or with half a download. The status columns
/// are a cache of the [ReconEvaluation] the caller passes in.
class ReconCaseDao {
  ReconCaseDao(this.db);

  final Database db;

  static const caseTable = 'a_tblCollectionReconCase';
  static const invoiceTable = 'a_tblCollectionReconCaseInvoice';
  static const activityTable = 'a_tblCollectionReconActivity';

  /// A case this device opened, with its invoices.
  Future<void> saveLocalCase(
      ReconCaseBundle bundle, ReconEvaluation evaluation) async {
    await db.transaction((txn) async {
      await _writeCase(txn, bundle, evaluation, ReconSource.local);
      for (final a in bundle.activities) {
        await txn.insert(activityTable, _activityRow(a, ReconSource.local),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// A step this device logged, and the case's cache as it stands after it.
  Future<void> addLocalActivity(
      ReconActivity activity, ReconEvaluation evaluation) async {
    await db.transaction((txn) async {
      await txn.insert(activityTable, _activityRow(activity, ReconSource.local),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update(caseTable, _cacheRow(evaluation),
          where: 'caseId = ?', whereArgs: [activity.caseId]);
    });
  }

  /// Who holds the case now: '' when released and waiting to be acquired.
  Future<void> setCollector(String caseId, String code, String name) =>
      db.update(caseTable, {'collectorCode': code, 'collectorName': name},
          where: 'caseId = ?', whereArgs: [caseId]);

  /// Every stored case, each with its invoices and log (oldest step first).
  Future<List<ReconCaseBundle>> getAll() async {
    final cases = await db.query(caseTable, orderBy: 'dateOpened, caseId');
    if (cases.isEmpty) return const [];
    final invoices = await db.query(invoiceTable, orderBy: 'rowid');
    final activities =
        await db.query(activityTable, orderBy: 'dateTime, activityId');
    return [
      for (final c in cases)
        _bundle(
          c,
          invoices.where((r) => r['caseId'] == c['caseId']).toList(),
          activities.where((r) => r['caseId'] == c['caseId']).toList(),
        ),
    ];
  }

  Future<ReconCaseBundle?> getCase(String caseId) async {
    final cases = await db.query(caseTable,
        where: 'caseId = ?', whereArgs: [caseId], limit: 1);
    if (cases.isEmpty) return null;
    final invoices = await db.query(invoiceTable,
        where: 'caseId = ?', whereArgs: [caseId], orderBy: 'rowid');
    final activities = await db.query(activityTable,
        where: 'caseId = ?',
        whereArgs: [caseId],
        orderBy: 'dateTime, activityId');
    return _bundle(cases.single, invoices, activities);
  }

  /// Take the server's cases from a download.
  ///
  /// - A case the server returned replaces the stored one (a case this device
  ///   opened becomes the server's copy once it has been uploaded).
  /// - Its steps are the server's, plus any step this device logged that the
  ///   server does not have yet: those are still waiting in the outbox and
  ///   must not be lost.
  /// - A server copy the server no longer returns (closed long ago) is
  ///   removed. A case this device opened and has not uploaded stays.
  Future<void> replaceServerCopies(
    List<ReconCaseBundle> bundles,
    ReconEvaluation Function(ReconCaseBundle bundle) evaluate,
  ) async {
    await db.transaction((txn) async {
      final keep = {for (final b in bundles) b.caseId};
      final gone = (await txn.query(caseTable,
              columns: ['caseId'],
              where: 'source = ?',
              whereArgs: [ReconSource.server]))
          .map((r) => r['caseId'] as String)
          .where((id) => !keep.contains(id))
          .toList();
      for (final id in gone) {
        await txn.delete(caseTable, where: 'caseId = ?', whereArgs: [id]);
        await txn.delete(invoiceTable, where: 'caseId = ?', whereArgs: [id]);
        await txn.delete(activityTable,
            where: 'caseId = ? AND source = ?',
            whereArgs: [id, ReconSource.server]);
      }

      for (final b in bundles) {
        await txn.delete(activityTable,
            where: 'caseId = ? AND source = ?',
            whereArgs: [b.caseId, ReconSource.server]);
        for (final a in b.activities) {
          await txn.insert(activityTable, _activityRow(a, ReconSource.server),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        // The cache follows the whole log, pending local steps included.
        final pending = (await txn.query(activityTable,
                where: 'caseId = ? AND source = ?',
                whereArgs: [b.caseId, ReconSource.local]))
            .map(_activity)
            .whereType<ReconActivity>();
        final merged = ReconCaseBundle(
          reconCase: b.reconCase,
          invoices: b.invoices,
          activities: [...b.activities, ...pending],
          source: ReconSource.server,
        );
        await _writeCase(txn, merged, evaluate(merged), ReconSource.server);
      }
    });
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $caseTable')) ??
      0;

  // --- rows ---------------------------------------------------------------

  Future<void> _writeCase(DatabaseExecutor txn, ReconCaseBundle b,
      ReconEvaluation e, String source) async {
    final c = b.reconCase;
    await txn.insert(
      caseTable,
      {
        'caseId': c.caseId,
        'clientCode': c.clientCode,
        'clientName': c.clientName,
        'collectorCode': c.collectorCode,
        'collectorName': c.collectorName,
        'dateOpened': c.dateOpened,
        'source': source,
        ..._cacheRow(e),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await txn.delete(invoiceTable, where: 'caseId = ?', whereArgs: [c.caseId]);
    for (final i in b.invoices) {
      await txn.insert(
        invoiceTable,
        {
          'caseId': c.caseId,
          'invoiceNo': i.invoiceNo,
          'amount': i.amount,
          'currentBalance': i.currentBalance,
          'clearedAt': i.clearedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Map<String, Object?> _cacheRow(ReconEvaluation e) => {
        'caseStatus': e.status.code,
        'nextActor': e.nextActor?.code,
        'lastActivityAt': e.lastActivity?.dateTime,
        'dateClosed':
            e.dateClosed == null ? null : BReconClock.format(e.dateClosed!),
        'soaDate': e.soaDate == null ? null : BReconClock.format(e.soaDate!),
        'soaAmount': e.soaAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  static Map<String, Object?> _activityRow(ReconActivity a, String source) => {
        'activityId': a.activityId,
        'caseId': a.caseId,
        'dateTime': a.dateTime,
        'type': a.type.code,
        'invoiceNos': a.invoiceNos.join(','),
        'remarks': a.remarks,
        'amount': a.amount,
        'validationResult': a.validationResult?.code,
        'nextAction': a.nextAction,
        'nextActionDueDate': a.nextActionDueDate,
        'attachmentIds': a.attachmentRefs.join(','),
        'recordedBy': a.recordedBy,
        'source': source,
        'createdAt': DateTime.now().toIso8601String(),
      };

  static ReconCaseBundle _bundle(Map<String, Object?> c,
      List<Map<String, Object?>> invoices, List<Map<String, Object?>> acts) {
    String s(String k) => (c[k] ?? '').toString();
    return ReconCaseBundle(
      reconCase: ReconCase(
        caseId: s('caseId'),
        clientCode: s('clientCode'),
        clientName: s('clientName'),
        collectorCode: s('collectorCode'),
        collectorName: s('collectorName'),
        dateOpened: s('dateOpened'),
      ),
      invoices: [
        for (final r in invoices)
          ReconCaseInvoice(
            invoiceNo: (r['invoiceNo'] ?? '').toString(),
            amount: (r['amount'] as num?)?.toDouble() ?? 0,
            currentBalance: (r['currentBalance'] as num?)?.toDouble(),
            clearedAt: r['clearedAt']?.toString(),
          ),
      ],
      activities: acts.map(_activity).whereType<ReconActivity>().toList(),
      source: s('source').isEmpty ? ReconSource.local : s('source'),
    );
  }

  /// Null for a row of a type this build does not know (a newer server).
  static ReconActivity? _activity(Map<String, Object?> r) {
    final type = ReconActivityType.fromCode(r['type']?.toString());
    if (type == null) return null;
    List<String> split(Object? v) => (v ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return ReconActivity(
      activityId: (r['activityId'] ?? '').toString(),
      caseId: (r['caseId'] ?? '').toString(),
      dateTime: (r['dateTime'] ?? '').toString(),
      type: type,
      invoiceNos: split(r['invoiceNos']),
      remarks: (r['remarks'] ?? '').toString(),
      amount: (r['amount'] as num?)?.toDouble(),
      validationResult:
          ReconValidationResult.fromCode(r['validationResult']?.toString()),
      nextAction: (r['nextAction'] ?? '').toString(),
      nextActionDueDate: r['nextActionDueDate']?.toString(),
      attachmentRefs: split(r['attachmentIds']),
      recordedBy: (r['recordedBy'] ?? '').toString(),
    );
  }
}
