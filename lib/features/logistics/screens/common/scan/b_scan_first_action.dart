import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';
import 'package:mdmpi_mobile_app/common/widgets/scanner/scanned_items_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_document_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/scan_form_target.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/request_form_navigator.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/scan_source_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/document_scan_review_sheet.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Scan first (decision 2026-10-15): from the Home header, one photo of a
/// delivery document. The review sheet asks which request it is for (only
/// the forms that document belongs to and the user may create), and Apply
/// opens that form already filled. Android only; hidden when the user may
/// create no request at all.
class BScanFirstAction extends StatelessWidget {
  const BScanFirstAction({super.key, this.showOnThisPlatform});

  /// Overrides the platform check (widget tests).
  final bool? showOnThisPlatform;

  @override
  Widget build(BuildContext context) {
    if (!(showOnThisPlatform ?? GetPlatform.isAndroid)) {
      return const SizedBox.shrink();
    }
    final users = Get.find<UserController>();
    return Obx(() {
      if (!ScanFormTarget.canScanAny(users.user.value.role)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: BSizes.sm),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('scanFirstAction'),
            style: FilledButton.styleFrom(
              backgroundColor: BColors.white,
              foregroundColor: BColors.primary,
              padding: const EdgeInsets.symmetric(vertical: BSizes.sm + BSizes.xs),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BSizes.md)),
            ),
            onPressed: () => _start(context, users.user.value.role),
            icon: const Icon(Iconsax.scan, size: 20),
            label: const Text('Scan Document',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      );
    });
  }

  Future<void> _start(BuildContext context, String role) async {
    final source = await ScanSourceSheet.show(context);
    if (source == null || !context.mounted) return;

    final scan = Get.find<DeliveryDocumentScanController>();
    final file = await ScanSourceSheet.pickFile(scan, source);
    if (file == null || !context.mounted) return;

    final scanning = scan.scanFile(file, fixedTarget: null, role: role);
    await DocumentScanReviewSheet.show(
      context,
      scanning: scanning,
      onApplied: (applied) async {
        final target = applied.target;
        if (target == null) return;
        final category = ScanFormTarget.categoryFor(target);
        // Selects the category tab and opens its form, the same way the
        // home grid does; the form shows what Apply just put in.
        await RequestFormNavigator.open(
            category.formPageIndex, AppRoutes.requestFormPages);
        if (applied.itemsAdded > 0) {
          Get.to(() => ScannedItemsScreen(
              controller: Get.find<StandardDeliveryController>()));
        }
      },
    );
  }
}
