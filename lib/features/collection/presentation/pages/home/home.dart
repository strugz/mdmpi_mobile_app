import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';

class CollectionHomeScreen extends StatelessWidget {
  const CollectionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
        children: [
          BPrimaryHeaderContainer(
            child: Column(
              children: [
                const BHomeAppBar(),
                const SizedBox(height: BSizes.spaceBtwSections),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: BSectionHeading(
              title: BTexts.collectionHomeTitle1,
              showActionButton: false,
            ),
          ),
          const SizedBox(height: BSizes.spaceBtwItemsLight),

          // Summary cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  CollectionSummaryCard(
                    title: 'Pending Collections',
                    value: '12',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  SizedBox(width: BSizes.spaceBtwItems),
                  CollectionSummaryCard(
                    title: 'Completed',
                    value: '128',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: BSizes.spaceBtwItems),
                  CollectionSummaryCard(
                    title: 'Overdue',
                    value: '3',
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: BSizes.spaceBtwSections),

          // Actions row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionButton(
                  icon: Icons.add_box,
                  label: 'New Collection',
                  onTap: () {},
                ),
                ActionButton(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () {},
                ),
                ActionButton(
                  icon: Icons.filter_list,
                  label: 'Filters',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: BSizes.spaceBtwSections),

          // Recent items
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: BSectionHeading(
              title: 'Recent Collections',
              showActionButton: true,
            ),
          ),

          const SizedBox(height: BSizes.spaceBtwItemsLight),

          // Placeholder list - replace with Obx + controller-driven list when available
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Column(
              children: List.generate(3, (index) {
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(Icons.folder, color: Colors.blue),
                      ),
                      title: Text('Collection #${index + 1}'),
                      subtitle: Text('Customer • Address details'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const SizedBox(height: BSizes.spaceBtwItemsLight),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: BSizes.spaceBtwSections),
        ],
      )),
    );
  }
}
