import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/pull_out_request_card.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/implementations/pull_out_role_handler.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';

import '../../../../base/utils/constants/text_string.dart';

/// Role priority map: Lower number = Higher priority (more capabilities)
const _rolePriority = {
  BTexts.roleRelease: 1, // Most powerful - can handle most statuses
  BTexts.roleCourier: 2, // Handles dispatch/drop-off
  BTexts.roleRequest: 3, // Can only advance "New Request"
  BTexts.roleViewer: 4, // View-only access
};

/// Selects the appropriate role based on status and available roles.
/// Prioritizes roles by status context, then by priority map.
String? _selectActiveRole(List<String> roles, String status) {
  // Picked-up/Cancelled: handled with default handler (no role selection needed)
  if (status.toLowerCase() == 'picked-up' ||
      status.toLowerCase() == 'cancelled') {
    return null;
  }

  // Default: find highest-priority role
  String? highestRole;
  int highestPriority = 999;

  for (final role in roles) {
    final priority = _rolePriority[role] ?? 999;
    if (priority < highestPriority) {
      highestPriority = priority;
      highestRole = role;
    }
  }

  return highestRole;
}

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
                  await controller.loadStockReceives();
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
                await controller.loadStockReceives();
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
/// Selects the highest-priority role handler to avoid multiple dialogs.
void _handleStockReceiveTap(
  BuildContext context,
  PullOutModel request,
  StockReceiveController controller,
  UserController userController,
) {
  final roles = userController.user.value.role
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  final userInitial = userController.user.value.initial;

  // Normalize status comparison for consistency
  final statusLower = request.requestStatus.toLowerCase();

  // Handle cancelled/picked-up status with default handler
  if (statusLower == 'cancelled' || statusLower == 'picked-up') {
    PullOutDefaultHandler().handleAction(
        context, request, controller as dynamic, userController, userInitial);
    return;
  }

  final activeRole = _selectActiveRole(roles, request.requestStatus);

  if (activeRole == null) {
    // No valid role - show default handler
    PullOutDefaultHandler().handleAction(
        context, request, controller as dynamic, userController, userInitial);
    return;
  }

  final handlers = <String, PullOutActionHandler>{
    BTexts.roleRequest: PullOutRequestRoleHandler(),
    BTexts.roleRelease: PullOutReleaseRoleHandler(),
    BTexts.roleCourier: PullOutCourierRoleHandler(),
    BTexts.roleViewer: PullOutViewerRoleHandler(),
  };

  // Invoke only the selected handler
  if (handlers.containsKey(activeRole)) {
    handlers[activeRole]!.handleAction(
        context, request, controller as dynamic, userController, userInitial);
  } else {
    // Fallback if no handler is registered for the selected role
    PullOutDefaultHandler().handleAction(
        context, request, controller as dynamic, userController, userInitial);
  }
}

