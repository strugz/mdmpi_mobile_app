import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../features/logistics/models/client_model.dart';
import '../../../data/models/item_category_model.dart';

class PickUpFormState {
  final TextEditingController preparedByController = TextEditingController();
  final TextEditingController itemPreparedAtController = TextEditingController();
  final TextEditingController itemPreparedEndAtController = TextEditingController();
  final TextEditingController datePickUpController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController releasedByController = TextEditingController();
  final TextEditingController receivedByController = TextEditingController();
  final TextEditingController itemCategoryController = TextEditingController();
  final RxList<TextEditingController> documentReferenceControllers = <TextEditingController>[].obs;
  final Rx<ClientModel?> clientInformation = Rx<ClientModel?>(ClientModel.empty());
  final RxString cameraDropOffPicture = RxString("");
  final RxString cameraPickUpPicture = RxString("");
  final Rx<Uint8List?> receiverSignatureBytes = Rx<Uint8List?>(null);
  final RxString receiverSignatureBase64 = RxString("");
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxList<ItemCategoryModel> itemCategories = <ItemCategoryModel>[].obs;

  void initializeDefaultDate() {
    final defaultDate = DateTime.now();
    datePickUpController.text = DateFormat('yyyy-MM-dd').format(defaultDate);
  }

  void reset() {
    preparedByController.text = '';
    itemPreparedAtController.text = '';
    itemPreparedEndAtController.text = '';
    datePickUpController.text = '';
    remarksController.text = '';
    releasedByController.text = '';
    receivedByController.text = '';
    itemCategoryController.text = '';
    receiverSignatureBase64.value = '';

    // If categories are already loaded, restore sensible defaults so the UI
    // doesn't end up with empty selections after a reset.
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
    preparedByController.dispose();
    itemPreparedAtController.dispose();
    itemPreparedEndAtController.dispose();
    datePickUpController.dispose();
    remarksController.dispose();
    releasedByController.dispose();
    receivedByController.dispose();
    itemCategoryController.dispose();
    for (var controller in documentReferenceControllers) {
      controller.dispose();
    }
  }
}

