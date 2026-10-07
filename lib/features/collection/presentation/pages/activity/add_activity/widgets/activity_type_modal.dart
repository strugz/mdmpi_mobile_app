import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Pick which kind of field engagement to record.
///
/// Rises from the Calendar's "Add field engagement" button and from the
/// header's plus. It is the first thing a collector sees on the way to a
/// form, so it is built like the module's other sheets (the defer reason
/// sheet, the bank picker): a bold title with a one-line explainer, a muted
/// close, and bordered rows that press down under the finger instead of
/// bare list tiles with a ripple. Each row wears the same icon and colour
/// the engagement will have on its card afterwards, so the choice reads the
/// same here as it will in the archive.
class ActivityTypeModal extends StatelessWidget {
  const ActivityTypeModal({super.key});

  /// Opens the sheet. The caller does not need to pad for the navigation
  /// bar: the sheet adds that inset once, at its own bottom.
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BCollectionColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => const ActivityTypeModal(),
      );

  static const String advancedPayment = 'Advanced Payment';

  static const List<EngagementType> types = [
    EngagementType(
      title: CollectionStatusColors.statusDeposit,
      subtitle: 'Bank deposit of collected payments',
      status: CollectionStatusColors.statusDeposit,
    ),
    EngagementType(
      title: CollectionStatusColors.statusCWTPickup,
      subtitle: 'Withholding tax certificate collected',
      status: CollectionStatusColors.statusCWTPickup,
    ),
    EngagementType(
      title: CollectionStatusColors.statusReconciliation,
      subtitle: 'Set invoices aside to reconcile',
      status: CollectionStatusColors.statusReconciliation,
    ),
    EngagementType(
      title: advancedPayment,
      subtitle: 'Payment received ahead of an invoice',
      // Not a status the archive knows, so it has no card colour to borrow.
      // The accent keeps the sheet at one hue per row without inventing one,
      // and stops it sharing amber with CWT as it did before.
      icon: Iconsax.card_send,
      color: BCollectionColors.primary,
    ),
  ];

  void _open(BuildContext context, EngagementType type) {
    Navigator.pop(context);
    Get.toNamed(routeFor(type.title));
  }

  /// The named route each engagement type opens. Public so the test can
  /// assert the mapping without pumping the whole route table.
  static String routeFor(String title) => switch (title) {
        CollectionStatusColors.statusDeposit => BRoutes.collectionDepositForm,
        CollectionStatusColors.statusCWTPickup =>
          BRoutes.collectionCwtPickupForm,
        CollectionStatusColors.statusReconciliation =>
          BRoutes.collectionReconciliationForm,
        _ => BRoutes.collectionAdvancedPaymentForm,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // The theme draws a drag handle above the sheet in its own 48pt zone,
      // so the title needs almost no padding of its own or it floats.
      padding: EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.xs,
        BSizes.defaultSpace,
        BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add field engagement',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Pick what you did in the field.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.inkMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.close_circle,
                    color: BCollectionColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: BSizes.md),
          for (var i = 0; i < types.length; i++) ...[
            _TypeRow(type: types[i], onTap: () => _open(context, types[i])),
            if (i < types.length - 1) const SizedBox(height: BSizes.sm),
          ],
        ],
      ),
    );
  }
}

/// One kind of engagement the sheet offers.
class EngagementType {
  const EngagementType({
    required this.title,
    required this.subtitle,
    this.status,
    IconData? icon,
    Color? color,
  })  : _icon = icon,
        _color = color;

  final String title;
  final String subtitle;

  /// The archive status this type becomes, when it has one. Its icon and
  /// colour come from [CollectionStatusColors] so they match the cards.
  final String? status;
  final IconData? _icon;
  final Color? _color;

  IconData get icon => _icon ?? CollectionStatusColors.iconFor(status!);
  Color get color => _color ?? CollectionStatusColors.colorFor(status!);
}

/// One engagement type. Built like the defer sheet's reason rows so the two
/// sheets feel like the same product: hairline border, a tinted icon well,
/// title over a muted one-liner, and a chevron that says "this goes
/// somewhere" (the rows push a form rather than select in place).
class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.onTap});

  final EngagementType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: type.title,
      child: BPressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(BSizes.spaceBtwItemsLight),
          decoration: BoxDecoration(
            color: BCollectionColors.surface,
            borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
            border: Border.all(color: BCollectionColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                ),
                alignment: Alignment.center,
                child: Icon(type.icon, size: 20, color: type.color),
              ),
              const SizedBox(width: BSizes.spaceBtwItemsLight),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.title,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    // One line each so the four rows are the same height
                    // and the eye can scan them as a set.
                    Text(
                      type.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BSizes.sm),
              const Icon(Iconsax.arrow_right_3,
                  size: 16, color: BCollectionColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
