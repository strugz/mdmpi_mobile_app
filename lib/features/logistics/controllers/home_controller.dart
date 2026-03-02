import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

/// Controller for Home screen - aggregates dashboard statistics from various module controllers.
///
/// Responsibilities:
/// - Aggregate statistics from all logistics module controllers
/// - Provide reactive dashboard data to the UI
/// - Keep UI layer pure by centralizing all business logic here
class HomeController extends GetxController {
  static HomeController get instance => Get.find();

  // ========================================================================
  // DEPENDENCIES
  // ========================================================================

  late final StandardDeliveryController _standardDeliveryController;

  // ========================================================================
  // COMPUTED PROPERTIES - Dashboard Statistics
  // ========================================================================

  /// Total requests across all modules.
  /// Currently aggregates from Standard Delivery only.
  /// TODO: Add other modules (Pull Out, Pick Up, Air/Sea, etc.) when available.
  int get totalRequest => _standardDeliveryController.totalRequest.value;

  /// Count of requests in "Getting Supplies Ready" status.
  int get gettingSuppliesReady => _standardDeliveryController.gettingSuppliesReady.value;

  /// Count of requests in "Items Prepared" status.
  int get itemPrepared => _standardDeliveryController.itemPrepared.value;

  /// Count of requests in "For Delivery" status.
  int get forDelivery => _standardDeliveryController.forDelivery.value;

  /// Count of requests in "Delivered" status.
  int get delivered => _standardDeliveryController.delivered.value;

  /// Current year for dashboard display.
  String get currentYear => DateTime.now().year.toString();

  // ========================================================================
  // LIFECYCLE
  // ========================================================================

  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
  }

  /// Initialize controller dependencies.
  void _initializeDependencies() {
    try {
      _standardDeliveryController = Get.find<StandardDeliveryController>();
    } catch (e) {
      // Log error but don't crash - UI will show 0 values
      print('HomeController: Failed to initialize StandardDeliveryController: $e');
    }
  }

  // ========================================================================
  // METHODS
  // ========================================================================

  /// Refresh dashboard statistics.
  /// Can be called when user pulls to refresh.
  Future<void> refreshDashboard() async {
    try {
      await _standardDeliveryController.loadRequests();
    } catch (e) {
      print('HomeController: Failed to refresh dashboard: $e');
    }
  }
}
