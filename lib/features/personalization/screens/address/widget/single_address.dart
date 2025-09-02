import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';

class BSingleAddress extends StatelessWidget {
  const BSingleAddress({super.key, required this.selectedAddress});

  final bool selectedAddress;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return BRoundedContainer(
      showBorder: true,
      padding: const EdgeInsets.all(BSizes.md),
      width: double.infinity,
      backgroundColor: selectedAddress
          ? BColors.primary.withOpacity(0.5)
          : Colors.transparent,
      borderColor: selectedAddress
          ? Colors.transparent
          : dark
              ? BColors.darkerGrey
              : BColors.grey,
      margin: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
      child: Stack(
        children: [
          Positioned(
            right: 5,
            top: 0,
            child: Icon(selectedAddress ? Iconsax.tick_circle5 : null,
                color: selectedAddress
                    ? dark
                        ? BColors.light
                        : BColors.dark
                    : null),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Juan Dela Cruz',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: BSizes.sm / 2),
              const Text('(+123) 456 7890', maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: BSizes.sm / 2),
              const Text('8256 Timmy Coves, South Liana, Maine, 87665, USA', softWrap: true),
            ],
          )
        ],
      ),
    );
  }
}
