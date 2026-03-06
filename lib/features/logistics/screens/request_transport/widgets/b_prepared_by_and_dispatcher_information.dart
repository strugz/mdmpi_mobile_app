
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';

class BPreparedByAndDispatcherInformation extends StatelessWidget {
  const BPreparedByAndDispatcherInformation({
    super.key,
    required this.requestController,
    required this.userController,
  });

  final IDeliveryRequestController requestController;
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    return Obx(() {
      final request = requestController.currentSelectedRequest.value;

      if (request == null) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BTextDivider(text: 'Delivery Information'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            if (request.deliveredBy.isNotEmpty) ...[
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
            ],
            if (request.helper.isNotEmpty)
              BProductTitleText(
                title: "Helper: ${request.helper}",
                maxLines: 2,
                smallSize: true,
                fontColor: textColor,
              ),
          ],
        ),
      ],
      );
    });
  }
}
