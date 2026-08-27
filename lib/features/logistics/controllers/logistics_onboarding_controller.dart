import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/navigation_menu.dart';

/// Logistics department onboarding controller
///
/// Handles the onboarding flow specifically for the Logistics department.
/// Manages page navigation, progress tracking, and completion.
class LogisticsOnboardingController extends GetxController {
  static LogisticsOnboardingController get instance => Get.find();

  /// Variables
  final PageController pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  /// Updates Current Index when Page Scroll
  void updatePageIndicator(int index) => currentPageIndex.value = index;

  /// Jump to the specific dot selected page.
  void dotNavigationClick(int index) {
    currentPageIndex.value = index;
    pageController.jumpTo(index.toDouble());
  }

  /// Update Current Index & jump to next page
  void nextPage() {
    if (currentPageIndex.value == 2) {
      final storage = GetStorage();

      // Mark logistics onboarding as complete
      storage.write('IsFirstTime', false);
      storage.write('LogisticsOnboardingComplete', true);

      Get.offAll(() => const NavigationMenu());
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  /// Update Current Index & jump to the last Page
  void skipPage() {
    currentPageIndex.value = 2;
    if (currentPageIndex.value == 2) {
      final storage = GetStorage();

      // Mark logistics onboarding as complete
      storage.write('IsFirstTime', false);
      storage.write('LogisticsOnboardingComplete', true);

      Get.offAll(() => const NavigationMenu());
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
