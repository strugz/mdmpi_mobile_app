import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/common/controllers/autocomplete_controller.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/models/client_contact_person_model.dart';

/// A reusable autocomplete text field that stores and suggests previously
/// entered values from a local database.
///
/// Usage:
/// ```dart
/// // In controller or form state:
/// final autocompleteController = AutocompleteController();
/// autocompleteController.initialize(myTextController);
///
/// // In widget:
/// BAutocompleteTextField(
///   controller: myController,
///   autocompleteController: autocompleteController,
///   label: 'Client Contact Person',
///   validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
class BAutocompleteTextField extends StatelessWidget {
  const BAutocompleteTextField({
    super.key,
    required this.controller,
    required this.autocompleteController,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.words,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final AutocompleteController autocompleteController;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ClientContactPersonModel>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<ClientContactPersonModel>.empty();
        }

        try {
          final dao = await DatabaseHelper.instance.clientContactPersonDao;
          final results = await dao.search(
            textEditingValue.text.trim(),
            limit: autocompleteController.maxSuggestions,
          );
          return results;
        } catch (e) {
          return const Iterable<ClientContactPersonModel>.empty();
        }
      },
      displayStringForOption: (ClientContactPersonModel option) => option.name,
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sync the external controller with the autocomplete's field controller
        fieldController.text = controller.text;
        fieldController.addListener(() {
          controller.text = fieldController.text;
        });
        controller.addListener(() {
          if (fieldController.text != controller.text) {
            fieldController.text = controller.text;
          }
        });

        return Obx(() {
          return TextFormField(
            controller: fieldController,
            focusNode: focusNode,
            validator: validator,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              suffixIcon: autocompleteController.isLoading.value
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(BColors.primary),
                        ),
                      ),
                    )
                  : null,
            ),
          );
        });
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<ClientContactPersonModel> onSelected,
        Iterable<ClientContactPersonModel> options,
      ) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.withValues(alpha: 0.5)
                      : BColors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark
                      ? Colors.grey.withValues(alpha: 0.3)
                      : BColors.grey.withValues(alpha: 0.2),
                ),
                itemBuilder: (BuildContext context, int index) {
                  final suggestion = options.elementAt(index);
                  final textColor = isDark ? Colors.white : Colors.black;

                  return ListTile(
                    dense: true,
                    title: Text(
                      suggestion.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                    ),
                    trailing: suggestion.usageCount > 1
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${suggestion.usageCount}x',
                              style: TextStyle(
                                fontSize: 10,
                                color: BColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      onSelected(suggestion);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (ClientContactPersonModel selection) {
        controller.text = selection.name;
        autocompleteController.selectSuggestion(selection.name);
      },
    );
  }
}

/// Save a contact person name to the local database for future autocomplete.
/// Should be called after successful form submission.
Future<void> saveClientContactPerson(String name) async {
  if (name.trim().isEmpty) return;

  try {
    final dao = await DatabaseHelper.instance.clientContactPersonDao;
    await dao.upsert(name.trim());
  } catch (e) {
    // Silent fail - don't block the user flow for autocomplete save issues
    print('Failed to save contact person: $e');
  }
}
