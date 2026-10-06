import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

import '../../../base/utils/constants/sizes.dart';

class BAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BAppBar(
      {super.key,
      this.title,
      this.showBackArrow = false,
      this.leadingIcon,
      this.actions,
      this.leadingOnPressed});

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final barTheme = Theme.of(context).appBarTheme;
    // A department theme with a coloured bar (Collection) sets these; the
    // base theme leaves them null and keeps the transparent bar it had.
    final arrowColor =
        barTheme.foregroundColor ?? (dark ? BColors.white : BColors.dark);
    // The bar is inset from the screen edges, so the gutters are filled
    // with the bar colour or a coloured bar would float between two strips.
    return ColoredBox(
      color: barTheme.backgroundColor ?? Colors.transparent,
      child: Padding(
      padding: EdgeInsets.symmetric(horizontal: BSizes.md),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackArrow
            ? IconButton(onPressed: () => Get.back(), icon: Icon(Iconsax.arrow_left, color: arrowColor))
            : leadingIcon != null
                ? IconButton(onPressed: leadingOnPressed, icon: Icon(leadingIcon))
                : null,
        title: title,
        actions: actions,
      ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(BDevicesUtils.getAppBarHeight());
}
