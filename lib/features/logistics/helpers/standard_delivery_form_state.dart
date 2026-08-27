import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../features/logistics/models/client_model.dart';
import '../../../data/models/item_category_model.dart';
import '../../../data/models/form_category_model.dart';
import '../../../data/models/inventory_item_model.dart';

/// Encapsulates all form-related state for Standard Delivery requests.
///
/// Responsibilities:
/// - Manages text controllers for all form fields
/// - Maintains reactive state (Rx) for client, document references, images, signature
/// - Provides initialization, reset, and disposal methods
/// - Stores loaded category lists for dropdown population
class StandardDeliveryFormState {
  // Basic delivery fields
  final TextEditingController shippingMethod = TextEditingController(text: 'Land');
  final TextEditingController deliveryTerms = TextEditingController(text: 'Full');
  final TextEditingController targetDate = TextEditingController();
  final TextEditingController requestedBy = TextEditingController();
  final TextEditingController preference = TextEditingController(text: 'Low');

  // Driver and delivery personnel fields
  final TextEditingController selectedDriver = TextEditingController();
  final TextEditingController selectedHelper = TextEditingController();
  final TextEditingController receiver = TextEditingController();
  final TextEditingController recipientContactDetails = TextEditingController();
  final TextEditingController recipientName = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController tripTicketNumber = TextEditingController();
  final TextEditingController remarks = TextEditingController();

  // Category fields
  final TextEditingController itemCategory = TextEditingController();
  final TextEditingController formCategory = TextEditingController();

  // Document references (dynamic list)
  final RxList<TextEditingController> documentReferenceControllers = <TextEditingController>[].obs;

  // Scanned inventory items populated by OCR/file analysis.
  // Kept in the form state so that form serialization and UI bindings
  // (e.g., BInventoryScanner) can read/write this list via the controller's
  // formState reference. Use reactive list to allow Obx bindings.
  final RxList<InventoryItemModel> scannedInventoryItems = <InventoryItemModel>[].obs;

  // Reactive state
  final Rx<DateTime?> deliveryDate = Rx<DateTime?>(null);
  final Rx<ClientModel?> clientInformation = Rx<ClientModel?>(ClientModel.empty());
  final RxString cameraDropOffPicture = RxString("");
  final RxString cameraPickUpPicture = RxString("");
  final Rx<Uint8List?> receiverSignatureBytes = Rx<Uint8List?>(null);
  final RxString receiverSignatureBase64 = RxString("");

  // Form validation key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Category lists for dropdowns
  final RxList<ItemCategoryModel> itemCategories = <ItemCategoryModel>[].obs;
  final RxList<FormCategoryModel> formCategories = <FormCategoryModel>[].obs;

  /// Initialize default date to today.
  void initializeDefaultDate() {
    DateTime defaultDate = DateTime.now();
    targetDate.text = DateFormat('yyyy-MM-dd').format(defaultDate);
  }

  /// Reset all form fields to their default values.
  /// Clears document references, client information, and signatures.
  void reset() {
    shippingMethod.text = 'Land';
    deliveryTerms.text = 'Full';
    cameraDropOffPicture.value = "";
    preference.text = 'Low';
    formKey.currentState?.reset();
    documentReferenceControllers.clear();
    clientInformation.value = ClientModel.empty();
    receiverSignatureBytes.value = null;
    receiverSignatureBase64.value = "";
     selectedDriver.clear();
     selectedHelper.clear();
     receiver.clear();
     recipientContactDetails.clear();
     recipientName.clear();
     mobile.clear();
    tripTicketNumber.clear();
    remarks.clear();

    // Clear dynamic lists
    documentReferenceControllers.forEach((c) => c.clear());
    // Also clear scanned inventory items when resetting the form
    scannedInventoryItems.clear();

    // Restore category defaults if already loaded
    if (formCategories.isNotEmpty) {
      final defaultForm = formCategories.firstWhere(
        (e) => e.name.toLowerCase().contains('standard'),
        orElse: () => formCategories.first,
      );
      formCategory.text = defaultForm.id;
    }

    if (itemCategories.isNotEmpty) {
      final defaultItem = itemCategories.firstWhere(
        (e) => e.name.toLowerCase().contains('reagent'),
        orElse: () => itemCategories.first,
      );
      itemCategory.text = defaultItem.id;
    }
  }

  /// Dispose all text controllers to prevent memory leaks.
  void dispose() {
    shippingMethod.dispose();
    deliveryTerms.dispose();
    targetDate.dispose();
    requestedBy.dispose();
    preference.dispose();
     selectedDriver.dispose();
     selectedHelper.dispose();
     receiver.dispose();
     recipientContactDetails.dispose();
     recipientName.dispose();
     mobile.dispose();
    tripTicketNumber.dispose();
    remarks.dispose();

    // Dispose document reference controllers
    for (final c in documentReferenceControllers) {
      try {
        c.dispose();
      } catch (_) {}
    }

    // Clear scanned inventory items (no dispose needed for model objects)
    scannedInventoryItems.clear();
  }
}
