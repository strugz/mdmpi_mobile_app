import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_delivery_details_section.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_header.dart';

/// Modal widget that displays detailed information about a standard delivery request.
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

  /// Builds the modal UI with status-conditional content sections.
  ///
  /// Displays different content based on [requestModel.status]:
  /// - Done Delivery: Shows receiver info, signature, and delivered item image
  /// - Cancelled: Shows cancellation remarks
  /// - Other statuses: Shows appropriate action buttons
  @override
  Widget build(BuildContext context) {
    // Check request status flags
    final bool isDoneDelivery =
        requestModel.status == BTexts.statusDoneDelivery;
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;

    // Preload cancel remarks for cancelled requests
    if (isCancelled) {
      final requestIdForRemarks =
          requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;
      requestController.loadCancelRemarks(requestIdForRemarks);
    }

    // Determine request ID for database lookups
    final requestIdForDb =
        requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;

    return RequestModalScaffold(
      header: RequestModalHeader(
        requestModel: requestModel,
        requestController: requestController,
      ),
      documentReferences: requestModel.documentReference,
      docsBottomDivider: true,
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
        // Section: Delivery Details (reusable component for completed deliveries)
        if (isDoneDelivery)
          BDeliveryDetailsSection(
            sectionTitle: 'Delivery Details',
            driver: requestModel.deliveredBy,
            helper: requestModel.helper,
            receivedBy: requestModel.receiver,
            receivedByLabel: 'Received By',
            departedAt: requestModel.locationStartedAt,
            departedAtLabel: 'Departed At',
            completedAt: requestModel.deliveredAt,
            completedAtLabel: 'Delivered At',
            requestId: requestIdForDb,
            showSignatureWatermark: true,
            viewItemButtonLabel: 'View Delivered Item',
            dialogTitle: 'Delivered Item',
            apiController: 'Request',
            showViewItemButton: true,
          ),

        // Section: Cancel Remarks (only for cancelled requests)
        if (isCancelled) ...[
          Obx(() {
            // Reactively load and display cancel remarks
            requestController.loadCancelRemarks(requestModel.id);
            final remarks = requestController.cancelRemarks.value;

            // Hide section if no remarks available
            if (remarks == null || remarks.remarks.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                BTextDivider(text: 'Cancel Remarks'),
                BCancelRemarks(
                  remarks: remarks.remarks,
                  date: remarks.date,
                  user: remarks.userUpdated,
                ),
              ],
            );
          }),
        ],

        // Footer with request metadata
        RequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
