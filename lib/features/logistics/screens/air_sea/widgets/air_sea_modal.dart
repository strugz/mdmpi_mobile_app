import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_dispatch_info_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_waybill_input_section.dart';

/// Modal widget displaying Air/Sea request details.
/// Shows header, document references, footer, and action buttons based on status.
class AirSeaModal extends StatelessWidget {
  final AirSeaModel requestModel;
  final VoidCallback onPressed;
  final bool isActionVisible;

  const AirSeaModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
    this.isActionVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;
    final controller = Get.find<AirSeaController>();

    // Load cancel remarks if cancelled
    if (isCancelled) {
      controller.loadCancelRemarks(requestModel.id);
    }

    return RequestModalScaffold(
      header: AirSeaRequestModalHeader(requestModel: requestModel),
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
            case 'Endorsed to Guard':
              return 'Mark Received';
            case 'Dispatch':
              return 'Mark Drop Off';
            case 'Drop Off':
              return 'Complete Delivery';
            case 'Received':
              return '';
            default:
              return 'Proceed';
          }
        },
      ),
      children: [
        if (requestModel.waybillNumber.isNotEmpty) ...[
          BLabelValueText(
            label: 'Waybill Number',
            value: requestModel.waybillNumber,
            showLabel: true,
            icon: Iconsax.clipboard_text,
            padding: EdgeInsets.zero,
            mainAlignment: MainAxisAlignment.start,
            copyable: true,
          ),
        ],
        // Waybill Input Section (shown when status is "Endorsed to Guard")
        if (requestModel.status == BTexts.statusEndorsedToGuard) ...[
          AirSeaWaybillInputSection(requestModel: requestModel),
        ],

        // Dispatch Information Section (shown when dispatch fields are populated)
        AirSeaDispatchInfoSection(requestModel: requestModel),

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
        AirSeaRequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
