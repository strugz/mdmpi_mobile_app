import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_sms_resend_icon_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';

class PullOutRequestCard extends StatelessWidget {
  const PullOutRequestCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.menuItems,
    this.trailing,
  });

  final PullOutModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<PopupMenuEntry>? menuItems;
  final Widget? trailing;

  bool get _isInteractive =>
      onTap != null || onLongPress != null || menuItems != null;

  String get _title {
    if (item.client.name.isNotEmpty) return item.client.name;
    return 'Pull-out Request';
  }

  String _safe(String v) => v.isNotEmpty ? v : '-';

  String get _formattedPullOutDate {
    final raw = item.pullOutDate.trim();
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
              const SizedBox(width: BSizes.xxs),
              BSmsResendIconButton(
                onResend: _handleResend,
                icon: Icons.send,
                iconSize: 15,
                dialogDetails:
                    'This will use the current pull-out request status and recipient list.',
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
                child: _metaLine(
                    label: 'Requested By',
                    value: item.requestedBy,
                    color: textColorPrimary),
              ),
              const SizedBox(width: BSizes.xs),
              _metaLine(
                  label: 'Pull-Out Date',
                  value: _formattedPullOutDate,
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
              StatusChip(status: item.requestStatus),
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
        color: item.requestStatus == BTexts.statusCancelled
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

  Future<void> _handleResend() async {
    final MessagingController controller = Get.find<MessagingController>();
    final SmsResult result = await controller.sendSmsMessage(
      item.requestStatus,
      item,
    );

    switch (result) {
      case SmsSuccess():
        BLoaders.successSnackBar(title: 'SMS sent', message: result.message);
        return;
      case SmsPartialSuccess():
        BLoaders.warningSnackBar(
          title: 'SMS partially sent',
          message: result.message,
        );
        return;
      case SmsLikelyNetworkIssue():
        throw Exception(result.message);
      case SmsPermissionDenied():
        throw Exception(result.message);
      case SmsSendError():
        throw Exception(result.error);
    }
  }
}
