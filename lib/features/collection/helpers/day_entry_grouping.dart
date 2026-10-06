/// One group per account, in the order the accounts first appear (newest
/// first, as [entries] is), each keeping its entries in that order.
///
/// Three invoices settled at one counter are one visit and read as one card
/// on the calendar. An entry with no account name cannot be told to be
/// anyone's and stands alone.
///
/// Entries are the maps produced by
/// `CollectionActivityController.activitiesByDate`; only `'accountName'` is
/// read here.
List<List<Map<String, dynamic>>> groupDayEntriesByAccount(
    List<Map<String, dynamic>> entries) {
  final groups = <List<Map<String, dynamic>>>[];
  final byName = <String, List<Map<String, dynamic>>>{};
  for (final e in entries) {
    final name = (e['accountName'] ?? '').toString();
    if (name.isEmpty) {
      groups.add([e]);
      continue;
    }
    final existing = byName[name];
    if (existing != null) {
      existing.add(e);
    } else {
      final g = [e];
      byName[name] = g;
      groups.add(g);
    }
  }
  return groups;
}
