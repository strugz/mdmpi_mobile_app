import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Settings → Default area (Collection TODO item 15): "All areas" then every
/// territory, in the same order as Filter by Area. Unlike that picker, no
/// row is dimmed: a default is chosen before the bucket is downloaded, so
/// there is no count to dim by. Pops the code ('' for all), null if dismissed.
class DefaultAreaSheet extends StatelessWidget {
  const DefaultAreaSheet({super.key, required this.selected});

  final String selected;

  static Future<String?> show(BuildContext context,
          {required String selected}) =>
      showModalBottomSheet<String>(
        context: context,
        backgroundColor: BCollectionColors.surface,
        builder: (_) => DefaultAreaSheet(selected: selected),
      );

  /// Filter by Area's reading order: Luzon together, then the rest.
  static const List<String> order = [
    'NLN',
    'CLN',
    'SLN',
    'NCR',
    'VIS',
    'MIN',
    'RAD',
    BCollectionArea.others,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = selected.trim().toUpperCase();
    Widget row(String code, String label, IconData icon) {
      final isCurrent = current == code;
      return ListTile(
        key: ValueKey('default-area-${code.isEmpty ? 'all' : code}'),
        leading: Icon(icon,
            color: isCurrent
                ? BCollectionColors.primary
                : BCollectionColors.inkSecondary),
        title: Text(label),
        selected: isCurrent,
        trailing: isCurrent
            ? const Icon(Iconsax.tick_circle, color: BCollectionColors.primary)
            : null,
        onTap: () => Navigator.of(context).pop(code),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BSizes.defaultSpace, BSizes.md, BSizes.defaultSpace, BSizes.xs),
              child: Text('Open the bucket on', style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.sm),
              child: Text(
                'Filter by Area can still change it for the day.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: BCollectionColors.inkMuted),
              ),
            ),
            row('', 'All areas', Iconsax.global),
            const Divider(height: 1),
            for (final code in order)
              row(code, BCollectionArea.names[code] ?? code, Iconsax.location),
            const SizedBox(height: BSizes.sm),
          ],
        ),
      ),
    );
  }
}
