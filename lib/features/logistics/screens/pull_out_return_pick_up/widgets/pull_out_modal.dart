
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal_body.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_request_modal_footer.dart';

class PullOutModal extends StatelessWidget {
  final PullOutModel requestModel;
  final VoidCallback onPressed;
  final bool isActionVisible;

  const PullOutModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
    this.isActionVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = requestModel.requestStatus == BTexts.statusCancelled;
    final controller = Get.find<PullOutController>();

    // Load cancel remarks if cancelled
    if (isCancelled) {
      controller.loadCancelRemarks(requestModel.id);
    }

    return RequestModalScaffold(
      header: PullOutRequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      bottomAction: StatusActionButton(
        status: requestModel.requestStatus,
        onPressed: onPressed,
        isVisible: isActionVisible,
        statusToTextMapper: (status) {
          if (status == null) return 'Proceed';
          switch (status) {
            case 'New Request':
              return 'Set In Transit';
            case 'In Transit':
              return 'Mark Taken Out';
            case 'Taken Out':
              return '';
            default:
              return 'Proceed';
          }
        },
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
        // Body with all sections (Delivery Info, Pull out Info, IRRF, Receiver Details)
        PullOutModalBody(requestModel: requestModel),
        // Footer with delivery details and proof of pull out
        PullOutRequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
