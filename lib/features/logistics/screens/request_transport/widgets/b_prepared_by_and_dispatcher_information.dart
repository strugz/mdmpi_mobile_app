import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

class BPreparedByAndDispatcherInformation
    extends StatelessWidget {
  const BPreparedByAndDispatcherInformation(
      {super.key, required this.request, required this.userController});

  final StandardDeliveryModel request;
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (request.deliveredBy.isNotEmpty)
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end, // Align text to the end
                children: [
                  Row(
                    children: [
                      BProductTitleText(
                        title: "Dispatcher: ${request.deliveredBy}",
                        maxLines: 2,
                        smallSize: true,
                        fontColor: textColor,
                      ),
                    ],
                  ),
                ],
              ),
            if (request.helper.isNotEmpty)
              BProductTitleText(
                title: "Helper: ${request.helper}",
                maxLines: 2,
                smallSize: true,
                fontColor: textColor,
              ),
          ],
        ),
        BProductTitleText(
          title: "Item Prepared By: ${request.itemPreparedBy}",
          maxLines: 2,
          smallSize: true,
          fontColor: textColor,
        ),
      ],
    );
  }
}
