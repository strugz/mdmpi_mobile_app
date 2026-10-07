/// What's new, shown on Settings → About (Collection TODO item 15).
///
/// Kept in code, not in a file the phone would have to download: the About
/// screen must work offline. Newest first. When bumping the version, add a
/// group for it at the top (see `.claude/commands/bump-version.md`); the
/// screen shows the group for the running version, or the newest one when
/// the running version has no group yet.
class WhatsNewGroup {
  const WhatsNewGroup({required this.version, required this.items});

  /// `major.minor.patch`, as in pubspec.
  final String version;
  final List<WhatsNewItem> items;
}

class WhatsNewItem {
  const WhatsNewItem({required this.title, required this.detail, this.area});

  final String title;
  final String detail;

  /// "Collection", "Logistics", or null when it is for everyone.
  final String? area;
}

class BWhatsNew {
  BWhatsNew._();

  static const List<WhatsNewGroup> groups = [
    WhatsNewGroup(version: '1.1.110', items: [
      WhatsNewItem(
          area: 'Collection',
          title: 'Team Activity for the Head',
          detail: 'A fifth tab for the Head of Collection: a calendar of what '
              'every collector has uploaded, for the whole team or one person.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'My Head',
          detail: 'Settings → My Head: choose who receives your Done '
              'Engagement notices. It follows you to another phone.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'Engagement History filters',
          detail: 'Today by default, with a From–To date range and a status '
              'filter that names every status, Advance Payment included.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'Actual Collection is the team\'s figure',
          detail: 'Posted by the office on the web, with the team target. '
              'Deposits are your activity only and count toward neither.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'Record Deposit is bank, amount and check number',
          detail: 'No account or invoices to pick. It is saved as your activity.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'Apply advance with a P.O. number',
          detail: 'The P.O. rides along when the advance creates the invoice.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'Amounts format as you type',
          detail: 'Thousands separators appear while typing; two decimals are '
              'padded when you leave the field.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'Upload outbox shows why',
          detail: 'A rejected upload now shows the server\'s reason under the '
              'attempt count.'),
      WhatsNewItem(
          area: 'Collection',
          title: 'Settings: default area, storage, about',
          detail: 'Open the bucket on your territory, see what is on the '
              'phone, and read this list.'),
    ]),
  ];

  /// The group for [version], else the newest.
  static WhatsNewGroup? forVersion(String version) {
    if (groups.isEmpty) return null;
    final v = version.trim();
    for (final g in groups) {
      if (g.version == v) return g;
    }
    return groups.first;
  }
}
