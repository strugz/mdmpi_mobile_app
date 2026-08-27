import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_submit_button.dart';

/// Modal dialog for confirming and retrying an SMS send action.
///
/// Use this when a previous SMS attempt failed or was interrupted and the
/// user should be able to resend the same message from a popup/modal.
class SmsResendDialog extends StatefulWidget {
  const SmsResendDialog({
    super.key,
    required this.onResend,
    this.title = 'Resend SMS?',
    this.message = 'Do you want to send the SMS again?',
    this.details,
    this.resendButtonText = 'Resend',
    this.cancelButtonText = 'Cancel',
    this.icon = Icons.refresh_rounded,
    this.onResendSuccess,
  });

  /// Action executed when the user taps the resend button.
  final Future<void> Function() onResend;

  /// Dialog title.
  final String title;

  /// Main prompt shown to the user.
  final String message;

  /// Optional supporting text, e.g. a network issue explanation.
  final String? details;

  /// Label for the resend button.
  final String resendButtonText;

  /// Label for the cancel button.
  final String cancelButtonText;

  /// Leading icon shown in the dialog header.
  final IconData icon;

  /// Optional callback fired after a successful resend.
  final VoidCallback? onResendSuccess;

  /// Shows the resend dialog and returns `true` when resend succeeds.
  static Future<bool?> show(
    BuildContext context, {
    required Future<void> Function() onResend,
    String title = 'Resend SMS?',
    String message = 'Do you want to send the SMS again?',
    String? details,
    String resendButtonText = 'Resend',
    String cancelButtonText = 'Cancel',
    IconData icon = Icons.refresh_rounded,
    VoidCallback? onResendSuccess,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return SmsResendDialog(
          onResend: onResend,
          title: title,
          message: message,
          details: details,
          resendButtonText: resendButtonText,
          cancelButtonText: cancelButtonText,
          icon: icon,
          onResendSuccess: onResendSuccess,
        );
      },
    );
  }

  @override
  State<SmsResendDialog> createState() => _SmsResendDialogState();
}

class _SmsResendDialogState extends State<SmsResendDialog> {
  bool _isResending = false;

  Future<void> _handleResend() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      await widget.onResend();
      if (!mounted) return;

      widget.onResendSuccess?.call();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      BLoaders.errorSnackBar(
        title: 'Resend failed',
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = BHelperFunctions.isDarkMode(context);
    final Color titleColor = dark ? BColors.light : BColors.black;
    final Color bodyColor = dark ? BColors.lightGrey : BColors.textPrimary;
    final Color iconBackground = dark
        ? BColors.white.withValues(alpha: 0.08)
        : BColors.primaryBackground;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.defaultSpace,
        BSizes.defaultSpace,
        0,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.sm,
        BSizes.defaultSpace,
        BSizes.defaultSpace,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        0,
        BSizes.defaultSpace,
        BSizes.defaultSpace,
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: BColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: titleColor,
                  ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: bodyColor,
                  ),
            ),
            if (widget.details != null && widget.details!.trim().isNotEmpty) ...[
              const SizedBox(height: BSizes.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BSizes.sm),
                decoration: BoxDecoration(
                  color: dark ? BColors.black : BColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dark ? BColors.darkGrey : BColors.grey,
                  ),
                ),
                child: Text(
                  widget.details!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: bodyColor,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isResending ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.cancelButtonText),
        ),
        BSubmitButton(
          onPressed: _handleResend,
          isLoading: _isResending,
          label: widget.resendButtonText,
        ),
      ],
    );
  }
}

