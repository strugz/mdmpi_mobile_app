import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// One selectable area, or a heading above a run of them.
class _AreaRow {
  const _AreaRow.area(this.code, this.name) : heading = null;
  const _AreaRow.heading(this.heading)
      : code = '',
        name = '';

  /// Non-null on a heading, which is label only and never tappable.
  final String? heading;
  final String code;
  final String name;

  bool get isHeading => heading != null;
}

/// Pick which territory the list is narrowed to.
///
/// This was a pushed screen of large two-up cards. Six of them filled a phone
/// and still truncated "Medical Imaging", the fixed tile ratio overflowed by a
/// pixel at the default text size, and Luzon was a card you drilled into, so
/// NCR cost two taps while Visayas cost one.
///
/// It is a sheet of rows now, rising from the chip that opens it. Every area
/// is one tap, Luzon is a heading rather than a level, names are never cut,
/// and the counts line up on one right edge so they can be compared down the
/// column. An area with nothing in it is dimmed and inert: picking it could
/// only produce an empty list.
class AreaPickerSheet extends StatelessWidget {
  const AreaPickerSheet({
    super.key,
    required this.selected,
    required this.countFor,
  });

  /// The area code in force, or empty for all areas.
  final String selected;

  /// Accounts currently in the list for an area code; empty means all.
  final int Function(String code) countFor;

  /// Opens the sheet and resolves to the chosen area code, empty for all
  /// areas, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String selected,
    required int Function(String code) countFor,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BCollectionColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => AreaPickerSheet(selected: selected, countFor: countFor),
      );

  /// The order areas are read in: the Luzon regions together under their own
  /// heading, then everything else. Flat, so no area is deeper than another.
  static const _rows = [
    _AreaRow.heading('Luzon'),
    _AreaRow.area('NLN', 'North Luzon'),
    _AreaRow.area('CLN', 'Central Luzon'),
    _AreaRow.area('SLN', 'South Luzon'),
    _AreaRow.area('NCR', 'NCR'),
    _AreaRow.heading('Other areas'),
    _AreaRow.area('VIS', 'Visayas'),
    _AreaRow.area('MIN', 'Mindanao'),
    _AreaRow.area('RAD', 'Medical Imaging'),
    _AreaRow.area(BCollectionArea.others, 'Others'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                BSizes.defaultSpace, BSizes.md, BSizes.sm, BSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text('Filter by area',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.close_circle,
                      color: BCollectionColors.inkMuted),
                ),
              ],
            ),
          ),
          // Bounded so the sheet never grows past half the screen on a small
          // phone; it scrolls instead.
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                  BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.md),
              children: [
                _AreaTile(
                  name: 'All areas',
                  count: countFor(''),
                  selected: selected.isEmpty,
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final row in _rows)
                  if (row.isHeading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          BSizes.xs, BSizes.md, 0, BSizes.xs),
                      child: Text(
                        row.heading!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: BCollectionColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    _AreaTile(
                      name: row.name,
                      count: countFor(row.code),
                      selected: selected == row.code,
                      onTap: () => Navigator.pop(context, row.code),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One area. The count sits on the right edge so the column can be compared
/// down the list, and an empty area is dimmed and inert.
class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.name,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  static const Duration _stateDuration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = count == 0;

    return Semantics(
      button: !empty,
      selected: selected,
      label: '$name, $count account${count == 1 ? '' : 's'}',
      child: BPressableScale(
        onTap: empty ? null : onTap,
        enabled: !empty,
        pressedScale: 0.985,
        child: AnimatedContainer(
          duration: _stateDuration,
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: BSizes.xs),
          padding: const EdgeInsets.symmetric(
              horizontal: BSizes.md, vertical: BSizes.spaceBtwItemsLight),
          decoration: BoxDecoration(
            color: selected
                ? BCollectionColors.primarySoft
                : BCollectionColors.surfaceMuted,
            borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
            border: Border.all(
              color: selected ? BCollectionColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: empty
                        ? BCollectionColors.inkMuted
                        : BCollectionColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: BSizes.sm),
              Text(
                empty ? 'None' : '$count',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? BCollectionColors.primary
                      : BCollectionColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // A fixed slot, so the counts stay on one edge whether or not a
              // row carries the check.
              SizedBox(
                width: 26,
                child: AnimatedOpacity(
                  duration: _stateDuration,
                  opacity: selected ? 1 : 0,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Iconsax.tick_circle5,
                        size: 18, color: BCollectionColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
