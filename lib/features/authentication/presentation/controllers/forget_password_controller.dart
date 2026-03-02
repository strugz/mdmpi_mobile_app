import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/password_configuration/reset_password.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();


  /// Variables
  final email = TextEditingController();
  GlobalKey<FormState> forgetPasswordFormKey = GlobalKey<FormState>();

  /// Send Reset Password Email
  Future<void> sendPasswordResetEmail() async {
    try {
      //  Start Loading
      BFullScreenLoader.openLoadingDialog('Processing your request...', BImages.docerAnimation);

      //  Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected){BFullScreenLoader.stopLoading(); return;}

      //  Form Validation
      if(!forgetPasswordFormKey.currentState!.validate()) {
        BFullScreenLoader.stopLoading();
        return;
      }

      //  Send Email to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email.text.trim());

      //  Remove Loader
      BFullScreenLoader.stopLoading();

      //  Show Success Screen
      BLoaders.successSnackBar(title: 'Email Sent', message: 'Email Link Sent to Reset your Password'.tr);
      
      //  Redirect
      Get.to(() => ResetPasswordScreen(email: email.text.trim()));

    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }


  Future<void> resendPasswordResetEmail(String email) async {
    try {
      //  Start Loading
      BFullScreenLoader.openLoadingDialog('Processing your request...', BImages.docerAnimation);

      //  Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected){BFullScreenLoader.stopLoading(); return;}

      //  Send Email to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email);

      //  Remove Loader
      BFullScreenLoader.stopLoading();

      //  Show Success Screen
      BLoaders.successSnackBar(title: 'Email Sent', message: 'Email Link Sent to Reset your Password'.tr);

    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }
}
