import 'package:flutter/material.dart';
import 'package:get/get.dart';
// InventoryListHeader removed — header rendering moved out of this page.
import 'package:mdmpi_mobile_app/features/logistics/controllers/inventory_item_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/widgets/inventory_item_view.dart';

/// Full-screen page that shows inventory items for a given requestId.
class InventoryItemsPage extends StatelessWidget {
  final String requestId;
  const InventoryItemsPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InventoryItemController>();

    // Trigger load if needed
    if (!invCtrl.isLoading.value && invCtrl.items.isEmpty) {
      Future.microtask(() => invCtrl.loadItems(requestId));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
      ),
      body: Obx(() {
        if (invCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (invCtrl.items.isEmpty) {
          return const Center(child: Text('No items found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const SizedBox(height: 4),
              ...invCtrl.items.map((it) => InventoryItemView(
                    item: it,
                    controller: invCtrl,
                    keyId:
                        it.itemCode.isNotEmpty ? it.itemCode : it.description,
                  )),
            ],
          ),
        );
      }),
    );
  }
}

