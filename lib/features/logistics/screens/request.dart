import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

class CustomFilterPanel extends StatelessWidget {
  const CustomFilterPanel({
    super.key,
    required this.title,
    required this.children,
    required this.onReset,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                ...children,
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset to Default'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Request screen displaying different request form categories in a tabbed carousel interface.
/// Uses RequestController for all business logic and state management.
class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with SingleTickerProviderStateMixin {

  late final RequestController controller;
  TabController? _tabController;
  CarouselSliderController? _carouselController;
  Worker? _categoriesWorker;
  Worker? _tabIndexWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<RequestController>();

    // Initialize controllers immediately if categories are already loaded
    if (controller.formCategories.isNotEmpty) {
      _initializeControllers();
    }

    // Listen to formCategories changes to initialize controllers when data is loaded
    _categoriesWorker = ever(controller.formCategories, (_) {
      if (controller.formCategories.isNotEmpty && mounted) {
        _initializeControllers();
      }
    });

    // Listen to tab index changes from controller to sync TabController
    _tabIndexWorker = ever(controller.currentTabIndex, (index) {
      if (_tabController != null && mounted) {
        if (_tabController!.index != index) {
          _tabController!.animateTo(index);
        }
      }
    });
  }

  /// Initialize TabController and CarouselController
  void _initializeControllers() {
    if (_tabController != null) {
      // Already initialized
      return;
    }

    setState(() {
      _tabController = TabController(
        length: controller.formCategories.length,
        vsync: this,
        initialIndex: controller.currentTabIndex.value,
      );
      _carouselController = CarouselSliderController();
    });
  }

  @override
  void dispose() {
    _categoriesWorker?.dispose();
    _tabIndexWorker?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Update controller's tab index, which will sync the TabBar
    controller.updateTabIndex(index);
  }

  void _onTabTapped(int index) {
    // Move carousel to the tapped tab
    _carouselController?.animateToPage(index);
    controller.updateTabIndex(index);
  }


  void _openCustomFilterPanel() {
    if (_tabController == null) return;

    final currentIndex = _tabController!.index;
    if (currentIndex >= controller.formCategories.length) return;

    final category = controller.formCategories[currentIndex];
    final categoryController = controller.getControllerForCategory(category.name);
    final lowerName = category.name.toLowerCase();

    if (categoryController is! StandardDeliveryController ||
        !(lowerName.contains('standard') || lowerName.contains('delivery'))) {
      Get.snackbar('Custom Filter', 'Custom filters are available for Standard Delivery only (for now).');
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Custom Filter',
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) {
        final categoryOptions = categoryController.formState.itemCategories
            .map((item) => MapEntry(item.id, item.name))
            .where((item) => item.key.isNotEmpty)
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        return CustomFilterPanel(
          title: 'Standard Delivery Filters',
          onReset: () {
            categoryController.selectFilter(RequestFilter.today);
            categoryController.selectStatusFilter(StandardDeliveryStatusFilter.all);
            categoryController.selectDateFrom(null);
            categoryController.selectDateTo(null);
            categoryController.selectItemCategoryId('');
            categoryController.setClientNameQuery('');
          },
          children: [
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilterDropdown<RequestFilter>(
              selectedFilter: categoryController.filterManager.selectedFilter,
              filterValues: RequestFilter.values,
              getDisplayName: (f) => f.displayName,
              onFilterChanged: categoryController.selectFilter,
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Date From', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() {
              final dateFrom = categoryController.filterManager.selectedDateFrom.value;
              return OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateFrom ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  categoryController.selectDateFrom(picked);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(dateFrom == null ? 'Pick start date' : dateFrom.toIso8601String().split('T').first),
              );
            }),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Date To', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() {
              final dateTo = categoryController.filterManager.selectedDateTo.value;
              return OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateTo ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  categoryController.selectDateTo(picked);
                },
                icon: const Icon(Icons.event),
                label: Text(dateTo == null ? 'Pick end date' : dateTo.toIso8601String().split('T').first),
              );
            }),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilterDropdown<StandardDeliveryStatusFilter>(
              selectedFilter: categoryController.filterManager.selectedStatusFilter,
              filterValues: StandardDeliveryStatusFilter.values,
              getDisplayName: (f) => f.displayName,
              onFilterChanged: categoryController.selectStatusFilter,
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Item Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
                  value: categoryController.filterManager.selectedItemCategoryId.value.isEmpty
                      ? ''
                      : categoryController.filterManager.selectedItemCategoryId.value,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All Categories')),
                    ...categoryOptions.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value))),
                  ],
                  onChanged: (value) => categoryController.selectItemCategoryId(value ?? ''),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                )),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Client Name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: categoryController.filterManager.clientNameQuery.value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search client name',
              ),
              onChanged: categoryController.setClientNameQuery,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Obx(() {
      // Loading state
      if (controller.isLoadingCategories.value) {
        return Scaffold(
          appBar: BAppBar(
            title: Text('Request',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      // Empty state
      if (controller.formCategories.isEmpty) {
        return Scaffold(
          appBar: BAppBar(
            title: Text('Request',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value ?? 'No form categories available',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (controller.errorMessage.value != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadFormCategories(),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      // Main content
      return Scaffold(
        appBar: BAppBar(
          title: Text('Request', style: Theme.of(context).textTheme.headlineMedium),
          actions: [
            if (_tabController != null)
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Custom Filter',
                onPressed: _openCustomFilterPanel,
              ),
            if (_tabController != null)
              AnimatedBuilder(
                animation: _tabController!,
                builder: (context, _) {
                  final currentIndex = _tabController!.index;
                  if (currentIndex >= controller.formCategories.length) {
                    return const SizedBox.shrink();
                  }
                  return Obx(() {
                    final category = controller.formCategories[currentIndex];
                    final categoryController = controller.getControllerForCategory(category.name);

                    if (categoryController == null) {
                      return const SizedBox.shrink();
                    }

                    bool useLocalStorageValue = false;
                    if (categoryController is StandardDeliveryController) {
                      useLocalStorageValue = categoryController.useLocalStorage.value;
                    } else if (categoryController is PullOutController) {
                      useLocalStorageValue = categoryController.useLocalStorage.value;
                    } else if (categoryController is PickUpController) {
                      useLocalStorageValue = categoryController.useLocalStorage.value;
                    } else if (categoryController is AirSeaController) {
                      useLocalStorageValue = categoryController.useLocalStorage.value;
                    } else if (categoryController is HotlineDirectController) {
                      useLocalStorageValue = categoryController.useLocalStorage.value;
                    } else if (categoryController is StockReceiveController) {
                      useLocalStorageValue = categoryController.useLocalStorage.value;
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
                              controller.toggleStoragePreferenceForCategory(
                                category.name,
                                newUseLocalStorage,
                              );
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
            // Filter widgets
            if (_tabController != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.defaultSpace, vertical: 8),
                child: AnimatedBuilder(
                  animation: _tabController!,
                  builder: (context, _) {
                    final currentIndex = _tabController!.index;
                    return Obx(() => controller.buildFilterForCategory(currentIndex));
                  },
                ),
              ),

            // Tab bar
            if (_tabController != null)
              TabBar(
                controller: _tabController,
                isScrollable: controller.formCategories.length > 4,
                onTap: _onTabTapped,
                tabs: controller.formCategories
                    .map((category) => Tab(text: category.name))
                    .toList(),
              ),

            const SizedBox(height: BSizes.spaceBtwItems),

            // Carousel with category lists
            if (_carouselController != null)
              Expanded(
                child: CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: controller.formCategories.length,
                  itemBuilder: (context, index, realIndex) {
                    final category = controller.formCategories[index];
                    return Column(
                      children: [
                        controller.getListWidgetForCategory(category.name),
                      ],
                    );
                  },
                  options: CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    initialPage: controller.currentTabIndex.value,
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
            return Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: BColors.primary,
              ),
              child: IconButton(
                onPressed: () => controller.openFormForCurrentCategory(),
                icon: const Icon(Icons.add),
                color: BColors.white,
              ),
            );
          }
        }),
      );
    });
  }
}

