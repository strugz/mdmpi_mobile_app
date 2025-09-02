import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

class ClientSearch extends StatelessWidget {
  const ClientSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 25,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const SizedBox(height: BSizes.md),
                BRoundedContainer(
                  backgroundColor: dark ? BColors.darkerGrey : BColors.light,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Iconsax.arrow_left)),
                      hintText: 'Search Here',
                    ),
                    onSubmitted: (value) {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
