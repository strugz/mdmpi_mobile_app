import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_request_card.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';

import '../../../../base/utils/constants/text_string.dart';

// ============================================================================
// STATUS-DRIVEN ROLE SELECTION
// ============================================================================
// For Pull Out module, only Courier has actions. This map defines which role
// should be preferred based on the request status.
//
// Status-Role Capability Matrix:
// ┌──────────────┬─────────┬─────────┬─────────┐
// │ Status       │ Request │ Release │ Courier │
// ├──────────────┼─────────┼─────────┼─────────┤
// │ New Request  │ View    │ View    │ ✅ Action│
// │ In Transit   │ View    │ View    │ ✅ Action│
// │ Taken Out    │ View    │ View    │ View    │
// │ Cancelled    │ View    │ View    │ View    │
// └──────────────┴─────────┴─────────┴─────────┘
// ============================================================================

/// Maps each status to the preferred role that has action capability.
/// Returns null if no role has actions for that status (all view-only).
const _statusToPreferredRole = {
  BTexts.statusNewRequest: BTexts.roleCourier, // Courier: Set In Transit
  BTexts.statusInTransit: BTexts.roleCourier, // Courier: Mark Taken Out
  // Taken Out, Cancelled, Picked-up: All roles are view-only (no preferred role)
};

/// Role priority for fallback when no preferred role exists for a status.
/// Lower number = Higher priority.
const _rolePriority = {
  BTexts.roleRelease: 1,
  BTexts.roleCourier: 2,
  BTexts.roleRequest: 3,
  BTexts.roleViewer: 4,
};

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
                      const SizedBox(height: BSizes.xxs),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
                      onTap: () {
                        controller.currentSelectedPullOut.value = item;
                        _handlePullOutTap(
                            context, item, controller, userController);
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
                              'No Pull out / Return requests found',
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

/// Handles tap on PullOut request based on user role.
/// Uses status-driven role selection to ensure users with multiple roles
/// can perform ALL available actions at ANY status.
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

  // Resolve the best role for this status
  final selectedRole = _resolveRoleForStatus(request.requestStatus, roles);

  final config = PullOutModalConfig.resolve(
    request: request,
    role: selectedRole,
    controller: controller,
  );
  BFullScreenLoader.showPullOutDialog(context, request, config);
}

/// Resolves the best role for a given status from the user's available roles.
///
/// Strategy:
/// 1. Check if there's a preferred role (with action capability) for this status
/// 2. If user has that role, use it
/// 3. Otherwise, fall back to highest-priority role for view-only access
String _resolveRoleForStatus(String status, List<String> userRoles) {
  if (userRoles.isEmpty) return BTexts.roleViewer;

  // 1. Check for status-specific preferred role
  final preferredRole = _statusToPreferredRole[status];
  if (preferredRole != null && userRoles.contains(preferredRole)) {
    return preferredRole;
  }

  // 2. Fallback to highest-priority role (for view-only statuses)
  String selectedRole = BTexts.roleViewer;
  int highestPriority = 999;

  for (final role in userRoles) {
    final priority = _rolePriority[role] ?? 999;
    if (priority < highestPriority) {
      highestPriority = priority;
      selectedRole = role;
    }
  }

  return selectedRole;
}
