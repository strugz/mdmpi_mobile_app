import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

class PullOutRequestModalHeader extends StatelessWidget {
  const PullOutRequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final PullOutModel requestModel;

  String _safeDate(String value) {
    if (value.isEmpty) return '';
    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    final hasAddress = requestModel.client.address.isNotEmpty;
    final hasRequestedBy = requestModel.requestedBy.isNotEmpty;
    final hasPullOutDate = requestModel.pullOutDate.isNotEmpty;
    final hasReleasedBy = requestModel.releasedBy.isNotEmpty;
    final hasSlip = requestModel.slipNo.isNotEmpty;
    final hasTrip = requestModel.tripTicketNumber.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BProductTitleText(
          title: requestModel.client.name.isNotEmpty
              ? requestModel.client.name
              : (requestModel.slipNo.isNotEmpty
                  ? 'Slip: ${requestModel.slipNo}'
                  : 'Pull-Out Request'),
          maxLines: 2,
          bold: true,
          fontColor: dark ? BColors.light : BColors.black,
        ),

        // Address (optional)
        if (hasAddress) ...[
          const SizedBox(height: BSizes.xs),
          BProductTitleText(
            title: requestModel.client.address,
            maxLines: 2,
            smallSize: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
        ],

        if (hasRequestedBy || hasPullOutDate) ...[
          const SizedBox(height: BSizes.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasRequestedBy)
                Expanded(
                  child: BProductTitleText(
                    title: 'Requested By: ${requestModel.requestedBy}',
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.black,
                  ),
                ),
              if (hasRequestedBy && hasPullOutDate)
                const SizedBox(width: BSizes.xs),
              if (hasPullOutDate)
                BProductTitleText(
                  title:
                      'Pull-Out Date: ${_safeDate(requestModel.pullOutDate)}',
                  maxLines: 1,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
            ],
          ),
        ],

        if (hasReleasedBy) ...[
          const SizedBox(height: BSizes.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasReleasedBy)
                Expanded(
                  child: BProductTitleText(
                    title: 'Released By: ${requestModel.releasedBy}',
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.black,
                  ),
                ),
            ],
          ),
        ],

        const SizedBox(height: BSizes.sm),

        if (hasSlip || hasTrip) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasSlip)
                BProductTitleText(
                  title: 'Slip No: ${requestModel.slipNo}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
              if (hasTrip)
                BProductTitleText(
                  title: 'Trip Ticket No: ${requestModel.tripTicketNumber}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black,
                ),
            ],
          ),
          const SizedBox(height: BSizes.xs),
        ],
      ],
    );
  }
}
