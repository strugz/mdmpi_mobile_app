import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/grid_layout.dart';
import 'package:mdmpi_mobile_app/common/widgets/product/product_cards/product_card_vertical.dart';

import '../../../../base/utils/constants/sizes.dart';

class BSortableProducts extends StatelessWidget {
  const BSortableProducts({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField(
          onChanged: (value) {},
          decoration: InputDecoration(prefixIcon: Icon(Iconsax.sort)),
          items: ['Common', 'Rarely']
              .map((option) =>
              DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
        ),
        const SizedBox(height: BSizes.spaceBtwSections),

        /// Products
        BGridLayout(
            itemCount: 2,
            itemBuilder: (_, index) =>
            const BProductCardVertical(showAddButton: true))
      ],
    );
  }
}