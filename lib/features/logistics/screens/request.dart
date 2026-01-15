import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

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

  @override
  void initState() {
    super.initState();
    controller = Get.find<RequestController>();

    // Listen to formCategories changes to initialize controllers when data is loaded
    ever(controller.formCategories, (_) {
      if (controller.formCategories.isNotEmpty && mounted) {
        // Initialize TabController and CarouselController after categories are loaded
        setState(() {
          _tabController = TabController(
            length: controller.formCategories.length,
            vsync: this,
            initialIndex: controller.currentTabIndex.value,
          );
          _carouselController = CarouselSliderController();
        });
      }
    });

    // Listen to tab index changes from controller to sync TabController
    ever(controller.currentTabIndex, (index) {
      if (_tabController != null && mounted) {
        if (_tabController!.index != index) {
          _tabController!.animateTo(index);
        }
      }
    });
  }

  @override
  void dispose() {
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


