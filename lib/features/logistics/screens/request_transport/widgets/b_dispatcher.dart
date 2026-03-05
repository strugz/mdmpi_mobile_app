import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/draggable_bottom_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_request_details.dart';

import '../../../../personalization/controller/user_controller.dart';
import '../../../controllers/request_transport_controller.dart';

/// Bottom sheet dispatcher for the Request Transport screen.
///
/// Uses [BDraggableBottomSheet] for the drag-handle + scroll + fixed-action
/// layout, composing transport-specific widgets for the body and action button.
class BDispatcher extends StatelessWidget {
  const BDispatcher({
    super.key,
    required this.requestController,
  });

  final IDeliveryRequestController requestController;

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final requestTransportController = Get.find<RequestTransportController>();

    return BDraggableBottomSheet(
      body: BRequestDetails(
        requestController: requestController,
        userController: userController,
        requestTransportController: requestTransportController,
      ),
      bottomAction: BActionButton(
        requestController: requestController,
        requestTransportController: requestTransportController,
      ),
    );
  }
}
