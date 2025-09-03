// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';

import '../../base/utils/constants/colors.dart';

class BShadowStyle {
  static final verticalProductShadow = BoxShadow(
      color: BColors.darkGrey.withOpacity(0.1),
      blurRadius: 50,
      spreadRadius: 7,
      offset: const Offset(0, 2));

  static final horizontalProductShadow = BoxShadow(
      color: BColors.darkGrey.withOpacity(0.1),
      blurRadius: 50,
      spreadRadius: 7,
      offset: const Offset(0, 2));
}
