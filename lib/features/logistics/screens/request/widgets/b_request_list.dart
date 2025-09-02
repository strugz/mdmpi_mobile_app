import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/b_request_list_widgets/b_request_card_horizontal.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../base/utils/popups/shimmer.dart';
import '../../../models/request_model.dart';
import '../../../services/implementations/request_role_handler.dart';

class BRequestList extends StatelessWidget {
  const BRequestList({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final requestController = Get.find<RequestController>();
    final userController = Get.find<UserController>();
    // You might want to wrap the whole thing in Obx if allPendingRequests
    // also dictates loading state dynamically
    return Obx(() {
      // First, check the primary content list
      if (requestController.filterManager.filteredRequests.isNotEmpty) {
        return Expanded(
          // Or not, depending on layout needs
          child: Padding(
            // You had Padding here before
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: RefreshIndicator(
              onRefresh: () async {
                // Call the method in your controller to reload the data
                // Make sure this method returns a Future
                await requestController
                    .loadRequests(); // Or your specific refresh logic
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
                      requestController.currentSelectedRequest.value = request,
                      _handleRequestLongPress(
                          context, request, requestController, userController)
                    },
                    child: BRequestCardHorizontal(requestModel: request),
                  );
                },
              ),
            ),
          ),
        );
      }
      // If filteredRequests is empty, then decide what to show:
      // Maybe a loading indicator if data is still being fetched,
      // or "No Data" if fetching is done.
      else if (requestController.isLoading.value &&
          requestController.filterManager.filteredRequests.isEmpty) {
        // Assuming you have an isLoading RxBool
        return const Padding(
          padding: EdgeInsets.all(BSizes.defaultSpace),
          child: BShimmerEffect(width: 350, height: 80),
        );
      } else {
        // This means not loading and filteredRequests is empty
        return Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await requestController.loadRequests();
            },
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Text(
                      'No Data Found!',
                      style:
                          TextStyle(color: dark ? BColors.white : BColors.dark),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }
    });
  }

// Less recommended, as it centralizes status logic again
  void _handleRequestLongPress(
    BuildContext context,
    RequestModel request,
    RequestController requestController,
    UserController userController,
  ) {
    final userRolesString = userController.user.value.role;
    final List<String> userRoles =
        userRolesString.split(',').map((e) => e.trim()).toList();
    final userInitial = userController.user.value.initial;

    // Define the role-specific handlers
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

      /// If the current role handler is null, skip this iteration
      if (currentRoleHandler == null) {
        continue;
      }

      /// If the request is done delivery, use the default handler
      if (request.status == BTexts.statusDoneDelivery) {
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
        } else if (request.status == BTexts.statusItemPrepared && !userRoles.contains('Courier')) {
          currentRoleHandler.handleAction(
              context, request, requestController, userController, userInitial);
          break;
        } else if (request.status == BTexts.statusForDelivery && !userRoles.contains('Courier')) {
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
