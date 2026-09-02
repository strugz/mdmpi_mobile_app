import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/stock_receive_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal_body.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_request_modal_footer.dart';

/// Modal dialog for viewing and acting on Stock Receive requests.
/// Driven by [StockReceiveModalConfig] to determine visibility and action behavior.
///
/// Reuses the Pull Out modal widgets with [StockReceiveController] injected so
/// inputs (trip ticket, driver, vehicle, released by, signature) land in the
/// same form state the Stock Receive validator reads.
class StockReceiveModal extends StatelessWidget {
  final PullOutModel requestModel;
  final StockReceiveModalConfig config;

  const StockReceiveModal({
    super.key,
    required this.requestModel,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled =
        requestModel.requestStatus == BTexts.statusCancelled;
    final controller = Get.find<StockReceiveController>();

    // Load cancel remarks if cancelled
    if (isCancelled) {
      controller.loadCancelRemarks(requestModel.id);
    }

    return RequestModalScaffold(
      header: PullOutRequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      bottomAction: StatusActionButton(
        status: requestModel.requestStatus,
        onPressed: () async {
          if (config.nextStatus != null) {
            // Run optional validator first
            if (config.validate != null) {
              final valid = await config.validate!();
              if (!valid) return;
            }
            await controller.updateStatusWithInputs(
                requestModel, config.nextStatus!);
          }
        },
        isVisible: config.isActionVisible,
        statusToTextMapper: (status) => config.buttonLabel,
      ),
      children: [
        // Cancel Remarks Section
        if (isCancelled)
          Obx(() {
            final remarks = controller.cancelRemarks.value;
            if (remarks == null || remarks.remarks.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BTextDivider(text: 'Cancel Remarks'),
                BCancelRemarks(
                  remarks: remarks.remarks,
                  date: remarks.date,
                  user: remarks.userUpdated,
                ),
              ],
            );
          }),
        // Body with all sections (Delivery Info at New Request for Release)
        PullOutModalBody(requestModel: requestModel, controller: controller),
        // Footer with proof of pull out (In Transit, Courier) and details
        PullOutRequestModalFooter(
            requestModel: requestModel, controller: controller),
      ],
    );
  }
}
