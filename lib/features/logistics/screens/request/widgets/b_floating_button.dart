import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/b_request_form.dart';

import '../../../../../base/utils/constants/colors.dart';

class BFloatingButton extends StatelessWidget {
  const BFloatingButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100), color: BColors.primary),
        child: IconButton(
          onPressed: () => Get.to(() => const BRequestForm()),
          icon: Icon(Iconsax.add),
          color: BColors.white,
        ));
  }
}