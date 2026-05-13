import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';


class PickUpRequestCard extends StatelessWidget {
  const PickUpRequestCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.menuItems,
    this.trailing,
  });

  final PickUpModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<PopupMenuEntry>? menuItems;
  final Widget? trailing;

  bool get _isInteractive =>
      onTap != null || onLongPress != null || menuItems != null;

  String get _title {
    if (item.client.name.isNotEmpty) return item.client.name;
    return 'Pick-Up Request';
  }

  String _safe(String v) => v.isNotEmpty ? v : '-';

  String get _formattedPickUpDate {
    final raw = item.datePickUp.trim();
    if (raw.isEmpty) return '-';
    String datePart;
    if (raw.contains('T')) {
      datePart = raw.split('T').first;
    } else if (raw.length >= 10) {
      datePart = raw.substring(0, 10);
    } else {
      datePart = raw;
    }
    return datePart;
  }

  Widget _metaLine(
      {required String label, required String value, required Color color}) {
    return BProductTitleText(
      title: '$label: ${_safe(value)}',
      maxLines: 1,
      smallSize: true,
      fontColor: color,
    );
  }

  Future<String> _getItemCategoryName() async {
    // If already has a name, return it
    if (item.itemCategory.name.isNotEmpty) {
      return item.itemCategory.name;
    }

    // If no itemCategoryId, return empty
    if (item.itemCategoryId.isEmpty) {
      return '';
    }

    // Fetch from repository
    try {
      final categoryName = await ItemCategoryRepository.instance.fetchItemCategory(item.itemCategoryId);
      return categoryName ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColorPrimary = dark ? BColors.light : BColors.darkerGrey;

    Widget content = Padding(
      padding: const EdgeInsets.all(BSizes.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BProductTitleText(
                  title: _title,
                  maxLines: 2,
                  bold: true,
                  fontColor: textColorPrimary,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: BSizes.xxs),
                trailing!,
              ] else if (menuItems != null) ...[
                PopupMenuButton(
                  icon:
                      Icon(Icons.more_vert, size: 18, color: textColorPrimary),
                  itemBuilder: (_) => menuItems!,
                ),
              ],
            ],
          ),
          const SizedBox(height: BSizes.xxs),
          Row(
            children: [
              Expanded(
                child: FutureBuilder<String>(
                  future: _getItemCategoryName(),
                  builder: (context, snapshot) {
                    final categoryName = snapshot.data ?? item.itemCategory.name;
                    return BLabelValueText(
                      icon: Iconsax.category,
                      label: 'Item Category',
                      value: categoryName.isNotEmpty ? categoryName : '-',
                      textColor: textColorPrimary,
                      dense: true,
                      maxLines: 1,
                      showLabel: false,
                    );
                  },
                ),
              ),
              const SizedBox(width: BSizes.xs),
              _metaLine(
                  label: 'Pick-Up Date',
                  value: _formattedPickUpDate,
                  color: textColorPrimary),
            ],
          ),
          const SizedBox(height: BSizes.xxs),
          Row(
            children: [
              _metaLine(
                  label: 'Created By',
                  value: item.createdBy,
                  color: textColorPrimary),
              BCircularIcon(
                backgroundColor: Colors.transparent,
                icon: Iconsax.add_circle1,
                color: dark ? BColors.white : BColors.black,
                size: 5,
                width: 20,
                height: 20,
              ),
              // Footer status chip
              StatusChip(status: item.status),
            ],
          ),
        ],
      ),
    );

    final card = Container(
      // Removed fixed width; let parent layout decide.
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        color: item.status == BTexts.statusCancelled
            ? BColors.cancelledBackground
            : null,
      ),
      child: content,
    );

    if (!_isInteractive) return card;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
      child: card,
    );
  }
}
