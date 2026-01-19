import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/verify_email_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/widgets/verification_screen.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VerifyEmailController>();

    return VerificationScreen(
      identifier: email ?? '',
      showCloseButton: true,
      onClose: () => AuthenticationRepository.instance.logout(),
      onContinue: () => controller.checkEmailVerificationStatus(),
      onResend: () => controller.sendEmailVerification(),
    );
  }
}
