import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';

/// Widget to display dispatch information (Trip Ticket, Driver, Helper, Vehicle)
/// for Air/Sea requests that have been dispatched.
class AirSeaDispatchInfoSection extends StatelessWidget {
  const AirSeaDispatchInfoSection({
    super.key,
    required this.requestModel,
  });

  final AirSeaModel requestModel;

  @override
  Widget build(BuildContext context) {
    final hasTripTicket = requestModel.tripTicketNumber.isNotEmpty;
    final hasDriver = requestModel.driver.isNotEmpty;
    final hasHelper = requestModel.helper.isNotEmpty;
    final hasVehicle = requestModel.mobileId != null;

    // Don't show section if no dispatch info
    if (!hasTripTicket && !hasDriver && !hasHelper && !hasVehicle) {
      return const SizedBox.shrink();
    }

    String? vehicleName;
    if (hasVehicle) {
      try {
        final mobileController = Get.find<MobileController>();
        final vehicle = mobileController.mobile.firstWhereOrNull(
            (m) => int.tryParse(m.mobileID) == requestModel.mobileId);
        vehicleName = vehicle?.mobileName;
      } catch (_) {
        // MobileController not available
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.sm),
        const BTextDivider(text: 'Dispatch Details'),

        // Trip Ticket Number and Vehicle - Primary Info
        if (hasTripTicket) ...[
          const SizedBox(height: BSizes.xs),
          BLabelValueText(
            label: 'Trip Ticket No',
            value: requestModel.tripTicketNumber,
            showLabel: false,
            icon: Iconsax.ticket,
            padding: EdgeInsets.zero,
            copyable: true,
          ),
        ],

        if (hasVehicle && vehicleName != null) ...[
          const SizedBox(height: BSizes.xs),
          BLabelValueText(
            label: 'Vehicle',
            value: vehicleName,
            showLabel: false,
            icon: Iconsax.truck,
            padding: EdgeInsets.zero,
          ),
        ],

        // Driver and Helper - Personnel Info (with labels)
        if (hasDriver || hasHelper) ...[
          const SizedBox(height: BSizes.xs),
          Row(
            children: [
              if (hasDriver)
                Expanded(
                  child: BLabelValueText(
                    label: 'Driver',
                    value: requestModel.driver,
                    showLabel: true,
                    icon: Iconsax.user,
                    padding: EdgeInsets.zero,
                  ),
                ),
              if (hasDriver && hasHelper) const SizedBox(width: BSizes.sm),
              if (hasHelper)
                Expanded(
                  child: BLabelValueText(
                    label: 'Helper',
                    value: requestModel.helper,
                    showLabel: true,
                    icon: Iconsax.user_tag,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

