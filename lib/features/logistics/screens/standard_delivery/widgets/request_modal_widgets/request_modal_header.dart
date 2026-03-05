import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Header widget for the Standard Delivery request modal.
///
/// Displays client name, address, and status chip.
/// Matches the design pattern of [PullOutRequestModalHeader].
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Client Name - responsive with flexible text wrapping
        if (requestModel.client.name.isNotEmpty)
          BProductTitleText(
            title: requestModel.client.name,
            maxLines: 3,
            bold: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
        // Client Address - responsive
        if (hasAddress) ...[
          const SizedBox(height: BSizes.xs),
          BProductTitleText(
            title: requestModel.client.address,
            maxLines: 3,
            smallSize: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
        ],
        // Status Chip - responsive
        if (requestModel.status.isNotEmpty) ...[
          const SizedBox(height: BSizes.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              status: requestModel.status,
              compact: false,
            ),
          ),
        ],
      ],
    );
  }
}
