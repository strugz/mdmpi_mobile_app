import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/pressable/b_pressable.dart';

/// Human label for the dashboard's active date scope.
String dateScopeLabel(int? year, int? month) {
  if (year == null) return BTexts.dashboardAllTime;
  if (month == null) return '$year';
  return DateFormat('MMM yyyy').format(DateTime(year, month));
}

/// Opens the year/month scope picker as a bottom sheet.
Future<void> showDateScopeSheet(
  BuildContext context, {
  required int? year,
  required int? month,
  required List<int> yearOptions,
  required ValueChanged<int?> onYearChanged,
  required ValueChanged<int?> onMonthChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor:
        BHelperFunctions.isDarkMode(context) ? BColors.dark : BColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DateScopeSheet(
      initialYear: year,
      initialMonth: month,
      yearOptions: yearOptions,
      onYearChanged: onYearChanged,
      onMonthChanged: onMonthChanged,
    ),
  );
}

/// Bottom sheet for the year and month scope. Changes apply immediately so the
/// numbers behind the sheet update while it is open; "Done" just closes it.
class DateScopeSheet extends StatefulWidget {
  const DateScopeSheet({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    required this.yearOptions,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  final int? initialYear;
  final int? initialMonth;
  final List<int> yearOptions;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onMonthChanged;

  @override
  State<DateScopeSheet> createState() => _DateScopeSheetState();
}

class _DateScopeSheetState extends State<DateScopeSheet> {
  late int? _year = widget.initialYear;
  late int? _month = widget.initialMonth;

  void _pickYear(int? year) {
    setState(() {
      _year = year;
      _month = null;
    });
    widget.onYearChanged(year);
  }

  void _pickMonth(int? month) {
    setState(() => _month = month);
    widget.onMonthChanged(month);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottom = BDevicesUtils.systemBottomInset(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.sm,
        BSizes.defaultSpace,
        BSizes.defaultSpace + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Show requests from',
              style: textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: BSizes.md),
          Text('Year', style: textTheme.labelMedium),
          const SizedBox(height: BSizes.sm),
          Wrap(
            spacing: BSizes.sm,
            runSpacing: BSizes.sm,
            children: [
              _OptionChip(
                label: BTexts.dashboardAllTime,
                selected: _year == null,
                onTap: () => _pickYear(null),
              ),
              for (final y in widget.yearOptions)
                _OptionChip(
                  label: '$y',
                  selected: _year == y,
                  onTap: () => _pickYear(y),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _year == null
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: BSizes.md),
                      Text('Month', style: textTheme.labelMedium),
                      const SizedBox(height: BSizes.sm),
                      Wrap(
                        spacing: BSizes.sm,
                        runSpacing: BSizes.sm,
                        children: [
                          _OptionChip(
                            label: BTexts.dashboardWholeYear,
                            selected: _month == null,
                            onTap: () => _pickMonth(null),
                          ),
                          for (var m = 1; m <= 12; m++)
                            _OptionChip(
                              label: DateFormat('MMM')
                                  .format(DateTime(2000, m)),
                              selected: _month == m,
                              onTap: () => _pickMonth(m),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: BSizes.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return BPressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: BSizes.md,
          vertical: BSizes.sm + BSizes.xxs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? BColors.primary
              : (dark
                  ? BColors.white.withValues(alpha: 0.06)
                  : BColors.softGrey),
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: selected
                    ? BColors.white
                    : (dark ? BColors.white : BColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
