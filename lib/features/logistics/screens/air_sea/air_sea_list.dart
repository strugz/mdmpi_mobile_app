import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/air_sea_page.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/air_sea_page_stages.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_request_card.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';

import '../../../../base/utils/constants/text_strings.dart';
import '../../../../base/utils/popups/shimmer.dart';

/// Role priority map: Lower number = Higher priority (more capabilities)
const _rolePriority = {
  BTexts.roleRelease: 1,
  BTexts.roleCourier: 2,
  BTexts.roleProvincial: 3,
  BTexts.roleRequest: 4,
  BTexts.roleViewer: 5,
};

/// Main list screen for Air/Sea requests.
/// Displays filtered requests with pull-to-refresh and tap handling based on user roles.
class AirSeaList extends StatelessWidget {
  const AirSeaList({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<AirSeaController>();
    final userController = Get.find<UserController>();

    return Obx(() {
      final items = controller.filteredAirSeaRequests;

      if (items.isNotEmpty) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: AbsorbPointer(
              absorbing: controller.isLoading.value,
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.loadAirSeaRequests();
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
                        controller.currentSelectedAirSea.value = item;
                        _handleAirSeaTap(
                            context, item, controller, userController);
                      },
                      onLongPress: () async {
                        if (item.status != BTexts.statusProvincialDelivered &&
                            item.status != BTexts.statusReceived &&
                            item.status != BTexts.statusDropOff &&
                            item.status.toLowerCase() != 'cancelled') {
                          controller.currentSelectedAirSea.value = item;
                          await BDialog.showRemarksDialog(context, item);
                        }
                      },
                      child: AirSeaRequestCard(item: item),
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
                await controller.loadAirSeaRequests();
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
                              'No Air / Sea requests found',
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
                },
              ),
            ),
          ),
        );
      }
    });
  }
}

/// Handles tap on Air/Sea request based on user role.
/// Resolves a single [AirSeaModalConfig] from the highest-priority role and
/// opens the modal — no handler classes needed.
void _handleAirSeaTap(
  BuildContext context,
  AirSeaModel request,
  AirSeaController controller,
  UserController userController,
) {
  final roles = userController.user.value.role
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // Force Courier for dispatch-related statuses
  if ((request.status == BTexts.statusForDispatch ||
          request.status == BTexts.statusDispatch) &&
      roles.contains(BTexts.roleCourier)) {
    final config = AirSeaModalConfig.resolve(
        request: request, role: BTexts.roleCourier, controller: controller);
    BHelperFunctions.navigateWithSlide(
      context,
      AirSeaPageStages(requestModel: request, config: config),
      duration: const Duration(milliseconds: 350),
    );
    return;
  }

  // Force Provincial for provincial-leg statuses
  if ((request.status == BTexts.statusReceived ||
          request.status == BTexts.statusDropOff ||
          request.status == BTexts.statusProvincialPickUp ||
          request.status == BTexts.statusProvincialInTransit ||
          request.status == BTexts.statusProvincialDelivered) &&
      roles.contains(BTexts.roleProvincial)) {
    final config = AirSeaModalConfig.resolve(
      request: request,
      role: BTexts.roleProvincial,
      controller: controller,
    );
    BHelperFunctions.navigateWithSlide(
      context,
      AirSeaPageStages(requestModel: request, config: config),
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

  final config = AirSeaModalConfig.resolve(
    request: request,
    role: selectedRole,
    controller: controller,
  );
  BHelperFunctions.navigateWithSlide(
    context,
    AirSeaPageStages(requestModel: request, config: config),
    duration: const Duration(milliseconds: 350),
  );
}
