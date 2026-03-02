import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../features/logistics/models/client_model.dart';
import '../../../data/models/item_category_model.dart';
import '../../../data/models/form_category_model.dart';
import '../../../common/controllers/autocomplete_controller.dart';

class PullOutFormState {
  final TextEditingController clientContactPersonController = TextEditingController();
  final TextEditingController irrfNumberController = TextEditingController();
  final TextEditingController irrfDateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController releasedByController = TextEditingController();
  final TextEditingController pullOutDateController = TextEditingController();
  final TextEditingController pullOutStartController = TextEditingController();
  final TextEditingController pullOutEndController = TextEditingController();
  final TextEditingController tripTicketController = TextEditingController();
  final TextEditingController driverController = TextEditingController();
  final TextEditingController helperController = TextEditingController();
  final TextEditingController formCategoryController = TextEditingController();
  final TextEditingController itemCategoryController = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final RxList<TextEditingController> documentReferenceControllers = <TextEditingController>[].obs;
  final Rx<ClientModel?> clientInformation = Rx<ClientModel?>(ClientModel.empty());
  final RxString cameraDropOffPicture = RxString("");
  final RxString cameraPickUpPicture = RxString("");
  final Rx<Uint8List?> receiverSignatureBytes = Rx<Uint8List?>(null);
  final RxString receiverSignatureBase64 = RxString("");
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxList<ItemCategoryModel> itemCategories = <ItemCategoryModel>[].obs;
  final RxList<FormCategoryModel> formCategories = <FormCategoryModel>[].obs;

  /// Autocomplete controller for Client Contact Person
  late final AutocompleteController clientContactPersonAutocomplete;

  PullOutFormState() {
    // Initialize autocomplete controller
    clientContactPersonAutocomplete = AutocompleteController();
    clientContactPersonAutocomplete.initialize(clientContactPersonController);
  }

  void initializeDefaultDate() {
    final defaultDate = DateTime.now();
    pullOutDateController.text = DateFormat('yyyy-MM-dd').format(defaultDate);
    // IRRF Date is optional - no default value
  }

  void reset() {
    clientContactPersonController.text = '';
    irrfNumberController.text = '';
    irrfDateController.text = '';
    reasonController.text = '';
    releasedByController.text = '';
    pullOutDateController.text = '';
    pullOutStartController.text = '';
    pullOutEndController.text = '';
    tripTicketController.text = '';
    driverController.text = '';
    helperController.text = '';
    formCategoryController.text = '';
    itemCategoryController.text = '';
    receiverSignatureBase64.value = '';
    mobile.text = '';

    // If categories are already loaded, restore sensible defaults so the UI
    // doesn't end up with empty selections after a reset.
    if (formCategories.isNotEmpty) {
      final defaultForm = formCategories.firstWhere(
        (e) => e.name.toLowerCase().contains('pull'),
        orElse: () => formCategories.first,
      );
      formCategoryController.text = defaultForm.id;
    }

    if (itemCategories.isNotEmpty) {
      final defaultItem = itemCategories.firstWhere(
        (e) => e.name.toLowerCase().contains('reagent'),
        orElse: () => itemCategories.first,
      );
      itemCategoryController.text = defaultItem.id;
    }

    cameraDropOffPicture.value = "";
    cameraPickUpPicture.value = "";
    formKey.currentState?.reset();
    for (var c in documentReferenceControllers) {
      try {
        c.dispose();
      } catch (_) {}
    }
    documentReferenceControllers.clear();
    clientInformation.value = ClientModel.empty();
    receiverSignatureBytes.value = null;
    receiverSignatureBase64.value = "";
  }

  void dispose() {
    clientContactPersonController.dispose();
    irrfNumberController.dispose();
    irrfDateController.dispose();
    reasonController.dispose();
    releasedByController.dispose();
    pullOutDateController.dispose();
    pullOutStartController.dispose();
    pullOutEndController.dispose();
    tripTicketController.dispose();
    driverController.dispose();
    helperController.dispose();
    mobile.dispose();
    formCategoryController.dispose();
    itemCategoryController.dispose();
    for (var controller in documentReferenceControllers) {
      controller.dispose();
    }
  }
}
