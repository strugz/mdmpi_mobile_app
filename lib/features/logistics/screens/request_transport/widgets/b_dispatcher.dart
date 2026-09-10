import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/draggable_bottom_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_request_details.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';

import '../../../../personalization/controller/user_controller.dart';
import '../../../controllers/request_transport_controller.dart';
import '../../../models/standard_delivery_model.dart';

/// Bottom sheet dispatcher for the Request Transport screen.
///
/// Uses [BDraggableBottomSheet] for the drag-handle + scroll + fixed-action
/// layout, composing transport-specific widgets for the body and action button.
class BDispatcher extends StatelessWidget {
  const BDispatcher({
    super.key,
    required this.requestController,
  });

  final IDeliveryRequestController requestController;

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final requestTransportController = Get.find<RequestTransportController>();

    // React to selectedRequest changes so sheet sizing updates when status changes
    return Obx(() {
      final StandardDeliveryModel? selected =
          requestController.currentSelectedRequest.value;

      // Helper: estimate a sensible initial height fraction based on visible sections
      double estimateInitialSize(StandardDeliveryModel? r) {
        if (r == null) return 0.45;

        // Presence flags
        final hasClient = r.client.name.isNotEmpty;
        final hasAddress = r.client.address.isNotEmpty;
        // status & preference always shown per requirement
        final hasEta = requestTransportController.eta.value?.isNotEmpty ?? false;
        final hasPreparation = r.itemPreparedBy.isNotEmpty || r.itemPreparedAt.isNotEmpty || r.itemPreparedEndAt.isNotEmpty || r.tripTicketNumber.isNotEmpty;
        final hasDispatch = r.deliveredBy.isNotEmpty || r.helper.isNotEmpty;
        final hasDocRefs = r.documentReference.isNotEmpty;
        final docCount = r.documentReference.length;
        final hasProof = r.status == BTexts.statusForDelivery;

        // If the request is 'Item Prepared', use a deterministic compact sizing strategy
        if (r.status == BTexts.statusItemPrepared) {
          // Count visible lines/sections roughly
          int sections = 0;
          if (hasClient) sections += 1;
          if (hasAddress) sections += 1;
          // chips count as one section
          sections += 1;
          if (hasEta) sections += 1;
          if (hasPreparation) sections += 1;
          if (hasDispatch) sections += 1;
          // document refs contribute per item
          sections += docCount;
          if (hasProof) sections += 2; // proof includes image + signature controls

          // If only header + chips + doc refs are present (common Item Prepared case),
          // use a tighter fixed size to avoid leaving a large blank area below docs.
          final onlyHeaderAndDocs = !hasPreparation && !hasDispatch && !hasProof;
          if (onlyHeaderAndDocs) {
            // small base + per-doc increment (doc lines are compact)
            final baseSmall = 0.22; // fits client+chips
            final perDoc = 0.03; // each doc increases height slightly
            final sizeForDocs = baseSmall + (docCount * perDoc);
            return sizeForDocs.clamp(0.20, 0.36);
          }

          // Derive fraction: base + per-section increment for other Item Prepared cases
          double size = 0.10 + (sections * 0.045);
          // When there are many doc refs, limit growth
          final maxForPrepared = 0.48;
          return size.clamp(0.16, maxForPrepared);
        }

        // Default heuristic for other statuses: sum fractional sizes
        double size = 0.10; // base for handle + small header
        if (hasClient) size += 0.06;
        if (hasAddress) size += 0.04;
        // status + preference chips
        size += 0.07;
        if (hasEta) size += 0.04;
        if (hasPreparation) size += 0.12;
        if (hasDispatch) size += 0.10;
        if (hasDocRefs) size += 0.08;
        if (hasProof) size += 0.18;

        // Clamp to safe min/max to avoid being too small/large
        return size.clamp(0.16, 0.85);
      }

      final isItemPrepared = selected?.status == BTexts.statusItemPrepared;

      // Compute sizes: dynamic initialChildSize based on visible content
      final initialChildSize = estimateInitialSize(selected);
      final minChildSize = isItemPrepared ? 0.06 : 0.06;
      final maxChildSize = 0.50;

      // Clamp initialChildSize so it never exceeds maxChildSize (avoids DraggableScrollableSheet assertion)
      final clampedInitialChildSize = initialChildSize.clamp(minChildSize, maxChildSize);

      // Publish the sheet's extent so the map FABs can ride its top edge.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (requestTransportController.sheetExtent.value == 0) {
          requestTransportController.sheetExtent.value =
              clampedInitialChildSize;
        }
      });

      return NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          requestTransportController.sheetExtent.value = notification.extent;
          return false;
        },
        child: BDraggableBottomSheet(
          initialChildSize: clampedInitialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          body: BRequestDetails(
            requestController: requestController,
            userController: userController,
            requestTransportController: requestTransportController,
          ),
          bottomAction: BActionButton(
            requestController: requestController,
            requestTransportController: requestTransportController,
          ),
        ),
      );
    });
  }
}
