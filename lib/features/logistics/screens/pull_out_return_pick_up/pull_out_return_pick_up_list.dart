import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/pull_out_request_card.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/implementations/pull_out_role_handler.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_request_list_widgets/b_dialog.dart';

import '../../../../base/utils/constants/text_string.dart';

class PullOutReturnPickUpList extends StatelessWidget {
  const PullOutReturnPickUpList({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<PullOutController>();
    final userController = Get.find<UserController>();

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
                    return InkWell(
                      borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
                      onTap: () {
                        controller.currentSelectedPullOut.value = item;
                        _handlePullOutTap(context, item, controller, userController);
                      },
                      onLongPress: () async {
                        if (item.requestStatus != 'Picked-up' &&
                            item.requestStatus.toLowerCase() != 'cancelled') {
                          controller.currentSelectedPullOut.value = item;
                          await BDialog.showRemarksDialog(context, item);
                        }
                      },
                      child: PullOutRequestCard(item: item),
                    );
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

void _handlePullOutTap(
  BuildContext context,
  PullOutModel request,
  PullOutController controller,
  UserController userController,
) {
  final roles = userController.user.value.role
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  final userInitial = userController.user.value.initial;

  final handlers = <String, PullOutActionHandler>{
    BTexts.roleRequest: PullOutRequestRoleHandler(),
    BTexts.roleRelease: PullOutReleaseRoleHandler(),
    BTexts.roleCourier: PullOutCourierRoleHandler(),
    BTexts.roleViewer: PullOutViewerRoleHandler(),
  };

  for (final role in roles) {
    final handler = handlers[role];
    if (handler == null) continue;

    if (request.requestStatus.toLowerCase() == 'cancelled' ||
        request.requestStatus.toLowerCase() == 'picked-up') {
      PullOutDefaultHandler().handleAction(context, request, controller, userController, userInitial);
      break;
    }

    handler.handleAction(context, request, controller, userController, userInitial);
    break;
  }
}
