import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// A small reusable card used on collection home to show a KPI/value.
class CollectionSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const CollectionSummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use withAlpha instead of withOpacity to avoid deprecated API usage.
    final backgroundColor = color.withAlpha((0.08 * 255).round());

    return Container(
      width: 110,
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
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
