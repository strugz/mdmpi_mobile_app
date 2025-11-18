import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

import '../../../../controllers/standard_delivery_controller.dart';
import '../../../../models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/cancel_reason_dialog.dart';

/// Small helper that shows dialogs used in the standard delivery flows.
class BDialog {
  /// Shows a dialog allowing the user to select a cancellation reason
  /// for [requestModel].
  ///
  /// The method resolves the controller via Get.find() (per DI conventions),
  /// keeps UI-local state in a StatefulBuilder, and disposes controllers
  /// after the dialog is dismissed.
  static Future<void> showRemarksDialog(
      BuildContext context, Object requestModel) async {
    // Use shared CancelReasonDialog defaults for reasons.
    // Two supported request types: StandardDeliveryModel and PullOutModel.
    if (requestModel is StandardDeliveryModel) {
      final requestController = Get.find<StandardDeliveryController>();
      await CancelReasonDialog.show(context, (reason) async {
        // Delegate cancellation to controller
        await requestController.updateRequestForCancellation(requestModel, reason);
      });
    } else if (requestModel is PullOutModel) {
      final requestController = Get.find<PullOutController>();
      await CancelReasonDialog.show(context, (reason) async {
        // Update pull-out: set status Cancelled and store reason
        // Use the cancel flow to send the same payload as Standard Delivery cancel endpoint
        await requestController.cancelPullOut(requestModel.id, reason);
      });
    } else {
      BLoaders.errorSnackBar(title: 'Error', message: 'Unsupported request type for remarks dialog');
    }
  }
}
