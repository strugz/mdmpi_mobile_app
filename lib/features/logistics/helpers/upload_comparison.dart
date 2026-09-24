import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_date_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

enum ComparisonKind { status, text, date, stamp }

/// One field of a request, as the phone and the server each hold it.
class ComparisonField {
  const ComparisonField({
    required this.label,
    required this.kind,
    required this.phone,
    required this.server,
    required this.differs,
  });

  final String label;
  final ComparisonKind kind;

  /// Raw values; the UI formats them by [kind]. Empty means not set.
  final String phone;
  final String server;

  final bool differs;
}

/// Lines up the phone's copy of a request with the server's, field by field,
/// for the Upload Data comparison sheet.
///
/// Values are compared the way the server compares them, not as strings: the
/// phone stores "2026-09-17 09:07:21.149665" where the server sends
/// "2026-09-17 09:07:21", and those are the same moment. Stamps match to the
/// second, dates to the day, statuses and names ignoring case and spaces.
class BUploadComparison {
  BUploadComparison._();

  static List<ComparisonField> fields(
      StandardDeliveryModel phone, StandardDeliveryModel? server) {
    ComparisonField f(String label, ComparisonKind kind,
        String Function(StandardDeliveryModel r) read) {
      final p = read(phone).trim();
      final s = server == null ? '' : read(server).trim();
      return ComparisonField(
        label: label,
        kind: kind,
        phone: p,
        server: s,
        differs: server != null && !_same(kind, p, s),
      );
    }

    return [
      f('Status', ComparisonKind.status, (r) => r.status),
      f('Delivery date', ComparisonKind.date, (r) => r.deliveryDate),
      f('Prepared by', ComparisonKind.text, (r) => r.itemPreparedBy),
      f('Preparation started', ComparisonKind.stamp, (r) => r.itemPreparedAt),
      f('Preparation ended', ComparisonKind.stamp, (r) => r.itemPreparedEndAt),
      f('Trip ticket', ComparisonKind.text, (r) => r.tripTicketNumber),
      f('Driver', ComparisonKind.text, (r) => r.deliveredBy),
      f('Helper', ComparisonKind.text, (r) => r.helper),
      f('Vehicle', ComparisonKind.text, _vehicle),
      f('Delivery started', ComparisonKind.stamp, (r) => r.deliveredAt),
      f('Delivered at', ComparisonKind.stamp, (r) => r.deliveredEndAt),
      f('Receiver', ComparisonKind.text, (r) => r.receiver),
    ];
  }

  /// The vehicle's name when known, else its ID.
  static String _vehicle(StandardDeliveryModel r) {
    final name = r.mobileName.trim();
    if (name.isNotEmpty) return name;
    final id = r.mobileID;
    return id == null || id == 0 ? '' : 'Vehicle $id';
  }

  static bool _same(ComparisonKind kind, String a, String b) {
    if (a.isEmpty || b.isEmpty) return a.isEmpty && b.isEmpty;
    switch (kind) {
      case ComparisonKind.date:
        final da = BUploadDateFilter.parseDay(a);
        final db = BUploadDateFilter.parseDay(b);
        return da != null && db != null ? da == db : _norm(a) == _norm(b);
      case ComparisonKind.stamp:
        final ta = BFormatter.parseLocal(a);
        final tb = BFormatter.parseLocal(b);
        if (ta == null || tb == null) return _norm(a) == _norm(b);
        return ta.millisecondsSinceEpoch ~/ 1000 ==
            tb.millisecondsSinceEpoch ~/ 1000;
      case ComparisonKind.status:
      case ComparisonKind.text:
        return _norm(a) == _norm(b);
    }
  }

  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
