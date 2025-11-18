import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/pull_out/pull_out_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart'; // For RequestFilter reuse
import 'package:mdmpi_mobile_app/data/models/item_category_model.dart';
import 'package:mdmpi_mobile_app/data/models/form_category_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_form_state.dart';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

/// Controller for managing pull-out requests state and operations.
class PullOutController extends GetxController {
  final PullOutRepository _repository = Get.find();

  static PullOutController get instance => Get.find();

  /// Raw list of pull-out requests.
  final RxList<PullOutModel> pullOuts = <PullOutModel>[].obs;

  /// Currently selected pull-out (for UI actions/navigation).
  final Rx<PullOutModel?> currentSelectedPullOut = Rx<PullOutModel?>(null);

  /// Loading flag for list operations.
  final RxBool isLoading = false.obs;

  /// Loading flag for save/update operations.
  final RxBool isSaving = false.obs;

  /// Last error message, if any.
  final RxnString errorMessage = RxnString();

  /// Manager for date & status filtering.
  late final PullOutFilterManager filterManager;

  /// --- Form state and controllers ---
  late final RequestFormState formState;

  final TextEditingController slipNoController = TextEditingController();
  final TextEditingController clientContactPersonController =
      TextEditingController();
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

  /// CreatedBy is derived from the logged-in user and stored here (not exposed as an editable UI field).
  String createdBy = '';

  final TextEditingController formCategoryController = TextEditingController();
  final TextEditingController itemCategoryController = TextEditingController();

  // Category caches
  final RxList<ItemCategoryModel> itemCategories = <ItemCategoryModel>[].obs;
  final RxList<FormCategoryModel> formCategories = <FormCategoryModel>[].obs;

  Map<String, String> get _itemNameToId =>
      {for (var e in itemCategories) e.name: e.id};
  Map<String, String> get _formNameToId =>
      {for (var e in formCategories) e.name: e.id};

  /// Load categories from repositories (safe to call repeatedly)
  Future<void> loadCategories() async {
    try {
      final items = await Get.find<ItemCategoryRepository>().getAll();
      final forms = await Get.find<FormCategoryRepository>().getAll();
      itemCategories.assignAll(items);
      formCategories.assignAll(forms);

      if (formCategoryController.text.trim().isEmpty &&
          formCategories.isNotEmpty) {
        final defaultForm = formCategories.firstWhere(
          (e) => e.name.toLowerCase().contains('pull'),
          orElse: () => formCategories.first,
        );
        formCategoryController.text = defaultForm.name;
      }

      if (itemCategoryController.text.trim().isEmpty &&
          itemCategories.isNotEmpty) {
        final defaultItem = itemCategories.firstWhere(
          (e) => e.name.toLowerCase().contains('reagent'),
          orElse: () => itemCategories.first,
        );
        itemCategoryController.text = defaultItem.name;
      }
    } catch (e) {
      logDebug('PullOutController.loadCategories failed: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    filterManager = PullOutFilterManager();
    formState = RequestFormState();
    formState.initializeDefaultDate();
    loadCategories();
    loadPullOuts();

    final userCtrl = Get.find<UserController>();
    createdBy = userCtrl.user.value.initial;
  }

  /// Convenience access to filtered list.
  List<PullOutModel> get filteredPullOuts => filterManager.filteredPullOuts;

  /// Update status filter.
  void selectStatusFilter(PullOutStatusFilter statusFilter) {
    filterManager.selectStatusFilter(statusFilter, pullOuts);
  }

  /// Update date filter.
  void selectDateFilter(RequestFilter filter) {
    filterManager.selectFilter(filter, pullOuts);
  }

  /// Fetch all pull-out requests from repository.
  Future<void> loadPullOuts() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      logDebug('PullOutController: loading pull-outs...');
      final results = await _repository.getAll();
      pullOuts.assignAll(results);
      filterManager.applyFilter(pullOuts.toList());
    } catch (e) {
      errorMessage.value = e.toString();
      logDebug('PullOutController: failed to load pull-outs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Insert a new pull-out request and refresh the list.
  Future<void> addPullOut(PullOutModel model) async {
    if (isSaving.value) return;
    isSaving.value = true;
    errorMessage.value = null;
    try {
      logDebug('PullOutController: inserting pull-out...');
      await _repository.insert(model);
      await loadPullOuts();
    } catch (e) {
      errorMessage.value = e.toString();
      logDebug('PullOutController: failed to insert pull-out: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Update an existing pull-out request and refresh the list.
  Future<void> updatePullOut(PullOutModel model) async {
    if (isSaving.value) return;
    isSaving.value = true;
    errorMessage.value = null;
    try {
      await _repository.updatePullOut(model);
      await loadPullOuts();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  /// Cancel a pull-out request with remarks.
  Future<void> cancelPullOut(String requestId, String remarks) async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await _repository.cancelPullOut(requestId, remarks);
      await loadPullOuts();
    } catch (e) {
      errorMessage.value = e.toString();
      logDebug('PullOutController.cancelPullOut failed: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Build a PullOutModel from the controllers and submit.
  Future<void> submitFromForm() async {
    if (isSaving.value) return;

    final stdController = Get.find<StandardDeliveryController>();
    final client = stdController.formState.clientInformation.value;
    final documentReferences = stdController
        .formState.documentReferenceControllers
        .map((c) => c.text)
        .toList();
    if (documentReferences.isEmpty) {
      documentReferences.add('');
    }

    final requestedByValue = Get.find<UserController>().user.value.initial;

    if (client == null || client.id.isEmpty) {
      BLoaders.errorSnackBar(
          title: 'Validation', message: 'Please select a client');
      return;
    }
    if (pullOutDateController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
          title: 'Validation', message: 'Please pick a pull out date');
      return;
    }

    final model = PullOutModel(
      clientId: client.id,
      client: client,
      clientContactPerson: clientContactPersonController.text,
      createdBy: createdBy.isNotEmpty ? createdBy : '',
      requestStatus: 'New Request',
      formCategoryId: _formNameToId[formCategoryController.text] ?? '',
      itemCategoryId: _itemNameToId[itemCategoryController.text] ?? '',
      slipNo: slipNoController.text,
      irrfNumber: irrfNumberController.text,
      irrfDate: irrfDateController.text,
      reasonForReturn: reasonController.text,
      releasedBy: releasedByController.text,
      pullOutDate: pullOutDateController.text,
      pullOutDateStartAt: pullOutStartController.text,
      pullOutDateEndAt: pullOutEndController.text,
      tripTicketNumber: tripTicketController.text,
      driver: driverController.text,
      helper: helperController.text,
      requestedBy: requestedByValue,
      documentReference: documentReferences,
    );
    await addPullOut(model);
  }

  @override
  void onClose() {
    try {
      slipNoController.dispose();
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
      formCategoryController.dispose();
      itemCategoryController.dispose();
      formState.dispose();
    } catch (_) {}
    super.onClose();
  }
}
