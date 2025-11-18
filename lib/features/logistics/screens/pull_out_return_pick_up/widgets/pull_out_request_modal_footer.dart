import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

import '../../../../../../base/utils/constants/colors.dart';
import '../../../../../../base/utils/constants/sizes.dart';
import '../../../../../../common/widgets/texts/product_title_text.dart';
import '../../../models/pull_out_model.dart';

class PullOutRequestModalFooter extends StatelessWidget {
  const PullOutRequestModalFooter({super.key, required this.requestModel});

  final PullOutModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    final hasDriver = requestModel.driver.isNotEmpty;
    final hasHelper = requestModel.helper.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDriver || hasHelper) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasDriver)
                BProductTitleText(
                  title: 'Driver: ${requestModel.driver}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
              if (hasHelper)
                BProductTitleText(
                  title: 'Helper: ${requestModel.helper}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
            ],
          ),
          const SizedBox(height: BSizes.xs),
        ],
      ],
    );
  }
}
