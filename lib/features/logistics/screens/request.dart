import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/filter_dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/panels/custom_filter_panel.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

import '../helpers/pull_out_filter_manager.dart';

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

  /// Initialize TabController and CarouselController.
  /// Recreates the TabController when a background category refresh changes
  /// the number of categories, since TabController's length is fixed.
  void _initializeControllers() {
    final categoryCount = controller.formCategories.length;
    if (_tabController != null && _tabController!.length == categoryCount) {
      // Already initialized with the correct length
      return;
    }

    setState(() {
      _tabController?.dispose();
      final initialIndex =
          controller.currentTabIndex.value.clamp(0, categoryCount - 1);
      _tabController = TabController(
        length: categoryCount,
        vsync: this,
        initialIndex: initialIndex,
      );
      _carouselController ??= CarouselSliderController();
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
    final categoryController =
        controller.getControllerForCategory(category.name);
    final lowerName = category.name.toLowerCase();

    final isStandardDelivery =
        categoryController is StandardDeliveryController &&
            (lowerName.contains('standard') || lowerName.contains('delivery'));

    final isPullOut =
        categoryController is PullOutController && lowerName.contains('pull');

    final isPickUp = categoryController is PickUpController &&
        lowerName.contains('pick') &&
        lowerName.contains('up');

    final isAirSea =
        categoryController is AirSeaController &&
            (lowerName.contains('air') || lowerName.contains('sea'));

    final isHotlineDirect =
        categoryController is HotlineDirectController &&
            (lowerName.contains('hotline') || lowerName.contains('direct'));

    final isStockReceive =
        categoryController is StockReceiveController &&
            lowerName.contains('stock') &&
            lowerName.contains('receive');

    if (!isStandardDelivery && !isPullOut && !isPickUp && !isAirSea && !isHotlineDirect && !isStockReceive) {
      Get.snackbar(
        'Custom Filter',
        'Custom filters are available for Standard Delivery, Pull Out / Return, Pick Up, Air / Sea / Land, Hotline Direct, and Stock Receive only.',
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Custom Filter',
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) {
        if (isPullOut) {
          final pullOutController = categoryController as PullOutController;
          final categoryOptions = pullOutController.formState.itemCategories
              .map((item) => MapEntry(item.id, item.name))
              .where((item) => item.key.isNotEmpty)
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          return CustomFilterPanel(
            title: 'Pull Out / Return Filters',
            onReset: () {
              pullOutController.selectDateFilter(RequestFilter.today);
              pullOutController.selectStatusFilter(PullOutStatusFilter.all);
              pullOutController.selectDateFrom(null);
              pullOutController.selectDateTo(null);
              pullOutController.selectItemCategoryId('');
              pullOutController.setClientNameQuery('');
              pullOutController.setDocumentReferenceQuery('');
            },
            children: [
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date Range',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<RequestFilter>(
                selectedFilter: pullOutController.filterManager.selectedFilter,
                filterValues: RequestFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: pullOutController.selectDateFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date From', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateFrom =
                    pullOutController.filterManager.selectedDateFrom.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    pullOutController.selectDateFrom(picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateFrom == null
                      ? 'Pick start date'
                      : dateFrom.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date To', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateTo =
                    pullOutController.filterManager.selectedDateTo.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    pullOutController.selectDateTo(picked);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(dateTo == null
                      ? 'Pick end date'
                      : dateTo.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<PullOutStatusFilter>(
                selectedFilter:
                    pullOutController.filterManager.selectedStatusFilter,
                filterValues: PullOutStatusFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: pullOutController.selectStatusFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Item Category',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: pullOutController
                            .filterManager.selectedItemCategoryId.value.isEmpty
                        ? ''
                        : pullOutController
                            .filterManager.selectedItemCategoryId.value,
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('All Categories')),
                      ...categoryOptions.map((item) => DropdownMenuItem(
                          value: item.key, child: Text(item.value))),
                    ],
                    onChanged: (value) =>
                        pullOutController.selectItemCategoryId(value ?? ''),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined)),
                  )),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Client Name',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue:
                    pullOutController.filterManager.clientNameQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search client name',
                ),
                onChanged: pullOutController.setClientNameQuery,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Document Reference', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: pullOutController.filterManager.documentReferenceQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Search document reference',
                ),
                onChanged: pullOutController.setDocumentReferenceQuery,
              ),
            ],
          );

        } else if (isPickUp) {
          final pickUpController = categoryController as PickUpController;
          final categoryOptions = pickUpController.formState.itemCategories
              .map((item) => MapEntry(item.id, item.name))
              .where((item) => item.key.isNotEmpty)
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          return CustomFilterPanel(
            title: 'Pick Up Filters',
            onReset: () {
              pickUpController.selectDateFilter(RequestFilter.today);
              pickUpController.selectStatusFilter(PickUpStatusFilter.all);
              pickUpController.selectDateFrom(null);
              pickUpController.selectDateTo(null);
              pickUpController.selectItemCategoryId('');
              pickUpController.setClientNameQuery('');
              pickUpController.setDocumentReferenceQuery('');
            },
            children: [
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<RequestFilter>(
                selectedFilter: pickUpController.filterManager.selectedFilter,
                filterValues: RequestFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: pickUpController.selectDateFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date From', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateFrom = pickUpController.filterManager.selectedDateFrom.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    pickUpController.selectDateFrom(picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateFrom == null
                      ? 'Pick start date'
                      : dateFrom.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date To', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateTo = pickUpController.filterManager.selectedDateTo.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    pickUpController.selectDateTo(picked);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(dateTo == null
                      ? 'Pick end date'
                      : dateTo.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<PickUpStatusFilter>(
                selectedFilter: pickUpController.filterManager.selectedStatusFilter,
                filterValues: PickUpStatusFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: pickUpController.selectStatusFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Item Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: pickUpController.filterManager.selectedItemCategoryId.value.isEmpty
                        ? ''
                        : pickUpController.filterManager.selectedItemCategoryId.value,
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All Categories')),
                      ...categoryOptions.map((item) => DropdownMenuItem(
                          value: item.key, child: Text(item.value))),
                    ],
                    onChanged: (value) => pickUpController.selectItemCategoryId(value ?? ''),
                    decoration:
                        const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                  )),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Client Name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: pickUpController.filterManager.clientNameQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search client name',
                ),
                onChanged: pickUpController.setClientNameQuery,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Document Reference', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: pickUpController.filterManager.documentReferenceQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Search document reference',
                ),
                onChanged: pickUpController.setDocumentReferenceQuery,
              ),
            ],
          );

        } else if (isAirSea) {
          final airSeaController = categoryController as AirSeaController;
          final categoryOptions = airSeaController.formState.itemCategories
              .map((item) => MapEntry(item.id, item.name))
              .where((item) => item.key.isNotEmpty)
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          return CustomFilterPanel(
            title: 'Air / Sea / Land Filters',
            onReset: () {
              airSeaController.selectDateFilter(RequestFilter.today);
              airSeaController.selectStatusFilter(AirSeaStatusFilter.all);
              airSeaController.selectDateFrom(null);
              airSeaController.selectDateTo(null);
              airSeaController.selectItemCategoryId('');
              airSeaController.setClientNameQuery('');
              airSeaController.setDocumentReferenceQuery('');
            },
            children: [
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<RequestFilter>(
                selectedFilter: airSeaController.filterManager.selectedFilter,
                filterValues: RequestFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: airSeaController.selectDateFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date From', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateFrom = airSeaController.filterManager.selectedDateFrom.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    airSeaController.selectDateFrom(picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateFrom == null
                      ? 'Pick start date'
                      : dateFrom.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date To', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateTo = airSeaController.filterManager.selectedDateTo.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    airSeaController.selectDateTo(picked);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(dateTo == null
                      ? 'Pick end date'
                      : dateTo.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<AirSeaStatusFilter>(
                selectedFilter: airSeaController.filterManager.selectedStatusFilter,
                filterValues: AirSeaStatusFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: airSeaController.selectStatusFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Item Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: airSeaController.filterManager.selectedItemCategoryId.value.isEmpty
                        ? ''
                        : airSeaController.filterManager.selectedItemCategoryId.value,
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All Categories')),
                      ...categoryOptions.map((item) => DropdownMenuItem(
                          value: item.key, child: Text(item.value))),
                    ],
                    onChanged: (value) => airSeaController.selectItemCategoryId(value ?? ''),
                    decoration:
                        const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                  )),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Client Name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: airSeaController.filterManager.clientNameQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search client name',
                ),
                onChanged: airSeaController.setClientNameQuery,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Document Reference', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: airSeaController.filterManager.documentReferenceQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Search document reference',
                ),
                onChanged: airSeaController.setDocumentReferenceQuery,
              ),
            ],
          );
        } else if (isHotlineDirect) {
          final hotlineDirectController =
              categoryController as HotlineDirectController;
          final categoryOptions = hotlineDirectController.formState.itemCategories
              .map((item) => MapEntry(item.id, item.name))
              .where((item) => item.key.isNotEmpty)
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          return CustomFilterPanel(
            title: 'Hotline Direct Filters',
            onReset: () {
              hotlineDirectController.selectFilter(RequestFilter.today);
              hotlineDirectController
                  .selectStatusFilter(StandardDeliveryStatusFilter.all);
              hotlineDirectController.selectDateFrom(null);
              hotlineDirectController.selectDateTo(null);
              hotlineDirectController.selectItemCategoryId('');
              hotlineDirectController.setClientNameQuery('');
              hotlineDirectController.setDocumentReferenceQuery('');
            },
            children: [
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<RequestFilter>(
                selectedFilter:
                    hotlineDirectController.filterManager.selectedFilter,
                filterValues: RequestFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: hotlineDirectController.selectFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date From', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateFrom =
                    hotlineDirectController.filterManager.selectedDateFrom.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    hotlineDirectController.selectDateFrom(picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateFrom == null
                      ? 'Pick start date'
                      : dateFrom.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date To', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateTo =
                    hotlineDirectController.filterManager.selectedDateTo.value;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    hotlineDirectController.selectDateTo(picked);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(dateTo == null
                      ? 'Pick end date'
                      : dateTo.toIso8601String().split('T').first),
                );
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<StandardDeliveryStatusFilter>(
                selectedFilter: hotlineDirectController
                    .filterManager.selectedStatusFilter,
                filterValues: StandardDeliveryStatusFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: hotlineDirectController.selectStatusFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Item Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: hotlineDirectController
                            .filterManager.selectedItemCategoryId.value.isEmpty
                        ? ''
                        : hotlineDirectController
                            .filterManager.selectedItemCategoryId.value,
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('All Categories')),
                      ...categoryOptions.map((item) => DropdownMenuItem(
                          value: item.key, child: Text(item.value))),
                    ],
                    onChanged: (value) => hotlineDirectController
                        .selectItemCategoryId(value ?? ''),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined)),
                  )),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Client Name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue:
                    hotlineDirectController.filterManager.clientNameQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search client name',
                ),
                onChanged: hotlineDirectController.setClientNameQuery,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Document Reference', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: hotlineDirectController.filterManager.documentReferenceQuery.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Search document reference',
                ),
                onChanged: hotlineDirectController.setDocumentReferenceQuery,
              ),
            ],
          );
        } else if (isStockReceive) {
          final stockReceiveController = categoryController as StockReceiveController;
          final categoryOptions = stockReceiveController.formState.itemCategories
              .map((item) => MapEntry(item.id, item.name))
              .where((item) => item.key.isNotEmpty)
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          return CustomFilterPanel(
            title: 'Stock Receive Filters',
            onReset: () {
              stockReceiveController.selectDateFilter(RequestFilter.today);
              stockReceiveController.selectStatusFilter(PullOutStatusFilter.all);
              stockReceiveController.selectDateFrom(null);
              stockReceiveController.selectDateTo(null);
              stockReceiveController.selectItemCategoryId('');
              stockReceiveController.setClientNameQuery('');
              stockReceiveController.setDocumentReferenceQuery('');
            },
            children: [
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<RequestFilter>(
                selectedFilter: stockReceiveController.filterManager.selectedFilter,
                filterValues: RequestFilter.values,
                getDisplayName: (f) => f.displayName,
                onFilterChanged: stockReceiveController.selectDateFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date From', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateFrom = stockReceiveController.filterManager.selectedDateFrom.value;
                return OutlinedButton.icon(onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: dateFrom ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  stockReceiveController.selectDateFrom(picked);
                }, icon: const Icon(Icons.calendar_today), label: Text(dateFrom == null ? 'Pick start date' : dateFrom.toIso8601String().split('T').first));
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Date To', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() {
                final dateTo = stockReceiveController.filterManager.selectedDateTo.value;
                return OutlinedButton.icon(onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: dateTo ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  stockReceiveController.selectDateTo(picked);
                }, icon: const Icon(Icons.event), label: Text(dateTo == null ? 'Pick end date' : dateTo.toIso8601String().split('T').first));
              }),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilterDropdown<PullOutStatusFilter>(
                selectedFilter: stockReceiveController.filterManager.selectedStatusFilter,
                // For Pull Out is a Pull Out / Return-only status; Stock
                // Receive keeps its New Request → In Transit → Taken Out flow.
                filterValues: PullOutStatusFilter.values
                    .where((f) => f != PullOutStatusFilter.statusForPullOut)
                    .toList(),
                getDisplayName: (f) => f.displayName,
                onFilterChanged: stockReceiveController.selectStatusFilter,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Item Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: stockReceiveController.filterManager.selectedItemCategoryId.value.isEmpty ? '' : stockReceiveController.filterManager.selectedItemCategoryId.value,
                    items: [const DropdownMenuItem(value: '', child: Text('All Categories')), ...categoryOptions.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value)))],
                    onChanged: (value) => stockReceiveController.selectItemCategoryId(value ?? ''),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                  )),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Client Name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: stockReceiveController.filterManager.clientNameQuery.value,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search client name'),
                onChanged: stockReceiveController.setClientNameQuery,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text('Document Reference', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: stockReceiveController.filterManager.documentReferenceQuery.value,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.description_outlined), hintText: 'Search document reference'),
                onChanged: stockReceiveController.setDocumentReferenceQuery,
              ),
            ],
          );
        }

        final standardDeliveryController =
            categoryController as StandardDeliveryController;
        final categoryOptions = standardDeliveryController.formState.itemCategories
            .map((item) => MapEntry(item.id, item.name))
            .where((item) => item.key.isNotEmpty)
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));


        return CustomFilterPanel(
          title: 'Standard Delivery Filters',
          onReset: () {
            standardDeliveryController.selectFilter(RequestFilter.today);
            standardDeliveryController
                .selectStatusFilter(StandardDeliveryStatusFilter.all);
            standardDeliveryController.selectDateFrom(null);
            standardDeliveryController.selectDateTo(null);
            standardDeliveryController.selectItemCategoryId('');
            standardDeliveryController.setClientNameQuery('');
            standardDeliveryController.setDocumentReferenceQuery('');
          },
          children: [
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilterDropdown<RequestFilter>(
              selectedFilter: standardDeliveryController.filterManager.selectedFilter,
              filterValues: RequestFilter.values,
              getDisplayName: (f) => f.displayName,
              onFilterChanged: standardDeliveryController.selectFilter,
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Date From', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() {
              final dateFrom =
                  standardDeliveryController.filterManager.selectedDateFrom.value;
              return OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateFrom ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  standardDeliveryController.selectDateFrom(picked);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(dateFrom == null
                    ? 'Pick start date'
                    : dateFrom.toIso8601String().split('T').first),
              );
            }),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Date To', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() {
              final dateTo =
                  standardDeliveryController.filterManager.selectedDateTo.value;
              return OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateTo ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  standardDeliveryController.selectDateTo(picked);
                },
                icon: const Icon(Icons.event),
                label: Text(dateTo == null
                    ? 'Pick end date'
                    : dateTo.toIso8601String().split('T').first),
              );
            }),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilterDropdown<StandardDeliveryStatusFilter>(
              selectedFilter:
              standardDeliveryController.filterManager.selectedStatusFilter,
              filterValues: StandardDeliveryStatusFilter.values,
              getDisplayName: (f) => f.displayName,
              onFilterChanged: standardDeliveryController.selectStatusFilter,
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Item Category',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
                  value: standardDeliveryController
                          .filterManager.selectedItemCategoryId.value.isEmpty
                      ? ''
                      : standardDeliveryController
                          .filterManager.selectedItemCategoryId.value,
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('All Categories')),
                    ...categoryOptions.map((item) => DropdownMenuItem(
                        value: item.key, child: Text(item.value))),
                  ],
                  onChanged: (value) =>
                      standardDeliveryController.selectItemCategoryId(value ?? ''),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined)),
                )),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Client Name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              initialValue:
              standardDeliveryController.filterManager.clientNameQuery.value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search client name',
              ),
              onChanged: standardDeliveryController.setClientNameQuery,
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text('Document Reference',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: standardDeliveryController
                  .filterManager.documentReferenceQuery.value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.description_outlined),
                hintText: 'Search document reference',
              ),
              onChanged: standardDeliveryController.setDocumentReferenceQuery,
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
                const Icon(Icons.category_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value ??
                      'No form categories available',
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
          title: Text('Request',
              style: Theme.of(context).textTheme.headlineMedium),
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
                    final categoryController =
                        controller.getControllerForCategory(category.name);

                    if (categoryController == null) {
                      return const SizedBox.shrink();
                    }

                    bool useLocalStorageValue = false;
                    if (categoryController is StandardDeliveryController) {
                      useLocalStorageValue =
                          categoryController.useLocalStorage.value;
                    } else if (categoryController is PullOutController) {
                      useLocalStorageValue =
                          categoryController.useLocalStorage.value;
                    } else if (categoryController is PickUpController) {
                      useLocalStorageValue =
                          categoryController.useLocalStorage.value;
                    } else if (categoryController is AirSeaController) {
                      useLocalStorageValue =
                          categoryController.useLocalStorage.value;
                    } else if (categoryController is HotlineDirectController) {
                      useLocalStorageValue =
                          categoryController.useLocalStorage.value;
                    } else if (categoryController is StockReceiveController) {
                      useLocalStorageValue =
                          categoryController.useLocalStorage.value;
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
                    return Obx(
                        () => controller.buildFilterForCategory(currentIndex));
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
          final role = userController.user.value.role;
          // Couriers (drivers) may create requests, but only on the Hotline
          // Direct tab; everywhere else creation stays with the Request role.
          final isHotlineTab = FormCategoryConstants.fromCategoryName(
                  controller.currentSelectedCategory.value?.name ?? '') ==
              FormCategoryType.hotlineDirect;
          final canCreate = role.contains(BTexts.roleRequest) ||
              (isHotlineTab && role.contains(BTexts.roleCourier));
          if (!canCreate) {
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
