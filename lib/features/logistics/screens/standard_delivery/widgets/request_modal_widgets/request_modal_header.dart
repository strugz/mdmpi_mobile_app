import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Header widget for the Standard Delivery request modal.
///
/// Displays client name, address, status/preference chips,
/// item category, shipping method, delivery terms, delivery date,
/// and requested by.
class RequestModalHeader extends StatelessWidget {
  const RequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final StandardDeliveryModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final hasAddress = requestModel.client.address.isNotEmpty;
    final hasShippingMethod = requestModel.shippingMethod.isNotEmpty;
    final hasDeliveryTerms = requestModel.deliveryTerms.isNotEmpty;
    final hasDeliveryDate = requestModel.deliveryDate.isNotEmpty;
    final hasRequestBy = requestModel.requestBy.isNotEmpty;
    final hasItemCategory = requestModel.itemCategoryID.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Client Name
        if (requestModel.client.name.isNotEmpty)
          BProductTitleText(
            title: requestModel.client.name,
            maxLines: 3,
            bold: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
        // Client Address
        if (hasAddress) ...[
          const SizedBox(height: BSizes.xs),
          BProductTitleText(
            title: requestModel.client.address,
            maxLines: 3,
            smallSize: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
        ],
        // Status Chip + Preference Chip
        const SizedBox(height: BSizes.xs),
        Wrap(
          spacing: BSizes.sm,
          runSpacing: BSizes.xs,
          children: [
            StatusChip(status: requestModel.status, compact: false),
            StatusChip(status: requestModel.preference, compact: false),
          ],
        ),

        // Item Category (async lookup)
        if (hasItemCategory) ...[
          const SizedBox(height: BSizes.sm),
          FutureBuilder<String?>(
            future: ItemCategoryRepository.instance
                .fetchItemCategory(requestModel.itemCategoryID),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return BLabelValueText(
                label: 'Item Category',
                value: snapshot.data!,
                showLabel: false,
                icon: Iconsax.category,
                padding: EdgeInsets.zero,
              );
            },
          ),
        ],

        // Shipping Method + Delivery Terms
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

        // Delivery Date + Requested By
        if (hasDeliveryDate || hasRequestBy) ...[
          const SizedBox(height: BSizes.sm),
          Row(
            children: [
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
              if (hasDeliveryDate && hasRequestBy)
                const SizedBox(width: BSizes.xs),
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
            ],
          ),
        ],
      ],
    );
  }
}


