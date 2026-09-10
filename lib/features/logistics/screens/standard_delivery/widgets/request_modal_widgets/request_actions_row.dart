import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/inventory_item_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/inventory_items_page.dart';

/// The request's secondary actions in one row under the header:
/// `View items (12)` and, once delivered, `Proof photos`.
///
/// They used to be centred text links floating between sections (one of them
/// inside the delivery block). Actions belong together and should look like
/// actions; the item count tells the reader whether the tap is worth it.
class RequestActionsRow extends StatelessWidget {
  const RequestActionsRow({super.key, required this.requestModel});

  final StandardDeliveryModel requestModel;

  @override
  Widget build(BuildContext context) {
    final requestId =
        requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;
    final delivered = requestModel.status == BTexts.statusDoneDelivery;

    return Padding(
      padding: const EdgeInsets.only(top: BSizes.md),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<int?>(
              future: _itemCount(requestId),
              builder: (context, snapshot) {
                final count = snapshot.data;
                return OutlinedButton.icon(
                  onPressed: () =>
                      Get.to(() => InventoryItemsPage(requestId: requestId)),
                  icon: const Icon(Iconsax.box, size: 18),
                  label: Text(count == null || count == 0
                      ? 'View items'
                      : 'View items ($count)'),
                );
              },
            ),
          ),
          if (delivered) ...[
            const SizedBox(width: BSizes.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showRequestImagesDialog(
                  context,
                  requestId: requestId,
                  types: const ['Proof', 'Proof_2', 'Proof_3'],
                  semanticsLabel: 'Delivered item image for request $requestId',
                  apiController: 'Request',
                  title: 'Delivered Item',
                ),
                icon: const Icon(Iconsax.camera, size: 18),
                label: const Text('Proof photos'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<int?> _itemCount(String requestId) async {
    if (requestId.isEmpty || !Get.isRegistered<InventoryItemRepository>()) {
      return null;
    }
    final result =
        await Get.find<InventoryItemRepository>().fetchItems(requestId);
    return result.isSuccess ? result.value.length : null;
  }
}
