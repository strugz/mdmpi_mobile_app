import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/text_strings.dart';

class BHomeAppBar extends StatelessWidget {
  const BHomeAppBar({
    super.key,
    this.title,
    this.actions,
  });

  final String? title;

  /// Buttons at the right of the bar (Collection's Light/Dark toggle).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();
    return BAppBar(
      actions: actions,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title ?? BTexts.dashboardTitle,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .apply(color: BColors.grey)),
          Obx(
            () {
              if (controller.profileLoading.value) {
                //  Display a shimmer loader while user profile is being loaded
                return BShimmerEffect(width: 80, height: 15);
              } else {
                return Text(controller.user.value.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .apply(color: BColors.white));
              }
            },
          ),
        ],
      ),
    );
  }
}
