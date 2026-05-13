import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/standard_delivery_page.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/back_load/backload_transaction_page.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/backload_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/request_transport.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_request_card_horizontal.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';
import '../../../../base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Role priority map: Lower number = Higher priority (more capabilities)
const _rolePriority = {
  BTexts.roleAdmin: 0, // Full access
  BTexts.roleRelease: 1, // Most powerful for initial stages
  BTexts.roleCourier: 2, // Most powerful for delivery stages
  BTexts.roleRequest: 3, // Limited to viewing
  BTexts.roleViewer: 4, // View-only access
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
                      onTap: () {
                        requestController.currentSelectedRequest.value =
                            request;
                        _handleRequestTap(context, request, requestController,
                            userController);
                      },
                      onLongPress: () {
                        if (request.status != BTexts.statusDoneDelivery &&
                            request.status != BTexts.statusCancelled &&
                            request.status != BTexts.statusBackLoad) {
                          requestController.currentSelectedRequest.value =
                              request;
                          // Directly open BackLoad page per BackLoad spec (no choice sheet)
                          Get.find<BackLoadController>()
                              .initForRequest(request);
                          Get.to(() =>
                              BackLoadTransactionPage(requestModel: request));
                        }
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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color:
                                      dark ? BColors.light : BColors.darkGrey,
                                ),
                          ),
                          const SizedBox(height: BSizes.sm),
                          Text(
                            'Try adjusting your filters',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      dark ? BColors.light : BColors.darkGrey,
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
}

/// Handles tap on Standard Delivery request based on user role.
/// Resolves a single [StandardDeliveryModalConfig] from the highest-priority role and
/// opens the modal — no handler classes needed.
void _handleRequestTap(
  BuildContext context,
  StandardDeliveryModel request,
  StandardDeliveryController controller,
  UserController userController,
) {
  final roles = userController.user.value.role
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // Force Release for New Request / Getting Supplies Ready
  if ((request.status == BTexts.statusNewRequest ||
          request.status == BTexts.statusGettingSuppliesReady) &&
      roles.contains(BTexts.roleRelease)) {
    final config = StandardDeliveryModalConfig.resolve(
      request: request,
      role: BTexts.roleRelease,
      controller: controller,
    );
    BHelperFunctions.navigateWithSlide(
      context,
      StandardDeliveryPage(requestModel: request, config: config),
      duration: const Duration(milliseconds: 350),
    );
    return;
  }

  // Force Courier for Item Prepared / For Delivery
  if ((request.status == BTexts.statusItemPrepared ||
          request.status == BTexts.statusForDelivery) &&
      roles.contains(BTexts.roleCourier)) {
    BHelperFunctions.navigateWithSlide(
      context,
      RequestTransport(
        request: request,
        requestController: controller,
      ),
      duration: const Duration(milliseconds: 350),
    );
    return;
  }

  // Find the highest-priority role the user has
  String selectedRole = BTexts.roleViewer;
  int highestPriority = 999;

  for (final role in roles) {
    final priority = _rolePriority[role] ?? 999;
    if (priority < highestPriority) {
      highestPriority = priority;
      selectedRole = role;
    }
  }

  final config = StandardDeliveryModalConfig.resolve(
    request: request,
    role: selectedRole,
    controller: controller,
  );

  BHelperFunctions.navigateWithSlide(
    context,
    StandardDeliveryPage(requestModel: request, config: config),
    duration: const Duration(milliseconds: 350),
  );
}
