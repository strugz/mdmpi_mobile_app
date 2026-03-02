import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/formatters/formatters.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../common/widgets/dialogs/request_image_dialog.dart';

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
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<PickUpController>();
    final Color textColor = dark ? BColors.light : BColors.black;
    final hasReceivedBy = requestModel.receivedBy.isNotEmpty;

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
        if (requestModel.status == BTexts.statusReceived) ...[
          const SizedBox(height: BSizes.xs),
          const BTextDivider(text: 'Release Details'),
          if (hasReceivedBy) ...[
            const SizedBox(height: BSizes.sm),
            BLabelValueText(
              label: 'Received By',
              value: requestModel.receivedBy,
              showLabel: false,
              icon: Iconsax.user_octagon,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.center,
            ),
            BLabelValueText(
              label: 'Received at',
              value:
                  BFormatter.formatDate2(BFormatter.formatDateTimeCustomizable(
                requestModel.updatedAt,
                "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                "yyyy-MM-dd HH:mm",
              )),
              showLabel: false,
              icon: Iconsax.calendar_1,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.center,
            ),
            const SizedBox(height: BSizes.sm),
            CapturedSignatureImage(requestId: requestModel.id),
            ViewDeliveredItemButton(
              textColor: textColor,
              labelTitle: BTexts.requestModalViewItemReceivedText,
              onPressed: () {
                final requestIdForDb = requestModel.id;
                showRequestImageDialog(context,
                    requestId: requestIdForDb,
                    fetchIfMissing: true,
                    semanticsLabel:
                        'Delivered item image for request ${requestModel.id}',
                    apiController: 'RequestPickUp',
                    title: 'Pick Up Item');
              },
            )
          ],
        ],
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
