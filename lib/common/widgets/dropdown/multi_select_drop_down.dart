import 'package:flutter/material.dart';

/// A form field that lets the user pick SEVERAL entries from a list.
///
/// Renders like a dropdown (label, icon, joined selected names) but opens a
/// checkbox dialog. Items follow the same shape as [BDropDownDynamicList]:
/// a list of maps read through [valueKey] / [displayKey].
class BMultiSelectDropDown extends StatelessWidget {
  const BMultiSelectDropDown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.valueKey = 'id',
    this.displayKey = 'name',
    this.icon,
    this.validator,
  });

  final String label;

  /// Option maps, read through [valueKey]/[displayKey].
  final List<Map<String, dynamic>> items;

  /// Currently selected values (contents of [valueKey]).
  final List<String> selectedValues;

  final ValueChanged<List<String>> onChanged;
  final String valueKey;
  final String displayKey;
  final IconData? icon;
  final String? Function(List<String>?)? validator;

  String _displayFor(String value) {
    for (final item in items) {
      if (item[valueKey]?.toString() == value) {
        return item[displayKey]?.toString() ?? value;
      }
    }
    return value;
  }

  Future<void> _openPicker(
      BuildContext context, FormFieldState<List<String>> state) async {
    final working = List<String>.from(selectedValues);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(label),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in items)
                  CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(item[displayKey]?.toString() ?? ''),
                    value: working.contains(item[valueKey]?.toString()),
                    onChanged: (checked) {
                      final value = item[valueKey]?.toString() ?? '';
                      setState(() {
                        if (checked == true) {
                          if (!working.contains(value)) working.add(value);
                        } else {
                          working.remove(value);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(working),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      onChanged(result);
      state.didChange(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: selectedValues,
      validator: validator,
      builder: (state) {
        final names = selectedValues.map(_displayFor).join(', ');
        return InkWell(
          onTap: () => _openPicker(context, state),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: icon != null ? Icon(icon) : null,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              errorText: state.errorText,
            ),
            isEmpty: selectedValues.isEmpty,
            child: Text(
              names,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
