import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/validators/validation.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/forget_password_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/widgets/auth_header.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgetPasswordController>();
    return Scaffold(
      appBar: const BAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          children: [
            /// Header
            const AuthHeader(
              title: BTexts.forgetPasswordTitle,
              subtitle: BTexts.forgetPasswordSubTitle,
              showLogo: false,
            ),
            const SizedBox(height: BSizes.spaceBtwSections * 2),

            /// Text Field
            Form(
              key: controller.forgetPasswordFormKey,
              child: TextFormField(
                controller: controller.email,
                validator: BValidator.validateEmail,
                decoration: const InputDecoration(
                    labelText: BTexts.email,
                    prefixIcon: Icon(Iconsax.direct_right)),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),

            /// Submit Button
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => controller.sendPasswordResetEmail(),
                    child: const Text(BTexts.submit))),
          ],
        ),
      ),
    );
  }
}
