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
  final String? Function(String?)? validator; // NEW: optional validator
  final bool readOnly; // NEW: whether dropdown is read-only
  final bool enableSearch; // NEW: enable search functionality

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
    this.readOnly = false,
    this.enableSearch = false,
  });

  @override
  State<BDropDownDynamicList> createState() => _BDropDownDynamicListState();
}

class _BDropDownDynamicListState extends State<BDropDownDynamicList> {
  String? _selectedValue;
  VoidCallback? _controllerListener;

  // Keeps the searchable FormField's internal value in sync with the
  // selection; without didChange the validator only ever sees the value
  // present when the field was first validated.
  final GlobalKey<FormFieldState<String>> _searchFieldKey =
      GlobalKey<FormFieldState<String>>();

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
          _searchFieldKey.currentState?.didChange(_selectedValue);
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
      // Sync the form field after this build frame (didChange can't run mid-build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFieldKey.currentState?.didChange(null);
      });
    }
  }

  @override
  void dispose() {
    _detachControllerListener();
    super.dispose();
  }

  void _showSearchableDropdown() async {
    final textStyle = Theme.of(context).textTheme.labelSmall;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SearchableDropdownDialog(
        items: widget.dropdownList,
        selectedValue: _selectedValue,
        getItemValue: _getItemValue,
        getItemLabel: _getItemLabel,
        textStyle: textStyle,
        hint: widget.hint ?? 'Select',
      ),
    );

    if (result != null) {
      setState(() => _selectedValue = result);
      if (widget.controller != null) {
        widget.controller!.text = result;
      }
      final fieldState = _searchFieldKey.currentState;
      fieldState?.didChange(result);
      // Clear a stale "please select" error as soon as a value is picked.
      if (fieldState?.hasError ?? false) fieldState!.validate();
      if (widget.onChanged != null) widget.onChanged!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textStyle = Theme.of(context).textTheme.labelSmall;
    // If search is enabled, use custom searchable dropdown
    if (widget.enableSearch) {
      final selectedLabel = _selectedValue != null
          ? widget.dropdownList
              .where((item) => _getItemValue(item) == _selectedValue)
              .map(_getItemLabel)
              .firstOrNull
          : null;

      return FormField<String>(
        key: _searchFieldKey,
        initialValue: _selectedValue,
        validator: widget.validator,
        builder: (fieldState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.readOnly ? null : _showSearchableDropdown,
                child: InputDecorator(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    prefixIcon: widget.icon is IconData
                        ? Icon(widget.icon as IconData,
                            size: 20, color: BColors.grey)
                        : (widget.icon is Widget
                            ? widget.icon as Widget
                            : const Icon(Iconsax.arrow_down_1,
                                size: 20, color: BColors.grey)),
                    suffixIcon: const Icon(Iconsax.search_normal,
                        size: 20, color: BColors.grey),
                    labelText: widget.label,
                    hintText: widget.hint ?? 'Select',
                    errorText: fieldState.errorText,
                  ),
                  child: Text(
                    selectedLabel ?? widget.hint ?? 'Select',
                    style: textStyle?.copyWith(
                      color: selectedLabel != null ? null : BColors.grey,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    // Standard dropdown without search
    final items = widget.dropdownList.map((item) {
      final value = _getItemValue(item);
      final label = _getItemLabel(item);
      return DropdownMenuItem<String>(
        value: value,
        child: Text(label, style: textStyle),
      );
    }).toList();

    final containsSelected =
        _selectedValue != null && items.any((it) => it.value == _selectedValue);

    return DropdownButtonFormField<String>(
      initialValue: containsSelected ? _selectedValue : null,
      isExpanded: widget.isExpanded,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        prefixIcon: widget.icon is IconData
            ? Icon(widget.icon as IconData, size: 20, color: BColors.grey)
            : (widget.icon is Widget
                ? widget.icon as Widget
                : const Icon(Iconsax.arrow_down_1,
                    size: 20, color: BColors.grey)),
        labelText: widget.label,
        hintText: widget.hint ?? 'Select',
      ),
      items: items,
      onChanged: widget.readOnly
          ? null
          : (String? newValue) {
              setState(() => _selectedValue = newValue);
              if (widget.controller != null) {
                widget.controller!.text = newValue ?? '';
              }
              if (widget.onChanged != null) widget.onChanged!(newValue);
            },
      style: textStyle,
      dropdownColor: dark ? BColors.dark : Colors.white,
      validator: widget.validator,
    );
  }
}

class _SearchableDropdownDialog extends StatefulWidget {
  final List<dynamic> items;
  final String? selectedValue;
  final String Function(dynamic) getItemValue;
  final String Function(dynamic) getItemLabel;
  final TextStyle? textStyle;
  final String hint;

  const _SearchableDropdownDialog({
    required this.items,
    required this.selectedValue,
    required this.getItemValue,
    required this.getItemLabel,
    required this.textStyle,
    required this.hint,
  });

  @override
  State<_SearchableDropdownDialog> createState() =>
      _SearchableDropdownDialogState();
}

class _SearchableDropdownDialogState extends State<_SearchableDropdownDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final label = widget.getItemLabel(item).toLowerCase();
          return label.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    return Dialog(
      backgroundColor: dark ? BColors.dark : Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.hint.toLowerCase()}...',
                  prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const Divider(height: 1),
            // Filtered items list
            Flexible(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No results found',
                          style:
                              widget.textStyle?.copyWith(color: BColors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final value = widget.getItemValue(item);
                        final label = widget.getItemLabel(item);
                        final isSelected = value == widget.selectedValue;

                        return ListTile(
                          title: Text(label, style: widget.textStyle),
                          selected: isSelected,
                          selectedTileColor: dark
                              ? BColors.primary.withValues(alpha: 0.2)
                              : BColors.primary.withValues(alpha: 0.1),
                          trailing: isSelected
                              ? const Icon(Icons.check,
                                  color: BColors.primary, size: 20)
                              : null,
                          onTap: () {
                            Navigator.of(context).pop(value);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
