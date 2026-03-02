
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

import '../../controllers/standard_delivery_controller.dart';
import '../../models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/cancel_reason_dialog.dart';

class BDialog {
  static Future<void> showRemarksDialog(
      BuildContext context, Object requestModel) async {
    if (requestModel is StandardDeliveryModel) {
      final requestController = Get.find<StandardDeliveryController>();
      await CancelReasonDialog.show(context, (reason) async {
        await requestController.updateRequestForCancellation(requestModel, reason);
      });
    } else if (requestModel is PullOutModel) {
      final requestController = Get.find<PullOutController>();
      await CancelReasonDialog.show(context, (reason) async {
        await requestController.cancelPullOut(requestModel, reason);
      });
    } else if (requestModel is PickUpModel) {
      final requestController = Get.find<PickUpController>();
      await CancelReasonDialog.show(context, (reason) async {
        await requestController.cancelPickUp(requestModel, reason);
      });
    } else if (requestModel is AirSeaModel) {
      final requestController = Get.find<AirSeaController>();
      await CancelReasonDialog.show(context, (reason) async {
        await requestController.cancelAirSea(requestModel, reason);
      });
    } else {
      BLoaders.errorSnackBar(title: 'Error', message: 'Unsupported request type for remarks dialog');
    }
  }
}
