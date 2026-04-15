import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/backload_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Full-screen page opened when a user long-presses a transaction for back-load.
///
/// Displays the Standard Delivery `InsertDto` fields in **read-only** mode,
/// with only `deliveryDate` editable and a required remarks dropdown.
///
/// **Important:** Call `controller.initForRequest(model)` before navigating
/// to this page so the form is reset and pre-populated.
class BackLoadTransactionPage extends GetView<BackLoadController> {
  final StandardDeliveryModel requestModel;

  const BackLoadTransactionPage({super.key, required this.requestModel});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final request = requestModel;
    final textColor = dark ? BColors.light : BColors.black;
    final cardBg = dark ? BColors.dark : BColors.white;

    return Scaffold(
      backgroundColor: dark ? BColors.black : BColors.light,
      appBar: BAppBar(
        showBackArrow: true,
        leadingOnPressed: () => Navigator.of(context).pop(),
        title: Text(
          'Back Load',
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    // ── Scrollable content ──────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(BSizes.defaultSpace),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Header Card ────────────────────────────
                            BRoundedContainer(
                              showBorder: true,
                              borderColor:
                                  dark ? BColors.darkerGrey : BColors.grey,
                              backgroundColor: cardBg,
                              padding: const EdgeInsets.all(BSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Client Name
                                  if (request.client.name.isNotEmpty)
                                    BProductTitleText(
                                      title: request.client.name,
                                      maxLines: 3,
                                      bold: true,
                                      fontColor: textColor,
                                    ),
                                  // Client Address
                                  if (request.client.address.isNotEmpty) ...[
                                    const SizedBox(height: BSizes.xs),
                                    BProductTitleText(
                                      title: request.client.address,
                                      maxLines: 3,
                                      smallSize: true,
                                      fontColor: textColor,
                                    ),
                                  ],
                                  // Status + Preference chips
                                  const SizedBox(height: BSizes.sm),
                                  Wrap(
                                    spacing: BSizes.sm,
                                    runSpacing: BSizes.xs,
                                    children: [
                                      StatusChip(
                                          status: request.status,
                                          compact: false),
                                      if (request.preference.isNotEmpty)
                                        StatusChip(
                                            status: request.preference,
                                            compact: false),
                                    ],
                                  ),
                                  const SizedBox(height: BSizes.sm),

                                  // Shipping Method + Delivery Terms (side by side)
                                  if (request.shippingMethod.isNotEmpty ||
                                      request.deliveryTerms.isNotEmpty)
                                    Row(
                                      children: [
                                        if (request.shippingMethod.isNotEmpty)
                                          Expanded(
                                            child: BLabelValueText(
                                              label: 'Shipping',
                                              value: request.shippingMethod,
                                              showLabel: false,
                                              icon: Iconsax.ship,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        if (request.shippingMethod.isNotEmpty &&
                                            request.deliveryTerms.isNotEmpty)
                                          const SizedBox(width: BSizes.xs),
                                        if (request.deliveryTerms.isNotEmpty)
                                          Expanded(
                                            child: BLabelValueText(
                                              label: 'Terms',
                                              value: request.deliveryTerms,
                                              showLabel: false,
                                              icon: Iconsax.truck,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                      ],
                                    ),

                                  // Delivery Date + Requested By (side by side)
                                  if (request.deliveryDate.isNotEmpty ||
                                      request.requestBy.isNotEmpty) ...[
                                    const SizedBox(height: BSizes.xs),
                                    Row(
                                      children: [
                                        if (request.deliveryDate.isNotEmpty)
                                          Expanded(
                                            child: BLabelValueText(
                                              label: 'Delivery Date',
                                              value: BFormatter.formatDate3(
                                                  request.deliveryDate),
                                              showLabel: false,
                                              icon: Iconsax.calendar_1,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        if (request.deliveryDate.isNotEmpty &&
                                            request.requestBy.isNotEmpty)
                                          const SizedBox(width: BSizes.xs),
                                        if (request.requestBy.isNotEmpty)
                                          Expanded(
                                            child: BLabelValueText(
                                              label: 'Requested By',
                                              value: request.requestBy,
                                              showLabel: false,
                                              icon: Iconsax.user,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],

                                  // Created By
                                  if (request.createdBy.isNotEmpty) ...[
                                    const SizedBox(height: BSizes.xs),
                                    BLabelValueText(
                                      label: 'Created By',
                                      value: request.createdBy,
                                      showLabel: false,
                                      icon: Iconsax.profile_circle,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: BSizes.spaceBtwItems),

                            // ── Back Load Form Card ────────────────────
                            const BTextDivider(text: 'Back Load Details'),
                            const SizedBox(height: BSizes.sm),
                            BRoundedContainer(
                              showBorder: true,
                              borderColor:
                                  dark ? BColors.darkerGrey : BColors.grey,
                              backgroundColor: cardBg,
                              padding: const EdgeInsets.all(BSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Delivery Date — EDITABLE
                                  Text(
                                    'New Delivery Date *',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                  ),
                                  const SizedBox(height: BSizes.sm),
                                  BTextFormField(
                                    controller:
                                        controller.deliveryDateController,
                                    label: 'Select delivery date',
                                    readOnly: true,
                                    prefixIcon: Iconsax.calendar_edit,
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final raw = controller
                                              .selectedDeliveryDate.value ??
                                          now;
                                      // Clamp so initialDate is never before firstDate
                                      final initial =
                                          raw.isBefore(now) ? now : raw;
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: initial,
                                        firstDate: now,
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        controller.selectedDeliveryDate.value =
                                            picked;
                                        controller.deliveryDateController.text =
                                            DateFormat('yyyy-MM-dd')
                                                .format(picked);
                                      }
                                    },
                                  ),
                                  const SizedBox(
                                      height: BSizes.spaceBtwSections),

                                  // Remarks dropdown
                                  Text(
                                    'Reason for Back Load *',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                  ),
                                  const SizedBox(height: BSizes.sm),
                                  Obx(() {
                                    final selected =
                                        controller.selectedRemarks.value;
                                    return DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        hintText: 'Select reason',
                                        prefixIcon: const Icon(
                                            Iconsax.message_question),
                                      ),
                                      value: selected,
                                      items: BackLoadController.remarksOptions
                                          .map((r) => DropdownMenuItem(
                                              value: r, child: Text(r)))
                                          .toList(),
                                      onChanged: (v) =>
                                          controller.selectedRemarks.value = v,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Required'
                                          : null,
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: BSizes.spaceBtwSections),
                          ],
                        ),
                      ),
                    ),

                    // ── Fixed bottom submit button ─────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: BSizes.defaultSpace,
                        vertical: BSizes.md,
                      ),
                      decoration: BoxDecoration(
                        color: dark ? BColors.black : BColors.light,
                        border: Border(
                          top: BorderSide(
                            color: dark ? BColors.darkerGrey : BColors.grey,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Obx(() => ElevatedButton.icon(
                            onPressed: controller.isSaving.value
                                ? null
                                : () async {
                                    final success = await controller
                                        .submitBackLoad(requestModel);
                                    if (success && context.mounted) {
                                      Navigator.of(context).pop(true);
                                    }
                                  },
                            icon: controller.isSaving.value
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Iconsax.send_1),
                            label: const Text('Submit Back Load'),
                          )),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
