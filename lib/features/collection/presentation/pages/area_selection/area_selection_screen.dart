import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class AreaSelectionScreen extends StatefulWidget {
  final Widget Function()? targetScreenBuilder;
  final String title;
  final bool isFilterMode;

  const AreaSelectionScreen({
    super.key,
    this.targetScreenBuilder,
    required this.title,
    this.isFilterMode = false,
  });

  @override
  State<AreaSelectionScreen> createState() => _AreaSelectionScreenState();
}

class _AreaSelectionScreenState extends State<AreaSelectionScreen> {
  String? selectedMainCategory;

  final List<Map<String, dynamic>> mainCategories = [
    {'name': 'Luzon', 'icon': Iconsax.map, 'hasSub': true},
    {'name': 'Visayas', 'icon': Iconsax.map_1, 'code': 'VIS'},
    {'name': 'Mindanao', 'icon': Iconsax.map, 'code': 'MIN'},
    {'name': 'Medical Imaging', 'icon': Iconsax.mask, 'code': 'RAD'},
  ];

  final List<Map<String, String>> luzonSubCategories = [
    {'name': 'North Luzon', 'code': 'NLN'},
    {'name': 'South Luzon', 'code': 'SLN'},
    {'name': 'Central Luzon', 'code': 'CLN'},
  ];

  void _onSelect(String code) {
    final controller = CollectionActivityController.instance;
    controller.selectedArea.value = code;
    if (widget.isFilterMode) {
      Get.back();
    } else if (widget.targetScreenBuilder != null) {
      Get.off(() => widget.targetScreenBuilder!());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BAppBar(
        title: Text(widget.isFilterMode ? 'Filter by Area' : 'Select Area - ${widget.title}'),
        showBackArrow: true,
        actions: widget.isFilterMode ? [
          TextButton(
            onPressed: () {
              CollectionActivityController.instance.selectedArea.value = '';
              Get.back();
            },
            child: const Text('Clear', style: TextStyle(color: BColors.primary)),
          ),
        ] : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedMainCategory == null 
                  ? 'Choose a main category' 
                  : 'Choose a region in $selectedMainCategory',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
            
            Expanded(
              child: selectedMainCategory == null 
                  ? _buildMainGrid() 
                  : _buildSubGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: BSizes.spaceBtwItems,
        mainAxisSpacing: BSizes.spaceBtwItems,
        childAspectRatio: 1.1,
      ),
      itemCount: mainCategories.length,
      itemBuilder: (context, index) {
        final item = mainCategories[index];
        return _buildAreaCard(
          name: item['name'],
          icon: item['icon'],
          onTap: () {
            if (item['hasSub'] == true) {
              setState(() => selectedMainCategory = item['name']);
            } else {
              _onSelect(item['code']);
            }
          },
        );
      },
    );
  }

  Widget _buildSubGrid() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: BSizes.spaceBtwItems,
              mainAxisSpacing: BSizes.spaceBtwItems,
              childAspectRatio: 1.1,
            ),
            itemCount: luzonSubCategories.length,
            itemBuilder: (context, index) {
              final sub = luzonSubCategories[index];
              return _buildAreaCard(
                name: sub['name']!,
                icon: Iconsax.location,
                onTap: () => _onSelect(sub['code']!),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => selectedMainCategory = null),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Main Categories'),
        ),
      ],
    );
  }

  Widget _buildAreaCard({required String name, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.borderRadiusLg)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(BSizes.md),
              decoration: BoxDecoration(
                color: BColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: BColors.primary, size: 32),
            ),
            const SizedBox(height: BSizes.sm),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
