import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/sms_resend_dialog.dart';

/// Compact resend action button that opens the shared SMS resend dialog.
class BSmsResendIconButton extends StatelessWidget {
  const BSmsResendIconButton({
    super.key,
    required this.onResend,
    this.tooltipMessage = 'Resend SMS',
    this.dialogTitle = 'Resend SMS?',
    this.dialogMessage = 'Send the SMS notification again for this request?',
    this.dialogDetails,
    this.resendButtonText = 'Resend',
    this.cancelButtonText = 'Cancel',
    this.icon = Iconsax.send_1,
    this.rotationAngle = -0.7,
    this.iconColor = BColors.primary,
    this.iconSize = 18,
    this.buttonSize = 30,
  });

  /// Callback executed after the confirmation dialog is accepted.
  final Future<void> Function() onResend;

  /// Tooltip shown on hover/long-press.
  final String tooltipMessage;

  /// Dialog title.
  final String dialogTitle;

  /// Main dialog message.
  final String dialogMessage;

  /// Optional secondary explanation shown in the dialog.
  final String? dialogDetails;

  /// Confirm button text.
  final String resendButtonText;

  /// Cancel button text.
  final String cancelButtonText;

  /// Icon displayed in the button.
  final IconData icon;

  /// Rotation angle in radians.
  final double rotationAngle;

  /// Icon color.
  final Color iconColor;

  /// Icon size.
  final double iconSize;

  /// Square hit area size.
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipMessage,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        onPressed: () async {
          await SmsResendDialog.show(
            context,
            title: dialogTitle,
            message: dialogMessage,
            details: dialogDetails,
            resendButtonText: resendButtonText,
            cancelButtonText: cancelButtonText,
            icon: icon,
            onResend: onResend,
          );
        },
        icon: Transform.rotate(
          angle: rotationAngle,
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}


