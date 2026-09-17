import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

/// What the collector chose in [DeferReasonSheet].
class DeferReason {
  const DeferReason({required this.status, required this.remarks});

  /// The status written on the account: one of the outcome statuses.
  final String status;

  /// The remark stored with the release.
  final String remarks;
}

/// Pick the reason an account goes back to the bucket without a collection.
///
/// This used to be a centred dialog with radio tiles and a red Confirm. It
/// is a bottom sheet now: the Defer button lives in the bottom bar, so the
/// sheet rises from where the finger already is. Each reason is a row with
/// its status icon and colour, the same ones the invoice cards use, so the
/// choice reads the same here as it will on the card afterwards. Picking
/// Others unfolds a remark field; the confirm stays disabled until there is
/// text, instead of letting the tap through and scolding with a snackbar.
/// Releasing is not destructive (nothing is lost, the account is just
/// unassigned), so the confirm is the ordinary primary, not red.
class DeferReasonSheet extends StatefulWidget {
  const DeferReasonSheet({
    super.key,
    required this.accountName,
    this.initialReason = CollectionStatusColors.statusFollowUp,
  });

  final String accountName;
  final String initialReason;

  static const reasons = [
    CollectionStatusColors.statusFollowUp,
    CollectionStatusColors.statusUnavailable,
    CollectionStatusColors.statusRefused,
    CollectionStatusColors.statusOthers,
  ];

  /// Opens the sheet and resolves to the chosen reason, or null if dismissed.
  static Future<DeferReason?> show(
    BuildContext context, {
    required String accountName,
  }) =>
      showModalBottomSheet<DeferReason>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => DeferReasonSheet(accountName: accountName),
      );

  @override
  State<DeferReasonSheet> createState() => _DeferReasonSheetState();
}

class _DeferReasonSheetState extends State<DeferReasonSheet> {
  late String _selected = widget.initialReason;
  final _remark = TextEditingController();

  bool get _isOthers => _selected == CollectionStatusColors.statusOthers;

  bool get _canConfirm => !_isOthers || _remark.text.trim().isNotEmpty;

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_canConfirm) return;
    final remark = _remark.text.trim();
    Navigator.pop(
      context,
      DeferReason(
        status: _isOthers ? CollectionStatusColors.statusOthers : _selected,
        remarks: _isOthers ? remark : 'No collection done: $_selected',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Keyboard clearance once, here, so the field and the button both
      // rise above it. The navigation bar inset is added once at the bottom.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          BSizes.defaultSpace,
          BSizes.md,
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
                      Text('Defer engagement',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.accountName} goes back to the bucket '
                        'with the reason you pick.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: BColors.darkGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon:
                      const Icon(Iconsax.close_circle, color: BColors.darkGrey),
                ),
              ],
            ),
            const SizedBox(height: BSizes.md),
            for (final reason in DeferReasonSheet.reasons) ...[
              _ReasonRow(
                reason: reason,
                selected: reason == _selected,
                onTap: () => setState(() => _selected = reason),
              ),
              const SizedBox(height: BSizes.sm),
            ],
            // The field unfolds under Others rather than popping in, so the
            // sheet grows instead of jumping.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isOthers
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: BSizes.sm),
                      child: TextField(
                        controller: _remark,
                        autofocus: true,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _confirm(),
                        decoration: const InputDecoration(
                          hintText: 'What happened?',
                          isDense: true,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: BSizes.sm),
            ElevatedButton(
              onPressed: _canConfirm ? _confirm : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                elevation: 0,
                backgroundColor: BColors.primary,
                foregroundColor: BColors.white,
                disabledBackgroundColor:
                    BColors.primary.withValues(alpha: 0.35),
                disabledForegroundColor: BColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                ),
              ),
              child: const Text('Defer account'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One selectable reason. Selection is a tinted border and background in the
/// status colour plus a check, so the state is visible at a glance without a
/// radio control that reads as a form.
class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final String reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CollectionStatusColors.colorFor(reason);

    return Semantics(
      button: true,
      selected: selected,
      label: reason,
      child: BPressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : BColors.white,
            borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
            border: Border.all(
              color: selected ? color : BColors.grey,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
                ),
                child: Icon(CollectionStatusColors.iconFor(reason),
                    size: 18, color: color),
              ),
              const SizedBox(width: BSizes.sm),
              Expanded(
                child: Text(
                  reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: selected ? 1 : 0,
                child: Icon(Iconsax.tick_circle5, size: 20, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
