import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

import 'data/controllers/navigation_controller.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;
    final dark = BHelperFunctions.isDarkMode(context);

    return SafeArea(
      top: false,
      bottom: !isGestureNavigation,
      child: Scaffold(
        bottomNavigationBar: Obx(
          () => CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            onTap: (index) => controller.changeScreen(index),
            index: controller.selectedIndex.value,
            height: 70,
            color: dark ? BColors.black : BColors.light,
            items: controller.items,
          ),
        ),
        body: Obx(() => controller.screens[controller.selectedIndex.value]),
      ),
    );
  }
}
