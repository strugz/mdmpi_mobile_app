import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_list_tile.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: BSizes.spaceBtwItems),
          
          /// Filter chips
          ActivityFilterChips(
            onFilterChanged: (filter) {
              // Placeholder for filtering logic
            },
          ),

          const SizedBox(height: BSizes.spaceBtwSections),

          /// Placeholder Activity list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
              itemBuilder: (context, index) {
                return ActivityListTile(
                  title: 'Placeholder Client ${index + 1}',
                  subtitle: 'Bank Name • Doc #12345',
                  time: '2026-03-03 10:30',
                  status: title == 'Delays' ? 'Overdue' : 'Pending',
                  statusColor: color,
                  icon: title == 'Delays' ? Icons.warning_amber_rounded : Icons.receipt_long,
                  amount: '₱${(index + 1) * 1000}.00',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
