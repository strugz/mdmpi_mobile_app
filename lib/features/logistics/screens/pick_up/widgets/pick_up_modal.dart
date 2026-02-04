
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_request_modal_footer.dart';

class PickUpModal extends StatelessWidget {
  final PickUpModel requestModel;
  final VoidCallback onPressed;
  final bool isActionVisible;

  const PickUpModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
    this.isActionVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;
    final controller = Get.find<PickUpController>();

    // Load cancel remarks if cancelled
    if (isCancelled) {
      controller.loadCancelRemarks(requestModel.id);
    }

    return RequestModalScaffold(
      header: PickUpRequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      bottomAction: StatusActionButton(
        status: requestModel.status,
        onPressed: onPressed,
        isVisible: isActionVisible,
        statusToTextMapper: (status) {
          if (status == null) return 'Proceed';
          switch (status) {
            case 'New Request':
              return 'Mark Preparing';
            case 'Getting supplies ready':
              return 'Mark Item Packed';
            case 'Item Prepared':
              return 'Mark Received';
            case 'Received':
              return '';
            default:
              return 'Proceed';
          }
        },
      ),
      children: [
        if (isCancelled) BTextDivider(text: 'Cancel Remarks'),
        Obx(
          () {
            controller.loadCancelRemarks(requestModel.id);
            final remarks = controller.cancelRemarks.value;
            if (remarks == null || remarks.remarks.isEmpty) {
              return const SizedBox.shrink();
            }
            return BCancelRemarks(
              remarks: remarks.remarks,
              date: remarks.date,
              user: remarks.userUpdated,
            );
          },
        ),
        PickUpRequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
