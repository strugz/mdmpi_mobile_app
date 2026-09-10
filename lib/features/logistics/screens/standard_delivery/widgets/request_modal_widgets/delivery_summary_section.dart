import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/b_section_title.dart';
import 'package:mdmpi_mobile_app/common/widgets/signature/captured_signature_image.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_fact_grid.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// "Delivery" section of the Standard Delivery modal / page: crew, the two
/// timestamps in chronological order, the receiver, and the receiver's
/// signature in its own captioned card.
///
/// Replaces the shared [BDeliveryDetailsSection] for Standard Delivery, whose
/// mixed row styles (`Driver: BPT` as a title, a bold `Received By:` wrapping
/// beside a watermark signature, two unlabelled times) were the main source
/// of visual noise on the page. Hides itself when nothing is recorded yet.
class DeliverySummarySection extends StatelessWidget {
  const DeliverySummarySection({super.key, required this.requestModel});

  final StandardDeliveryModel requestModel;

  @override
  Widget build(BuildContext context) {
    final r = requestModel;
    // A helper identical to the driver is legacy duplicate data.
    final helper = r.helper == r.deliveredBy ? '' : r.helper;
    final hasAnything = r.deliveredBy.isNotEmpty ||
        helper.isNotEmpty ||
        r.deliveredAt.isNotEmpty ||
        r.deliveredEndAt.isNotEmpty ||
        r.receiver.isNotEmpty;
    if (!hasAnything) return const SizedBox.shrink();

    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final requestId = r.id.isNotEmpty ? r.id : r.requestID;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BSectionTitle('Delivery'),
        BFactGrid(
          textColor: textColor,
          facts: [
            BFact('Driver', r.deliveredBy),
            BFact('Helper', helper),
            BFact('Dispatched', BFormatter.formatDateWithAmPm(r.deliveredAt)),
            BFact('Delivered', BFormatter.formatDateWithAmPm(r.deliveredEndAt)),
          ],
        ),
        if (r.receiver.isNotEmpty) ...[
          const SizedBox(height: BSizes.sm),
          BFactGrid(
            columns: 1,
            textColor: textColor,
            facts: [BFact('Received by', r.receiver, emphasize: true)],
          ),
          const SizedBox(height: BSizes.sm),
          // Signature in its own frame, captioned, instead of a watermark
          // fighting the receiver's name for width.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BSizes.sm),
            decoration: BoxDecoration(
              color: dark ? BColors.darkerGrey : BColors.white,
              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
              border: Border.all(color: textColor.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: CapturedSignatureImage(requestId: requestId),
                ),
                const SizedBox(height: BSizes.xs),
                Text(
                  'Receiver signature',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
