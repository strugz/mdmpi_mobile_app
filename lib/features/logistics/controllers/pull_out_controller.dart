import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/pull_out/pull_out_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart'; // For RequestFilter reuse

/// Controller for managing pull-out requests state and operations.
class PullOutController extends GetxController {
  // Resolve repository via GetX DI per project conventions.
  final PullOutRepository _repository = Get.find();

  static PullOutController get instance => Get.find();

  /// Raw list of pull-out requests.
  final RxList<PullOutModel> pullOuts = <PullOutModel>[].obs;

  /// Loading flag for list operations.
  final RxBool isLoading = false.obs;

  /// Loading flag for save/update operations.
  final RxBool isSaving = false.obs;

  /// Last error message, if any.
  final RxnString errorMessage = RxnString();

  /// Manager for date & status filtering.
  late final PullOutFilterManager filterManager;

  @override
  void onInit() {
    super.onInit();
    filterManager = PullOutFilterManager();
    loadPullOuts();
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
      // Re-apply filters after data changes
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
      logDebug('PullOutController: updating pull-out...');
      await _repository.updatePullOut(model);
      await loadPullOuts();
    } catch (e) {
      errorMessage.value = e.toString();
      logDebug('PullOutController: failed to update pull-out: $e');
    } finally {
      isSaving.value = false;
    }
  }
}
