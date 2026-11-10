import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_pull_out_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_view_items_button.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/commute_id.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/widgets/trip_ticket_input.dart';
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

  /// True when the request belongs to the Stock Receive category, which is
  /// dispatched on the create form instead of by Release.
  bool _isStockReceiveCategory(PullOutModel request) {
    if (request.formCategoryId == FormCategoryIds.stockReceive) return true;
    try {
      final categories = Get.find<RequestController>().formCategories;
      final name = categories
              .firstWhereOrNull((c) => c.id == request.formCategoryId)
              ?.name ??
          '';
      return FormCategoryConstants.fromCategoryName(name) ==
          FormCategoryType.stockReceive;
    } catch (_) {
      return false;
    }
  }

  /// Display name of the vehicle saved on the request, or its id when the
  /// vehicle list has not loaded.
  String _vehicleName(MobileController mobileController, int? mobileId) {
    if (mobileId == null || mobileId == 0) return '';
    final id = mobileId.toString();
    return mobileController.mobile
            .firstWhereOrNull((m) => m.mobileID == id)
            ?.mobileName ??
        id;
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
    final isStockReceive = _isStockReceiveCategory(requestModel);
    final isNewRequest = requestModel.requestStatus == BTexts.statusNewRequest;

    // Pull Out: Release sets In Transit and enters the trip ticket, driver,
    // helper, and vehicle here. Stock Receive gets them on the create form;
    // the Courier only fills them in here for an older request saved without
    // them (the In Transit check would otherwise have nothing to pass).
    // A commuting driver's request carries a Commute ID and no vehicle.
    final hasStockReceiveDispatchInfo =
        requestModel.tripTicketNumber.trim().isNotEmpty &&
            requestModel.driver.trim().isNotEmpty &&
            ((requestModel.mobileID ?? 0) != 0 ||
                BCommuteId.isCommuteId(requestModel.tripTicketNumber));
    final showDeliveryInputs = isNewRequest &&
        (isStockReceive
            ? role.contains(BTexts.roleCourier) && !hasStockReceiveDispatchInfo
            : role.contains(BTexts.roleRelease));

    final tripTicket = requestModel.tripTicketNumber.trim();
    final vehicle = _vehicleName(mobileController, requestModel.mobileID);
    final showTripInfo =
        isStockReceive && (tripTicket.isNotEmpty || vehicle.isNotEmpty);

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
        // ========== BODY: Trip Info (Stock Receive, read-only) ==========
        if (showTripInfo) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Trip Info'),
          const SizedBox(height: BSizes.sm),
          Row(
            children: [
              if (tripTicket.isNotEmpty)
                Expanded(
                  child: BLabelValueText(
                    label: BCommuteId.label(tripTicket),
                    value: tripTicket,
                    // Spell out "Commute ID" so it is not read as a trip ticket.
                    showLabel: BCommuteId.isCommuteId(tripTicket),
                    copyable: true,
                    icon: Iconsax.ticket,
                    padding: EdgeInsets.zero,
                  ),
                ),
              if (tripTicket.isNotEmpty && vehicle.isNotEmpty)
                const SizedBox(width: BSizes.xs),
              if (vehicle.isNotEmpty)
                Expanded(
                  child: BLabelValueText(
                    label: 'Vehicle',
                    value: vehicle,
                    showLabel: false,
                    icon: Iconsax.truck,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],

        if (showDeliveryInputs) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Delivery Info'),
          const SizedBox(height: BSizes.spaceBtwItems),
          TripTicketInput(
            tripTicket: requestController.formState.tripTicketController,
            commute: requestController.formState.commute,
            vehicle: requestController.formState.mobile,
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
            // A commuting driver has no vehicle to pick.
            if (requestController.formState.commute.isOn.value) {
              return const SizedBox.shrink();
            }
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
