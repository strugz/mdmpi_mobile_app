import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/common/styles/spacing_styles.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/app_version_text.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/login/widgets/login_form.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/daily_quote_prompt_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Signed out, Login is the first screen of the day: the daily quote
    // pops up here (once a day, so not again over Home after signing in).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Get.isRegistered<DailyQuotePromptController>()) {
        Get.find<DailyQuotePromptController>().showIfDue();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Padding(
        padding: BSpacingStyle.paddingWithAppBarHeight,
        child: Column(
          children: [
            const AuthHeader(
              title: BTexts.loginTitle,
              subtitle: BTexts.signInTitle,
            ),
            const LoginForm(),
            const SizedBox(height: BSizes.spaceBtwSections),

            /// Open to everyone, signed in or not.
            TextButton.icon(
              key: const ValueKey('login-quote-of-the-day'),
              onPressed: () => Get.toNamed(BRoutes.quoteOfTheDay),
              icon: const Icon(Iconsax.quote_up, size: BSizes.iconSm),
              label: const Text('Quote of the Day'),
            ),
            const SizedBox(height: BSizes.sm),

            /// Which APK this is, for when someone cannot get past login.
            const BAppVersionText(),
          ],
        ),
      ),
    ));
  }
}
