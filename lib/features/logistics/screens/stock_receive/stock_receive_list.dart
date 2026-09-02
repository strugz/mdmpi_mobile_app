import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_request_card.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/utils/role_resolver.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/stock_receive_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';

import '../../../../base/utils/constants/text_strings.dart';

// ============================================================================
// STATUS-DRIVEN ROLE SELECTION
// ============================================================================
// Stock Receive mirrors Pull Out minus the "For Pull Out" step: Release
// dispatches (New Request → In Transit) and Courier completes
// (In Transit → Taken Out).
//
// Status-Role Capability Matrix:
// ┌──────────────┬─────────┬─────────┬─────────┐
// │ Status       │ Request │ Release │ Courier │
// ├──────────────┼─────────┼─────────┼─────────┤
// │ New Request  │ View    │ ✅ Action│ View    │
// │ In Transit   │ View    │ View    │ ✅ Action│
// │ Taken Out    │ View    │ View    │ View    │
// │ Cancelled    │ View    │ View    │ View    │
// └──────────────┴─────────┴─────────┴─────────┘
// ============================================================================

/// Maps each status to the preferred role that has action capability.
const _statusToPreferredRole = {
  BTexts.statusNewRequest: BTexts.roleRelease, // Release: Set In Transit
  BTexts.statusInTransit: BTexts.roleCourier, // Courier: Mark Taken Out
  // Taken Out, Cancelled, Picked-up: All roles are view-only
};

/// List widget for displaying Stock Receive requests.
///
/// Displays filtered Stock Receive requests in a scrollable list with:
/// - Pull-to-refresh functionality
/// - Loading states
/// - Empty state messages
/// - Request cards with tap handling
/// - Role-based dialog display
class StockReceiveList extends StatelessWidget {
  const StockReceiveList({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<StockReceiveController>();
    final userController = Get.find<UserController>();

    return Obx(() {
      final items = controller.filteredStockReceives;

      if (items.isNotEmpty) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: AbsorbPointer(
              absorbing: controller.isLoading.value,
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.hardResetStockReceives();
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
                        controller.currentSelectedStockReceive.value = item;
                        _handleStockReceiveTap(
                            context, item, controller, userController);
                      },
                      onLongPress: () async {
                        if (item.requestStatus != 'Picked-up' &&
                            item.requestStatus.toLowerCase() != 'cancelled') {
                          controller.currentSelectedStockReceive.value = item;
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
                await controller.hardResetStockReceives();
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
                              'No Stock Receive requests found',
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

/// Handles tap on Stock Receive request based on user role.
/// Uses status-driven role selection so users with multiple roles
/// can perform ALL available actions at ANY status.
void _handleStockReceiveTap(
  BuildContext context,
  PullOutModel request,
  StockReceiveController controller,
  UserController userController,
) {
  final roles = RoleResolver.parseRoles(userController.user.value.role);

  // Resolve the best role for this status using RoleResolver
  final selectedRole = RoleResolver.resolveRoleForStatus(
    status: request.requestStatus,
    userRoles: roles,
    statusToPreferredRole: _statusToPreferredRole,
  );

  final config = StockReceiveModalConfig.resolve(
    request: request,
    role: selectedRole,
    controller: controller,
  );
  BFullScreenLoader.showStockReceiveDialog(context, request, config);
}

