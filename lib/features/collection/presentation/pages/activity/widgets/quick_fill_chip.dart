import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// A one-tap value. Used wherever the collector would otherwise type something
/// the app already knows: the invoice balance, today's date, a bank they have
/// used before, the outcome implied by the amount.
///
/// Sized for a thumb (40pt tall) because these are the fastest path through
/// the form and should be the easiest thing on screen to hit.
class BQuickFillChip extends StatelessWidget {
  const BQuickFillChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.iconTurns = 0,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  /// Rotation applied to [icon], in turns. Half a turn mirrors a glyph, which
  /// is the only way to get an exact up/down pair: the icon set draws its own
  /// up and down arrows in different styles, so they do not read as one
  /// control changing direction.
  final double iconTurns;

  /// Accent for the selected state. Defaults to the app primary.
  final Color? color;

  static const Duration _stateDuration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? BCollectionColors.primary;

    return BPressableScale(
      onTap: onTap,
      pressedScale: 0.96,
      child: Semantics(
        button: true,
        selected: selected,
        child: AnimatedContainer(
          duration: _stateDuration,
          curve: Curves.easeOut,
          height: 40,
          padding:
              const EdgeInsets.symmetric(horizontal: BSizes.spaceBtwItemsLight),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.10)
                : BCollectionColors.surface,
            borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
            // Constant width so selecting never nudges neighbouring chips.
            border: Border.all(
              color: selected ? accent : BCollectionColors.outline,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                // Animated, so a chip that flips its arrow turns it over
                // rather than swapping one glyph for another.
                AnimatedRotation(
                  turns: iconTurns,
                  duration: _stateDuration,
                  curve: Curves.easeOut,
                  child: Icon(icon,
                      size: 16,
                      color:
                          selected ? accent : BCollectionColors.inkSecondary),
                ),
                const SizedBox(width: BSizes.xs),
              ],
              // Flexible, so a long label ellipsizes inside the chip rather
              // than overflowing the row it sits in. `maxLines` alone cannot
              // do that: the Text still asks for its full width.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? accent : BCollectionColors.inkSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
