import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';

import '../../../../../../base/utils/constants/colors.dart';
import '../../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../models/standard_delivery_model.dart';

class RequestModalFooter extends StatelessWidget {
  const RequestModalFooter({super.key, required this.requestModel});

  final StandardDeliveryModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requestModel.deliveredBy.isNotEmpty) ...[
          BTextDivider(text: "Driver information"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Dispatcher
              if (requestModel.deliveredBy.isNotEmpty)
                BProductTitleText(
                  title: "Driver: ${requestModel.deliveredBy}",
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
              if (requestModel.helper.isNotEmpty)
                BProductTitleText(
                  title: "Helper: ${requestModel.helper}",
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                )
            ],
          ),
        ]
      ],
    );
  }
}
