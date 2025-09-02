import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/controllers/loading_screen/loading_screen_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  /// Variables
  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  final userController = Get.find<UserController>();

  final loadingController = Get.find<LoadingScreenController>();

  @override
  void onInit() {
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    super.onInit();
  }

  /// --  Email and Password SignIn
  Future<void> emailAndPasswordSignIn() async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      BLoaders.errorSnackBar(
          title: 'Internet', message: 'No Internet Connection');
      return;
    }

    //  Form Validation
    if (!loginFormKey.currentState!.validate()) {
      BLoaders.errorSnackBar(
          title: 'Authentication', message: 'Invalid Credentials');
      return;
    }

    try {
      BFullScreenLoader.openLoadingDialog(
          'Logging you in...', BImages.docerAnimation);

      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      }

      await AuthenticationRepository.instance
          .loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      //  Remove Loader
      BFullScreenLoader.stopLoading();

      //  Redirect
      await loadingController.loadInitialData();
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// --  Google SignIn Authentication
  Future<void> googleSignIn() async {
    try {
      //  Start Loading
      BFullScreenLoader.openLoadingDialog(
          'Logging you in...', BImages.docerAnimation);

      //  Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        BFullScreenLoader.stopLoading();
        return;
      }

      //  Google Authentication
      final userCredentials =
          await AuthenticationRepository.instance.signInWithGoogle();

      //  Save User Record
      await userController.saveUserRecord(userCredentials);

      //  Remove Loader
      BFullScreenLoader.stopLoading();

      //  Redirect
      await loadingController.loadInitialData();

      //  Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }
}
