import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

class BTabBar extends StatelessWidget implements PreferredSizeWidget {
  const BTabBar({super.key, required this.tabs});

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Material(
      color: dark ? BColors.black : BColors.white,
      child: TabBar(
        tabs: tabs,
        isScrollable: true,
        indicatorColor: BColors.primary,
        labelColor: dark ? BColors.white : BColors.primary,
        unselectedLabelColor: BColors.darkGrey,
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(BDevicesUtils.getAppBarHeight());


}
