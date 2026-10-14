import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

/// One `ReconCases` entry of the workspace download → a [ReconCaseBundle].
///
/// Pure, and defensive like the rest of the workspace parser: PascalCase keys
/// (what the API pins) or camelCase, numbers as numbers or strings, missing
/// keys as blanks. The server's cached status is ignored: the phone works it
/// out from the log itself, so the two cannot disagree on screen.
class ReconCaseMapper {
  const ReconCaseMapper._();

  /// Null for a case that cannot be kept: no id or no account.
  static ReconCaseBundle? fromJson(Map<String, dynamic> json) {
    final caseId = _str(json, 'CaseId').trim();
    final clientCode = _str(json, 'ClientCode').trim();
    if (caseId.isEmpty || clientCode.isEmpty) return null;

    return ReconCaseBundle(
      reconCase: ReconCase(
        caseId: caseId,
        clientCode: clientCode,
        clientName: _str(json, 'ClientName').trim(),
        collectorCode: _str(json, 'CollectorCode').trim(),
        collectorName: _str(json, 'CollectorName').trim(),
        dateOpened: _str(json, 'DateOpened').trim(),
      ),
      invoices: [
        for (final m in _maps(json, 'Invoices'))
          if (_str(m, 'DocumentId').trim().isNotEmpty)
            ReconCaseInvoice(
              invoiceNo: _str(m, 'DocumentId').trim(),
              amount: _num(m, 'Amount') ?? 0,
              currentBalance: _num(m, 'CurrentBalance'),
              clearedAt: _strOrNull(m, 'ClearedAt'),
            ),
      ],
      activities: [
        for (final m in _maps(json, 'Activities'))
          if (_activity(caseId, m) case final a?) a,
      ],
      source: ReconSource.server,
    );
  }

  /// Null for a step with no id or of a type this build does not know (a
  /// newer server): it cannot be shown or evaluated, so it is left out rather
  /// than guessed.
  static ReconActivity? _activity(String caseId, Map<String, dynamic> m) {
    final id = _str(m, 'ActivityId').trim();
    final type = ReconActivityType.fromCode(_str(m, 'Type').trim());
    if (id.isEmpty || type == null) return null;
    return ReconActivity(
      activityId: id,
      caseId: caseId,
      dateTime: _str(m, 'DateTime').trim(),
      type: type,
      invoiceNos: _strings(m, 'DocumentIds'),
      remarks: _str(m, 'Remarks'),
      amount: _num(m, 'Amount'),
      validationResult: ReconValidationResult.fromCode(
          _strOrNull(m, 'ValidationResult')?.toUpperCase()),
      nextAction: _str(m, 'NextAction'),
      nextActionDueDate: _strOrNull(m, 'NextActionDueDate'),
      attachmentRefs: _strings(m, 'AttachmentIds'),
      recordedBy: _str(m, 'RecordedBy'),
    );
  }

  // --- tolerant accessors ---------------------------------------------------

  static dynamic _pick(Map<String, dynamic> m, String key) {
    if (m.containsKey(key)) return m[key];
    return m[key[0].toLowerCase() + key.substring(1)];
  }

  static String _str(Map<String, dynamic> m, String key) =>
      (_pick(m, key) ?? '').toString();

  static String? _strOrNull(Map<String, dynamic> m, String key) {
    final v = _pick(m, key)?.toString().trim();
    return v == null || v.isEmpty ? null : v;
  }

  static double? _num(Map<String, dynamic> m, String key) {
    final v = _pick(m, key);
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static List<Map<String, dynamic>> _maps(Map<String, dynamic> m, String key) {
    final v = _pick(m, key);
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// A list of strings, or one comma-separated string.
  static List<String> _strings(Map<String, dynamic> m, String key) {
    final v = _pick(m, key);
    final raw = v is List
        ? v.map((e) => e?.toString() ?? '')
        : (v?.toString() ?? '').split(',');
    return raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}
