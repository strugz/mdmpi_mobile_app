import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../controllers/request_transport_controller.dart';

class BClientSearch extends StatelessWidget {
  const BClientSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final requestTransportController = Get.find<RequestTransportController>();
    return Obx(
      () => InkWell(
        onTap: () {
          requestTransportController.onSearchHerePressed();
          requestTransportController.searchFocusNode.requestFocus();
        },
        child: requestTransportController.isSearching.value
            ? Column(
                children: [
                  BRoundedContainer(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    radius: 100,
                    margin: EdgeInsets.only(top: 10),
                    backgroundColor: BColors.darkerGrey,
                    child: TextField(
                      focusNode: requestTransportController.searchFocusNode,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: BColors.light),
                      onTapOutside: (event) {
                        requestTransportController.onSearchHerePressed();
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          if (value.length.bitLength > 1) {
                            requestTransportController
                                .addressTextController.text = value;
                            requestTransportController
                                .getCoordinatesFromPlace(value);
                            FocusScope.of(context).unfocus();
                          }
                        }
                      },
                      controller:
                          requestTransportController.addressTextController,
                      decoration: InputDecoration(
                        hintText: 'Search Here',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .apply(color: BColors.light),
                        border: InputBorder.none,
                        focusedBorder:
                            InputBorder.none, // Remove focused border
                        enabledBorder:
                            InputBorder.none, // Remove enabled border
                        suffixIcon: IconButton(
                            onPressed: () {
                              requestTransportController.searchFocusNode
                                  .requestFocus();
                              requestTransportController.addressTextController
                                  .clear();
                            },
                            icon: Icon(Iconsax.close_circle)),
                        prefixIcon: IconButton(
                          onPressed: () {
                            requestTransportController.onSearchHerePressed();
                          },
                          icon: Icon(Iconsax.arrow_left),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : BRoundedContainer(
                padding: EdgeInsets.symmetric(horizontal: 6),
                radius: 100,
                margin: EdgeInsets.only(top: 10),
                backgroundColor: BColors.darkerGrey,
                child: TextField(
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BColors.light),
                  controller: requestTransportController.addressTextController,
                  decoration: InputDecoration(
                    enabled: false,
                    hintStyle: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .apply(color: BColors.light),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none, // Remove focused border
                    enabledBorder: InputBorder.none, // Remove enabled border
                    prefixIcon: IconButton(
                      onPressed: () {
                        requestTransportController.onSearchHerePressed();
                      },
                      icon: Icon(Iconsax.location),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
