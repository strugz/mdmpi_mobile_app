import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/models/client_contact_person_model.dart';

/// Reusable controller for autocomplete functionality with local database storage.
/// 
/// Usage:
/// ```dart
/// final controller = Get.put(AutocompleteController(), tag: 'clientContact');
/// controller.initialize(myTextController);
/// 
/// // In widget:
/// BAutocompleteTextField(
///   controller: myTextController,
///   autocompleteController: controller,
///   label: 'Client Contact Person',
/// )
/// ```
class AutocompleteController extends GetxController {
  final RxList<ClientContactPersonModel> suggestions = <ClientContactPersonModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool showOverlay = false.obs;

  TextEditingController? _textController;
  int maxSuggestions = 5;

  @override
  void onInit() {
    super.onInit();
    _setupTextListener();
  }

  @override
  void onClose() {
    _textController?.removeListener(_onTextChanged);
    super.onClose();
  }

  /// Initialize the controller with a text controller and optional max suggestions.
  void initialize(TextEditingController textController, {int max = 5}) {
    _textController = textController;
    maxSuggestions = max;
    _setupTextListener();
  }

  void _setupTextListener() {
    _textController?.removeListener(_onTextChanged);
    _textController?.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    loadSuggestions();
  }

  /// Load suggestions from the database based on current text input.
  Future<void> loadSuggestions() async {
    if (_textController == null) return;

    isLoading.value = true;

    try {
      final dao = await DatabaseHelper.instance.clientContactPersonDao;
      final query = _textController!.text.trim();
      final results = await dao.search(query, limit: maxSuggestions);

      suggestions.assignAll(results);
      showOverlay.value = results.isNotEmpty;
    } catch (e) {
      suggestions.clear();
      showOverlay.value = false;
      // Silent fail - don't block user flow
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a suggestion and populate the text field.
  void selectSuggestion(String value) {
    if (_textController == null) return;
    
    _textController!.text = value;
    _textController!.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    hideOverlay();
  }

  /// Hide the suggestions overlay.
  void hideOverlay() {
    showOverlay.value = false;
    suggestions.clear();
  }

  /// Show suggestions for the current input.
  void show() {
    loadSuggestions();
  }

  /// Clear all suggestions and hide overlay.
  void clear() {
    suggestions.clear();
    showOverlay.value = false;
  }
}

