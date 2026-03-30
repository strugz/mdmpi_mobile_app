import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/inventory_item_controller.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/b_simple_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/widgets/inventory_batch_details.dart';

/// A small, reusable widget that shows an inventory item header and a
/// collapsible details area (batches / serials). UI remains pure — all
/// business logic lives in [InventoryItemController].
class InventoryItemView extends StatelessWidget {
  final InventoryItemModel item;
  final InventoryItemController? controller;
  final String? keyId;
  final bool showTrailingActions;

  const InventoryItemView({
    super.key,
    required this.item,
    this.controller,
    this.keyId,
    this.showTrailingActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? Get.find<InventoryItemController>();
    final itemKey =
        keyId ?? (item.itemCode.isNotEmpty ? item.itemCode : item.description);

    final theme = Theme.of(context);

    return Card(
      color: BColors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Obx(() {
        final expanded = ctrl.isExpanded(itemKey);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => ctrl.toggleExpanded(itemKey),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: avatar, item code (flex 6), qty (flex 2), actions (flex 3)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: BColors.primaryBackground,
                            child: Icon(
                              Icons.inventory_2,
                              color: BColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Item code column (aligns with header flex 6)
                          Expanded(
                            flex: 6,
                            child: Tooltip(
                              message: item.itemCode.isNotEmpty
                                  ? item.itemCode
                                  : '(no code)',
                              child: BProductTitleText(
                                title: item.itemCode.isNotEmpty
                                    ? item.itemCode
                                    : '(no code)',
                                smallSize: true,
                                bold: true,
                                maxLines: 2,
                                fontColor: BColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Qty column (aligns with header flex 2)
                          BSimpleChip(
                            label:
                                '${BFormatter.formatIntegerNoDecimal(item.qty)} ${item.unit}',
                            backgroundColor: BColors.primaryBackground,
                            textStyle: theme.textTheme.bodySmall?.copyWith(
                                color: BColors.primary, fontSize: 11),
                          ),
                          // Actions placeholder (aligns with header flex 3)
                          const Expanded(flex: 2, child: SizedBox.shrink()),
                        ],
                      ),

                      // Description row (indented under avatar) — use same title styling
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 52.0),
                          child: BProductTitleText(
                            title: item.description,
                            smallSize: true,
                            bold: false,
                            maxLines: 3,
                            fontColor: BColors.textSecondary,
                          ),
                        ),
                      ],

                      // Centered toggle below the description/top-row — keeps UI consistent
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Center(
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: expanded ? 'Collapse' : 'Expand',
                            onPressed: () => ctrl.toggleExpanded(itemKey),
                            icon: AnimatedRotation(
                              turns: expanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.expand_more,
                                  color: BColors.darkerGrey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Details area with subtle background and rounded bottom corners
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: BColors.lightContainer,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: InventoryBatchDetails(batches: item.batches),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      }),
    );
  }
}
