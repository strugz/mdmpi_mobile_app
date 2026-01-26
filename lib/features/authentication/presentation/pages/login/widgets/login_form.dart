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

  // Local FocusNodes to control focus traversal inside this form
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // Local hide password to avoid rebuilding the whole TextFormField with Obx
  bool _hidePassword = true;

  // Cache controller reference to prevent repeated Get.find calls
  late final LoginController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LoginController>();
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.spaceBtwSections),
        child: Column(
          children: [
            /// Username - Next action moves to password field
            TextFormField(
              controller: controller.email,
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (value) => BValidator.validateEmail(value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                labelText: BTexts.email,
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Password - Done action submits the form
            TextFormField(
              validator: (value) => BValidator.validatePassword(value),
              controller: controller.password,
              focusNode: _passwordFocus,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => controller.emailAndPasswordSignIn(_formKey),
              decoration: InputDecoration(
                labelText: BTexts.password,
                prefixIcon: const Icon(Iconsax.password_check),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _hidePassword = !_hidePassword);
                  },
                  icon: Icon(_hidePassword ? Iconsax.eye_slash : Iconsax.eye),
                ),
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
