import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_fact_grid.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Header of the Standard Delivery request modal / page.
///
/// Client name, a tappable address (opens maps), the status chip, and a
/// labelled two-column grid of the request facts. Labels replace the old
/// icon-only rows: "RAL" or "Full" mean nothing without a name, and one
/// column of labels lets the eye scan instead of read.
class RequestModalHeader extends StatelessWidget {
  const RequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final StandardDeliveryModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final address = requestModel.client.address.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (requestModel.client.name.isNotEmpty)
          BProductTitleText(
            title: requestModel.client.name,
            maxLines: 3,
            bold: true,
            fontColor: textColor,
          ),
        // Address is the one fact a courier acts on — make it open maps.
        if (address.isNotEmpty) ...[
          const SizedBox(height: BSizes.xxs),
          InkWell(
            onTap: () => BDevicesUtils.launchUrl(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: textColor.withValues(alpha: 0.75)),
                  ),
                ),
                const SizedBox(width: BSizes.xs),
                Icon(Iconsax.location,
                    size: 14, color: textColor.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ],
        const SizedBox(height: BSizes.sm),
        // One status chip. Priority is a fact, not a second status.
        StatusChip(status: requestModel.status, compact: false),
        const SizedBox(height: BSizes.md),
        FutureBuilder<String?>(
          future: requestModel.itemCategoryID.isEmpty
              ? Future.value(null)
              : ItemCategoryRepository.instance
                  .fetchItemCategory(requestModel.itemCategoryID),
          builder: (context, snapshot) {
            return BFactGrid(
              textColor: textColor,
              facts: [
                BFact('Item category', snapshot.data ?? ''),
                BFact('Priority', requestModel.preference),
                BFact('Shipping', requestModel.shippingMethod),
                BFact('Terms', requestModel.deliveryTerms),
                BFact('Delivery date',
                    BFormatter.formatDate3(requestModel.deliveryDate)),
                BFact('Requested by', requestModel.requestBy),
              ],
            );
          },
        ),
      ],
    );
  }
}
