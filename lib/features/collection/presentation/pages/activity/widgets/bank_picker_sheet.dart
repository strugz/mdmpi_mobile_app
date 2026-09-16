import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/models/bank_model.dart';

/// Pick a bank from the company list.
///
/// The bank was a free-text field, so the same bank reached the server as
/// "BPI", "bpi" and "Bank of the Philippine Islands" depending on who typed
/// it. Fifty-three banks is too many for chips and too many to scroll, so it
/// is a sheet that filters as you type, on code or on name — "bpi" and
/// "philippine" both find the same one.
class BankPickerSheet extends StatefulWidget {
  const BankPickerSheet({super.key, required this.banks, this.selected});

  final List<BankModel> banks;

  /// The bank name currently on the form, matched loosely so a value typed
  /// before this picker existed still shows as selected.
  final String? selected;

  /// Opens the sheet and resolves to the chosen bank, or null if dismissed.
  static Future<BankModel?> show(
    BuildContext context, {
    required List<BankModel> banks,
    String? selected,
  }) =>
      showModalBottomSheet<BankModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => BankPickerSheet(banks: banks, selected: selected),
      );

  @override
  State<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<BankPickerSheet> {
  late final TextEditingController _search;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BankModel> get _results =>
      widget.banks.where((b) => b.matches(_query)).toList();

  bool _isSelected(BankModel bank) {
    final current = widget.selected?.trim().toLowerCase();
    if (current == null || current.isEmpty) return false;
    return bank.name.toLowerCase() == current ||
        bank.code.toLowerCase() == current;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;

    return Padding(
      // The sheet's own keyboard and navigation-bar clearance.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.md,
                  BSizes.defaultSpace, BSizes.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Select bank',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle,
                        color: BColors.darkGrey),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: TextField(
                controller: _search,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Bank name or code',
                  prefixIcon: Icon(Iconsax.search_normal),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: BSizes.sm),
            Expanded(
              child: results.isEmpty
                  ? _empty(theme)
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                          bottom: BSizes.defaultSpace +
                              MediaQuery.paddingOf(context).bottom),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final bank = results[index];
                        final selected = _isSelected(bank);
                        return ListTile(
                          dense: true,
                          title: Text(bank.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                          // The code is how collectors refer to banks out
                          // loud, so it stays visible rather than being only
                          // something you can search by.
                          leading: SizedBox(
                            width: 56,
                            child: Text(
                              bank.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: selected
                                    ? BColors.primary
                                    : BColors.darkGrey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          trailing: selected
                              ? const Icon(Iconsax.tick_circle5,
                                  color: BColors.primary, size: 20)
                              : null,
                          onTap: () => Navigator.pop(context, bank),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Text(
            widget.banks.isEmpty
                // The list is cached on the device, so this only happens
                // before the first successful download.
                ? 'The bank list has not downloaded yet. Type the bank name instead.'
                : 'No bank matches "$_query"',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
          ),
        ),
      );
}
