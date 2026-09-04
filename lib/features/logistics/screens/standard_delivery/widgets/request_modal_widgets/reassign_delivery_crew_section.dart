import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// Release-role control to re-assign the driver/helper on a request that is
/// already prepared (Item Prepared / For Delivery).
///
/// Re-assignment is a rare corrective action, so the section stays collapsed:
/// a single "Change Driver / Helper" action next to the existing Dispatch
/// Info display. Tapping it reveals the editor (dropdowns + Save/Cancel);
/// saving or cancelling collapses it again. Shared by the Standard Delivery
/// request modal footer and the RequestTransport details screen (Hotline
/// Direct included via the same widgets).
class ReassignDeliveryCrewSection extends StatefulWidget {
  const ReassignDeliveryCrewSection({
    super.key,
    required this.requestModel,
    required this.requestController,
  });

  final StandardDeliveryModel requestModel;
  final IDeliveryRequestController requestController;

  @override
  State<ReassignDeliveryCrewSection> createState() =>
      _ReassignDeliveryCrewSectionState();
}

class _ReassignDeliveryCrewSectionState
    extends State<ReassignDeliveryCrewSection> {
  final TextEditingController _driverCtrl = TextEditingController();
  final TextEditingController _helperCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  StandardDeliveryModel get _currentRequest =>
      widget.requestController.currentSelectedRequest.value ??
      widget.requestModel;

  @override
  void dispose() {
    _driverCtrl.dispose();
    _helperCtrl.dispose();
    super.dispose();
  }

  void _openEditor() {
    // Seed from the live request each time, so a previous edit or an update
    // from elsewhere is reflected instead of a stale snapshot.
    _driverCtrl.text = _currentRequest.deliveredBy;
    _helperCtrl.text = _currentRequest.helper;
    setState(() => _editing = true);
  }

  void _closeEditor() {
    if (_saving) return;
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Assignment updates for Standard Delivery and Hotline Direct both go
      // through the Standard Delivery data manager (shared repository).
      final saved = await Get.find<StandardDeliveryController>()
          .dataManager
          .updateDriverHelperAssignment(
            controller: widget.requestController,
            request: _currentRequest,
            driver: _driverCtrl.text,
            helper: _helperCtrl.text,
          );
      if (mounted && saved) {
        setState(() => _editing = false);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _editing ? _buildEditor(context) : _buildCollapsed(context),
    );
  }

  /// Collapsed: one quiet, right-aligned action beside the Dispatch Info the
  /// screen already displays — no duplicated values, no extra section.
  Widget _buildCollapsed(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _openEditor,
        icon: const Icon(Iconsax.user_edit, size: 16),
        label: const Text('Change Driver / Helper'),
        style: TextButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: BSizes.sm, vertical: 4),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final userController = Get.find<UserInitialController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.sm),
        const BTextDivider(text: 'Re-assign Driver / Helper'),
        const SizedBox(height: BSizes.spaceBtwItems),
        Obx(() {
          final users = userController.userList.toList();
          if (users.isEmpty) {
            return const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          return Row(
            children: [
              Expanded(
                child: DropdownList<UserModel>(
                  label: 'Driver',
                  dropdownList: users,
                  controller: _driverCtrl,
                  getValue: (u) => u.initial,
                  getDisplay: (u) => u.initial,
                  onChanged: (UserModel? value) {
                    _driverCtrl.text = value?.initial ?? '';
                  },
                ),
              ),
              const SizedBox(width: BSizes.spaceBtwItems),
              Expanded(
                child: DropdownList<UserModel>(
                  label: 'Helper',
                  dropdownList: users,
                  controller: _helperCtrl,
                  getValue: (u) => u.initial,
                  getDisplay: (u) => u.initial,
                  onChanged: (UserModel? value) {
                    _helperCtrl.text = value?.initial ?? '';
                  },
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: BSizes.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _saving ? null : _closeEditor,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: BSizes.xs),
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Iconsax.tick_circle, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save Assignment'),
            ),
          ],
        ),
      ],
    );
  }
}
