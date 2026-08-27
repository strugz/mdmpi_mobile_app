import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';

class PickUpRequestModalHeader extends StatelessWidget {
  const PickUpRequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final PickUpModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    final hasAddress = requestModel.client.address.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BProductTitleText(
            title: requestModel.client.name,
            maxLines: 2,
            bold: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
          if (hasAddress) ...[
            const SizedBox(height: BSizes.xxs),
            BLabelValueText(
              label: 'Address',
              value: requestModel.client.address,
              showLabel: false,
              maxLines: 3,
              copyable: true,
              smallSize: true,
            )
          ],
          const SizedBox(height: BSizes.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(status: requestModel.status, compact: false),
          ),
        ],
      ),
    );
  }
}
