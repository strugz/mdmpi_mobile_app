import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/pull_out_request_card.dart';

/// Pull-out / Return Pick-up request list.
///
/// UI-only: reads reactive state from PullOutController and renders a list with
/// loading and empty states. Business/data logic stays in the controller.
class PullOutReturnPickUpList extends StatelessWidget {
  const PullOutReturnPickUpList({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<PullOutController>();

    return Obx(() {
      final items = controller.filteredPullOuts;

      if (items.isNotEmpty) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: AbsorbPointer(
              absorbing: controller.isLoading.value,
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.loadPullOuts();
                },
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: BSizes.spaceBtwItems),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return PullOutRequestCard(item: item);
                  },
                ),
              ),
            ),
          ),
        );
      } else if (controller.isLoading.value && items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(BSizes.defaultSpace),
          child: BShimmerEffect(width: 350, height: 80),
        );
      } else {
        return Expanded(
          child: AbsorbPointer(
            absorbing: controller.isLoading.value,
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.loadPullOuts();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Text(
                          'No Data Found!',
                          style: TextStyle(color: dark ? BColors.white : BColors.dark),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }
    });
  }
}
