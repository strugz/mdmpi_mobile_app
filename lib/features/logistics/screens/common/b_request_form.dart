import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/grid_layout.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';

class BRequestForm extends StatelessWidget {
  const BRequestForm({
    super.key,
    required this.labels,
    required this.pages,
    required this.iconPaths,
  });

  final List<String> labels;
  final List<StatelessWidget> pages;
  final List<String> iconPaths;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.all(BSizes.spaceBtwItems),
      child: BGridLayout(
        itemCount: labels.length,
        crossAxisCount: 3,
        mainAxisExtent: 110, // keep squares consistent height
        itemBuilder: (context, index) {
          return InkWell(
            borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
            onTap: () {
              Get.to(() => pages[index]);
            },
            child: BRoundedContainer(
              backgroundColor: dark ? BColors.black : BColors.light,
              radius: BSizes.cardRadiusLg,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconPaths[index],
                    width: 52,
                    height: 52,
                    color: dark ? BColors.white : BColors.black,
                  ),
                  const SizedBox(height: BSizes.spaceBtwItems / 2),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
