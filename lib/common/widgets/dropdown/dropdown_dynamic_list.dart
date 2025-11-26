import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../base/utils/constants/colors.dart';

/// Dynamic Dropdown that accepts either a list of strings or a list of maps.
/// When using a list of maps, provide [valueKey] and [displayKey] to extract
/// the stored value (e.g. id) and the visible label respectively.
class BDropDownDynamicList extends StatefulWidget {
  final List<dynamic> dropdownList;
  final TextEditingController? controller; // Stores selected value (id)
  final String? valueKey; // key in map to use as value
  final String? displayKey; // key in map to show as label
  final ValueChanged<String?>? onChanged;
  /// icon may be either an IconData or a Widget. If IconData is provided,
  /// it will be wrapped with Icon(...).
  final Object? icon;
  final String? label;
  final String? hint;
  final bool isExpanded;
  final String? Function(String?)? validator; // NEW: optional validator

  const BDropDownDynamicList({
    super.key,
    required this.dropdownList,
    this.controller,
    this.valueKey,
    this.displayKey,
    this.onChanged,
    this.icon,
    this.label,
    this.hint,
    this.isExpanded = true,
    this.validator,
  });

  @override
  State<BDropDownDynamicList> createState() => _BDropDownDynamicListState();
}

class _BDropDownDynamicListState extends State<BDropDownDynamicList> {
  String? _selectedValue;
  VoidCallback? _controllerListener;

  @override
  void initState() {
    super.initState();
    // Initialize from controller if provided
    _selectedValue = widget.controller?.text.isNotEmpty == true
        ? widget.controller!.text
        : null;
    _attachControllerListener();
  }

  void _attachControllerListener() {
    if (widget.controller != null) {
      _controllerListener ??= () {
        final text = widget.controller!.text;
        if (text != _selectedValue) {
          setState(() {
            _selectedValue = text.isEmpty ? null : text;
          });
        }
      };
      widget.controller!.addListener(_controllerListener!);
    }
  }

  void _detachControllerListener() {
    if (widget.controller != null && _controllerListener != null) {
      widget.controller!.removeListener(_controllerListener!);
    }
    _controllerListener = null;
  }

  String _getItemValue(dynamic item) {
    if (item is Map && widget.valueKey != null) {
      return (item[widget.valueKey] ?? '').toString();
    }
    return item?.toString() ?? '';
  }

  String _getItemLabel(dynamic item) {
    if (item is Map && widget.displayKey != null) {
      return (item[widget.displayKey] ?? '').toString();
    }
    return item?.toString() ?? '';
  }

  @override
  void didUpdateWidget(covariant BDropDownDynamicList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller instance changes, rewire the listener
    if (oldWidget.controller != widget.controller) {
      _detachControllerListener();
      _attachControllerListener();
      // Sync selection from the new controller
      final text = widget.controller?.text ?? '';
      if (text != _selectedValue) {
        _selectedValue = text.isEmpty ? null : text;
      }
    }
    // If dropdown items changed and current selection is no longer valid, clear it
    final currentItems = widget.dropdownList.map(_getItemValue).toSet();
    if (_selectedValue != null && !currentItems.contains(_selectedValue)) {
      _selectedValue = null;
    }
  }

  @override
  void dispose() {
    _detachControllerListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall;

    final items = widget.dropdownList.map((item) {
      final value = _getItemValue(item);
      final label = _getItemLabel(item);
      return DropdownMenuItem<String>(
        value: value,
        child: Text(label, style: textStyle),
      );
    }).toList();

    final containsSelected = _selectedValue != null &&
        items.any((it) => it.value == _selectedValue);

    return DropdownButtonFormField<String>(
      value: containsSelected ? _selectedValue : null,
      isExpanded: widget.isExpanded,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        prefixIcon: widget.icon is IconData
            ? Icon(widget.icon as IconData, size: 20, color: BColors.grey)
            : (widget.icon is Widget ? widget.icon as Widget : const Icon(Iconsax.arrow_down_1, size: 20, color: BColors.grey)),
        labelText: widget.label,
        hintText: widget.hint ?? 'Select',
      ),
      items: items,
      onChanged: (String? newValue) {
        setState(() => _selectedValue = newValue);
        if (widget.controller != null) {
          widget.controller!.text = newValue ?? '';
        }
        if (widget.onChanged != null) widget.onChanged!(newValue);
      },
      style: textStyle,
      dropdownColor: Colors.white,
      validator: widget.validator,
    );
  }
}
