import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_pull_out_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/pull_out/lose_item_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/inventory_item_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/lose_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Lost items on a Pull Out request.
///
/// - [PullOutLostItemsSection.editable]: courier view while In Transit — the
///   request's items with a "Lost" checkbox each; a checked item requires a
///   remark (written into `formState.lostItemRemarks`, validated and saved to
///   `a_tblLoseItem` on the Taken Out transition).
/// - [PullOutLostItemsSection.readOnly]: recorded lost items with remarks for
///   completed requests.
///
/// Renders nothing when the request has no items (e.g. Stock Receive, which
/// shares the pull-out modal) or, in read-only mode, no recorded lost items.
class PullOutLostItemsSection extends StatefulWidget {
  const PullOutLostItemsSection.editable({
    super.key,
    required this.requestModel,
    required this.requestController,
  }) : editable = true;

  const PullOutLostItemsSection.readOnly({
    super.key,
    required this.requestModel,
  })  : requestController = null,
        editable = false;

  final PullOutModel requestModel;
  final IPullOutRequestController? requestController;
  final bool editable;

  @override
  State<PullOutLostItemsSection> createState() =>
      _PullOutLostItemsSectionState();
}

class _PullOutLostItemsSectionState extends State<PullOutLostItemsSection> {
  final Map<String, TextEditingController> _remarkCtrls = {};
  List<InventoryItemModel> _items = const [];
  List<LoseItemModel> _lostItems = const [];
  bool _loading = true;

  RxMap<String, String> get _lostItemRemarks =>
      widget.requestController!.formState.lostItemRemarks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.editable) {
      final result = await Get.find<InventoryItemController>()
          .loadItems(widget.requestModel.id);
      if (!mounted) return;
      setState(() {
        _items = result.isSuccess ? result.value : const [];
        _loading = false;
      });
      // Seed remark editors from any previously entered state.
      for (final item in _items) {
        final existing = _lostItemRemarks[item.itemCode];
        if (existing != null) {
          _ctrlFor(item.itemCode).text = existing;
        }
      }
    } else {
      final result = await LoseItemRepository.instance
          .getByRequestId(widget.requestModel.id);
      if (!mounted) return;
      setState(() {
        _lostItems = result.isSuccess ? result.value : const [];
        _loading = false;
      });
    }
  }

  TextEditingController _ctrlFor(String itemCode) =>
      _remarkCtrls.putIfAbsent(itemCode, () => TextEditingController());

  @override
  void dispose() {
    for (final ctrl in _remarkCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return widget.editable ? _buildEditable(context) : _buildReadOnly(context);
  }

  Widget _buildEditable(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.md),
        const BTextDivider(text: 'Items Pulled Out'),
        const SizedBox(height: BSizes.xs),
        Text(
          'Uncheck items that could not be pulled out (e.g. lost) and state the reason.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: BSizes.xs),
        Obx(() {
          final lost = _lostItemRemarks;
          return Column(
            children: [
              for (final item in _items) ...[
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: !lost.containsKey(item.itemCode),
                  title: Text(
                    '${item.itemCode} — ${item.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Qty: ${item.qty} ${item.unit}'),
                  onChanged: (included) {
                    if (included == true) {
                      lost.remove(item.itemCode);
                    } else {
                      lost[item.itemCode] = _ctrlFor(item.itemCode).text.trim();
                    }
                  },
                ),
                if (lost.containsKey(item.itemCode))
                  Padding(
                    padding: const EdgeInsets.only(
                        left: BSizes.lg, bottom: BSizes.sm),
                    child: TextField(
                      controller: _ctrlFor(item.itemCode),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason (required)',
                        prefixIcon: Icon(Iconsax.message_text),
                        hintText: 'Why was this item not pulled out?',
                      ),
                      onChanged: (value) =>
                          lost[item.itemCode] = value.trim(),
                    ),
                  ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _buildReadOnly(BuildContext context) {
    if (_lostItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.md),
        const BTextDivider(text: 'Lost Items'),
        const SizedBox(height: BSizes.xs),
        for (final item in _lostItems)
          Padding(
            padding: const EdgeInsets.only(bottom: BSizes.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Iconsax.danger, size: 16),
                ),
                const SizedBox(width: BSizes.xs),
                Expanded(
                  child: Text(
                    '${item.itemCode} — ${item.remarks}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
