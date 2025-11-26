import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

import '../../../../../common/widgets/dialogs/request_image_dialog.dart';
import '../../../../../data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';

class PullOutRequestModalHeader extends StatelessWidget {
  const PullOutRequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final PullOutModel requestModel;

  String _formatDate(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    try {
      final dt = DateTime.parse(norm);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final Color textColor = dark ? BColors.light : BColors.black;

    final hasAddress = requestModel.client.address.isNotEmpty;
    final hasRequestedBy = requestModel.requestedBy.isNotEmpty;
    final hasPullOutDate = requestModel.pullOutDate.isNotEmpty;
    final hasReleasedBy = requestModel.releasedBy.isNotEmpty;
    final hasSlip = requestModel.slipNo.isNotEmpty;
    final hasTrip = requestModel.tripTicketNumber.isNotEmpty;
    final hasIrrfNumber = requestModel.irrfNumber.isNotEmpty;
    final hasIrrfDate = requestModel.irrfDate.isNotEmpty;
    final hasReasonForReturn = requestModel.reasonForReturn.isNotEmpty;

    final PullOutController requestController = Get.find();
    final userController = Get.find<UserInitialController>();
    final MobileController mobileController = Get.find();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          BProductTitleText(
            title: requestModel.client.name.isNotEmpty
                ? requestModel.client.name
                : (requestModel.slipNo.isNotEmpty
                    ? 'Slip: ${requestModel.slipNo}'
                    : 'Pull-Out Request'),
            maxLines: 2,
            bold: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
          if (hasAddress) ...[
            const SizedBox(height: BSizes.xxs),
            BProductTitleText(
              title: requestModel.client.address,
              maxLines: 2,
              smallSize: true,
              fontColor: dark ? BColors.light : BColors.black,
            ),
          ],
          if (hasRequestedBy || hasPullOutDate) ...[
            const SizedBox(height: BSizes.sm),
            const BTextDivider(text: 'Pull out Info'),
            Row(
              children: [
                if (hasRequestedBy)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Requested By',
                      value: requestModel.requestedBy,
                      showLabel: false,
                      icon: Iconsax.user,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (hasRequestedBy && hasPullOutDate)
                  const SizedBox(width: BSizes.xs),
                if (hasPullOutDate)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Pull-Out Date',
                      value: _formatDate(requestModel.pullOutDate),
                      showLabel: false,
                      icon: Iconsax.calendar_1,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
          if (hasTrip) ...[
            Row(
              children: [
                if (hasSlip && hasTrip) const SizedBox(width: BSizes.xs),
                if (hasTrip)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Trip Ticket No',
                      value: requestModel.tripTicketNumber,
                      showLabel: false,
                      copyable: true,
                      icon: Iconsax.ticket,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
          if (hasIrrfNumber || hasIrrfDate || hasReasonForReturn) ...[
            const BTextDivider(text: 'IRRF'),
            Row(
              children: [
                if (hasIrrfNumber)
                  Expanded(
                    child: BLabelValueText(
                      label: 'IRRF No',
                      value: requestModel.irrfNumber,
                      showLabel: false,
                      copyable: true,
                      icon: Iconsax.receipt_2,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (hasIrrfNumber && hasIrrfDate)
                  const SizedBox(width: BSizes.xs),
                if (hasIrrfDate)
                  Expanded(
                    child: BLabelValueText(
                      label: 'IRRF Date',
                      value: _formatDate(requestModel.irrfDate),
                      showLabel: false,
                      icon: Iconsax.calendar_1,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasSlip)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Slip No',
                      value: requestModel.slipNo,
                      showLabel: false,
                      copyable: true,
                      icon: Iconsax.document,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (hasReasonForReturn)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Reason',
                      value: requestModel.reasonForReturn,
                      showLabel: false,
                      maxLines: 3,
                      icon: Iconsax.message_text,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            if (hasReleasedBy) ...[
              const SizedBox(height: BSizes.sm),
              Center(
                child: BLabelValueText(
                  label: 'Released By',
                  value: requestModel.releasedBy,
                  showLabel: false,
                  icon: Iconsax.user_cirlce_add,
                  padding: EdgeInsets.zero,
                ),
              ),
              CapturedSignatureImage(requestId: requestModel.id),
              ViewDeliveredItemButton(
                textColor: textColor,
                onPressed: () {
                  final requestIdForDb = requestModel.id;
                  showRequestImageDialog(context,
                      requestId: requestIdForDb,
                      fetchIfMissing: true,
                      semanticsLabel:
                          'Delivered item image for request ${requestModel.id}',
                      apiController: 'RequestPullOutReturnPickUp');
                },
              ),
            ],
          ],

          /// -- For In Transit --
          if (requestModel.requestStatus == BTexts.statusNewRequest) ...[
            const BTextDivider(text: 'Delivery Info'),
            const SizedBox(height: BSizes.spaceBtwItems),
            BTextFormField(
              controller: requestController.formState.tripTicketController,
              label: 'Trip Ticket No',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
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
                      controller: requestController.formState.driverController,
                      getValue: (u) => u.initial,
                      getDisplay: (u) => u.initial,
                      onChanged: (UserModel? value) {
                        requestController.formState.driverController.text =
                            value?.initial ?? '';
                      },
                    ),
                  ),
                  const SizedBox(width: BSizes.spaceBtwItems),
                  Expanded(
                    child: DropdownList<UserModel>(
                      label: 'Helper',
                      dropdownList: users,
                      controller: requestController.formState.helperController,
                      getValue: (u) => u.initial,
                      getDisplay: (u) => u.initial,
                      onChanged: (UserModel? value) {
                        requestController.formState.helperController.text =
                            value?.initial ?? '';
                      },
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: BSizes.spaceBtwItems),
            Obx(() {
              final mobiles =
                  mobileController.mobile.map((m) => m.toJson()).toList();
              return BDropDownDynamicList(
                icon: Iconsax.truck,
                label: 'Vehicle',
                dropdownList: mobiles,
                controller: requestController.formState.mobile,
                valueKey: 'MobileID',
                displayKey: 'MobileName',
              );
            }),
          ],
        ],
      ),
    );
  }
}
