import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../features/logistics/models/client_model.dart';
import '../../../data/models/item_category_model.dart';
import '../../../data/models/form_category_model.dart';
import '../../../data/models/inventory_item_model.dart';
import 'commute_id.dart';

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

  // "Commuting" switch: fills [tripTicketNumber] with a Commute ID.
  final CommuteTicketToggle commute = CommuteTicketToggle();

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

  // Backloaded items entered by the courier before drop off: itemCode →
  // remark. Presence of a key means the item is marked "not received by the
  // client" (backloaded); the remark is required before Done Delivery.
  // Saved to `a_tblbackloaditem` on the drop-off transition.
  final RxMap<String, String> backloadItemRemarks = <String, String>{}.obs;

  // The request the entries in [backloadItemRemarks] belong to. The editable
  // section clears stale entries when the courier opens a different request.
  final RxString backloadItemsRequestId = RxString('');

  // Standard Delivery one-scan (plan §4.4a/§4.4b A6): the scanned address the
  // review sheet put on the client because its saved address was missing.
  // Saved with the request only while that same client is still selected.
  final Rx<({String clientId, String address})?> scannedFallbackAddress =
      Rx<({String clientId, String address})?>(null);

  /// The delivery address to store on the request: the scanned fallback when
  /// it belongs to the selected client, otherwise empty (today's payload).
  String deliveryAddressFor(String selectedClientId) {
    final fallback = scannedFallbackAddress.value;
    if (fallback == null || fallback.clientId != selectedClientId) return '';
    return fallback.address;
  }

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
    requestedBy.clear();
    formKey.currentState?.reset();
    documentReferenceControllers.clear();
    clientInformation.value = ClientModel.empty();
    scannedFallbackAddress.value = null;
    receiverSignatureBytes.value = null;
    receiverSignatureBase64.value = "";
     selectedDriver.clear();
     selectedHelper.clear();
     receiver.clear();
     recipientContactDetails.clear();
     recipientName.clear();
     mobile.clear();
    tripTicketNumber.clear();
    commute.reset();
    remarks.clear();

    // Clear dynamic lists
    documentReferenceControllers.forEach((c) => c.clear());
    // Also clear scanned inventory items when resetting the form
    scannedInventoryItems.clear();
    backloadItemRemarks.clear();
    backloadItemsRequestId.value = '';

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
