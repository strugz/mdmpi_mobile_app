import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// A temporary account (update checklist item 16): an account a collector
/// names for an advanced payment before it is in the client registry.
///
/// Its code is `TMP-<collector>-<yyyyMMddHHmmss>`, made on the phone; the
/// server registers it under the name the collector gave. The advance
/// cannot be applied to an invoice until the collector links it to the real
/// account (LINK_ADVANCE), which moves the advance there.
class BTemporaryAccount {
  BTemporaryAccount._();

  static const String prefix = 'TMP-';

  static bool isTemporary(String? clientCode) =>
      (clientCode ?? '').trim().toUpperCase().startsWith(prefix);

  /// A new temporary account named [name], for [collectorCode], at [now].
  static ClientModel create({
    required String name,
    required String collectorCode,
    required DateTime now,
  }) {
    String two(int v) => v.toString().padLeft(2, '0');
    final who = collectorCode.trim().isEmpty
        ? 'NA'
        : collectorCode.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    final code = '$prefix$who-$stamp';
    return ClientModel(
      id: code,
      code: code,
      name: name.trim().replaceAll(RegExp(r'\s+'), ' '),
      address: '',
      contact: '',
      emailAddress: '',
    );
  }
}
