import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/forget_password_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/login/login.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/widgets/verification_screen.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return VerificationScreen(
      identifier: email,
      title: BTexts.changeYourPasswordTitle,
      subtitle: BTexts.changeYourPasswordSubTitle,
      continueButtonText: BTexts.done,
      resendButtonText: BTexts.resendEmail,
      showCloseButton: true,
      onClose: () => Get.back(),
      onContinue: () => Get.offAll(() => const LoginScreen()),
      onResend: () => ForgetPasswordController.instance.resendPasswordResetEmail(email),
    );
  }
}
