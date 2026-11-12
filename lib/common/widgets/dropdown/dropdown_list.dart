import 'package:flutter/material.dart';

class DropdownList<T> extends StatelessWidget {
  final String label;
  final List<T> dropdownList;
  final TextEditingController controller;
  final String Function(T) getValue;
  final String Function(T) getDisplay;
  final void Function(T?) onChanged;

  /// When set, a first choice with this label clears the field (optional
  /// fields such as Helper).
  final String? emptyOptionLabel;

  const DropdownList({
    super.key,
    required this.label,
    required this.dropdownList,
    required this.controller,
    required this.getValue,
    required this.getDisplay,
    required this.onChanged,
    this.emptyOptionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: dropdownList.isNotEmpty &&
              dropdownList.any((item) => getValue(item) == controller.text)
          ? dropdownList.firstWhere((item) => getValue(item) == controller.text)
          : null,
      items: [
        if (emptyOptionLabel != null)
          DropdownMenuItem<T>(value: null, child: Text(emptyOptionLabel!)),
        ...dropdownList.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(getDisplay(item)),
          );
        }),
      ],
      onChanged: (value) {
        controller.text = value == null ? '' : getValue(value);
        onChanged(value);
      },
    );
  }
}
