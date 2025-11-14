import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_request_list_widgets/b_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_request_list_widgets/b_request_card_horizontal.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';
import '../../../../base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

import '../../services/implementations/request_role_handler.dart';

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
                        _handleRequestLongPress(
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
                      child: Text(
                        'No Data Found!',
                        style: TextStyle(
                            color: dark ? BColors.white : BColors.dark),
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

  /// Handles the tap event on a request item.
  ///
  /// This method determines the appropriate action to take based on the
  /// It utilizes a [RequestActionHandler] to perform role-specific actions.
  void _handleRequestLongPress(
    BuildContext context,
    StandardDeliveryModel request,
      StandardDeliveryController requestController,
    UserController userController,
  ) {
    final userRolesString = userController.user.value.role;
    final List<String> userRoles =
        userRolesString.split(',').map((e) => e.trim()).toList();
    final userInitial = userController.user.value.initial;

    final Map<String, RequestActionHandler> roleHandlers = {
      'Request': RequestRoleHandler(),
      'Release': ReleaseRoleHandler(),
      'Courier': CourierRoleHandler(),
      'Viewer': ViewerRoleHandler(),
    };

    for (String role in userRoles) {
      if (!roleHandlers.containsKey(role)) {
        continue;
      }
      RequestActionHandler? currentRoleHandler = roleHandlers[role];

      if (currentRoleHandler == null) {
        continue;
      }

      if (request.status == BTexts.statusDoneDelivery) {
        DefaultRequestHandler().handleAction(
            context, request, requestController, userController, userInitial);
        break;
      }
      if (request.status == BTexts.statusCancelled) {
        DefaultRequestHandler().handleAction(
            context, request, requestController, userController, userInitial);
        break;
      }
      if (role == 'Release') {
        if (request.status == BTexts.statusNewRequest ||
            request.status == BTexts.statusGettingSuppliesReady) {
          currentRoleHandler.handleAction(
              context, request, requestController, userController, userInitial);
          break;
        } else if (request.status == BTexts.statusItemPrepared &&
            !userRoles.contains('Courier')) {
          currentRoleHandler.handleAction(
              context, request, requestController, userController, userInitial);
          break;
        } else if (request.status == BTexts.statusForDelivery &&
            !userRoles.contains('Courier')) {
          currentRoleHandler.handleAction(
              context, request, requestController, userController, userInitial);
        }
      } else if (role == 'Courier') {
        if (request.status == BTexts.statusItemPrepared ||
            request.status == BTexts.statusForDelivery ||
            request.status == BTexts.statusNewRequest) {
          currentRoleHandler.handleAction(
              context, request, requestController, userController, userInitial);
          break;
        }
      } else if (role == 'Viewer') {
        currentRoleHandler.handleAction(
            context, request, requestController, userController, userInitial);
      }
    }
  }
}
