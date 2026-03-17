import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// A small reusable card used on collection home to show a KPI/value.
class CollectionSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  /// When true the card will expand to the available width (previous/default behaviour).
  /// Set to false when placing cards horizontally in a Row so they size to content.
  final bool expand;

  const CollectionSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color.withAlpha((0.08 * 255).round());

    return Container(
      // Preserve previous behaviour (full width) when `expand` is true.
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.all(BSizes.defaultSpace / 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  // Make the value more prominent
                  fontSize: BSizes.fontSizeLg * 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
