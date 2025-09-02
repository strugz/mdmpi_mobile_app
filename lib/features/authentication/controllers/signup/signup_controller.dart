import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/signup/verify_email.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

import '../../../../data/models/department_model.dart';
import '../../../../data/models/role_model.dart';
import '../../../../data/repositories/app_data/department_repository.dart';
import '../../../../data/repositories/app_data/role_repository.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variable
  final hidePassword = true.obs; // Observable for hiding/showing password
  final privacyPolicy = true.obs; //  Observable for privacy policy acceptance
  final email = TextEditingController(); // Controller for email input
  final lastName = TextEditingController(); // Controller for last name input
  final username = TextEditingController(); // Controller for username input
  final password = TextEditingController(); // Controller for password input
  final firstname = TextEditingController(); //  Controller for first name input
  final phoneNumber =
      TextEditingController(); //  Controller for phone number input
  final initial = TextEditingController(); //  Controller for initial input
  final department =
      TextEditingController(); //  Controller for department input

  final roles = Rx<List<RoleModel>>(
      List<RoleModel>.empty()); //  Controller for role input

  final departments = Rx<List<DepartmentModel>>(List<DepartmentModel>.empty());

  final selectedRole =
      TextEditingController(); //  Controller for selected role input

  GlobalKey<FormState> signupFormKey =
      GlobalKey<FormState>(); // Form key for form validation

  final roleRepository = Get.find<RoleRepository>();
  final departmentRepository = Get.find<DepartmentRepository>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    fetchAllRoles();
    fetchAllDepartments();
  }

  /// --  SIGNUP
  Future<void> signup() async {
    try {
      //  Start Loading
      BFullScreenLoader.openLoadingDialog(
          'We are processing your information...', BImages.docerAnimation);

      //  Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        BFullScreenLoader.stopLoading();
        return;
      }

      //  Form Validation
      if (!signupFormKey.currentState!.validate()) {
        BFullScreenLoader.stopLoading();
        return;
      }

      //  Privacy Policy Check
      if (!privacyPolicy.value) {
        BLoaders.warningSnackBar(
            title: 'Accept Privacy Policy',
            message:
                'In order to create account, you must have to read and accept the Privacy & Terms of Use.');
        return;
      }

      //  Register user in the Firebase Authentication & Save user data in the Firebase
      final userCredential = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(
              email.text.trim(), password.text.trim());

      //  Save Authenticated user data in Firebase Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: firstname.text.trim(),
        lastName: lastName.text.trim(),
        username: username.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: '',
        initial: initial.text.trim(),
        department: department.text.trim(),
        role: selectedRole.text,
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.saveUserRecord(newUser);

      //  Remove Loader
      BFullScreenLoader.stopLoading();

      //  Show Success
      BLoaders.successSnackBar(
          title: 'Congratulations',
          message: 'Your account has been created! Verify email to continue.');

      //  Move to Verify Email Screen
      Get.to(() => VerifyEmailScreen(email: email.text.trim()));
    } catch (e) {
      //  Remove Loader
      BFullScreenLoader.stopLoading();

      //  Show some Generic Error to the user
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// -- Load Sign up Components
  Future<void> fetchAllRoles() async {
    try {
      final role = await roleRepository.getRoles();
      roles(role);
    } catch (e) {
      roles(List<RoleModel>.empty());
    } finally {
      roles.refresh();
    }
  }

  Future<void> fetchAllDepartments() async {
    try {
      final department = await departmentRepository.getDepartments();
      departments(department);
    } catch (e) {
      departments(List<DepartmentModel>.empty());
    } finally {
      departments.refresh();
    }
  }

  /// Update role selected

  Future<void> updateRole(String role) async {
    if (!selectedRole.text.contains(role)) {
      selectedRole.text =
          selectedRole.text.isEmpty ? role : '${selectedRole.text}, $role';
      return;
    } else {
      selectedRole.text = selectedRole.text.replaceAll(
          selectedRole.text.contains(',')
              ? selectedRole.text.contains('$role, ')
                  ? '$role, '
                  : ', $role'
              : role,
          '');
      return;
    }
  }
}
