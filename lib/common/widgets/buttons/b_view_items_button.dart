import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/inventory_items_page.dart';

/// Reusable centered text button used to open an items page for a given
/// request id. By default this navigates to [InventoryItemsPage], but a
/// custom [pageBuilder] or [onPressed] can be provided for different
/// behaviors.
class BViewItemsButton extends StatelessWidget {
  final String requestId;
  final String label;
  final IconData icon;
  final Widget Function()? pageBuilder;
  final VoidCallback? onPressed;

  const BViewItemsButton({
    Key? key,
    required this.requestId,
    this.label = 'View Items',
    this.icon = Icons.visibility,
    this.pageBuilder,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          icon: Icon(icon),
          label: Text(label),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: onPressed ?? () {
            final page = pageBuilder?.call() ?? InventoryItemsPage(requestId: requestId);
            Get.to(() => page);
          },
        ),
      ),
    );
  }
}

