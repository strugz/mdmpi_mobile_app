import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_request_card_horizontal.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';
import '../../../../base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

import '../../services/implementations/hotline_direct_role_handler.dart';

/// Role priority map: Lower number = Higher priority (more capabilities)
const _rolePriority = {
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

/// List widget for displaying Hotline Direct requests.
///
/// Displays filtered Hotline Direct requests in a scrollable list with:
/// - Pull-to-refresh functionality
/// - Loading states
/// - Empty state messages
/// - Request cards with tap handling
/// - Role-based dialog display
class HotlineDirectList extends StatelessWidget {
  const HotlineDirectList({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final requestController = Get.find<HotlineDirectController>();
    final userController = Get.find<UserController>();

    return Obx(() {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: RefreshIndicator(
            onRefresh: () async {
              await requestController.loadRequests();
            },
            child: requestController.filterManager.filteredRequests.isNotEmpty
                ? ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    physics: const AlwaysScrollableScrollPhysics(),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: BSizes.spaceBtwItems),
                    itemCount: requestController
                        .filterManager.filteredRequests.length,
                    itemBuilder: (_, index) {
                      final request = requestController
                          .filterManager.filteredRequests[index];
                      return InkWell(
                        borderRadius:
                            BorderRadius.circular(BSizes.cardRadiusMd),
                        onTap: requestController.isLoading.value
                            ? null
                            : () => {
                                  requestController
                                      .currentSelectedRequest.value = request,
                                  _showAppropriateDialog(
                                      context,
                                      request,
                                      userController,
                                      requestController)
                                },
                        onLongPress: requestController.isLoading.value
                            ? null
                            : () => {
                                  if (request.status !=
                                          BTexts.statusDoneDelivery &&
                                      request.status !=
                                          BTexts.statusCancelled)
                                    {
                                      requestController
                                          .currentSelectedRequest.value =
                                          request,
                                      BDialog.showRemarksDialog(
                                          context, request),
                                    },
                                },
                        child: BRequestCardHorizontal(
                          requestModel: request,
                        ),
                      );
                    },
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: requestController.isLoading.value
                        ? const SizedBox(
                            height: 300,
                            child: BShimmerEffect(
                                width: double.infinity,
                                height: 300,
                                radius: 15),
                          )
                        : SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 80,
                                    color: dark
                                        ? BColors.light
                                        : BColors.darkGrey,
                                  ),
                                  const SizedBox(
                                      height: BSizes.spaceBtwItems),
                                  Text(
                                    'No Hotline Direct requests found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: dark
                                              ? BColors.light
                                              : BColors.darkGrey,
                                        ),
                                  ),
                                  const SizedBox(height: BSizes.sm),
                                  Text(
                                    'Try adjusting your filters',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: dark
                                              ? BColors.light
                                              : BColors.darkGrey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
          ),
        ),
      );
    });
  }

  /// Shows the appropriate dialog based on user role and request status.
  void _showAppropriateDialog(
    BuildContext context,
    StandardDeliveryModel request,
    UserController userController,
    IDeliveryRequestController requestController,
  ) {
    // Ensure user and user properties are not null
    final user = userController.user.value;
    if (user.role.isEmpty || user.initial.isEmpty) {
      // Fallback to default handler if user data is incomplete
      HotlineDirectDefaultHandler().handleAction(
          context, request, requestController, userController, '');
      return;
    }

    final userRoles = user.role.split(',').map((r) => r.trim()).toList();
    final activeRole = _selectActiveRole(userRoles, request.status);
    final userInitial = user.initial;

    // Handle done/cancelled status with default handler
    if (request.status == BTexts.statusDoneDelivery ||
        request.status == BTexts.statusCancelled) {
      HotlineDirectDefaultHandler().handleAction(
          context, request, requestController, userController, userInitial);
      return;
    }

    if (activeRole == null) {
      // No valid role - show view-only dialog
      HotlineDirectDefaultHandler().handleAction(
          context, request, requestController, userController, userInitial);
      return;
    }

    // Use hotline direct role handlers
    final handlers = <String, HotlineDirectActionHandler>{
      BTexts.roleRequest: HotlineDirectRequestRoleHandler(),
      BTexts.roleRelease: HotlineDirectReleaseRoleHandler(),
      BTexts.roleCourier: HotlineDirectCourierRoleHandler(),
      BTexts.roleViewer: HotlineDirectViewerRoleHandler(),
    };

    // Invoke only the selected handler
    final handler = handlers[activeRole];
    if (handler != null) {
      handler.handleAction(context, request, requestController,
          userController, userInitial);
    } else {
      // Fallback to default handler if no specific handler is found
      HotlineDirectDefaultHandler().handleAction(
          context, request, requestController, userController, userInitial);
    }
  }
}
