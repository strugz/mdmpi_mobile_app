import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_request_card_horizontal.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';
import '../../../../base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

import '../../services/implementations/request_role_handler.dart';

/// Role priority map: Lower number = Higher priority (more capabilities)
const _rolePriority = {
  BTexts.roleAdmin: 0, // Full access
  BTexts.roleRelease: 1, // Most powerful for initial stages
  BTexts.roleCourier: 2, // Most powerful for delivery stages
  BTexts.roleRequest: 3, // Limited to viewing
  BTexts.roleViewer: 4, // View-only access
};

/// Selects the appropriate role based on status and available roles.
/// Prioritizes Courier for delivery-stage statuses, Release for preparation statuses.
String? _selectActiveRole(List<String> roles, String status) {
  // Courier-priority statuses (delivery stage)
  if (status == BTexts.statusItemPrepared ||
      status == BTexts.statusForDelivery) {
    if (roles.contains(BTexts.roleCourier)) {
      return BTexts.roleCourier;
    }
    // Release can view/handle if no Courier
    if (roles.contains(BTexts.roleRelease)) {
      return BTexts.roleRelease;
    }
  }

  // Release-priority statuses (preparation stage)
  if (status == BTexts.statusNewRequest ||
      status == BTexts.statusGettingSuppliesReady) {
    if (roles.contains(BTexts.roleRelease)) {
      return BTexts.roleRelease;
    }
    if (roles.contains(BTexts.roleRequest)) {
      return BTexts.roleRequest;
    }
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

/// Pre-built handler map — avoids re-instantiation on every tap.
final _handlers = <String, RequestActionHandler>{
  BTexts.roleAdmin: ViewerRoleHandler(),
  BTexts.roleRequest: RequestRoleHandler(),
  BTexts.roleRelease: ReleaseRoleHandler(),
  BTexts.roleCourier: CourierRoleHandler(),
  BTexts.roleViewer: ViewerRoleHandler(),
};

class BList extends StatelessWidget {
  const BList({super.key});

  /// Builds the UI for displaying a list of requests.
  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final requestController = Get.find<StandardDeliveryController>();
    final userController = Get.find<UserController>();

    return Obx(() {
      if (requestController.filterManager.filteredRequests.isNotEmpty) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: AbsorbPointer(
              absorbing: requestController.isLoading.value,
              child: RefreshIndicator(
                onRefresh: () async {
                  await requestController.loadRequests();
                },
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: BSizes.spaceBtwItems),
                  itemCount:
                      requestController.filterManager.filteredRequests.length,
                  itemBuilder: (_, index) {
                    final request =
                        requestController.filterManager.filteredRequests[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
                      onTap: () => {
                        requestController.currentSelectedRequest.value =
                            request,
                        _handleRequestTap(
                            context, request, requestController, userController)
                      },
                      onLongPress: () => {
                        if (request.status != BTexts.statusDoneDelivery &&
                            request.status != BTexts.statusCancelled)
                          {
                            requestController.currentSelectedRequest.value =
                                request,
                            BDialog.showRemarksDialog(context, request),
                          },
                      },
                      child: BRequestCardHorizontal(requestModel: request),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      } else if (requestController.isLoading.value &&
          requestController.filterManager.filteredRequests.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(BSizes.defaultSpace),
          child: BShimmerEffect(width: 350, height: 80),
        );
      } else {
        return Expanded(
          child: AbsorbPointer(
            absorbing: requestController.isLoading.value,
            child: RefreshIndicator(
              onRefresh: () async {
                await requestController.loadRequests();
              },
              child: LayoutBuilder(builder: (context, constraints) {
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
                            'No Delivery requests found',
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
              }),
            ),
          ),
        );
      }
    });
  }

  /// Handles tap on Standard Delivery request based on user role.
  /// Selects the highest-priority role handler to avoid multiple dialogs.
  /// Uses status-aware role selection to prioritize Courier for delivery stages.
  void _handleRequestTap(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
  ) {
    final roles = userController.user.value.role
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final userInitial = userController.user.value.initial;

    // Handle done/cancelled status with default handler
    if (request.status == BTexts.statusDoneDelivery ||
        request.status == BTexts.statusCancelled) {
      DefaultRequestHandler().handleAction(
          context, request, requestController, userController, userInitial);
      return;
    }

    final handlers = _handlers;

    // Select the appropriate role for this status
    final selectedRole = _selectActiveRole(roles, request.status);

    // Invoke only the selected handler
    if (selectedRole != null && handlers.containsKey(selectedRole)) {
      handlers[selectedRole]!.handleAction(
          context, request, requestController, userController, userInitial);
    }
  }
}
