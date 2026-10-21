/// What's new, shown on Settings → About (Collection TODO item 15).
///
/// Kept in code, not in a file the phone would have to download: the About
/// screen must work offline. Newest first. When bumping the version, add a
/// group for it at the top (see `.claude/commands/bump-version.md`); the
/// screen shows the group for the running version, or the newest one when
/// the running version has no group yet.
library;

import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

class WhatsNewGroup {
  const WhatsNewGroup({required this.version, required this.items});

  /// `major.minor.patch`, as in pubspec.
  final String version;
  final List<WhatsNewItem> items;
}

class WhatsNewItem {
  const WhatsNewItem({
    required this.title,
    required this.detail,
    this.area,
    this.icon = Iconsax.tick_circle,
  });

  /// A few words; the screen shows it bold.
  final String title;

  /// One or two short sentences.
  final String detail;

  /// "Collection", "Logistics", or null when it is for everyone. The screen
  /// groups by it, so it is said once per group, not on every line.
  final String? area;

  /// What the change is about, so the list can be scanned by eye.
  final IconData icon;
}

class BWhatsNew {
  BWhatsNew._();

  static const List<WhatsNewGroup> groups = [
    WhatsNewGroup(version: '1.1.116', items: [
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.brush_2,
          title: 'Pick your theme',
          detail: 'Settings → Theme: Ocean, Teal, Rose, Cocoa or Graphite, and '
              'Phone, Light or Dark. The whole app follows.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.message_text,
          title: 'A remark for each invoice',
          detail: 'Logging a step on two or more invoices? Give each its own '
              'remark, plus one for all.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.timer_1,
          title: 'Opening a case shows its progress',
          detail: 'The form says what it is saving while the case opens, and '
              'cannot be tapped twice.'),
      WhatsNewItem(
          area: 'Logistics',
          icon: Iconsax.bus,
          title: 'Commute ID for commuting drivers',
          detail: 'No trip ticket? Turn on Commuting and the app fills in a '
              'Commute ID. No vehicle needed.'),
      WhatsNewItem(
          area: 'Logistics',
          icon: Iconsax.truck_fast,
          title: 'Stock Receive with its driver',
          detail: 'Enter the trip ticket, driver, helper and vehicle when you '
              'create the request; the driver sees it right away.'),
      WhatsNewItem(
          icon: Iconsax.info_circle,
          title: 'A clearer What\'s new',
          detail: 'This page: each change on its own card, grouped by area.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.chart_2,
          title: 'Actual Collection for your area',
          detail: 'With a default area set, Home shows your area\'s figure '
              'against its target. Switch to All areas for the team.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.receipt_2,
          title: 'Reconciliation invoices stay in the bucket',
          detail: 'Pick the exact invoices to claim. One collected in full is '
              'settled, and the case completes once all of them are.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.task_square,
          title: 'Easier invoice picking',
          detail: 'Select all on a reconciliation step, with the SI and P.O. '
              'number on every invoice.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.card,
          title: 'Pre-Collection card',
          detail: 'A new card on Home. Acquire an account from its page; '
              'Pre-Collection no longer settles the invoice.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.routing_2,
          title: 'Routing of Documents',
          detail: 'A new activity: pick the accounts, add your remarks.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.bank,
          title: 'Record Deposit',
          detail: 'Search for accounts. Remarks list one per line as '
              'Account - Amount; the check number is optional.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.user_add,
          title: 'Temporary accounts for advances',
          detail: 'Account not in the list? Record the advance under its name, '
              'then link it to the real account before applying.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.sms,
          title: 'SMS Outbox',
          detail: 'Texts send in the background and retry on their own. See '
              'the day\'s messages in Settings → SMS Outbox.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.printer,
          title: 'Calendar printout',
          detail: 'Print the month\'s calendar as a PDF for reimbursement.'),
      WhatsNewItem(
          area: 'Collection',
          icon: Iconsax.moon,
          title: 'Dark mode',
          detail: 'Tap the moon on Home to switch between light and dark.'),
    ]),
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
