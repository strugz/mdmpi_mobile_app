import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/backload_item_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/inventory_item_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/backload_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Backloaded items on a Standard Delivery / Hotline Direct request.
///
/// - [BackloadItemsSection.editable]: courier view while For Delivery, before
///   drop off — the request's items with a "received" checkbox each; an
///   unchecked item requires a remark (written into
///   `formState.backloadItemRemarks`, validated and saved to
///   `a_tblbackloaditem` on the Done Delivery transition).
/// - [BackloadItemsSection.readOnly]: recorded backloaded items with remarks
///   for completed requests.
///
/// Renders nothing when the request has no items or, in read-only mode, no
/// recorded backloaded items.
class BackloadItemsSection extends StatefulWidget {
  const BackloadItemsSection.editable({
    super.key,
    required this.requestModel,
    required this.requestController,
  }) : editable = true;

  const BackloadItemsSection.readOnly({
    super.key,
    required this.requestModel,
  })  : requestController = null,
        editable = false;

  final StandardDeliveryModel requestModel;
  final IDeliveryRequestController? requestController;
  final bool editable;

  @override
  State<BackloadItemsSection> createState() => _BackloadItemsSectionState();
}

class _BackloadItemsSectionState extends State<BackloadItemsSection> {
  final Map<String, TextEditingController> _remarkCtrls = {};
  List<InventoryItemModel> _items = const [];
  List<BackloadItemModel> _backloadItems = const [];
  bool _loading = true;

  RxMap<String, String> get _backloadRemarks =>
      widget.requestController!.formState.backloadItemRemarks;

  // Some load paths populate `requestID` but not `id`.
  String get _requestId => widget.requestModel.id.isNotEmpty
      ? widget.requestModel.id
      : widget.requestModel.requestID;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.editable) {
      // Entries left over from a different request must not be saved
      // against this one.
      final formState = widget.requestController!.formState;
      if (formState.backloadItemsRequestId.value != _requestId) {
        formState.backloadItemRemarks.clear();
        formState.backloadItemsRequestId.value = _requestId;
      }
      final result =
          await Get.find<InventoryItemController>().loadItems(_requestId);
      if (!mounted) return;
      setState(() {
        _items = result.isSuccess ? result.value : const [];
        _loading = false;
      });
      // Seed remark editors from any previously entered state.
      for (final item in _items) {
        final existing = _backloadRemarks[item.referenceCode];
        if (existing != null) {
          _ctrlFor(item.referenceCode).text = existing;
        }
      }
    } else {
      final result =
          await BackloadItemRepository.instance.getByRequestId(_requestId);
      if (!mounted) return;
      setState(() {
        _backloadItems = result.isSuccess ? result.value : const [];
        _loading = false;
      });
    }
  }

  /// Keyed by [InventoryItemModel.referenceCode], not the raw item code:
  /// a line entered from a Stock Issue Slip may have no item code at all.
  TextEditingController _ctrlFor(String code) =>
      _remarkCtrls.putIfAbsent(code, () => TextEditingController());

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
        const BTextDivider(text: 'Items to Deliver'),
        const SizedBox(height: BSizes.xs),
        Text(
          'Uncheck items the client will not receive (backload) and state the reason.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: BSizes.xs),
        Obx(() {
          final backload = _backloadRemarks;
          return Column(
            children: [
              for (final item in _items) ...[
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: !backload.containsKey(item.referenceCode),
                  title: Text(
                    '${item.referenceCode} — ${item.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Qty: ${item.qty} ${item.unit}'),
                  onChanged: (received) {
                    if (received == true) {
                      backload.remove(item.referenceCode);
                    } else {
                      backload[item.referenceCode] =
                          _ctrlFor(item.referenceCode).text.trim();
                    }
                  },
                ),
                if (backload.containsKey(item.referenceCode))
                  Padding(
                    padding: const EdgeInsets.only(
                        left: BSizes.lg, bottom: BSizes.sm),
                    child: TextField(
                      controller: _ctrlFor(item.referenceCode),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason (required)',
                        prefixIcon: Icon(Iconsax.message_text),
                        hintText: 'Why is this item being backloaded?',
                      ),
                      onChanged: (value) =>
                          backload[item.referenceCode] = value.trim(),
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
    if (_backloadItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.md),
        const BTextDivider(text: 'Backloaded Items'),
        const SizedBox(height: BSizes.xs),
        for (final item in _backloadItems)
          Padding(
            padding: const EdgeInsets.only(bottom: BSizes.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Iconsax.box_remove, size: 16),
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
