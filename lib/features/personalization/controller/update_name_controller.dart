import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/profile.dart';

class UpdateNameController extends GetxController {
  static UpdateNameController get instance => Get.find();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final userController =UserController.instance;
  UserRepository? userRepository;
  GlobalKey<FormState> updateUserNameFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    // Resolve userRepository lazily if available
    try {
      if (Firebase.apps.isNotEmpty && Get.isRegistered<UserRepository>()) {
        userRepository = Get.find<UserRepository>();
      }
    } catch (_) {}

    initializeNames();
    super.onInit();
  }

  /// Fetch user record
  Future<void> initializeNames() async {
    firstName.text = userController.user.value.firstName;
    lastName.text = userController.user.value.lastName;
  }

  Future<void> updateUserName() async {
    try {
      // Start Loading
      BFullScreenLoader.openLoadingDialog('We are updating your information...', BImages.docerAnimation);

      //Check Internet Connectivity
      final isConnected = await  NetworkManager.instance.isConnected();
      if(!isConnected) {
        BFullScreenLoader.stopLoading();
        return;
      }

      //Form Validation
      if(!updateUserNameFormKey.currentState!.validate()) {
        BFullScreenLoader.stopLoading();
        return;
      }

      // Update user's first & last name in the Firebase Firestore
      Map<String, dynamic> name = {'FirstName': firstName.text.trim(), 'LastName': lastName.text.trim()};
      if (userRepository == null) {
        BLoaders.errorSnackBar(title: 'Error', message: 'Operation not available on this platform.');
        return;
      }
      await userRepository!.updateSingleField(name);

      //  Update the Rx User value
      userController.user.value.firstName = firstName.text.trim();
      userController.user.value.lastName = lastName.text.trim();

      //  Remove Loader
      BFullScreenLoader.stopLoading();

      //  Show Success Message
      BLoaders.successSnackBar(title: 'Congratulations', message: 'Your Name has been update.');

      //  Move to previous screen
      Get.off(() => ProfileScreen());
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }
}
