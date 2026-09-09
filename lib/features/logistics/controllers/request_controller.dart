import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/models/form_category_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/standard_delivery_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/hotline_direct/hotline_direct_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/hotline_direct/widgets/hotline_direct_filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/pull_out_return_pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/stock_receive/stock_receive_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/stock_receive/widgets/stock_receive_filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/air_sea_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/filter_dropdown.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';

/// Controller for managing the Request screen state and business logic.
///
/// Responsibilities:
/// - Load and sort form categories from repository
/// - Manage current tab/page index reactively
/// - Map category names to appropriate controllers, widgets, and forms
/// - Handle tab/carousel synchronization logic
/// - Provide navigation to form pages with pre-selected categories
/// - Track loading states and errors
///
/// This controller centralizes all business logic that was previously
/// embedded in the RequestScreen StatefulWidget, following GetX architecture
/// patterns and keeping the UI layer pure.
class RequestController extends GetxController {
  static RequestController get instance => Get.find();

  // ========================================================================
  // STATE PROPERTIES
  // ========================================================================

  /// Observable list of form categories (sorted by display order).
  /// This is the complete list of available request types.
  final RxList<FormCategoryModel> formCategories = <FormCategoryModel>[].obs;

  /// Loading state for categories fetch operation.
  /// Used to show loading indicators in the UI while fetching categories.
  final RxBool isLoadingCategories = true.obs;

  /// Current active tab/page index.
  /// Synced with both TabController and CarouselController.
  final RxInt currentTabIndex = 0.obs;

  /// Currently selected form category based on active tab.
  /// This is used to pre-select the form category when opening forms.
  final Rx<FormCategoryModel?> currentSelectedCategory =
      Rx<FormCategoryModel?>(null);

  /// Stores the most recent error message from failed operations.
  /// Null when no error has occurred.
  final RxnString errorMessage = RxnString();

  // ========================================================================
  // CONSTANTS
  // ========================================================================

  /// Define the desired display order for form categories.
  /// Categories will be sorted according to this order when loaded.
  static const List<String> categoryOrder = [
    'Standard Delivery',
    'Pull Out / Return',
    'Pick Up',
    'Air / Sea / Land',
    'Air / Sea / Land HD',
    'Hotline Direct',
    'Stock Receive',
  ];

  // ========================================================================
  // INITIALIZATION
  // ========================================================================

  @override
  void onInit() {
    super.onInit();
    loadFormCategories();
  }

  // ========================================================================
  // DATA LOADING
  // ========================================================================

  /// Load form categories from repository and sort them according to predefined order.
  /// Sets loading state and handles errors appropriately.
  ///
  /// Loads cache-first (the repository falls back to the API when the local
  /// DB is empty), then refreshes from the server in the background so the
  /// screen renders instantly on subsequent opens.
  Future<void> loadFormCategories() async {
    try {
      isLoadingCategories.value = true;
      errorMessage.value = null;

      final repo = Get.find<FormCategoryRepository>();
      final categories = await repo.getAll();

      // Sort categories according to the defined order
      final sortedCategories = _sortCategoriesByOrder(categories);

      formCategories.value = sortedCategories;

      // Set initial selected category
      if (sortedCategories.isNotEmpty) {
        currentSelectedCategory.value = sortedCategories[0];
      }
    } catch (e) {
      errorMessage.value = 'Failed to load categories: $e';
      formCategories.clear();
      currentSelectedCategory.value = null;
    } finally {
      isLoadingCategories.value = false;
    }

    // Refresh from the server without blocking the UI; the cached list is
    // already on screen.
    unawaited(_refreshFormCategoriesInBackground());
  }

  /// Fetch the latest categories from the API and update state only when the
  /// server data differs from what is currently displayed.
  Future<void> _refreshFormCategoriesInBackground() async {
    try {
      final repo = Get.find<FormCategoryRepository>();
      final fresh = _sortCategoriesByOrder(await repo.getAll(forceRefresh: true));

      if (fresh.isEmpty || _sameCategories(fresh, formCategories)) {
        return;
      }

      formCategories.value = fresh;

      // Keep the selection valid if the list shrank.
      if (currentTabIndex.value >= fresh.length) {
        currentTabIndex.value = fresh.length - 1;
      }
      currentSelectedCategory.value = fresh[currentTabIndex.value];
    } catch (e) {
      // Cached data is already displayed; a failed refresh is not an error
      // worth surfacing.
      logDebug('RequestController: background category refresh failed: $e');
    }
  }

  bool _sameCategories(
      List<FormCategoryModel> a, List<FormCategoryModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].name != b[i].name) return false;
    }
    return true;
  }

  /// Sort categories according to the predefined order.
  /// Categories not in the order list are appended at the end.
  List<FormCategoryModel> _sortCategoriesByOrder(
      List<FormCategoryModel> categories) {
    final sorted = <FormCategoryModel>[];

    // Add categories in the defined order. Match by resolved category type
    // (which accepts legacy names) so a renamed category keeps its position
    // while the server row rename deploys.
    for (final orderName in categoryOrder) {
      final orderType = FormCategoryConstants.fromCategoryName(orderName);
      final category = categories.firstWhereOrNull((c) =>
          c.name.toLowerCase() == orderName.toLowerCase() ||
          (orderType != null &&
              FormCategoryConstants.fromCategoryName(c.name) == orderType));
      if (category != null) {
        sorted.add(category);
      }
    }

    // Add any remaining categories that weren't in the order list
    for (final category in categories) {
      if (!sorted.any((c) => c.id == category.id)) {
        sorted.add(category);
      }
    }

    return sorted;
  }

  // ========================================================================
  // CATEGORY MAPPING
  // ========================================================================

  /// Maps form category name to the appropriate controller instance.
  /// Returns null if no controller is found for the given category.
  dynamic getControllerForCategory(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    try {
      // Exact-name resolution first: 'Air / Sea / Land HD' would otherwise be
      // swallowed by the fuzzy contains('air')/contains('sea') branch below.
      if (FormCategoryConstants.fromCategoryName(categoryName) ==
          FormCategoryType.airSeaHd) {
        return Get.find<AirSeaHdController>();
      }
      if (lowerName.contains('standard') || lowerName.contains('delivery')) {
        return Get.find<StandardDeliveryController>();
      } else if (lowerName.contains('pull')) {
        return Get.find<PullOutController>();
      } else if (lowerName.contains('pick') && lowerName.contains('up')) {
        return Get.find<PickUpController>();
      } else if (lowerName.contains('air') || lowerName.contains('sea')) {
        return Get.find<AirSeaController>();
      } else if (lowerName.contains('hotline') ||
          lowerName.contains('direct')) {
        return Get.find<HotlineDirectController>();
      } else if (lowerName.contains('stock') && lowerName.contains('receive')) {
        return Get.find<StockReceiveController>();
      }
    } catch (e) {
      // Controller not found - may not be registered yet
      return null;
    }

    return null;
  }

  /// Maps form category to the appropriate list widget.
  /// Returns a placeholder widget if no implementation is available.
  Widget getListWidgetForCategory(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    // Exact-name resolution first (see getControllerForCategory).
    if (FormCategoryConstants.fromCategoryName(categoryName) ==
        FormCategoryType.airSeaHd) {
      return AirSeaList(controller: Get.find<AirSeaHdController>());
    }
    if (lowerName.contains('standard') || lowerName.contains('delivery')) {
      return const BList();
    } else if (lowerName.contains('pull')) {
      return const PullOutReturnPickUpList();
    } else if (lowerName.contains('pick') && lowerName.contains('up')) {
      return const PickUpList();
    } else if (lowerName.contains('air') || lowerName.contains('sea')) {
      return const AirSeaList();
    } else if (lowerName.contains('hotline') || lowerName.contains('direct')) {
      return const HotlineDirectList();
    } else if (lowerName.contains('stock') && lowerName.contains('receive')) {
      return const StockReceiveList();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No implementation available for "$categoryName"',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This category is coming soon.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds filter widgets for the given category index.
  /// Returns appropriate filter dropdowns based on the category type.
  Widget buildFilterForCategory(int index) {
    if (index >= formCategories.length) return const SizedBox.shrink();

    final category = formCategories[index];
    final controller = getControllerForCategory(category.name);
    final lowerName = category.name.toLowerCase();

    if (controller == null) {
      return const SizedBox.shrink();
    }

    // Standard Delivery filters
    if (lowerName.contains('standard') || lowerName.contains('delivery')) {
      final requestController = controller as StandardDeliveryController;
      return Column(
        children: [
          const BFilterDropdown(),
          const SizedBox(height: BSizes.spaceBtwItems),
          FilterDropdown(
            selectedFilter:
                requestController.filterManager.selectedStatusFilter,
            filterValues: StandardDeliveryStatusFilter.values,
            getDisplayName: (filter) => filter.displayName,
            onFilterChanged: (filter) {
              requestController.selectStatusFilter(filter);
            },
          ),

        ],
      );
    }

    // Pull Out / Return filters
    else if (lowerName.contains('pull')) {
      final pullOutController = controller as PullOutController;
      return Column(
        children: [
          FilterDropdown<RequestFilter>(
            selectedFilter: pullOutController.filterManager.selectedFilter,
            filterValues: RequestFilter.values,
            getDisplayName: (f) => f.displayName,
            onFilterChanged: (f) {
              pullOutController.selectDateFilter(f);
            },
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          FilterDropdown<PullOutStatusFilter>(
            selectedFilter:
                pullOutController.filterManager.selectedStatusFilter,
            filterValues: PullOutStatusFilter.values,
            getDisplayName: (f) => f.displayName,
            onFilterChanged: (f) {
              pullOutController.selectStatusFilter(f);
            },
          ),
        ],
      );
    }

    // Pick Up filters
    else if (lowerName.contains('pick') && lowerName.contains('up')) {
      final pickUpController = controller as PickUpController;
      return Column(
        children: [
          FilterDropdown<RequestFilter>(
            selectedFilter: pickUpController.filterManager.selectedFilter,
            filterValues: RequestFilter.values,
            getDisplayName: (f) => f.displayName,
            onFilterChanged: (f) {
              pickUpController.selectDateFilter(f);
            },
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          FilterDropdown<PickUpStatusFilter>(
            selectedFilter: pickUpController.filterManager.selectedStatusFilter,
            filterValues: PickUpStatusFilter.values,
            getDisplayName: (f) => f.displayName,
            onFilterChanged: (f) {
              pickUpController.selectStatusFilter(f);
            },
          ),
        ],
      );
    }

    // Air / Sea filters
    else if (lowerName.contains('air') || lowerName.contains('sea')) {
      final airSeaController = controller as AirSeaController;
      return Column(
        children: [
          FilterDropdown<RequestFilter>(
            selectedFilter: airSeaController.filterManager.selectedFilter,
            filterValues: RequestFilter.values,
            getDisplayName: (f) => f.displayName,
            onFilterChanged: (f) {
              airSeaController.selectDateFilter(f);
            },
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          FilterDropdown<AirSeaStatusFilter>(
            selectedFilter: airSeaController.filterManager.selectedStatusFilter,
            filterValues: AirSeaStatusFilter.values,
            getDisplayName: (f) => f.displayName,
            onFilterChanged: (f) {
              airSeaController.selectStatusFilter(f);
            },
          ),
        ],
      );
    }

    // Hotline Direct filters
    else if (lowerName.contains('hotline') || lowerName.contains('direct')) {
      final hotlineDirectController = controller as HotlineDirectController;
      return Column(
        children: [
          const HotlineDirectFilterDropdown(),
          const SizedBox(height: BSizes.spaceBtwItems),
          FilterDropdown(
            selectedFilter:
                hotlineDirectController.filterManager.selectedStatusFilter,
            filterValues: StandardDeliveryStatusFilter.values,
            getDisplayName: (filter) => filter.displayName,
            onFilterChanged: (filter) {
              hotlineDirectController.selectStatusFilter(filter);
            },
          ),
        ],
      );
    }

    // Stock Receive filters
    else if (lowerName.contains('stock') && lowerName.contains('receive')) {
      final stockReceiveController = controller as StockReceiveController;
      return Column(
        children: [
          const StockReceiveFilterDropdown(),
          const SizedBox(height: BSizes.spaceBtwItems),
          FilterDropdown<PullOutStatusFilter>(
            selectedFilter:
                stockReceiveController.filterManager.selectedStatusFilter,
            // For Pull Out is a Pull Out / Return-only status; Stock Receive
            // keeps its New Request → In Transit → Taken Out flow.
            filterValues: PullOutStatusFilter.values
                .where((f) => f != PullOutStatusFilter.statusForPullOut)
                .toList(),
            getDisplayName: (f) => f.displayName,
            onFilterChanged: (f) {
              stockReceiveController.selectStatusFilter(f);
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ========================================================================
  // NAVIGATION
  // ========================================================================

  /// Opens the appropriate request form based on the currently selected category.
  /// The form will read currentSelectedCategory from this controller to pre-select the category.
  void openFormForCurrentCategory() {
    if (formCategories.isEmpty) {
      return;
    }

    final index = currentTabIndex.value;
    if (index < 0 || index >= formCategories.length) {
      return;
    }

    final category = formCategories[index];
    final lowerName = category.name.toLowerCase();

    // Update current selected category for form to read
    currentSelectedCategory.value = category;

    // Map category names to their appropriate form pages
    Widget? formPage;

    if (lowerName.contains('standard') || lowerName.contains('delivery')) {
      formPage = AppRoutes.requestFormPages[0]; // StandardDelivery()
    } else if (lowerName.contains('pull')) {
      formPage = AppRoutes.requestFormPages[1]; // PullOutForm()
    } else if (lowerName.contains('pick') && lowerName.contains('up')) {
      formPage = AppRoutes.requestFormPages[2]; // PickUpForm()
    } else if (lowerName.contains('air') || lowerName.contains('sea')) {
      formPage = AppRoutes.requestFormPages[3]; // AirSeaForm()
    } else if (lowerName.contains('hotline') || lowerName.contains('direct')) {
      // Hotline Direct uses Standard Delivery form
      formPage = AppRoutes.requestFormPages[0]; // StandardDelivery()
    } else if (lowerName.contains('stock') && lowerName.contains('receive')) {
      // Stock Receive uses Pull Out form
      formPage = AppRoutes.requestFormPages[1]; // PullOutForm()
    }

    if (formPage != null) {
      // No arguments needed - form will read from RequestController.currentSelectedCategory
      Get.to(() => formPage!);
    }
  }

  // ========================================================================
  // TAB/PAGE MANAGEMENT
  // ========================================================================

  /// Update current tab index.
  /// Called when user swipes carousel or taps on tab.
  /// Also updates the currentSelectedCategory for form pre-selection.
  void updateTabIndex(int index) {
    if (index >= 0 && index < formCategories.length) {
      currentTabIndex.value = index;
      currentSelectedCategory.value = formCategories[index];
    }
  }

  /// Get storage preference (Server/Local) for the current category controller.
  /// Returns true if using local storage, false if using server.
  bool getStoragePreferenceForCategory(String categoryName) {
    final controller = getControllerForCategory(categoryName);

    if (controller == null) {
      return false;
    }

    try {
      if (controller is StandardDeliveryController) {
        return controller.useLocalStorage.value;
      } else if (controller is PullOutController) {
        return controller.useLocalStorage.value;
      } else if (controller is PickUpController) {
        return controller.useLocalStorage.value;
      } else if (controller is AirSeaController) {
        return controller.useLocalStorage.value;
      } else if (controller is HotlineDirectController) {
        return controller.useLocalStorage.value;
      } else if (controller is StockReceiveController) {
        return controller.useLocalStorage.value;
      }
    } catch (e) {
      // Handle any errors when accessing controller properties
      return false;
    }

    return false;
  }

  /// Toggle storage preference for the current category controller.
  void toggleStoragePreferenceForCategory(
      String categoryName, bool useLocalStorage) {
    final controller = getControllerForCategory(categoryName);

    if (controller == null) {
      return;
    }

    if (controller is StandardDeliveryController) {
      controller.toggleStoragePreference(useLocalStorage);
    } else if (controller is PullOutController) {
      controller.toggleStoragePreference(useLocalStorage);
    } else if (controller is PickUpController) {
      controller.toggleStoragePreference(useLocalStorage);
    } else if (controller is AirSeaController) {
      controller.toggleStoragePreference(useLocalStorage);
    } else if (controller is HotlineDirectController) {
      controller.toggleStoragePreference(useLocalStorage);
    } else if (controller is StockReceiveController) {
      controller.toggleStoragePreference(useLocalStorage);
    }
  }
}
