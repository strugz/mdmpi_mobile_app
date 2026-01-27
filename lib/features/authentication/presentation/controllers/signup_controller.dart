import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/verify_email.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

import '../../../../data/models/department_model.dart';
import '../../../../data/models/role_model.dart';
import '../../../../data/repositories/app_data/department_repository.dart';
import '../../../../data/repositories/app_data/role_repository.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variable
  final hidePassword = true.obs;
  final privacyPolicy = true.obs;
  final email = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final firstname = TextEditingController();
  final phoneNumber = TextEditingController();
  final initial = TextEditingController();
  final department = TextEditingController();

  // FocusNodes for explicit focus ordering in the sign up form
  final firstnameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final usernameFocus = FocusNode();
  final emailFocus = FocusNode();
  final initialFocus = FocusNode();
  final selectedRoleFocus = FocusNode();
  final phoneNumberFocus = FocusNode();
  final passwordFocus = FocusNode();

  final roles = Rx<List<RoleModel>>(List<RoleModel>.empty());

  final departments = Rx<List<DepartmentModel>>(List<DepartmentModel>.empty());

  final selectedRole = TextEditingController();

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  final roleRepository = Get.find<RoleRepository>();
  final departmentRepository = Get.find<DepartmentRepository>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    fetchAllRoles();
    fetchAllDepartments();
  }

  @override
  void onClose() {
    // Dispose focus nodes
    firstnameFocus.dispose();
    lastNameFocus.dispose();
    usernameFocus.dispose();
    emailFocus.dispose();
    initialFocus.dispose();
    selectedRoleFocus.dispose();
    phoneNumberFocus.dispose();
    passwordFocus.dispose();

    // Dispose text controllers
    email.dispose();
    lastName.dispose();
    username.dispose();
    password.dispose();
    firstname.dispose();
    phoneNumber.dispose();
    initial.dispose();
    department.dispose();
    selectedRole.dispose();

    super.onClose();
  }

  /// Clear all form fields
  void clearForm() {
    email.clear();
    lastName.clear();
    username.clear();
    password.clear();
    firstname.clear();
    phoneNumber.clear();
    initial.clear();
    department.clear();
    selectedRole.clear();
    privacyPolicy.value = true;
    hidePassword.value = true;
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

      //  Clear form data after successful signup
      clearForm();
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
