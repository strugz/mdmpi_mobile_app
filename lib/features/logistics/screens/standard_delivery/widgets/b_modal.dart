import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_body.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_header.dart';

/// Modal widget that displays detailed information about a standard delivery request.
///
/// Composed of three separate widgets following the Pull Out modal pattern:
/// - [RequestModalHeader]: Client name, address, status chip
/// - [RequestModalBody]: Request info labels + form inputs per status
/// - [RequestModalFooter]: Proof capture + delivery details section
///
/// This modal adapts its content based on the request status:
/// - Shows delivery details and signature for completed deliveries
/// - Displays cancel remarks for cancelled requests
/// - Provides status-specific action buttons for pending requests
class BModal extends StatelessWidget {
  final StandardDeliveryModel requestModel;
  final VoidCallback onPressed;
  final bool status;
  final IDeliveryRequestController requestController;

  const BModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
    required this.requestController,
    this.status = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;

    // Preload cancel remarks for cancelled requests
    if (isCancelled) {
      final requestIdForRemarks =
          requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;
      requestController.loadCancelRemarks(requestIdForRemarks);
    }

    return RequestModalScaffold(
      header: RequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      // Status-specific action button (Prepare Item, Packed and Ready, etc.)
      bottomAction: StatusActionButton(
        status: requestModel.status,
        onPressed: onPressed,
        isVisible: status,
        // Map status to appropriate button text
        statusToTextMapper: (status) {
          switch (status) {
            case BTexts.statusNewRequest:
              return BTexts.requestModalPrepareItemButtonText;
            case BTexts.statusGettingSuppliesReady:
              return BTexts.requestModalPackedAndReadyButtonText;
            default:
              return '';
          }
        },
      ),
      children: [
        // Cancel Remarks Section
        if (isCancelled)
          Obx(() {
            final remarks = requestController.cancelRemarks.value;
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
        // Body with all sections (Request Info, Preparation Info, Delivery Info)
        RequestModalBody(
          requestModel: requestModel,
          requestController: requestController,
        ),
        // Footer with proof capture and delivery details
        RequestModalFooter(
          requestModel: requestModel,
          requestController: requestController,
        ),
      ],
    );
  }
}
