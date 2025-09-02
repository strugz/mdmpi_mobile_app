import 'package:flutter/material.dart';

import '../../../base/utils/constants/sizes.dart';

class BGridLayout extends StatelessWidget {
  const BGridLayout({
    super.key,
    required this.itemCount,
    this.mainAxisExtent  = 288,
    required this.itemBuilder, this.crossAxisCount = 2,
  });

  final int itemCount;
  final double? mainAxisExtent;
  final Widget? Function(BuildContext, int) itemBuilder;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: BSizes.gridViewSpacing,
        crossAxisSpacing: BSizes.gridViewSpacing,
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: itemBuilder,
    );
  }
}
