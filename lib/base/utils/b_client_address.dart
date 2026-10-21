/// The address a delivery request shows for its client
/// (Standard Delivery one-scan, plan §4.4a).
class BClientAddress {
  BClientAddress._();

  static final RegExp _placeholder = RegExp(r'^(none|na|n/a)$', caseSensitive: false);

  /// Whether [address] says nothing: empty, spaces, or `NONE` / `NA` / `N/A`
  /// in any case. `ClientModel.empty()` uses `N/A`, so that counts too.
  static bool isMissing(String? address) {
    final trimmed = address?.trim() ?? '';
    return trimmed.isEmpty || _placeholder.hasMatch(trimmed);
  }

  /// The client's saved address wins. The address read off the scanned
  /// document is used only when the saved one [isMissing] and the scan read
  /// one; otherwise the saved value is kept as it is. `fromScan` tells the
  /// review sheet to label it "Address from scanned document".
  ///
  /// This never writes anything: the result goes on a copy of the client
  /// for this one request, never into `ACCMST_`.
  static ({String address, bool fromScan}) resolve(
    String? savedAddress,
    String? scannedAddress,
  ) {
    final saved = savedAddress ?? '';
    if (!isMissing(saved)) return (address: saved, fromScan: false);
    final scanned = scannedAddress?.trim() ?? '';
    if (isMissing(scanned)) return (address: saved, fromScan: false);
    return (address: scanned, fromScan: true);
  }
}
