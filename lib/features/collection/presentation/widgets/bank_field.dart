import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/bank_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/bank_picker_sheet.dart';

/// Every place the app asks which bank.
///
/// One widget rather than the same read-only-field-plus-picker written out on
/// each screen, because the interesting part is the fallback: until the
/// company list has downloaded, this has to stay an ordinary text field so a
/// collector with no signal and a check in their hand is never stuck.
class BBankField extends StatefulWidget {
  const BBankField({
    super.key,
    required this.controller,
    this.label = 'Bank',
    this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;

  @override
  State<BBankField> createState() => _BBankFieldState();
}

class _BBankFieldState extends State<BBankField> {
  /// The company list, held by the controller. Empty before the first
  /// successful download, and on any screen reached without the controller.
  List<BankModel> get _banks => Get.isRegistered<CollectionActivityController>()
      ? CollectionActivityController.instance.banks
      : const <BankModel>[];

  Future<void> _pick() async {
    final picked = await BankPickerSheet.show(
      context,
      banks: _banks,
      selected: widget.controller.text,
    );
    if (picked != null) {
      setState(() => widget.controller.text = picked.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reactive, because the list is fetched after the screen is built. Read
    // once, the field would render as plain text before the download landed
    // and stay that way for the life of the screen — which is a picker that
    // never appears.
    if (!Get.isRegistered<CollectionActivityController>()) return _field(false);
    return Obx(
        () => _field(CollectionActivityController.instance.banks.isNotEmpty));
  }

  Widget _field(bool hasList) => TextFormField(
        controller: widget.controller,
        // A picker where there is a list to pick from, a plain field where
        // there is not.
        readOnly: hasList,
        onTap: hasList ? _pick : null,
        textCapitalization: TextCapitalization.characters,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Iconsax.bank),
          suffixIcon: hasList
              ? const Icon(Iconsax.arrow_down_1,
                  size: 18, color: BColors.darkGrey)
              : null,
        ),
      );
}
