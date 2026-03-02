import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/onboarding/widgets/onboarding_dot_navigation.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/onboarding/widgets/onboarding_page.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/onboarding/widgets/onboarding_skip.dart';

import '../../../../logistics/screens/onboarding/widgets/onboarding_next_button.dart';
import '../../controllers/collection_onboarding_controller.dart';

class CollectionOnBoardingScreen extends StatelessWidget {
  const CollectionOnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionOnboardingController>();
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardingPage(
                image: BImages.darkAppLogo,
                title: BTexts.onBoardingTitle1,
                subtitle: BTexts.onBoardingSubTitle1,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage1,
                title: BTexts.onBoardingTitle2,
                subtitle: BTexts.onBoardingSubTitle2,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage2,
                title: BTexts.onBoardingTitle3,
                subtitle: BTexts.onBoardingSubTitle3,
              ),
            ],
          ),

          /// Skip Button
          const OnBoardingSkip(),

          /// Dot navigation SmoothPageIndicator
          const OnBoardingDotNavigation(),

          /// Circular Button
          const OnBoardingNextButton()
        ],
      ),
    );
  }
}
