import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/validators/validation.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/login_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/password_configuration/forget_password.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/signup.dart';

import '../../../../../../../base/utils/constants/sizes.dart';
import '../../../../../../../base/utils/constants/text_string.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.spaceBtwSections),
        child: Column(
          children: [
            /// Username
            TextFormField(
              controller: controller.email,
              validator: (value) => BValidator.validateEmail(value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                labelText: BTexts.email,
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Password
            Obx(
              () => TextFormField(
                validator: (value) => BValidator.validatePassword(value),
                controller: controller.password,
                obscureText: controller.hidePassword.value,
                decoration: InputDecoration(
                    labelText: BTexts.password,
                    prefixIcon: const Icon(Iconsax.password_check),
                    suffixIcon: IconButton(
                        onPressed: () => controller.hidePassword.value =
                            !controller.hidePassword.value,
                        icon: Icon(controller.hidePassword.value
                            ? Iconsax.eye_slash
                            : Iconsax.eye))),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields / 2),

            /// Remember Me &  Forget password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Remember me
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                          value: controller.rememberMe.value,
                          onChanged: (value) => controller.rememberMe.value =
                              !controller.rememberMe.value),
                    ),
                    const Text(BTexts.rememberMe),
                  ],
                ),

                /// Forget Password
                TextButton(
                    onPressed: () => Get.to(const ForgetPassword()),
                    child: Text(BTexts.forgetPassword))
              ],
            ),
            const SizedBox(height: BSizes.spaceBtwSections),

            /// Sign in
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => controller.emailAndPasswordSignIn(_formKey),
                  child: Text(BTexts.signIn)),
            ),
            const SizedBox(height: BSizes.spaceBtwItems),

            /// Create Account
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: () => Get.to(() => const SignupScreen()),
                  child: const Text(BTexts.createAccount)),
            ),
          ],
        ),
      ),
    );
  }
}
