import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/styles/spacing_styles.dart';
import 'package:mdmpi_mobile_app/common/widgets/login_signup/form_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/login_signup/social_buttons.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/login/widgets/login_form.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/login/widgets/login_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: SingleChildScrollView(
      child: Padding(
        padding: BSpacingStyle.paddingWithAppBarHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoginHeader(),
            const LoginForm(),

            /// Divider
            const FormDivider(dividerText: BTexts.orSignInWith),
            const SizedBox(width: BSizes.spaceBtwSections),

            /// Footer
            const BSocialButtons()
          ],
        ),
      ),
    ));
  }
}
