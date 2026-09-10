import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// One labelled fact for [BFactGrid].
class BFact {
  const BFact(
    this.label,
    this.value, {
    this.copyable = false,
    this.onTap,
    this.trailingIcon,
    this.emphasize = false,
  });

  final String label;
  final String value;

  /// Tap copies [value] and toasts. Ignored when [onTap] is set.
  final bool copyable;

  /// Custom tap handler (e.g. open the address in maps).
  final VoidCallback? onTap;

  /// Small icon after the value (a chevron for tappable facts, copy icon…).
  final IconData? trailingIcon;

  /// Render the value in a heavier weight (the one or two facts that matter
  /// most on the screen).
  final bool emphasize;

  bool get isEmpty => value.trim().isEmpty;
}

/// A compact two-column grid of `label / value` facts.
///
/// Replaces rows of icon-only values: a muted small label above a normal
/// value, so the reader scans one column of labels instead of decoding icons.
/// Empty facts are skipped; an odd trailing fact spans its row alone.
class BFactGrid extends StatelessWidget {
  const BFactGrid({
    super.key,
    required this.facts,
    this.columns = 2,
    this.textColor,
    this.rowSpacing = BSizes.sm,
    this.columnSpacing = BSizes.md,
  });

  final List<BFact> facts;
  final int columns;
  final Color? textColor;
  final double rowSpacing;
  final double columnSpacing;

  @override
  Widget build(BuildContext context) {
    final visible = facts.where((f) => !f.isEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final rows = <List<BFact>>[];
    for (var i = 0; i < visible.length; i += columns) {
      rows.add(visible.sublist(
          i, i + columns > visible.length ? visible.length : i + columns));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: rowSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < rows[r].length; c++) ...[
                if (c > 0) SizedBox(width: columnSpacing),
                Expanded(
                  child: _FactCell(fact: rows[r][c], textColor: textColor),
                ),
              ],
              // Keep a lone trailing fact in its column, not stretched.
              if (rows[r].length < columns && columns > 1)
                for (var pad = rows[r].length; pad < columns; pad++) ...[
                  SizedBox(width: columnSpacing),
                  const Expanded(child: SizedBox.shrink()),
                ],
            ],
          ),
        ],
      ],
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({required this.fact, this.textColor});

  final BFact fact;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final color = textColor ?? (dark ? BColors.light : BColors.black);
    final theme = Theme.of(context).textTheme;

    final labelStyle = theme.labelSmall?.copyWith(
      color: color.withValues(alpha: 0.6),
      letterSpacing: 0.3,
    );
    final valueStyle = theme.bodyMedium?.copyWith(
      color: color,
      height: 1.2,
      fontWeight: fact.emphasize ? FontWeight.w600 : FontWeight.w400,
    );

    final trailing = fact.trailingIcon ??
        (fact.copyable && fact.onTap == null ? Iconsax.copy : null);

    final cell = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(fact.label, style: labelStyle, maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(fact.value, style: valueStyle, maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
            if (trailing != null) ...[
              const SizedBox(width: BSizes.xs),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(trailing,
                    size: 14, color: color.withValues(alpha: 0.6)),
              ),
            ],
          ],
        ),
      ],
    );

    final onTap = fact.onTap ??
        (fact.copyable
            ? () async {
                await Clipboard.setData(ClipboardData(text: fact.value));
                BHelperFunctions.showSnackBar('Copied ${fact.value}');
              }
            : null);
    if (onTap == null) return cell;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: cell,
      ),
    );
  }
}
