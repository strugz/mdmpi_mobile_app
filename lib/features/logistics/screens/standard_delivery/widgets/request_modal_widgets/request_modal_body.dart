import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_mobile.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// Body content for Standard Delivery modal — contains request info
/// display fields and form inputs for the "Getting Supplies Ready" status.
class RequestModalBody extends StatelessWidget {
  const RequestModalBody({
    super.key,
    required this.requestModel,
    required this.requestController,
  });

  final StandardDeliveryModel requestModel;
  final IDeliveryRequestController requestController;

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserInitialController>();

    final hasShippingMethod = requestModel.shippingMethod.isNotEmpty;
    final hasDeliveryTerms = requestModel.deliveryTerms.isNotEmpty;
    final hasDeliveryDate = requestModel.deliveryDate.isNotEmpty;
    final hasPreference = requestModel.preference.isNotEmpty;
    final hasRequestBy = requestModel.requestBy.isNotEmpty;
    final hasCreatedBy = requestModel.createdBy.isNotEmpty;
    final hasCreatedAt = requestModel.createdAt.isNotEmpty;
    final hasMobileName = requestModel.mobileName.isNotEmpty;

    final hasRequestInfo = hasShippingMethod ||
        hasDeliveryTerms ||
        hasDeliveryDate ||
        hasPreference ||
        hasRequestBy ||
        hasCreatedBy ||
        hasCreatedAt ||
        hasMobileName;

    final showPreparedBy = requestModel.status != BTexts.statusNewRequest &&
        requestModel.itemPreparedBy.isNotEmpty;
    final preparedByTitle =
        requestModel.status == BTexts.statusGettingSuppliesReady
            ? 'Preparing By: ${requestModel.itemPreparedBy}'
            : 'Prepared By: ${requestModel.itemPreparedBy}';

    final isPreparingUser =
        requestModel.status == BTexts.statusGettingSuppliesReady &&
            requestModel.itemPreparedBy ==
                requestController.userController.user.value.initial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========== SUB BODY: Request Info ==========
        if (hasRequestInfo) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Request Info'),
          const SizedBox(height: BSizes.sm),
          Row(
            children: [
              if (hasRequestBy)
                Expanded(
                  child: BLabelValueText(
                    label: 'Requested By',
                    value: requestModel.requestBy,
                    showLabel: false,
                    icon: Iconsax.user,
                    padding: EdgeInsets.zero,
                  ),
                ),
              if (hasRequestBy && hasDeliveryDate)
                const SizedBox(width: BSizes.xs),
              if (hasDeliveryDate)
                Expanded(
                  child: BLabelValueText(
                    label: 'Delivery Date',
                    value: BFormatter.formatDate2(requestModel.deliveryDate),
                    showLabel: false,
                    icon: Iconsax.calendar_1,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          if (hasShippingMethod || hasDeliveryTerms) ...[
            const SizedBox(height: BSizes.sm),
            Row(
              children: [
                if (hasShippingMethod)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Shipping Method',
                      value: requestModel.shippingMethod,
                      showLabel: false,
                      icon: Iconsax.ship,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (hasShippingMethod && hasDeliveryTerms)
                  const SizedBox(width: BSizes.xs),
                if (hasDeliveryTerms)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Delivery Terms',
                      value: requestModel.deliveryTerms,
                      showLabel: false,
                      icon: Iconsax.truck,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
          if (hasPreference) ...[
            const SizedBox(height: BSizes.sm),
            BLabelValueText(
              label: 'Preference',
              value: requestModel.preference,
              showLabel: false,
              icon: Iconsax.setting_2,
              padding: EdgeInsets.zero,
            ),
          ],
          if (hasCreatedBy || hasCreatedAt) ...[
            const SizedBox(height: BSizes.sm),
            Row(
              children: [
                if (hasCreatedBy)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Created By',
                      value: requestModel.createdBy,
                      showLabel: false,
                      icon: Iconsax.user_edit,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (hasCreatedBy && hasCreatedAt)
                  const SizedBox(width: BSizes.xs),
                if (hasCreatedAt)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Created At',
                      value: BFormatter.formatDate2(requestModel.createdAt),
                      showLabel: false,
                      icon: Iconsax.clock,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
          if (hasMobileName) ...[
            const SizedBox(height: BSizes.sm),
            BLabelValueText(
              label: 'Mobile',
              value: requestModel.mobileName,
              showLabel: false,
              icon: Iconsax.mobile,
              padding: EdgeInsets.zero,
            ),
          ],
        ],

        // ========== SUB BODY: Preparation Info ==========
        if (showPreparedBy ||
            requestModel.itemPreparedAt.isNotEmpty ||
            requestModel.tripTicketNumber.isNotEmpty) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Preparation Info'),
          const SizedBox(height: BSizes.sm),
          if (showPreparedBy)
            BLabelValueText(
              label: preparedByTitle,
              value: '',
              showLabel: true,
              icon: Iconsax.user_tick,
              padding: EdgeInsets.zero,
            ),
          if (requestModel.itemPreparedAt.isNotEmpty ||
              requestModel.itemPreparedEndAt.isNotEmpty) ...[
            const SizedBox(height: BSizes.sm),
            Row(
              children: [
                if (requestModel.itemPreparedAt.isNotEmpty)
                  Expanded(
                    child: BLabelValueText(
                      label: 'From',
                      value: BFormatter.formatDate2(
                          requestModel.itemPreparedAt),
                      showLabel: false,
                      icon: Iconsax.clock,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (requestModel.itemPreparedAt.isNotEmpty &&
                    requestModel.itemPreparedEndAt.isNotEmpty)
                  const SizedBox(width: BSizes.xs),
                if (requestModel.itemPreparedEndAt.isNotEmpty)
                  Expanded(
                    child: BLabelValueText(
                      label: 'To',
                      value: BFormatter.formatDate2(
                          requestModel.itemPreparedEndAt),
                      showLabel: false,
                      icon: Iconsax.clock,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
          if (requestModel.tripTicketNumber.isNotEmpty) ...[
            const SizedBox(height: BSizes.sm),
            BLabelValueText(
              label: 'Trip Ticket No',
              value: requestModel.tripTicketNumber,
              showLabel: false,
              copyable: true,
              icon: Iconsax.receipt_2,
              padding: EdgeInsets.zero,
            ),
          ],
        ],

        // ========== BODY: Delivery Info (for Getting Supplies Ready — current preparer) ==========
        if (isPreparingUser) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Delivery Info'),
          const SizedBox(height: BSizes.spaceBtwItems),
          if (requestModel.tripTicketNumber.isEmpty)
            TextFormField(
              controller: requestController.formState.tripTicketNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Trip Ticket No',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          if (requestModel.tripTicketNumber.isEmpty)
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
      ],
    );
  }
}

