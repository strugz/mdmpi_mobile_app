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
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_header.dart';

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

  @override
  Widget build(BuildContext context) {
    final bool dark = BHelperFunctions.isDarkMode(context);
    final Color textColor = dark ? BColors.light : BColors.black;
    final bool isDoneDelivery =
        requestModel.status == BTexts.statusDoneDelivery;
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;
    final controller = Get.find<StandardDeliveryController>();

    // Load cancel remarks if cancelled
    if (isCancelled) {
      final requestIdForRemarks =
          requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;
      controller.loadCancelRemarks(requestIdForRemarks);
    }

    return RequestModalScaffold(
      header: RequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      docsBottomDivider: true,
      bottomAction: StatusActionButton(
        status: requestModel.status,
        onPressed: onPressed,
        isVisible: status,
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
        const SizedBox(height: BSizes.spaceBtwSections),
        if (isDoneDelivery)
          Center(
            child: BProductTitleText(
                title: "Received By: ${requestModel.receiver}",
                maxLines: 2,
                smallSize: true,
                fontColor: dark ? BColors.light : BColors.black),
          ),
        if (isDoneDelivery) CapturedSignatureImage(requestId: requestModel.id),
        const SizedBox(height: BSizes.xs),
        if (isDoneDelivery)
          ViewDeliveredItemButton(
            textColor: textColor,
            onPressed: () {
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
          ),
        if (isCancelled)
          Obx(() {
            controller.loadCancelRemarks(requestModel.id);
            final remarks = controller.cancelRemarks.value;
            if (remarks == null || remarks.remarks.isEmpty) {
              return const SizedBox.shrink();
            }
            BTextDivider(text: 'Cancel Remarks');
            return BCancelRemarks(
              remarks: remarks.remarks,
              date: remarks.date,
            );
          }),
        RequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
