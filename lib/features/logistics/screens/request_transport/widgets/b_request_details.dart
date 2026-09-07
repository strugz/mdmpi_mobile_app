import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_document_reference.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/backload_items_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_proof_photo_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/reassign_delivery_crew_section.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_view_items_button.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../personalization/controller/user_controller.dart';
import '../../../controllers/request_transport_controller.dart';

/// Details content for the Request Transport draggable bottom sheet.
///
/// Follows the standard delivery modal body pattern:
/// - If a field has a value → show it as read-only `BLabelValueText`
/// - If a field is empty → hide it (or show a form input when editable)
class BRequestDetails extends StatelessWidget {
  const BRequestDetails({
    super.key,
    required this.requestController,
    required this.requestTransportController,
    required this.userController,
  });

  final IDeliveryRequestController requestController;
  final RequestTransportController requestTransportController;
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final iconColor = dark ? BColors.light : BColors.black;

    return Obx(
      () {
        final updatedRequest = requestController.currentSelectedRequest.value;

        // If somehow null, cannot render
        if (updatedRequest == null) {
          return const Center(child: Text('Request not found'));
        }

        final hasClientName = updatedRequest.client.name.isNotEmpty;
        final hasClientAddress = updatedRequest.client.address.isNotEmpty;
        final hasPreparedBy = updatedRequest.itemPreparedBy.isNotEmpty;
        final hasPreparedAt = updatedRequest.itemPreparedAt.isNotEmpty;
        final hasPreparedEndAt = updatedRequest.itemPreparedEndAt.isNotEmpty;
        final hasTripTicket = updatedRequest.tripTicketNumber.isNotEmpty;
        final hasDocRefs = updatedRequest.documentReference.isNotEmpty;
        final hasDriver = updatedRequest.deliveredBy.isNotEmpty;
        // A helper identical to the driver is legacy duplicate data — show
        // the person once, as the driver.
        final hasHelper = updatedRequest.helper.isNotEmpty &&
            updatedRequest.helper != updatedRequest.deliveredBy;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ========== HEADER: Client Info + Status + Preference (always shown) ==========
            if (hasClientName)
              BProductTitleText(
                title: updatedRequest.client.name,
                maxLines: 3,
                fontColor: textColor,
                bold: true,
              ),
            if (hasClientAddress) ...[
              const SizedBox(height: BSizes.xs),
              BProductTitleText(
                title: updatedRequest.client.address,
                maxLines: 3,
                smallSize: true,
                fontColor: textColor,
              ),
            ],
            // Always show status and preference as chips because these fields are mandatory
            const SizedBox(height: BSizes.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: BSizes.sm,
                runSpacing: BSizes.xs,
                children: [
                  StatusChip(
                    status: updatedRequest.status,
                    compact: false,
                  ),
                  StatusChip(
                    status: updatedRequest.preference,
                    compact: false,
                  ),
                ],
              ),
            ),

            // ETA
            if (requestTransportController.eta.value?.isNotEmpty ?? false) ...[
              const SizedBox(height: BSizes.xs),
              BLabelValueText(
                label: 'ETA',
                value: requestTransportController.eta.value!,
                showLabel: false,
                icon: Iconsax.clock,
                padding: EdgeInsets.zero,
              ),
            ],

            // ========== Preparation Details ==========
            if (hasPreparedBy || hasPreparedAt || hasTripTicket) ...[
              const SizedBox(height: BSizes.sm),
              const BTextDivider(text: 'Preparation Details'),
              const SizedBox(height: BSizes.sm),
              if (hasPreparedBy)
                BLabelValueText(
                  label: 'Prepared By',
                  value: updatedRequest.itemPreparedBy,
                  showLabel: false,
                  icon: Iconsax.user_tick,
                  padding: EdgeInsets.zero,
                ),
              if (hasPreparedAt || hasPreparedEndAt) ...[
                const SizedBox(height: BSizes.sm),
                Row(
                  children: [
                    if (hasPreparedAt)
                      Expanded(
                        child: BLabelValueText(
                          label: 'Start',
                          value: BFormatter.formatDate2(
                              updatedRequest.itemPreparedAt),
                          showLabel: false,
                          icon: Iconsax.clock,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    if (hasPreparedAt && hasPreparedEndAt)
                      const SizedBox(width: BSizes.xs),
                    if (hasPreparedEndAt)
                      Expanded(
                        child: BLabelValueText(
                          label: 'End',
                          value: BFormatter.formatDate2(
                              updatedRequest.itemPreparedEndAt),
                          showLabel: false,
                          icon: Iconsax.clock,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
              if (hasTripTicket) ...[
                const SizedBox(height: BSizes.sm),
                BLabelValueText(
                  label: 'Trip Ticket No',
                  value: updatedRequest.tripTicketNumber,
                  showLabel: false,
                  copyable: true,
                  icon: Iconsax.receipt_2,
                  padding: EdgeInsets.zero,
                ),
              ],
            ],

            // ========== Dispatch Info (driver, helper) ==========
            if (hasDriver || hasHelper) ...[
              const SizedBox(height: BSizes.sm),
              const BTextDivider(text: 'Dispatch Info'),
              const SizedBox(height: BSizes.sm),
              Row(
                children: [
                  if (hasDriver)
                    Expanded(
                      child: BLabelValueText(
                        label: 'Driver',
                        value: updatedRequest.deliveredBy,
                        showLabel: true,
                        icon: Iconsax.user,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  if (hasDriver && hasHelper) const SizedBox(width: BSizes.xs),
                  if (hasHelper)
                    Expanded(
                      child: BLabelValueText(
                        label: 'Helper',
                        value: updatedRequest.helper,
                        showLabel: true,
                        icon: Iconsax.user,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],

            // ========== Re-assign Driver / Helper (Release role) ==========
            // Multi-role users with Courier are routed to this screen instead
            // of the request modal, so the Release re-assignment section must
            // also live here.
            if (userController.user.value.role.contains(BTexts.roleRelease) &&
                (updatedRequest.status == BTexts.statusItemPrepared ||
                    updatedRequest.status == BTexts.statusForDelivery))
              ReassignDeliveryCrewSection(
                requestModel: updatedRequest,
                requestController: requestController,
              ),

            // ========== Document References ==========
            if (hasDocRefs) ...[
              const SizedBox(height: BSizes.xs),
              BDocumentReference(request: updatedRequest),
              BViewItemsButton(requestId: updatedRequest.id),
            ],

            // ========== Proof of Delivery (For Delivery status only) ==========
            if (updatedRequest.status == BTexts.statusForDelivery) ...[
              // Before drop off the courier can uncheck items the client will
              // not receive (backload) with a required reason each; hidden
              // automatically when the request has no item list.
              BackloadItemsSection.editable(
                key: ValueKey('backload-items-${updatedRequest.id}'),
                requestModel: updatedRequest,
                requestController: requestController,
              ),
              const SizedBox(height: BSizes.md),
              const BTextDivider(text: 'Proof of Delivery'),
              const SizedBox(height: BSizes.sm),
              BProofPhotoList(
                requestId: updatedRequest.id,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: BSizes.xs),
              const Divider(),
              const SizedBox(height: BSizes.xs),
              const SizedBox(height: BSizes.xs),
              const Divider(),
              const SizedBox(height: BSizes.xs),
              TextFormField(
                controller: requestController.formState.receiver,
                autocorrect: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Iconsax.user_tick),
                  labelText: 'Receiver',
                ),
              ),
              const SizedBox(height: BSizes.xs),
              Obx(
                () => TextButton.icon(
                  onPressed: () =>
                      BFullScreenLoader.showRequestTransportSignatureDialog(
                    context,
                    requestController,
                  ),
                  icon: Icon(
                    requestController
                                .formState.receiverSignatureBytes.value ==
                            null
                        ? Iconsax.edit
                        : Iconsax.document_upload,
                    color: textColor,
                  ),
                  label: Text(
                    requestController
                                .formState.receiverSignatureBytes.value ==
                            null
                        ? 'Capture Signature'
                        : 'Signature Captured (Tap to Redo)',
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),
              Obx(() {
                if (requestController
                        .formState.receiverSignatureBytes.value !=
                    null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: BSizes.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Captured Signature:',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: BSizes.xs),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: BColors.grey),
                          ),
                          child: Image.memory(
                            requestController
                                .formState.receiverSignatureBytes.value!,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ],
        );
      },
    );
  }

  // Replaced by reusable widget: use `ImagePreviewDialog.show(context, path)`
}
