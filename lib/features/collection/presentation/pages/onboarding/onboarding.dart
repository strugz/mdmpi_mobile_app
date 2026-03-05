import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/onboarding/widgets/onboarding_dot_navigation.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/onboarding/widgets/onboarding_page.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/onboarding/widgets/onboarding_skip.dart';

import 'widgets/onboarding_next_button.dart';
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
                image: BImages.onBoardingImage1Collection,
                title: BTexts.onBoardingTitle1Collection,
                subtitle: BTexts.onBoardingSubTitle1Collection,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage2Collection,
                title: BTexts.onBoardingTitle2Collection,
                subtitle: BTexts.onBoardingSubTitle2Collection,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage3Collection,
                title: BTexts.onBoardingTitle3Collection,
                subtitle: BTexts.onBoardingSubTitle3Collection,
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
