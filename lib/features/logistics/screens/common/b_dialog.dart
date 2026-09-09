import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/cancel_reason_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Centralised dialog helper for logistics long-press actions.
///
/// Each module can define its own cancellation reasons via the private
/// `_*Reasons` lists below. Callers may also pass a custom [reasons] list to
/// override the defaults for a specific flow.
class BDialog {
  /// Pull-out cancellation reasons.
  static const List<String> _pullOutReasons = [
    'Item not ready',
    'No gate pass',
    'Not coordinated with customer',
  ];

  /// Pick-up cancellation reasons.
  static const List<String> _pickUpReasons = [
    'Customer unavailable',
    'Wrong address',
    'Duplicate entry',
    'Item already picked up',
    'Other (specify)',
  ];

  /// Air / Sea cancellation reasons.
  static const List<String> _airSeaReasons = [
    'Shipment rerouted',
    'Customs hold',
    'Duplicate booking',
    'Customer request',
    'Other (specify)',
  ];

  /// Shows the correct cancel-reason dialog for the selected module.
  ///
  /// Standard Delivery no longer uses cancel remarks here, so it is intentionally
  /// not handled in this helper.
  static Future<void> showRemarksDialog(
    BuildContext context,
    Object requestModel, {
    List<String>? reasons,
  }) async {
    try {
      if (requestModel is PullOutModel) {
        final requestController = Get.find<PullOutController>();
        await CancelReasonDialog.show(
          context,
          (reason) async =>
              requestController.cancelPullOut(requestModel, reason),
          reasons: reasons ?? _pullOutReasons,
        );
        return;
      }

      if (requestModel is PickUpModel) {
        final requestController = Get.find<PickUpController>();
        await CancelReasonDialog.show(
          context,
          (reason) async =>
              requestController.cancelPickUp(requestModel, reason),
          reasons: reasons ?? _pickUpReasons,
        );
        return;
      }

      if (requestModel is AirSeaModel) {
        final requestController = AirSeaControllers.forRequest(requestModel);
        await CancelReasonDialog.show(
          context,
          (reason) async =>
              requestController.cancelAirSea(requestModel, reason),
          reasons: reasons ?? _airSeaReasons,
        );
        return;
      }

      BLoaders.errorSnackBar(
        title: 'Error',
        message: 'Unsupported request type for remarks dialog',
      );
    } catch (e) {
      BLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }
}
