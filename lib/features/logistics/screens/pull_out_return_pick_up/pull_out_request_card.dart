import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Card widget for a single Pull-Out / Return Pick-up request.
///
/// Shows a compact view with the following fields:
/// - Client
/// - RequestedBy
/// - Pull-Out Date
/// - CreatedBy
/// - RequestStatus
class PullOutRequestCard extends StatelessWidget {
  const PullOutRequestCard({super.key, required this.item});

  final PullOutModel item;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    return Container(
      width: 310,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        color: item.requestStatus.toLowerCase() == 'cancelled'
            ? BColors.cancelledBackground
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client name (title)
            BProductTitleText(
              title: item.client.name.isNotEmpty
                  ? item.client.name
                  : (item.slipNo.isNotEmpty ? 'Slip: ${item.slipNo}' : 'Pull-out Request'),
              maxLines: 1,
              bold: true,
              fontColor: dark ? BColors.light : BColors.darkerGrey,
            ),
            const SizedBox(height: BSizes.xxs),

            // Requested By + Pull-Out Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: BProductTitleText(
                    title: 'Requested By: ${item.requestedBy.isNotEmpty ? item.requestedBy : '-'}',
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.darkerGrey,
                  ),
                ),
                const SizedBox(width: BSizes.xs),
                BProductTitleText(
                  title: 'Pull-Out Date: ${_safeDate(item.pullOutDate)}',
                  maxLines: 1,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.darkerGrey,
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),

            // Created By + Status badge
            Row(
              children: [
                Expanded(
                  child: BProductTitleText(
                    title: 'Created By: ${item.createdBy.isNotEmpty ? item.createdBy : '-'}',
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.darkerGrey,
                  ),
                ),
                const SizedBox(width: BSizes.xs),
                BRoundedContainer(
                  radius: 100,
                  width: 110,
                  backgroundColor: dark ? BColors.darkerGrey : BColors.light,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BSizes.md,
                        vertical: BSizes.xxs,
                      ),
                      child: BProductTitleText(
                        title: item.requestStatus.isNotEmpty ? item.requestStatus : 'Pending',
                        maxLines: 1,
                        smallSize: true,
                        fontColor: dark ? BColors.light : BColors.darkerGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _safeDate(String value) {
    if (value.isEmpty) return '';
    return value.length >= 10 ? value.substring(0, 10) : value;
  }
}
