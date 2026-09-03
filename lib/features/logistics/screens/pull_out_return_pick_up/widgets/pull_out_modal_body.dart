import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_pull_out_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_view_items_button.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// Body content for Pull Out modal - contains all sections except header
class PullOutModalBody extends StatelessWidget {
  const PullOutModalBody({
    super.key,
    required this.requestModel,
    this.controller,
  });

  final PullOutModel requestModel;

  /// Controller owning the form state the inputs write to. Defaults to
  /// [PullOutController]; Stock Receive passes its own controller so the
  /// module's validator reads the same form state the fields wrote to.
  final IPullOutRequestController? controller;

  /// True when the request belongs to the Pull Out / Return category (this
  /// modal is shared with Stock Receive, which has no item list).
  bool _isPullOutCategory(PullOutModel request) {
    try {
      final categories = Get.find<RequestController>().formCategories;
      final name = categories
              .firstWhereOrNull((c) => c.id == request.formCategoryId)
              ?.name ??
          '';
      return FormCategoryConstants.fromCategoryName(name) ==
          FormCategoryType.pullOutReturn;
    } catch (_) {
      return false;
    }
  }

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
    final hasRequestedBy = requestModel.requestedBy.isNotEmpty;
    final hasPullOutDate = requestModel.pullOutDate.isNotEmpty;
    final hasIrrfDate = requestModel.irrfDate.isNotEmpty;
    final hasReasonForReturn = requestModel.reasonForReturn.isNotEmpty;
    final hasIrrfNumber = requestModel.irrfNumber.isNotEmpty;


    final IPullOutRequestController requestController =
        controller ?? Get.find<PullOutController>();
    final userInitialController = Get.find<UserInitialController>();
    final MobileController mobileController = Get.find();
    final UserController userController = Get.find();

    final role = userController.user.value.role;
    // Show Delivery Info if user has Release role (Release can set In Transit
    // and enters the trip ticket, driver, helper, and vehicle).
    final hasReleaseRole = role.contains(BTexts.roleRelease);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========== SUB BODY: Pull out Info ==========
        if (hasRequestedBy || hasPullOutDate) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Pull out Info'),
          const SizedBox(height: BSizes.sm),
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
          if (hasReasonForReturn) ...[
            if (hasIrrfDate) const SizedBox(height: BSizes.sm),
            Row(
              children: [
                Expanded(
                  child: BLabelValueText(
                    label: 'Reason',
                    value: requestModel.reasonForReturn,
                    maxLines: 3,
                    icon: Iconsax.message_text,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          // Items are Pull Out-only (Stock Receive shares this modal but
          // carries no item list).
          if (_isPullOutCategory(requestModel) && requestModel.id.isNotEmpty)
            BViewItemsButton(requestId: requestModel.id),
        ],

        // ========== BODY: Delivery Info (for new requests) ==========
        if (requestModel.requestStatus == BTexts.statusNewRequest && hasReleaseRole) ...[
          const SizedBox(height: BSizes.sm),
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
            final users = userInitialController.userList.toList();
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
        const SizedBox(height: BSizes.spaceBtwItems),
        // ========== SUB BODY: IRRF ==========
        if (hasIrrfDate) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'IRRF'),
          const SizedBox(height: BSizes.sm),
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
              const SizedBox(width: BSizes.xs),
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
        ],
      ],
    );
  }
}
