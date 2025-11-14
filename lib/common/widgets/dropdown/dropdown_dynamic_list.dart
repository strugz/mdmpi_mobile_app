import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/helpers/helper_functions.dart';

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
  });

  @override
  State<BDropDownDynamicList> createState() => _BDropDownDynamicListState();
}

class _BDropDownDynamicListState extends State<BDropDownDynamicList> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.controller?.text.isNotEmpty == true ? widget.controller!.text : null;
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

    return DropdownButtonFormField<String>(
      value: _selectedValue != null && items.any((it) => it.value == _selectedValue) ? _selectedValue : null,
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
        if (widget.controller != null && newValue != null) {
          widget.controller!.text = newValue;
        }
        if (widget.onChanged != null) widget.onChanged!(newValue);
      },
      style: textStyle,
      dropdownColor: Colors.white,
    );
  }
}
