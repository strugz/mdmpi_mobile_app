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

    final dark = BHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    // The bar has to differ from the body behind it, or the curved notch and
    // the sliding button disappear. On a white body (default theme) the bar
    // is light grey; on an off-white body (Collection) it is white.
    final onWhiteBody = theme.scaffoldBackgroundColor == Colors.white;
    final barColor = dark
        ? BColors.black
        : (onWhiteBody ? BColors.light : theme.colorScheme.surface);

    // Same shell layout as before item 15 (SafeArea around the Scaffold, so the
    // area under the tab bar is the Scaffold's own background), minus the
    // keyboard-height probe that used to switch the bottom padding off.
    return SafeArea(
      top: false,
      child: Scaffold(
        bottomNavigationBar: Obx(
          () => CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            onTap: (index) => controller.changeScreen(index),
            index: controller.selectedIndex.value,
            height: 70,
            color: barColor,
            buttonBackgroundColor: barColor,
            // The package default is 600ms, which reads as a lag when the
            // tab is tapped many times a day.
            animationDuration: const Duration(milliseconds: 300),
            items: controller.items,
          ),
        ),
        body: Obx(() => controller.screens[controller.selectedIndex.value]),
      ),
    );
  }
}
