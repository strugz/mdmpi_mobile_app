import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/client_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Expandable section that groups every hard-reset refresh action used by Settings.
class SettingsHardResetSection extends StatelessWidget {
  const SettingsHardResetSection({super.key});

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await action();
    }
  }

  Widget _sectionTile({
    required IconData icon,
    required String title,
    required String subTitle,
    required Future<void> Function() onRefresh,
  }) {
    return BSettingsMenuTile(
      icon: icon,
      title: title,
      subTitle: subTitle,
      onTap: () => onRefresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final standardDeliveryController = Get.find<StandardDeliveryController>();
    final hotlineDirectController = Get.find<HotlineDirectController>();
    final airSeaController = Get.find<AirSeaController>();
    final airSeaHdController = Get.find<AirSeaHdController>();
    final pickUpController = Get.find<PickUpController>();
    final pullOutController = Get.find<PullOutController>();
    final stockReceiveController = Get.find<StockReceiveController>();
    final clientController = Get.find<ClientController>();
    final userController = Get.find<UserController>();
    final userMdmpiController = Get.find<UserMdmpiController>();
    final mobileController = Get.find<MobileController>();

    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
      elevation: 0,
      color: isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : scheme.primaryContainer.withValues(alpha: 0.16),
      surfaceTintColor: scheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        side: BorderSide(
          color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
        ),
      ),
      child: ExpansionTile(
        collapsedIconColor: scheme.primary,
        iconColor: scheme.primary,
        collapsedTextColor: scheme.onSurface,
        textColor: scheme.onSurface,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: BSizes.md,
          vertical: BSizes.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          BSizes.md,
          0,
          BSizes.md,
          BSizes.md,
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(BSizes.sm),
          ),
          child: Icon(Iconsax.refresh, color: scheme.primary, size: 22),
        ),
        title: Text(
          'Hard Reset Refresh',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: scheme.onSurface),
        ),
        subtitle: Text(
          'Clear cached data and reload from the server',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        children: [
          const BSectionHeading(
            title: 'Request Data',
            showActionButton: false,
            textColor: BColors.primary,
          ),
          const SizedBox(height: BSizes.xs),
          _sectionTile(
            icon: Iconsax.document_upload,
            title: 'Standard Delivery',
            subTitle: 'Hard reset request cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Standard Delivery',
              message:
                  'This will clear local Standard Delivery data and re-download it from the server.',
              action: standardDeliveryController.hardResetRequests,
            ),
          ),
          _sectionTile(
            icon: Iconsax.document_upload,
            title: 'Hotline Direct',
            subTitle: 'Hard reset request cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Hotline Direct',
              message:
                  'This will clear local Hotline Direct data and re-download it from the server.',
              action: hotlineDirectController.hardResetRequests,
            ),
          ),
          _sectionTile(
            icon: Iconsax.document_upload,
            title: 'Air / Sea / Land',
            subTitle: 'Hard reset request cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Air / Sea / Land',
              message:
                  'This will clear cached Air / Sea / Land data and reload it from the server.',
              action: airSeaController.hardResetAirSeaRequests,
            ),
          ),
          _sectionTile(
            icon: Iconsax.document_upload,
            title: 'Air / Sea / Land HD',
            subTitle: 'Hard reset request cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Air / Sea / Land HD',
              message:
                  'This will clear cached Air / Sea / Land HD data and reload it from the server.',
              action: airSeaHdController.hardResetAirSeaRequests,
            ),
          ),
          _sectionTile(
            icon: Iconsax.document_upload,
            title: 'Pick Up',
            subTitle: 'Hard reset request cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Pick Up',
              message:
                  'This will clear cached Pick Up data and reload it from the server.',
              action: pickUpController.hardResetPickUps,
            ),
          ),
          _sectionTile(
            icon: Iconsax.document_upload,
            title: 'Pull Out / Return',
            subTitle: 'Hard reset request cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Pull Out / Return',
              message:
                  'This will reload Pull Out / Return data from the server.',
              action: pullOutController.hardResetPullOuts,
            ),
          ),
          _sectionTile(
            icon: Iconsax.document_upload,
            title: 'Stock Receive',
            subTitle: 'Hard reset request cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Stock Receive',
              message:
                  'This will reload Stock Receive data from the server.',
              action: stockReceiveController.hardResetStockReceives,
            ),
          ),
          const SizedBox(height: BSizes.sm),
          Divider(
            height: BSizes.spaceBtwItems,
            color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
          ),
          const BSectionHeading(
            title: 'Reference Data',
            showActionButton: false,
            textColor: BColors.primary,
          ),
          const SizedBox(height: BSizes.xs),
          _sectionTile(
            icon: Iconsax.receipt_item,
            title: 'Client List',
            subTitle: 'Hard reset client cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Client List',
              message:
                  'This will clear local client data and reload the latest list from the server.',
              action: () => clientController.hardResetClients(true),
            ),
          ),
          _sectionTile(
            icon: Iconsax.receipt_item,
            title: 'Users List',
            subTitle: 'Hard reset Users and MDMPI requester cache',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Users List',
              message:
                  'This will clear local user and requester caches and reload them from the server.',
              action: () async {
                await userController.hardResetUsers(true);
                await userMdmpiController.hardResetUserMdmpiList(true);
              },
            ),
          ),
          _sectionTile(
            icon: Iconsax.receipt_item,
            title: 'Vehicle List',
            subTitle: 'Hard reset vehicle cache and reload',
            onRefresh: () => _confirmAndRun(
              context,
              title: 'Hard Reset Vehicle List',
              message:
                  'This will clear local vehicle data and reload the latest list from the server.',
              action: () => mobileController.hardResetVehicles(true),
            ),
          ),
        ],
      ),
    );
  }
}




