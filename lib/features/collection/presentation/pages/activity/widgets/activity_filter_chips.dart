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
  });

  /// Called when the user selects a different filter.
  final ValueChanged<String>? onFilterChanged;

  /// Optional list of filters to display.
  final List<String>? filters;

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
    return SizedBox(
      height: 48,
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
            selectedColor: BColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? BColors.white : BColors.darkerGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
            ),
            side: BorderSide(
              color: isSelected ? BColors.primary : BColors.grey,
            ),
          );
        },
      ),
    );
  }
}
