import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/signature/captured_signature_image.dart';
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
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// Full-screen Air/Sea details page.
///
/// Mirrors [StandardDeliveryPage] in structure: AppBar + [RequestModalScaffold]
/// body + bottom action button — driven entirely by [AirSeaModalConfig].
class AirSeaPage extends StatelessWidget {
  final AirSeaModel requestModel;
  final AirSeaModalConfig config;
  final AirSeaController controller;

  /// Creates the Air/Sea details page with the selected request and modal
  /// configuration, resolving its controller from GetX dependency injection.
  AirSeaPage({
    super.key,
    required this.requestModel,
    required this.config,
  })  : controller = Get.find<AirSeaController>();

  @override
  /// Builds the full-screen request details view, including the header,
  /// status-driven content sections, cancel remarks, and optional footer
  /// action for progressing the request.
  Widget build(BuildContext context) {
    // Detect current theme mode so we can pick an appropriate background
    // color that matches the rest of the app's dark/light styling.
    final bool dark = BHelperFunctions.isDarkMode(context);

    // Determine whether the request is cancelled so we can show cancel
    // remarks and avoid showing actions that are inappropriate for a
    // cancelled request.
    final bool isCancelled = requestModel.status.toLowerCase() == 'cancelled';

    // Color used for small action buttons that were previously shown in
    // the header (moved here). Matches header's text color selection.
    final Color textColor = dark ? BColors.light : BColors.black;

    // Local helper flags used by the inserted guard / drop-off UI blocks.
    final bool hasReceivedBy = requestModel.receivedBy.isNotEmpty;

    if (isCancelled) {
      // Load cancel remarks if the request is cancelled. This populates
      // `controller.cancelRemarks` for the UI below (observed with `Obx`).
      controller.loadCancelRemarks(requestModel.id);
    }

    // Load request history for display/logging. The method is invoked for
    // its side-effects (controller state update) so we don't keep the
    // returned value locally.
    controller.loadHistory(requestModel.id);



    // Use the `dark` flag to choose the page background so the UI matches
    // the app's dark/light mode. This uses the shared color constants.
    // The page is presented as a full scaffold with a constrained center
    // column so it looks reasonable on large screens (desktop / tablet)
    // while remaining full-screen on phones.
    return Scaffold(
      // Choose background color according to theme to keep consistent
      // visual appearance across the app.
      backgroundColor: dark ? BColors.black : BColors.light,
      appBar: BAppBar(
        showBackArrow: true,
        leadingOnPressed: () => Navigator.of(context).pop(),
        title: Text(
          'Air / Sea / Land Details',
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

                // Footer section with request summary / quick actions that
                // are common to Air/Sea requests.
                AirSeaRequestModalFooter(
                  requestModel: requestModel,
                  role: config.role,
                ),

                // Waybill Input Section (Release role only, when status is "Endorsed to Guard")
                if (requestModel.status == BTexts.statusEndorsedToGuard &&
                    config.role == BTexts.roleRelease) ...[
                  AirSeaWaybillInputSection(requestModel: requestModel),
                ],

                // Dispatch info when assigned to a mobile unit
                if (requestModel.mobileId != null) ...[
                  AirSeaDispatchInfoSection(requestModel: requestModel),
                ],

                // Guard Endorsement section (moved from header). Shown when
                // status is 'Endorsed to Guard' and the active role is not
                // provincial.
                if (requestModel.status == BTexts.statusEndorsedToGuard &&
                    config.role != BTexts.roleProvincial) ...[
                  const SizedBox(height: BSizes.xs),
                  const BTextDivider(text: 'Guard Endorsement'),
                  if (hasReceivedBy) ...[
                    const SizedBox(height: BSizes.sm),
                    BLabelValueText(
                      label: 'Endorsed To (Guard)',
                      value: requestModel.receivedBy,
                      showLabel: false,
                      icon: Iconsax.user_octagon,
                      padding: EdgeInsets.zero,
                      mainAlignment: MainAxisAlignment.center,
                    ),
                    BLabelValueText(
                      label: 'Endorsed at',
                      value: BFormatter.formatDateTimeCustomizable(
                        requestModel.updatedAt,
                        "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                        "MMM d, yyyy hh:mm a",
                      ),
                      showLabel: false,
                      icon: Iconsax.calendar_1,
                      padding: EdgeInsets.zero,
                      mainAlignment: MainAxisAlignment.center,
                    ),
                    const SizedBox(height: BSizes.sm),
                  ],

                  // Display captured guard signature image
                  CapturedSignatureImage(requestId: requestModel.id),
                  // Button to view guard receipt proof image
                  ViewDeliveredItemButton(
                    textColor: textColor,
                    labelTitle: 'View Guard Receipt Proof',
                    onPressed: () {
                      final requestIdForDb = requestModel.id;
                      showRequestImageDialog(context,
                          requestId: requestIdForDb,
                          semanticsLabel:
                              'Guard receipt proof image for request ${requestModel.id}',
                          apiController: 'RequestAirSea',
                          title: 'Guard Receipt Proof');
                    },
                  ),
                ],

                // Drop Off details section (moved from header). Shown when
                // status is 'Drop Off' and the active role is not provincial.
                if (requestModel.status == BTexts.statusDropOff &&
                    config.role != BTexts.roleProvincial) ...[
                  const SizedBox(height: BSizes.xs),
                  const BTextDivider(text: 'Drop Off Details'),
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
                    if (requestModel.dropOffAt.isNotEmpty)
                      BLabelValueText(
                        label: 'Dropped Off at',
                        value: BFormatter.formatDateTimeCustomizable(
                          requestModel.dropOffAt,
                          "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                          "MMM d, yyyy hh:mm a",
                        ),
                        showLabel: false,
                        icon: Iconsax.calendar_1,
                        padding: EdgeInsets.zero,
                        mainAlignment: MainAxisAlignment.center,
                      ),
                    const SizedBox(height: BSizes.sm),

                    // Display captured receiver signature image
                    CapturedSignatureImage(requestId: requestModel.id),
                    // Button to view drop off proof image
                    ViewDeliveredItemButton(
                      textColor: textColor,
                      labelTitle: 'View Drop Off Proof',
                      onPressed: () {
                        final requestIdForDb = requestModel.id;
                        showRequestImageDialog(context,
                            requestId: requestIdForDb,
                            semanticsLabel:
                                'Drop off proof image for request ${requestModel.id}',
                            apiController: 'RequestAirSea',
                            title: 'Drop Off Proof');
                      },
                    )
                    ],

                // Insert provincial workflow sections (pickup / in-transit /
                // delivery) according to the current status and role.
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: config.isActionVisible
          ? SafeArea(
              child: StatusActionButton(
                status: requestModel.status,
                // Primary action for the page — may validate inputs via
                // `config.validate`, then resolve the next status either
                // directly from `config.nextStatus` or via the helper below
                // and finally call repository/controller to update state.
                onPressed: () async {
                  // Allow the modal config to perform validation (e.g., a
                  // form check) before proceeding. If validation fails,
                  // abort the action.
                  if (config.validate != null) {
                    final valid = await config.validate!();
                    if (!valid) return;
                  }

                  // Determine the effective next status:
                  // - Prefer an explicit `nextStatus` from the modal config.
                  // - Otherwise fall back to resolving selection-driven
                  //   statuses (e.g., the "Item Packed" dropdown).
                  final effectiveNextStatus = config.nextStatus ??
                      _resolveItemPackedNextStatus(controller);

                  // If we have an actionable next status, perform the
                  // controller-driven update which may prompt for inputs
                  // (signatures / photos) before persisting.
                  if (effectiveNextStatus != null) {
                    await controller.updateStatusWithInputs(
                      requestModel,
                      effectiveNextStatus,
                    );
                  }

                  // Close the modal/page after a successful action. Guard
                  // with `context.mounted` to avoid calling Navigator when the
                  // widget tree has been disposed.
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

  /// Builds the provincial workflow sections that should be shown for the
  /// current request status, enabling editing only when the active role and
  /// status allow provincial updates.
  List<Widget> _buildProvincialSections() {
    final status = requestModel.status;
    // Only users with the provincial role are allowed to edit provincial
    // workflow fields (pickup / in-transit / delivery). Other roles may be
    // able to view read-only information.
    final bool canEditProvincial = config.role == BTexts.roleProvincial;

    // Decide which provincial sub-sections should be displayed. These boolean
    // expressions reflect the state machine used elsewhere in the app:
    // - showPickUpSection: Visible when the request is received / dropped off
    //   and the user can edit provincial info, or when the request is already
    //   at one of the provincial stages.
    final bool showPickUpSection =
        ((status == BTexts.statusReceived || status == BTexts.statusDropOff) &&
                canEditProvincial) ||
            status == BTexts.statusProvincialPickUp ||
            status == BTexts.statusProvincialInTransit ||
            status == BTexts.statusProvincialDelivered;

    // showInTransitSection: Visible while the item is in the provincial
    // transit lifecycle (pickup -> in-transit -> delivered).
    final bool showInTransitSection = status == BTexts.statusProvincialPickUp ||
        status == BTexts.statusProvincialInTransit ||
        status == BTexts.statusProvincialDelivered;

    // showDeliverySection: Visible once the item has entered provincial
    // delivery flow (in-transit or delivered states).
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
