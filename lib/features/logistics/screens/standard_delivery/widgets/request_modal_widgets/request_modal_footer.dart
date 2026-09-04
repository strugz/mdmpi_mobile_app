import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_delivery_details_section.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/reassign_delivery_crew_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_proof_photo_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_mobile.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// Footer widget for the Standard Delivery request modal.
///
/// Displays Delivery Info form (driver/helper/mobile) for the preparing user,
/// proof capture for "For Delivery" status, receiver input,
/// signature capture, and the [BDeliveryDetailsSection] for completed deliveries.
class RequestModalFooter extends StatelessWidget {
  const RequestModalFooter({
    super.key,
    required this.requestModel,
    required this.requestController,
  });

  final StandardDeliveryModel requestModel;
  final IDeliveryRequestController requestController;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final iconColor = dark ? BColors.light : BColors.black;
    final userController = Get.find<UserInitialController>();

    // Determine request ID for database lookups
    final requestIdForDb =
        requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;

    final isPreparingUser =
        requestModel.status == BTexts.statusGettingSuppliesReady &&
            requestModel.itemPreparedBy ==
                requestController.userController.user.value.initial;

    // Release can re-assign the driver/helper after preparation, while the
    // request is Item Prepared or For Delivery.
    final canReassignCrew = requestController.userController.user.value.role
            .contains(BTexts.roleRelease) &&
        (requestModel.status == BTexts.statusItemPrepared ||
            requestModel.status == BTexts.statusForDelivery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- Delivery Info (for preparing user) --
        if (isPreparingUser) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Delivery Info'),
          const SizedBox(height: BSizes.spaceBtwItems),
          Obx(() {
            final users = userController.userList.toList();
            if (users.isEmpty) {
              return const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2));
            }
            return Row(
              children: [
                Expanded(
                  child: DropdownList<UserModel>(
                    label: 'Driver',
                    dropdownList: users,
                    controller: requestController.formState.selectedDriver,
                    getValue: (u) => u.initial,
                    getDisplay: (u) => u.initial,
                    onChanged: (UserModel? value) {
                      requestController.formState.selectedDriver.text =
                          value?.initial ?? '';
                    },
                  ),
                ),
                const SizedBox(width: BSizes.spaceBtwItems),
                Expanded(
                  child: DropdownList<UserModel>(
                    label: 'Helper',
                    dropdownList: users,
                    controller: requestController.formState.selectedHelper,
                    getValue: (u) => u.initial,
                    getDisplay: (u) => u.initial,
                    onChanged: (UserModel? value) {
                      requestController.formState.selectedHelper.text =
                          value?.initial ?? '';
                    },
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: BSizes.spaceBtwItems),
          BMobile(requestController: requestController),
        ],

        /// -- Re-assign Driver / Helper (Release, after preparation) --
        if (canReassignCrew)
          ReassignDeliveryCrewSection(
            requestModel: requestModel,
            requestController: requestController,
          ),

        /// -- Proof of Delivery (for For Delivery status) --
        if (requestModel.status == BTexts.statusForDelivery) ...[
          const SizedBox(height: BSizes.md),
          const BTextDivider(text: 'Proof of Delivery'),
          const SizedBox(height: BSizes.sm),
          BProofPhotoList(
            requestId: requestModel.id,
            iconColor: iconColor,
            textColor: textColor,
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          BTextFormField(
            controller: requestController.formState.receiver,
            label: 'Received By',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: BSizes.sm),
          Obx(
            () => Center(
              child: TextButton.icon(
                onPressed: () =>
                    BFullScreenLoader.showRequestTransportSignatureDialog(
                        context, requestController),
                icon: Icon(
                  requestController.formState.receiverSignatureBytes.value ==
                          null
                      ? Iconsax.edit
                      : Iconsax.document_upload,
                  color: textColor,
                ),
                label: Text(
                  requestController.formState.receiverSignatureBytes.value ==
                          null
                      ? 'Capture Signature'
                      : 'Signature Captured (Tap to Redo)',
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          ),
          Obx(() {
            if (requestController.formState.receiverSignatureBytes.value !=
                null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: BSizes.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Captured Signature:',
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: BSizes.xs),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: BColors.grey),
                        ),
                        child: Image.memory(requestController
                            .formState.receiverSignatureBytes.value!),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],

        /// -- Delivery Details --
        BDeliveryDetailsSection(
          driver: requestModel.deliveredBy,
          helper: requestModel.helper,
          receivedBy: requestModel.receiver,
          receivedByLabel: 'Received By',
          departedAt: requestModel.deliveredAt,
          completedAt: requestModel.deliveredEndAt,
          completedAtLabel: 'Delivered At',
          requestId: requestIdForDb,
          apiController: 'Request',
          viewItemButtonLabel: 'Item Photo',
          dialogTitle: 'Delivered Item',
          imageProofTypes: const ['Proof', 'Proof_2', 'Proof_3'],
          showViewItemButton: requestModel.status == BTexts.statusDoneDelivery,
        ),
      ],
    );
  }
}
