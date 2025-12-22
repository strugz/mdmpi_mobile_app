import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_floating_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/standard_delivery_list.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/pull_out_return_pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/air_sea_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/data/models/form_category_model.dart';

import '../controllers/standard_delivery_controller.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> with SingleTickerProviderStateMixin {
  List<FormCategoryModel> formCategories = [];
  bool isLoadingCategories = true;
  TabController? _tabController;
  CarouselSliderController? _carouselController;

  // Define the desired display order for form categories
  static const List<String> _categoryOrder = [
    'Standard Delivery',
    'Pull Out / Return',
    'Pick Up',
    'Air / Sea',
    'Hotline Direct',
    'Stock Receive',
  ];

  @override
  void initState() {
    super.initState();
    _loadFormCategories();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadFormCategories() async {
    try {
      final repo = Get.find<FormCategoryRepository>();
      final categories = await repo.getAll(forceRefresh: true);

      // Sort categories according to the defined order
      final sortedCategories = _sortCategoriesByOrder(categories);

      if (mounted) {
        setState(() {
          formCategories = sortedCategories;
          isLoadingCategories = false;
        });

        // Initialize TabController and CarouselController after categories are loaded
        _tabController = TabController(
          length: formCategories.length,
          vsync: this,
        );

        _carouselController = CarouselSliderController();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    // Update TabBar to match the carousel page
    _tabController!.animateTo(index);
  }

  void _onTabTapped(int index) {
    // Move carousel to the tapped tab
    _carouselController?.animateToPage(index);
  }

  /// Sort categories according to the predefined order
  List<FormCategoryModel> _sortCategoriesByOrder(List<FormCategoryModel> categories) {
    final sorted = <FormCategoryModel>[];

    // Add categories in the defined order
    for (final orderName in _categoryOrder) {
      final category = categories.firstWhereOrNull(
          (c) => c.name.toLowerCase() == orderName.toLowerCase());
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

  /// Maps form category name to the appropriate controller
  dynamic _getControllerForCategory(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    if (lowerName.contains('standard') || lowerName.contains('delivery')) {
      return Get.find<StandardDeliveryController>();
    } else if (lowerName.contains('pull')) {
      return Get.find<PullOutController>();
    } else if (lowerName.contains('pick') && lowerName.contains('up')) {
      return Get.find<PickUpController>();
    } else if (lowerName.contains('air') || lowerName.contains('sea')) {
      return Get.find<AirSeaController>();
    } else if (lowerName.contains('hotline')) {
      // Hotline Direct uses StandardDeliveryController for now
      return Get.find<StandardDeliveryController>();
    } else if (lowerName.contains('stock') && lowerName.contains('receive')) {
      // Stock Receive uses StandardDeliveryController for now
      return Get.find<StandardDeliveryController>();
    }
    return null;
  }

  /// Maps form category to the appropriate list widget
  Widget _getListWidgetForCategory(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    if (lowerName.contains('standard') || lowerName.contains('delivery')) {
      return const BList();
    } else if (lowerName.contains('pull')) {
      return const PullOutReturnPickUpList();
    } else if (lowerName.contains('pick') && lowerName.contains('up')) {
      return const PickUpList();
    } else if (lowerName.contains('air') || lowerName.contains('sea')) {
      return const AirSeaList();
    } else if (lowerName.contains('hotline')) {
      // Hotline Direct uses BList for now (similar to Standard Delivery)
      return const BList();
    } else if (lowerName.contains('stock') && lowerName.contains('receive')) {
      // Stock Receive uses BList for now (similar to Standard Delivery)
      return const BList();
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

  /// Builds filter widgets for the given category index
  Widget _buildFilterForCategory(int index, TabController tabController) {
    if (index >= formCategories.length) return const SizedBox.shrink();

    final category = formCategories[index];
    final controller = _getControllerForCategory(category.name);
    final lowerName = category.name.toLowerCase();

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
    } else if (lowerName.contains('pull')) {
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
    } else if (lowerName.contains('pick') && lowerName.contains('up')) {
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
    } else if (lowerName.contains('air') || lowerName.contains('sea')) {
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

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingCategories) {
      return Scaffold(
        appBar: BAppBar(
          title: Text('Request',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (formCategories.isEmpty) {
      return Scaffold(
        appBar: BAppBar(
          title: Text('Request',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        body: const Center(child: Text('No form categories available')),
      );
    }

    final userController = Get.find<UserController>();

    return Scaffold(
          appBar: BAppBar(
            title: Text('Request',
                style: Theme.of(context).textTheme.headlineMedium),
            actions: [
              if (_tabController != null)
                AnimatedBuilder(
                  animation: _tabController!,
                  builder: (context, _) {
                    final currentIndex = _tabController!.index;
                    if (currentIndex >= formCategories.length) {
                      return const SizedBox.shrink();
                    }
                    return Obx(() {
                    final category = formCategories[currentIndex];
                    final controller = _getControllerForCategory(category.name);

                    if (controller == null) {
                      return const SizedBox.shrink();
                    }

                    bool useLocalStorageValue = false;
                    if (controller is StandardDeliveryController) {
                      useLocalStorageValue = controller.useLocalStorage.value;
                    } else if (controller is PullOutController) {
                      useLocalStorageValue = controller.useLocalStorage.value;
                    } else if (controller is PickUpController) {
                      useLocalStorageValue = controller.useLocalStorage.value;
                    } else if (controller is AirSeaController) {
                      useLocalStorageValue = controller.useLocalStorage.value;
                    }

                    final switchValue = !useLocalStorageValue;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        children: [
                          Text(switchValue ? 'Server' : 'Local'),
                          Switch(
                            value: switchValue,
                            onChanged: (value) {
                              final newUseLocalStorage = !value;
                              if (controller is StandardDeliveryController) {
                                controller.toggleStoragePreference(
                                    newUseLocalStorage);
                              } else if (controller is PullOutController) {
                                controller.toggleStoragePreference(
                                    newUseLocalStorage);
                              } else if (controller is PickUpController) {
                                controller.toggleStoragePreference(
                                    newUseLocalStorage);
                              } else if (controller is AirSeaController) {
                                controller.toggleStoragePreference(
                                    newUseLocalStorage);
                              }
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeThumbColor: Colors.green,
                          ),
                        ],
                      ),
                    );
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (_tabController != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: BSizes.defaultSpace, vertical: 8),
                  child: AnimatedBuilder(
                    animation: _tabController!,
                    builder: (context, _) {
                      final currentIndex = _tabController!.index;
                      return _buildFilterForCategory(currentIndex, _tabController!);
                    },
                  ),
                ),
              if (_tabController != null)
                TabBar(
                  controller: _tabController,
                  isScrollable: formCategories.length > 4,
                  onTap: _onTabTapped,
                  tabs: formCategories
                      .map((category) => Tab(text: category.name))
                      .toList(),
                ),
              const SizedBox(height: BSizes.spaceBtwItems),
              if (_carouselController != null)
                Expanded(
                  child: CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: formCategories.length,
                    itemBuilder: (context, index, realIndex) {
                      final category = formCategories[index];
                      return Column(
                        children: [
                          _getListWidgetForCategory(category.name),
                        ],
                      );
                    },
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: true,
                      initialPage: 0,
                      scrollDirection: Axis.horizontal,
                      onPageChanged: (index, reason) {
                        _onPageChanged(index);
                      },
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: Obx(() {
            if (!userController.user.value.role.contains(BTexts.roleRequest)) {
              return Container();
            } else {
              return const BFloatingButton();
            }
          }),
        );
  }
}
