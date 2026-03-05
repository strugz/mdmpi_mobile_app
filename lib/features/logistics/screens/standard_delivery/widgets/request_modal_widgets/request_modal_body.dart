import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Body content for Standard Delivery modal — contains
/// Preparation Info and Trip Ticket No input.
class RequestModalBody extends StatelessWidget {
  const RequestModalBody({
    super.key,
    required this.requestModel,
    required this.requestController,
  });

  final StandardDeliveryModel requestModel;
  final IDeliveryRequestController requestController;

  @override
  Widget build(BuildContext context) {
    final showPreparedBy = requestModel.status != BTexts.statusNewRequest &&
        requestModel.itemPreparedBy.isNotEmpty;
    final preparedByTitle =
        requestModel.status == BTexts.statusGettingSuppliesReady
            ? 'Preparing By: ${requestModel.itemPreparedBy}'
            : 'Prepared By: ${requestModel.itemPreparedBy}';

    final isPreparingUser =
        requestModel.status == BTexts.statusGettingSuppliesReady &&
            requestModel.itemPreparedBy ==
                requestController.userController.user.value.initial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========== Preparation Info ==========
        if (showPreparedBy ||
            requestModel.itemPreparedAt.isNotEmpty ||
            requestModel.tripTicketNumber.isNotEmpty) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Preparation Info'),
          const SizedBox(height: BSizes.sm),
          if (showPreparedBy)
            BLabelValueText(
              label: preparedByTitle,
              value: requestModel.itemPreparedBy,
              showLabel: false,
              icon: Iconsax.user_tick,
              padding: EdgeInsets.zero,
            ),
          if (requestModel.itemPreparedAt.isNotEmpty ||
              requestModel.itemPreparedEndAt.isNotEmpty) ...[
            const SizedBox(height: BSizes.sm),
            Row(
              children: [
                if (requestModel.itemPreparedAt.isNotEmpty)
                  Expanded(
                    child: BLabelValueText(
                      label: 'From',
                      value: BFormatter.formatDate2(
                          requestModel.itemPreparedAt),
                      showLabel: false,
                      icon: Iconsax.clock,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (requestModel.itemPreparedAt.isNotEmpty &&
                    requestModel.itemPreparedEndAt.isNotEmpty)
                  const SizedBox(width: BSizes.xs),
                if (requestModel.itemPreparedEndAt.isNotEmpty)
                  Expanded(
                    child: BLabelValueText(
                      label: 'To',
                      value: BFormatter.formatDate2(
                          requestModel.itemPreparedEndAt),
                      showLabel: false,
                      icon: Iconsax.clock,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
          if (requestModel.tripTicketNumber.isNotEmpty) ...[
            const SizedBox(height: BSizes.sm),
            BLabelValueText(
              label: 'Trip Ticket No',
              value: requestModel.tripTicketNumber,
              showLabel: false,
              copyable: true,
              icon: Iconsax.receipt_2,
              padding: EdgeInsets.zero,
            ),
          ],
        ],

        // ========== Trip Ticket No Input (for preparing user) ==========
        if (isPreparingUser && requestModel.tripTicketNumber.isEmpty) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Trip Ticket'),
          const SizedBox(height: BSizes.spaceBtwItems),
          TextFormField(
            controller: requestController.formState.tripTicketNumber,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Trip Ticket No',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ],
      ],
    );
  }
}

