import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';

/// Card widget displaying Air/Sea request summary.
/// Shows client name, item category, pick-up date, and status.
/// Supports tap gestures, long press, and optional popup menu for actions.
class AirSeaRequestCard extends StatelessWidget {
  const AirSeaRequestCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.menuItems,
    this.trailing,
  });

  final AirSeaModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<PopupMenuEntry>? menuItems;
  final Widget? trailing;

  /// Determines if the card should respond to user interactions
  bool get _isInteractive =>
      onTap != null || onLongPress != null || menuItems != null;

  /// Returns the card title - prioritizes client name, falls back to generic label
  String get _title {
    if (item.client.name.isNotEmpty) return item.client.name;
    return 'Air/Sea Request';
  }

  /// Safely returns a value or dash if empty
  String _safe(String v) => v.isNotEmpty ? v : '-';

  /// Extracts and formats the pick-up date from ISO 8601 string (YYYY-MM-DD format)
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

  /// Fetches the item category name asynchronously from the repository.
  /// Returns empty string if no category ID or fetch fails.
  Future<String> _getItemCategoryName() async {
    // If no itemCategoryId, return empty
    if (item.itemCategoryId.isEmpty) {
      return '';
    }

    // Fetch from repository
    try {
      final categoryName = await ItemCategoryRepository.instance
          .fetchItemCategory(item.itemCategoryId);
      return categoryName ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColorPrimary = dark ? BColors.light : BColors.darkerGrey;

    // Main card content with client name, category, date, and status
    Widget content = Padding(
      padding: const EdgeInsets.all(BSizes.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and optional menu/trailing widget
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
          // Item category and pick-up date row
          Row(
            children: [
              Expanded(
                child: FutureBuilder<String>(
                  future: _getItemCategoryName(),
                  builder: (context, snapshot) {
                    final categoryName = snapshot.data ?? '';
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
          // Status chip (e.g., New Request, Item Packed, etc.)
          StatusChip(status: item.status),
        ],
      ),
    );

    // Container with conditional background color for cancelled requests
    final card = Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        color: item.status == BTexts.statusCancelled
            ? BColors.cancelledBackground
            : null,
      ),
      child: content,
    );

    // Return non-interactive card if no gestures are configured
    if (!_isInteractive) return card;

    // Wrap card with InkWell for tap/long-press gestures
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
      child: card,
    );
  }
}
