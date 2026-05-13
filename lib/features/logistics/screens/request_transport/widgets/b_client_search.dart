import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../controllers/request_transport_controller.dart';
import '../../../controllers/standard_delivery_controller.dart';

class BClientSearch extends StatelessWidget {
  const BClientSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final requestTransportController = Get.find<RequestTransportController>();
    final standardDeliveryController = Get.find<StandardDeliveryController>();

    return Obx(
      () {
        // Check if saved location should be displayed
        final currentStatus = standardDeliveryController.currentSelectedRequest.value?.status;
        final isSavedLocationAvailable =
            currentStatus == BTexts.statusForDelivery &&
            requestTransportController.hasLocationAlternative.value;

        // If saved location available and not in search mode, show saved location
        if (isSavedLocationAvailable && !requestTransportController.isSearching.value) {
          return Column(
            children: [
              // Saved Location Display
              BRoundedContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                radius: 100,
                margin: const EdgeInsets.only(top: 10),
                backgroundColor: BColors.primary.withValues(alpha: 0.1),
                borderColor: BColors.primary,
                showBorder: true,
                child: Row(
                  children: [
                    Icon(
                      Iconsax.location_tick,
                      color: BColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Location',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            requestTransportController.currentLocationAlternative.value?.address ??
                            requestTransportController.addressTextController.text,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BColors.light,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Toggle to search mode to allow editing
                        requestTransportController.onSearchHerePressed();
                        requestTransportController.searchFocusNode.requestFocus();
                      },
                      icon: const Icon(Iconsax.edit, color: BColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Normal search widget (original logic)
        return InkWell(
          onTap: () {
            requestTransportController.onSearchHerePressed();
            requestTransportController.searchFocusNode.requestFocus();
          },
          child: requestTransportController.isSearching.value
              ? Column(
                  children: [
                    BRoundedContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      radius: 100,
                      margin: const EdgeInsets.only(top: 10),
                      backgroundColor: BColors.darkerGrey,
                      child: TextField(
                        focusNode: requestTransportController.searchFocusNode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: BColors.light),
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
                              InputBorder.none,
                          enabledBorder:
                              InputBorder.none,
                          suffixIcon: IconButton(
                              onPressed: () {
                                requestTransportController.searchFocusNode
                                    .requestFocus();
                                requestTransportController.addressTextController
                                    .clear();
                              },
                              icon: const Icon(Iconsax.close_circle)),
                          prefixIcon: IconButton(
                            onPressed: () {
                              requestTransportController.onSearchHerePressed();
                            },
                            icon: const Icon(Iconsax.arrow_left),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : BRoundedContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  radius: 100,
                  margin: const EdgeInsets.only(top: 10),
                  backgroundColor: BColors.darkerGrey,
                  child: TextField(
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BColors.light),
                    controller: requestTransportController.addressTextController,
                    decoration: InputDecoration(
                      enabled: false,
                      hintStyle: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .apply(color: BColors.light),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      prefixIcon: IconButton(
                        onPressed: () {
                          requestTransportController.onSearchHerePressed();
                        },
                        icon: const Icon(Iconsax.location),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
