import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/delivery_location/location_google.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/home.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/settings.dart';

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIndex = 0.obs;



  // Store route names instead of widget instances
  final List<String> screenRoutes = [
    BRoutes.home,
    BRoutes.request,
    BRoutes.location,
    BRoutes.settings,
  ];

  // Call this from NavigationMenu's onTap
  void navigateToScreen(int index) {
    if (index >= 0 && index < screenRoutes.length) {
      selectedIndex.value = index;
      // You can choose the type of navigation:
      Get.toNamed(screenRoutes[index]);
      // Or, if you don't want to build up a stack for simple tab switching:
      // Get.offNamed(screenRoutes[index]);
      // Or, if these are top-level sections and you want to clear any nested routes within them:
      // Get.offAllNamed(screenRoutes[index], id: 1); // if using a nested navigator with id 1
    }
  }

  void changeScreen(int index) {
    selectedIndex.value = index;
  }

  // Function to navigate back to the previous screen
  final screens = [
    const HomeScreen(),
    const RequestScreen(),
    const LocationPageGoogle(),
    const SettingsScreen()
  ];

}