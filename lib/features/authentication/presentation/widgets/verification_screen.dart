import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Generic verification screen widget
///
/// Used for email verification, password reset confirmation, 2FA, etc.
/// Shows an image, email/identifier, title, subtitle, and action buttons.
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({
    super.key,
    required this.identifier,
    required this.onContinue,
    required this.onResend,
    this.title,
    this.subtitle,
    this.continueButtonText,
    this.resendButtonText,
    this.image,
    this.showCloseButton = true,
    this.onClose,
  });

  /// The email, phone number, or other identifier being verified
  final String identifier;

  /// Callback when the continue/verify button is pressed
  final VoidCallback onContinue;

  /// Callback when the resend button is pressed
  final VoidCallback onResend;

  /// Title text (defaults to "Confirm Email")
  final String? title;

  /// Subtitle text (defaults to confirmation instructions)
  final String? subtitle;

  /// Continue button text (defaults to "Continue")
  final String? continueButtonText;

  /// Resend button text (defaults to "Resend Email")
  final String? resendButtonText;

  /// Image to display (defaults to email illustration)
  final String? image;

  /// Whether to show close button in app bar
  final bool showCloseButton;

  /// Callback when close button is pressed
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: showCloseButton
            ? [
                IconButton(
                  onPressed: onClose ?? () {},
                  icon: const Icon(CupertinoIcons.clear),
                )
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Column(
            children: [
              /// Image
              Image(
                image: AssetImage(
                  image ?? BImages.deliveredEmailIllustration,
                ),
                width: BHelperFunctions.screenWidth() * 0.6,
              ),
              const SizedBox(height: BSizes.spaceBtwSections),

              /// Identifier (email, phone, etc.)
              Text(
                identifier,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),

              /// Title
              Text(
                title ?? BTexts.confirmEmail,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BSizes.spaceBtwItems),

              /// Subtitle
              Text(
                subtitle ?? BTexts.confirmEmailSubTitle,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BSizes.spaceBtwSections),

              /// Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: Text(continueButtonText ?? BTexts.tContinue),
                ),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),

              /// Resend Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onResend,
                  child: Text(resendButtonText ?? BTexts.resendEmail),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
