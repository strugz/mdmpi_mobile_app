import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../features/logistics/models/client_model.dart';

class RequestFormState {
  final TextEditingController shippingMethod = TextEditingController(text: 'Land');
  final TextEditingController deliveryTerms = TextEditingController(text: 'Full');
  final TextEditingController targetDate = TextEditingController();
  final TextEditingController requestedBy = TextEditingController();
  final TextEditingController preference = TextEditingController(text: 'Low');
  final TextEditingController selectedDriver = TextEditingController();
  final TextEditingController selectedHelper = TextEditingController();
  final TextEditingController receiver = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController tripTicketNumber = TextEditingController();
  final RxList<TextEditingController> documentReferenceControllers = <TextEditingController>[].obs;
  final Rx<DateTime?> deliveryDate = Rx<DateTime?>(null);
  final Rx<ClientModel?> clientInformation = Rx<ClientModel?>(ClientModel.empty());
  final RxString cameraDropOffPicture = RxString("");
  final RxString cameraPickUpPicture = RxString("");
  final Rx<Uint8List?> receiverSignatureBytes = Rx<Uint8List?>(null);
  final RxString receiverSignatureBase64 = RxString("");
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void initializeDefaultDate() {
    DateTime defaultDate = DateTime.now();
    targetDate.text = DateFormat('yyyy-MM-dd').format(defaultDate);
  }

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
  }

  void dispose() {
    shippingMethod.dispose();
    deliveryTerms.dispose();
    targetDate.dispose();
    requestedBy.dispose();
    preference.dispose();
    selectedDriver.dispose();
    selectedHelper.dispose();
    receiver.dispose();
    mobile.dispose();
    for (var controller in documentReferenceControllers) {
      controller.dispose();
    }
  }
}
