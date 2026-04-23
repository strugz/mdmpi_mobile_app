import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_dispatch_info_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_provincial_delivery_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_provincial_in_transit_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_provincial_pick_up_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_waybill_input_section.dart';

/// Full-screen Air/Sea details page.
///
/// Mirrors [StandardDeliveryPage] in structure: AppBar + [RequestModalScaffold]
/// body + bottom action button — driven entirely by [AirSeaModalConfig].
class AirSeaPage extends StatelessWidget {
  final AirSeaModel requestModel;
  final AirSeaModalConfig config;

  const AirSeaPage({
    super.key,
    required this.requestModel,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = BHelperFunctions.isDarkMode(context);
    final bool isCancelled = requestModel.status.toLowerCase() == 'cancelled';
    final controller = Get.find<AirSeaController>();

    if (isCancelled) {
      controller.loadCancelRemarks(requestModel.id);
    }

    // Use the `dark` flag to choose the page background so the UI matches
    // the app's dark/light mode. This uses the shared color constants.
    return Scaffold(
      backgroundColor: dark ? BColors.black : BColors.light,
      appBar: BAppBar(
        showBackArrow: true,
        leadingOnPressed: () => Navigator.of(context).pop(),
        title: Text(
          'Air / Sea Details',
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RequestModalScaffold(
              header: AirSeaRequestModalHeader(
                requestModel: requestModel,
                role: config.role,
              ),
              documentReferences: requestModel.documentReference,
              children: [
                // Waybill number (read-only, shown when filled)
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

                AirSeaRequestModalFooter(
                  requestModel: requestModel,
                  role: config.role,
                ),

                // Waybill Input Section (Release role only, when status is "Endorsed to Guard")
                if (requestModel.status == BTexts.statusEndorsedToGuard &&
                    config.role == BTexts.roleRelease) ...[
                  AirSeaWaybillInputSection(requestModel: requestModel),
                ],

                if (requestModel.mobileId != null) ...[
                  AirSeaDispatchInfoSection(requestModel: requestModel),
                ],

                ..._buildProvincialSections(),

                // Cancel remarks
                if (isCancelled) const BTextDivider(text: 'Cancel Remarks'),
                Obx(() {
                  final remarks = controller.cancelRemarks.value;
                  if (remarks == null || remarks.remarks.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return BCancelRemarks(
                    remarks: remarks.remarks,
                    date: remarks.date,
                    user: remarks.userUpdated,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: config.isActionVisible
          ? SafeArea(
              child: StatusActionButton(
                status: requestModel.status,
                onPressed: () async {
                  if (config.validate != null) {
                    final valid = await config.validate!();
                    if (!valid) return;
                  }

                  final effectiveNextStatus = config.nextStatus ??
                      _resolveItemPackedNextStatus(controller);

                  if (effectiveNextStatus != null) {
                    await controller.updateStatusWithInputs(
                      requestModel,
                      effectiveNextStatus,
                    );
                  }

                  if (context.mounted) Navigator.of(context).pop();
                },
                isVisible: config.isActionVisible,
                statusToTextMapper: (_) => config.buttonLabel,
              ),
            )
          : null,
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

  List<Widget> _buildProvincialSections() {
    final status = requestModel.status;
    final bool canEditProvincial = config.role == BTexts.roleProvincial;
    final bool showPickUpSection =
        ((status == BTexts.statusReceived || status == BTexts.statusDropOff) &&
                canEditProvincial) ||
            status == BTexts.statusProvincialPickUp ||
            status == BTexts.statusProvincialInTransit ||
            status == BTexts.statusProvincialDelivered;

    final bool showInTransitSection = status == BTexts.statusProvincialPickUp ||
        status == BTexts.statusProvincialInTransit ||
        status == BTexts.statusProvincialDelivered;

    final bool showDeliverySection =
        status == BTexts.statusProvincialInTransit ||
            status == BTexts.statusProvincialDelivered;

    return [
      if (showPickUpSection)
        AirSeaProvincialPickUpSection(
          requestModel: requestModel,
          isEditable: canEditProvincial &&
              (status == BTexts.statusReceived ||
                  status == BTexts.statusDropOff),
        ),
      if (showInTransitSection)
        AirSeaProvincialInTransitSection(
          requestModel: requestModel,
          isActive:
              canEditProvincial && status == BTexts.statusProvincialPickUp,
        ),
      if (showDeliverySection)
        AirSeaProvincialDeliverySection(
          requestModel: requestModel,
          isEditable:
              canEditProvincial && status == BTexts.statusProvincialInTransit,
        ),
    ];
  }
}
