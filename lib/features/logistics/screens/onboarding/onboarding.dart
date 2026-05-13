import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/logistics_onboarding_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_dot_navigation.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_next_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_page.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_skip.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LogisticsOnboardingController>();
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardingPage(
                image: BImages.darkAppLogo,
                title: BTexts.onBoardingTitle1Logistics,
                subtitle: BTexts.onBoardingSubTitle1Logistics,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage1,
                title: BTexts.onBoardingTitle2Logistics,
                subtitle: BTexts.onBoardingSubTitle2Logistics,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage2,
                title: BTexts.onBoardingTitle3Logistics,
                subtitle: BTexts.onBoardingSubTitle3Logistics,
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
