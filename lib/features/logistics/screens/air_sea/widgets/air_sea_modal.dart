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

import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_dispatch_info_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_waybill_input_section.dart';

/// Modal widget displaying Air/Sea request details.
///
/// Driven by [AirSeaModalConfig] which encapsulates role, visibility,
/// button label, next status, and validation — eliminating the need
/// for separate handler classes.
class AirSeaModal extends StatelessWidget {
  final AirSeaModel requestModel;
  final AirSeaModalConfig config;

  const AirSeaModal({
    super.key,
    required this.requestModel,
    required this.config,
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
        onPressed: () async {
          // Run validator if present; abort on failure
          if (config.validate != null) {
            final valid = await config.validate!();
            if (!valid) return;
          }

          // For Item Packed → dynamic next status from dropdown
          final effectiveNextStatus =
              config.nextStatus ?? _resolveItemPackedNextStatus(controller);

          if (effectiveNextStatus != null) {
            await controller.updateStatusWithInputs(
              requestModel,
              effectiveNextStatus,
            );
          }

          // Close the modal after action
          if (context.mounted) Navigator.of(context).pop();
        },
        isVisible: config.isActionVisible,
        statusToTextMapper: (_) => config.buttonLabel,
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

        // Waybill Input Section (Release role only, when status is "Endorsed to Guard")
        if (requestModel.status == BTexts.statusEndorsedToGuard &&
            config.role == BTexts.roleRelease) ...[
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
        AirSeaRequestModalFooter(
          requestModel: requestModel,
          role: config.role,
        ),
      ],
    );
  }

  /// Resolves the next status for "Item Packed" from the dropdown selection.
  String? _resolveItemPackedNextStatus(AirSeaController controller) {
    final selected = controller.formState.endorsedToController.text;
    if (selected == 'Endorsed to Guard') return BTexts.statusEndorsedToGuard;
    if (selected == 'Received') return BTexts.statusReceived;
    if (selected == BTexts.statusForDispatch) return BTexts.statusForDispatch;
    return null;
  }
}
