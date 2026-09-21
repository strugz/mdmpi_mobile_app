import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

import 'data/controllers/navigation_controller.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    final dark = BHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    // The bar has to differ from the body behind it, or the curved notch and
    // the sliding button disappear. Collection takes its header navy so the
    // screen is bookended top and bottom, with the selected icon on a blue
    // disc and white icons throughout. Other departments keep the light bar.
    final isCollection =
        theme.scaffoldBackgroundColor == BCollectionColors.background;
    final barColor = dark
        ? BColors.black
        : (isCollection ? BCollectionColors.headerBackground : BColors.light);
    final buttonColor = isCollection ? BCollectionColors.primary : barColor;
    final iconColor = dark || isCollection ? BColors.white : BColors.dark;

    // Same shell layout as before item 15 (SafeArea around the Scaffold, so the
    // area under the tab bar is the Scaffold's own background), minus the
    // keyboard-height probe that used to switch the bottom padding off.
    return SafeArea(
      top: false,
      child: Scaffold(
        bottomNavigationBar: Obx(
          () => IconTheme(
            data: IconThemeData(color: iconColor),
            child: CurvedNavigationBar(
              backgroundColor: Colors.transparent,
              onTap: (index) => controller.changeScreen(index),
              index: controller.selectedIndex.value,
              height: 70,
              color: barColor,
              buttonBackgroundColor: buttonColor,
              // The package default is 600ms, which reads as a lag when the
              // tab is tapped many times a day.
              animationDuration: const Duration(milliseconds: 300),
              items: controller.items,
            ),
          ),
        ),
        body: Obx(() => controller.screens[controller.selectedIndex.value]),
      ),
    );
  }
}
