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
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_request_modal_footer.dart';

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/formatters/formatters.dart';

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

    final hasPreparedBy = requestModel.preparedBy.isNotEmpty;
    final hasItemPreparedAt = requestModel.itemPreparedAt.isNotEmpty;
    final hasItemPreparedEndAt = requestModel.itemPreparedEndAt.isNotEmpty;

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

        // Preparation / request details moved to modal body
        if (hasPreparedBy || hasItemPreparedAt || hasItemPreparedEndAt) ...[
          SizedBox(height: BSizes.xs),
          BTextDivider(text: 'Preparation Details'),
          if (hasPreparedBy)
            BLabelValueText(
              label: 'Prepared By',
              value: requestModel.preparedBy,
              showLabel: false,
              icon: Iconsax.user_edit,
              padding: EdgeInsets.zero,
            ),
          if (hasItemPreparedAt)
            BLabelValueText(
              label: 'Item prepared at',
              value: BFormatter.formatDate2(
                BFormatter.formatDateTimeCustomizable(
                  requestModel.itemPreparedAt,
                  "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                  "yyyy-MM-dd HH:mm",
                ),
              ),
              showLabel: false,
              icon: Iconsax.calendar,
              padding: EdgeInsets.zero,
            ),
          if (hasItemPreparedEndAt)
            BLabelValueText(
              label: 'Item prepared end at',
              value: BFormatter.formatDate2(
                BFormatter.formatDateTimeCustomizable(
                  requestModel.itemPreparedEndAt,
                  "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                  "yyyy-MM-dd HH:mm",
                ),
              ),
              showLabel: false,
              icon: Iconsax.calendar_1,
              padding: EdgeInsets.zero,
            ),
        ],
        const SizedBox(height: BSizes.xs),
        // Footer and view item capture are handled inside BDeliveryDetailsSection
        PickUpRequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
