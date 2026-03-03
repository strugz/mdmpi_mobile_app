import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';

import '../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/collection_bucket_button.dart';
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
              child: Column(
                children: const [
                  CollectionSummaryCard(
                    title: 'Pending Collections',
                    value: '12',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  SizedBox(height: BSizes.spaceBtwItems),
                  CollectionSummaryCard(
                    title: 'Completed',
                    value: '128',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(height: BSizes.spaceBtwItems),
                  CollectionSummaryCard(
                    title: 'Overdue',
                    value: '3',
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: BSizes.spaceBtwSections),

            // Collection bucket button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: CollectionBucketButton(
                itemCount: 5,
                onTap: () {
                  // TODO: Navigate to collection bucket screen
                },
              ),
            ),

            const SizedBox(height: BSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }
}
