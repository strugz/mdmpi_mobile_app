import 'package:flutter/material.dart';

class DropdownList<T> extends StatelessWidget {
  final String label;
  final List<T> dropdownList;
  final TextEditingController controller;
  final String Function(T) getValue;
  final String Function(T) getDisplay;
  final void Function(T?) onChanged;

  const DropdownList({
    super.key,
    required this.label,
    required this.dropdownList,
    required this.controller,
    required this.getValue,
    required this.getDisplay,
    required this.onChanged,
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
      items: dropdownList.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(getDisplay(item)),
        );
      }).toList(),
      onChanged: (value) {
        controller.text = getValue(value as T);
        onChanged(value);
      },
    );
  }
}
