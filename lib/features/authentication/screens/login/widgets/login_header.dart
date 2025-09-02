
import 'package:flutter/material.dart';

import '../../../../../base/utils/constants/image_strings.dart';
import '../../../../../base/utils/constants/text_string.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({
    super.key
  });


  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image(
          height: 150,
          image: AssetImage(
              dark ? BImages.lightAppLogo : BImages.darkAppLogo),
        ),
        Text(BTexts.loginTitle,
            style: Theme.of(context).textTheme.headlineMedium),
        Text(BTexts.loginSubTitle,
            style: Theme.of(context).textTheme.bodyMedium)
      ],
    );
  }
}