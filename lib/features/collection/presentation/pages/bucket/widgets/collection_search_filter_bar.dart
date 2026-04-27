import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

class CollectionSearchFilterBar extends StatelessWidget {
  const CollectionSearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilter,
    this.searchHint = 'Search...',
    this.initialValue = '',
  });

  final Function(String) onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilter;
  final String searchHint;
  final String initialValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.defaultSpace,
        vertical: BSizes.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: initialValue,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Iconsax.search_normal),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: BSizes.sm),
          
          // Filter Button
          Container(
            decoration: BoxDecoration(
              color: hasActiveFilter ? BColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
              border: Border.all(color: hasActiveFilter ? BColors.primary : BColors.grey),
            ),
            child: IconButton(
              onPressed: onFilterTap,
              icon: Icon(
                Iconsax.filter_edit,
                color: hasActiveFilter ? BColors.primary : BColors.darkerGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
