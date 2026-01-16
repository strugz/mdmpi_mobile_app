import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_request.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_with_email_password_usecase.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_with_google_usecase.dart';
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

  // Use cases
  late final LoginWithEmailPasswordUseCase _loginUseCase;
  late final LoginWithGoogleUseCase _loginWithGoogleUseCase;

  @override
  void onInit() {
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';

    // Initialize use cases
    _loginUseCase = Get.find<LoginWithEmailPasswordUseCase>();
    _loginWithGoogleUseCase = Get.find<LoginWithGoogleUseCase>();

    super.onInit();
  }

  /// --  Email and Password SignIn
  Future<void> emailAndPasswordSignIn() async {
    //  Form Validation
    if (!loginFormKey.currentState!.validate()) {
      BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please fill in all required fields');
      return;
    }

    try {
      BFullScreenLoader.openLoadingDialog(
          'Logging you in...', BImages.docerAnimation);

      // Build request
      final request = LoginRequest(
        email: email.text.trim(),
        password: password.text.trim(),
        rememberMe: rememberMe.value,
      );

      // Execute use case
      final result = await _loginUseCase.execute(request);

      // Remove Loader
      BFullScreenLoader.stopLoading();

      // Handle result
      if (result.isSuccess) {
        // Success: load initial data and navigate
        await loadingController.loadInitialData();
      } else {
        // Failure: show error
        BLoaders.errorSnackBar(
          title: 'Login Failed',
          message: result.error,
        );
      }
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(
        title: 'Unexpected Error',
        message: e.toString(),
      );
    }
  }

  /// --  Google SignIn Authentication
  Future<void> googleSignIn() async {
    try {
      //  Start Loading
      BFullScreenLoader.openLoadingDialog(
          'Logging you in...', BImages.docerAnimation);

      // Execute Google login use case
      final result = await _loginWithGoogleUseCase.execute();

      //  Remove Loader
      BFullScreenLoader.stopLoading();

      // Handle result
      if (result.isSuccess) {
        // Success: load initial data and navigate
        await loadingController.loadInitialData();

        // Redirect to appropriate screen
        AuthenticationRepository.instance.screenRedirect();
      } else {
        // Failure: show error
        BLoaders.errorSnackBar(
          title: 'Google Sign-In Failed',
          message: result.error,
        );
      }
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(
        title: 'Unexpected Error',
        message: e.toString(),
      );
    }
  }
}
