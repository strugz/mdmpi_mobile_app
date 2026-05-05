import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

/// Horizontal scrollable filter chips for the Activity screen.
class ActivityFilterChips extends StatefulWidget {
  const ActivityFilterChips({
    super.key,
    this.onFilterChanged,
    this.filters,
    this.activeColor,
  });

  /// Called when the user selects a different filter.
  final ValueChanged<String>? onFilterChanged;

  /// Optional list of filters to display.
  final List<String>? filters;

  /// The color to use when a chip is selected.
  final Color? activeColor;

  @override
  State<ActivityFilterChips> createState() => _ActivityFilterChipsState();
}

class _ActivityFilterChipsState extends State<ActivityFilterChips> {
  int _selectedIndex = 0;

  List<String> get _currentFilters => widget.filters ?? [
    'All',
    ...CollectionStatusColors.allStatuses,
  ];

  @override
  Widget build(BuildContext context) {
    final filters = _currentFilters;
    final selectedColor = widget.activeColor ?? BColors.primary;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: BSizes.sm),
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return ChoiceChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedIndex = index);
              widget.onFilterChanged?.call(filters[index]);
            },
            selectedColor: selectedColor,
            labelStyle: TextStyle(
              color: isSelected ? BColors.white : BColors.darkerGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
            ),
            side: BorderSide(
              color: isSelected ? selectedColor : BColors.grey,
            ),
            padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
            pressElevation: 0,
          );
        },
      ),
    );
  }
}
