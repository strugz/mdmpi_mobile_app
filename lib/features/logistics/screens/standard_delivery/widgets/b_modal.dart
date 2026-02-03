import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
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

  const BModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
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
    // Determine theme mode and colors
    final bool dark = BHelperFunctions.isDarkMode(context);
    final Color textColor = dark ? BColors.light : BColors.black;

    // Check request status flags
    final bool isDoneDelivery =
        requestModel.status == BTexts.statusDoneDelivery;
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;
    final controller = Get.find<StandardDeliveryController>();

    // Preload cancel remarks for cancelled requests
    if (isCancelled) {
      final requestIdForRemarks =
          requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;
      controller.loadCancelRemarks(requestIdForRemarks);
    }

    return RequestModalScaffold(
      header: RequestModalHeader(requestModel: requestModel),
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
        // Section: Delivery Details (only for completed deliveries)
        if (isDoneDelivery) ...[
          BTextDivider(text: "Delivery details"),
          Center(
            child: BProductTitleText(
                title: "Received By: ${requestModel.receiver}",
                maxLines: 2,
                smallSize: true,
                fontColor: dark ? BColors.light : BColors.black),
          ),
        ],

        // Display captured signature for completed deliveries
        if (isDoneDelivery) CapturedSignatureImage(requestId: requestModel.id),

        // Button to view delivered item image
        if (isDoneDelivery) ...[
          ViewDeliveredItemButton(
            textColor: textColor,
            onPressed: () {
              // Use appropriate request ID for database lookup
              final requestIdForDb = requestModel.id.isNotEmpty
                  ? requestModel.id
                  : requestModel.requestID;
              showRequestImageDialog(context,
                  requestId: requestIdForDb,
                  fetchIfMissing: true,
                  semanticsLabel:
                      'Delivered item image for request ${requestModel.id}',
                  apiController: 'Request');
            },
          )
        ],

        // Section: Cancel Remarks (only for cancelled requests)
        if (isCancelled) ...[
          Obx(() {
            // Reactively load and display cancel remarks
            controller.loadCancelRemarks(requestModel.id);
            final remarks = controller.cancelRemarks.value;

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
