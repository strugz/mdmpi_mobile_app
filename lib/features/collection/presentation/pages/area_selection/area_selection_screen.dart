import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class AreaSelectionScreen extends StatefulWidget {
  final Widget Function() targetScreenBuilder;
  final String title;

  const AreaSelectionScreen({
    super.key,
    required this.targetScreenBuilder,
    required this.title,
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
    Get.off(() => widget.targetScreenBuilder());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BAppBar(
        title: Text('Select Area - ${widget.title}'),
        showBackArrow: true,
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
                  ? _buildMainCategories() 
                  : _buildSubCategories(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategories() {
    return ListView.separated(
      itemCount: mainCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
      itemBuilder: (context, index) {
        final item = mainCategories[index];
        return ListTile(
          leading: Icon(item['icon'], color: BColors.primary),
          title: Text(item['name']),
          trailing: const Icon(Iconsax.arrow_right_3),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: BColors.grey),
            borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
          ),
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

  Widget _buildSubCategories() {
    return Column(
      children: [
        ...luzonSubCategories.map((sub) => Padding(
          padding: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
          child: ListTile(
            title: Text(sub['name']!),
            trailing: const Icon(Iconsax.arrow_right_3),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: BColors.grey),
              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
            ),
            onTap: () => _onSelect(sub['code']!),
          ),
        )),
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() => selectedMainCategory = null),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Main Categories'),
        ),
      ],
    );
  }
}
