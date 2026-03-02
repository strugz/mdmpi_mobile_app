import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/styles/spacing_styles.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/login/widgets/login_form.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/widgets/auth_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: SingleChildScrollView(
      child: Padding(
        padding: BSpacingStyle.paddingWithAppBarHeight,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(
              title: BTexts.loginTitle,
              subtitle: BTexts.signInTitle,
            ),
            LoginForm(),
          ],
        ),
      ),
    ));
  }
}
