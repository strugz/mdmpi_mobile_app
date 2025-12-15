import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/air_sea_request_card.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/implementations/air_sea_role_handler.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_dialog.dart';

import '../../../../base/utils/constants/text_string.dart';

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
                        if (item.status != 'Received' &&
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
                        child: Text(
                          'No Data Found!',
                          style: TextStyle(
                              color: dark ? BColors.white : BColors.dark),
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
/// Delegates to appropriate role handler for status-specific actions.
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
  final userInitial = userController.user.value.initial;

  final handlers = <String, AirSeaActionHandler>{
    BTexts.roleRequest: AirSeaRequestRoleHandler(),
    BTexts.roleRelease: AirSeaReleaseRoleHandler(),
    BTexts.roleCourier: AirSeaCourierRoleHandler(),
    BTexts.roleViewer: AirSeaViewerRoleHandler(),
  };

  for (final role in roles) {
    final handler = handlers[role];
    if (handler == null) continue;

    if (request.status.toLowerCase() == 'cancelled' ||
        request.status == 'Received') {
      AirSeaDefaultHandler().handleAction(
          context, request, controller, userController, userInitial);
      break;
    }
    handler.handleAction(
        context, request, controller, userController, userInitial);
    break;
  }
}

