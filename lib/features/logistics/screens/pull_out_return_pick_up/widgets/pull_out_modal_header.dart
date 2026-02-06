import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

class PullOutRequestModalHeader extends StatelessWidget {
  const PullOutRequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final PullOutModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final hasAddress = requestModel.client.address.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Client Name
        BProductTitleText(
          title: requestModel.client.name,
          maxLines: 2,
          bold: true,
          fontColor: dark ? BColors.light : BColors.black,
        ),
        // Client Address
        if (hasAddress) ...[
          const SizedBox(height: BSizes.xs),
          BProductTitleText(
            title: requestModel.client.address,
            maxLines: 2,
            smallSize: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
        ],
        // Status Chip
        const SizedBox(height: BSizes.xs),
        StatusChip(
          status: requestModel.requestStatus,
          compact: false,
        ),
      ],
    );
  }
}
