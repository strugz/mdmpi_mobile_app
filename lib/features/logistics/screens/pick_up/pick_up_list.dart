import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_request_card.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/implementations/pick_up_role_handler.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';

import '../../../../base/utils/constants/text_string.dart';

/// Role priority map: Lower number = Higher priority (more capabilities)
const _rolePriority = {
  BTexts.roleRelease: 1, // Most powerful - can handle most statuses
  BTexts.roleCourier: 2, // Handles dispatch/drop-off
  BTexts.roleRequest: 3, // Can only advance "New Request"
  BTexts.roleViewer: 4, // View-only access
};

class PickUpList extends StatelessWidget {
  const PickUpList({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<PickUpController>();
    final userController = Get.find<UserController>();

    return Obx(() {
      final items = controller.filteredPickUps;

      if (items.isNotEmpty) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: AbsorbPointer(
              absorbing: controller.isLoading.value,
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.loadPickUps();
                },
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: BSizes.xxs),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
                      onTap: () {
                        controller.currentSelectedPickUp.value = item;
                        _handlePickUpTap(
                            context, item, controller, userController);
                      },
                      onLongPress: () async {
                        if (item.status != 'Received' &&
                            item.status.toLowerCase() != 'cancelled') {
                          controller.currentSelectedPickUp.value = item;
                          await BDialog.showRemarksDialog(context, item);
                        }
                      },
                      child: PickUpRequestCard(item: item),
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
                await controller.loadPickUps();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: dark ? BColors.light : BColors.darkGrey,
                            ),
                            const SizedBox(height: BSizes.spaceBtwItems),
                            Text(
                              'No Pick Up requests found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: dark ? BColors.light : BColors.darkGrey,
                              ),
                            ),
                            const SizedBox(height: BSizes.sm),
                            Text(
                              'Try adjusting your filters',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: dark ? BColors.light : BColors.darkGrey,
                              ),
                            ),
                          ],
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

/// Handles tap on PickUp request based on user role.
/// Selects the highest-priority role handler to avoid multiple dialogs.
void _handlePickUpTap(
  BuildContext context,
  PickUpModel request,
  PickUpController controller,
  UserController userController,
) {
  final roles = userController.user.value.role
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  final userInitial = userController.user.value.initial;

  // Handle cancelled/received status with default handler
  if (request.status.toLowerCase() == 'cancelled' ||
      request.status == 'Received') {
    PickUpDefaultHandler().handleAction(
        context, request, controller, userController, userInitial);
    return;
  }

  final handlers = <String, PickUpActionHandler>{
    BTexts.roleRequest: PickUpRequestRoleHandler(),
    BTexts.roleRelease: PickUpReleaseRoleHandler(),
    BTexts.roleCourier: PickUpCourierRoleHandler(),
    BTexts.roleViewer: PickUpViewerRoleHandler(),
  };

  // Find the highest-priority role the user has
  String? selectedRole;
  int highestPriority = 999;

  for (final role in roles) {
    if (handlers.containsKey(role)) {
      final priority = _rolePriority[role] ?? 999;
      if (priority < highestPriority) {
        highestPriority = priority;
        selectedRole = role;
      }
    }
  }

  // Invoke only the highest-priority handler
  if (selectedRole != null && handlers.containsKey(selectedRole)) {
    handlers[selectedRole]!.handleAction(
        context, request, controller, userController, userInitial);
  }
}

