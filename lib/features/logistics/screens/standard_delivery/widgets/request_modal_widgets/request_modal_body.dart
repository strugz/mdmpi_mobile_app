import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/b_section_title.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_fact_grid.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Body content for Standard Delivery modal — the Preparation section and,
/// for the preparing user, the Trip Ticket No input.
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
    final isPreparing =
        requestModel.status == BTexts.statusGettingSuppliesReady;
    final showPreparedBy = requestModel.status != BTexts.statusNewRequest &&
        requestModel.itemPreparedBy.isNotEmpty;

    final isPreparingUser = isPreparing &&
        requestModel.itemPreparedBy ==
            requestController.userController.user.value.initial;

    final hasPreparation = showPreparedBy ||
        requestModel.itemPreparedAt.isNotEmpty ||
        requestModel.tripTicketNumber.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========== Preparation ==========
        if (hasPreparation) ...[
          const BSectionTitle('Preparation'),
          BFactGrid(
            facts: [
              BFact(isPreparing ? 'Preparing by' : 'Prepared by',
                  showPreparedBy ? requestModel.itemPreparedBy : ''),
              BFact('Trip ticket', requestModel.tripTicketNumber,
                  copyable: true),
            ],
          ),
          // Start → end on one line with the date once: the duration is
          // what the reader wants, and the old two-column row truncated both.
          if (requestModel.itemPreparedAt.isNotEmpty ||
              requestModel.itemPreparedEndAt.isNotEmpty) ...[
            const SizedBox(height: BSizes.sm),
            BFactGrid(
              columns: 1,
              facts: [
                BFact(
                  isPreparing ? 'Started' : 'Prepared',
                  BFormatter.formatTimeRange(
                      requestModel.itemPreparedAt,
                      requestModel.itemPreparedEndAt),
                ),
              ],
            ),
          ],
        ],

        // ========== Trip Ticket No Input (for preparing user) ==========
        if (isPreparingUser && requestModel.tripTicketNumber.isEmpty) ...[
          const BSectionTitle('Trip ticket'),
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
