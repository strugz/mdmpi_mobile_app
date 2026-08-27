import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/common/utils/role_resolver.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_request_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/implementations/pick_up_role_handler.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

// ============================================================================
// STATUS-DRIVEN ROLE SELECTION
// ============================================================================
// For Pick Up module, only Release has actions. This map defines which role
// should be preferred based on the request status.
//
// Status-Role Capability Matrix:
// ┌─────────────────────────┬─────────┬─────────┬─────────┐
// │ Status                  │ Request │ Release │ Courier │
// ├─────────────────────────┼─────────┼─────────┼─────────┤
// │ New Request             │ View    │ ✅ Action│ View    │
// │ Getting Supplies Ready  │ View    │ ✅ Action│ View    │
// │ Item Packed             │ View    │ ✅ Action│ View    │
// │ Received                │ View    │ View    │ View    │
// │ Cancelled               │ View    │ View    │ View    │
// └─────────────────────────┴─────────┴─────────┴─────────┘
// ============================================================================

/// Maps each status to the preferred role that has action capability.
/// Returns null if no role has actions for that status (all view-only).
const _statusToPreferredRole = {
  BTexts.statusNewRequest: BTexts.roleRelease, // Release: → Getting Supplies Ready
  BTexts.statusGettingSuppliesReady: BTexts.roleRelease, // Release: → Item Packed
  BTexts.statusItemPacked: BTexts.roleRelease, // Release: → Received
  // Received, Cancelled: All roles are view-only (no preferred role)
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
/// Uses status-driven role selection to ensure users with multiple roles
/// can perform ALL available actions at ANY status.
void _handlePickUpTap(
  BuildContext context,
  PickUpModel request,
  PickUpController controller,
  UserController userController,
) {
  final roles = RoleResolver.parseRoles(userController.user.value.role);
  final userInitial = userController.user.value.initial;

  // Handle cancelled/received status with default handler
  if (request.status.toLowerCase() == 'cancelled' ||
      request.status == 'Received') {
    PickUpDefaultHandler().handleAction(
        context, request, controller, userController, userInitial);
    return;
  }

  // Resolve the best role for this status using RoleResolver
  final selectedRole = RoleResolver.resolveRoleForStatus(
    status: request.status,
    userRoles: roles,
    statusToPreferredRole: _statusToPreferredRole,
  );

  final handlers = <String, PickUpActionHandler>{
    BTexts.roleRequest: PickUpRequestRoleHandler(),
    BTexts.roleRelease: PickUpReleaseRoleHandler(),
    BTexts.roleCourier: PickUpCourierRoleHandler(),
    BTexts.roleViewer: PickUpViewerRoleHandler(),
  };

  // Invoke the resolved role handler
  if (handlers.containsKey(selectedRole)) {
    handlers[selectedRole]!.handleAction(
        context, request, controller, userController, userInitial);
  } else {
    // Fallback to default handler if role not found
    PickUpDefaultHandler().handleAction(
        context, request, controller, userController, userInitial);
  }
}

