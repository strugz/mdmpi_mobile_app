import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// Horizontal scrollable filter chips for the Activity screen.
///
/// Allows filtering activities by status (All, Pending, Completed, Overdue).
class ActivityFilterChips extends StatefulWidget {
  const ActivityFilterChips({super.key, this.onFilterChanged});

  /// Called when the user selects a different filter.
  final ValueChanged<String>? onFilterChanged;

  @override
  State<ActivityFilterChips> createState() => _ActivityFilterChipsState();
}

class _ActivityFilterChipsState extends State<ActivityFilterChips> {
  int _selectedIndex = 0;

  static const _filters = ['All', 'Pending', 'Completed', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: BSizes.sm),
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return ChoiceChip(
            label: Text(_filters[index]),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedIndex = index);
              widget.onFilterChanged?.call(_filters[index]);
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


