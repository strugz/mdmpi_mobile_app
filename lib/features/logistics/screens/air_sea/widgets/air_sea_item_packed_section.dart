import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/signature_capture_dialog.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';

/// Widget for handling Item Packed status transition to Received.
///
/// Captures receiver name and signature for the final receipt.
class AirSeaItemPackedSection extends StatelessWidget {
  const AirSeaItemPackedSection({super.key, required this.requestModel});

  final AirSeaModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<AirSeaController>();
    final cameraController = Get.find<CameraHandlerController>();

    // Add listener to trigger rebuild when dropdown changes
    controller.formState.endorsedToController.addListener(() {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.sm),
        const BTextDivider(text: 'Update Status'),
        const SizedBox(height: BSizes.sm),

        /// Status Dropdown
        BDropdown(
          controller: controller.formState.endorsedToController,
          label: 'Select Status',
          icon: Iconsax.status_up,
          dropdownList: const [
            'Endorsed to Guard',
            'Received',
            'For Dispatch',
          ],
        ),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Conditional fields based on selected status
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.formState.endorsedToController,
          builder: (context, value, child) {
            final selectedStatus = value.text;

            if (selectedStatus == 'Endorsed to Guard') {
              return _buildGuardFields(
                  context, controller, cameraController, dark);
            } else if (selectedStatus == 'Received') {
              return _buildReceiverFields(
                  context, controller, cameraController, dark);
            } else if (selectedStatus == 'For Dispatch') {
              return _buildDispatchFields(context, controller, dark);
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// Builds guard name and signature fields
  Widget _buildGuardFields(BuildContext context, AirSeaController controller, CameraHandlerController cameraController, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Guard Name Field
        BTextFormField(
          controller: controller.formState.receivedByController,
          label: 'Guard Name',
          prefixIcon: Iconsax.user,
        ),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Guard Signature Capture (using receiverSignatureBytes for all signatures)
        Center(
          child: Obx(() {
            final sig = controller.formState.receiverSignatureBytes.value;
            final hasSignature = sig != null && sig.isNotEmpty;

            return TextButton.icon(
              onPressed: () => BSignatureCaptureDialog.show(
                context: context,
                onSave: (bytes) => controller.formState.setSignature(bytes),
              ),
              icon: Icon(
                hasSignature ? Iconsax.document_upload : Iconsax.edit,
                color: dark ? BColors.light : BColors.black,
              ),
              label: Text(
                hasSignature
                    ? 'Signature Captured (Tap to Redo)'
                    : 'Capture Signature',
                style: TextStyle(color: dark ? BColors.light : BColors.black),
              ),
            );
          }),
        ),
        const SizedBox(height: BSizes.xs),

        /// Display captured signature
        Obx(() {
          final sig = controller.formState.receiverSignatureBytes.value;
          if (sig != null && sig.isNotEmpty) {
            return Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: BColors.grey),
                ),
                child: Image.memory(
                  sig,
                  height: 100,
                  width: 150,
                  fit: BoxFit.fill,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Proof Image Capture
        Center(
          child: Obx(() {
            return Column(
              children: [
                IconButton(
                  onPressed: () => Get.to(
                    () => BDropOffCapture(
                      title: 'Guard Receipt Proof',
                      onCapture: (camera) async =>
                          camera.takePictureWithAnimation(
                        requestModel.id,
                      ),
                    ),
                  ),
                  icon: Icon(Iconsax.camera,
                      size: 25, color: dark ? BColors.light : BColors.black),
                ),
                if (cameraController.imageProofPath.value.isNotEmpty)
                  BProductTitleText(
                    title: cameraController.imageProofPath.value,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.black,
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Builds receiver name and signature fields
  Widget _buildReceiverFields(BuildContext context, AirSeaController controller, CameraHandlerController cameraController, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Receiver Name Field
        BTextFormField(
          controller: controller.formState.receivedByController,
          label: 'Receiver Name',
          prefixIcon: Iconsax.user,
        ),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Waybill Number Field
        BTextFormField(
          controller: controller.formState.waybillNumberController,
          label: 'Waybill Number',
          prefixIcon: Iconsax.clipboard_text,
        ),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Receiver Signature Capture
        Center(
          child: Obx(() {
            final sig = controller.formState.receiverSignatureBytes.value;
            final hasSignature = sig != null && sig.isNotEmpty;

            return TextButton.icon(
              onPressed: () => BSignatureCaptureDialog.show(
                context: context,
                onSave: (bytes) => controller.formState.setSignature(bytes),
              ),
              icon: Icon(
                hasSignature ? Iconsax.document_upload : Iconsax.edit,
                color: dark ? BColors.light : BColors.black,
              ),
              label: Text(
                hasSignature
                    ? 'Signature Captured (Tap to Redo)'
                    : 'Capture Signature',
                style: TextStyle(color: dark ? BColors.light : BColors.black),
              ),
            );
          }),
        ),
        const SizedBox(height: BSizes.xs),

        /// Display captured signature
        Obx(() {
          final sig = controller.formState.receiverSignatureBytes.value;
          if (sig != null && sig.isNotEmpty) {
            return Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: BColors.grey),
                ),
                child: Image.memory(
                  sig,
                  height: 100,
                  width: 150,
                  fit: BoxFit.fill,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Proof Image Capture
        Center(
          child: Obx(() {
            return Column(
              children: [
                IconButton(
                  onPressed: () => Get.to(
                    () => BDropOffCapture(
                      title: 'Delivery Proof',
                      onCapture: (camera) async =>
                          camera.takePictureWithAnimation(
                        requestModel.id,
                      ),
                    ),
                  ),
                  icon: Icon(Iconsax.camera,
                      size: 25, color: dark ? BColors.light : BColors.black),
                ),
                if (cameraController.imageProofPath.value.isNotEmpty)
                  BProductTitleText(
                    title: cameraController.imageProofPath.value,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.black,
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Builds Trip Ticket No, Driver, Helper and Vehicle fields
  Widget _buildDispatchFields(BuildContext context, AirSeaController controller, bool dark) {
    final userController = Get.find<UserInitialController>();
    final mobileController = Get.find<MobileController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Trip Ticket Number Field
        BTextFormField(
          controller: controller.formState.tripTicketController,
          label: 'Trip Ticket No',
          prefixIcon: Iconsax.ticket,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Driver and Helper Dropdowns
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
                  controller: controller.formState.driverController,
                  getValue: (u) => u.initial,
                  getDisplay: (u) => u.initial,
                  onChanged: (UserModel? value) {
                    controller.formState.driverController.text =
                        value?.initial ?? '';
                  },
                ),
              ),
              const SizedBox(width: BSizes.spaceBtwItems),
              Expanded(
                child: DropdownList<UserModel>(
                  label: 'Helper',
                  dropdownList: users,
                  controller: controller.formState.helperController,
                  getValue: (u) => u.initial,
                  getDisplay: (u) => u.initial,
                  onChanged: (UserModel? value) {
                    controller.formState.helperController.text =
                        value?.initial ?? '';
                  },
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: BSizes.spaceBtwItems),

        /// Vehicle Dropdown
        Obx(() {
          final mobiles =
              mobileController.mobile.map((m) => m.toJson()).toList();
          return BDropDownDynamicList(
            icon: Iconsax.truck,
            label: 'Vehicle',
            dropdownList: mobiles,
            controller: controller.formState.vehicleController,
            valueKey: 'MobileID',
            displayKey: 'MobileName',
          );
        }),
      ],
    );
  }
}
