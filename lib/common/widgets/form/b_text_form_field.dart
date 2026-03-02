import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

/// A reusable wrapped [TextFormField] that standardizes label styling and
/// reduces boilerplate across forms. Prefer using this over the raw widget
/// inside feature screens.
class BTextFormField extends StatelessWidget {
  const BTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: BColors.darkGrey),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}

