import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_directory_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/verify_email.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_roles.dart';
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

  /// The department picked at the top of the form; the role list and the
  /// department's own fields follow it.
  final selectedDepartment = ''.obs;

  /// Collection only: the Head saved as `HeadKey` / `HeadName`, the same
  /// fields Settings → My Head writes. Optional at sign-up.
  final headKey = ''.obs;
  final headName = ''.obs;

  /// The user directory for the Head picker; empty when it cannot be read yet
  /// (masters download after the first login).
  final headDirectory = <DirectoryUser>[].obs;
  final headQuery = ''.obs;
  final headDirectoryLoading = false.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // Do NOT call Get.find<RoleRepository>() or Get.find<DepartmentRepository>()
  // at field initialization time. Those repositories create Firestore
  // instances and will throw if Firebase is not initialized. Resolve them
  // lazily in onInit or when needed.
  RoleRepository? _roleRepository;
  DepartmentRepository? _departmentRepository;

  @override
  void onInit() {
    super.onInit();

    // Resolve repositories only if Firebase is initialized and they are
    // registered in the binding. This prevents creating Firestore instances
    // on unsupported platforms.
    try {
      if (Firebase.apps.isNotEmpty) {
        if (Get.isRegistered<RoleRepository>()) {
          _roleRepository = Get.find<RoleRepository>();
        }
        if (Get.isRegistered<DepartmentRepository>()) {
          _departmentRepository = Get.find<DepartmentRepository>();
        }
      }
    } catch (_) {}

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

  bool get isCollection =>
      BCollectionRoles.isCollectionDepartment(selectedDepartment.value);

  /// The roles offered for the selected department; none until one is picked.
  List<RoleModel> get filteredRoles => roles.value
      .where((r) => r.appliesTo(selectedDepartment.value))
      .toList();

  /// People in the Head picker matching [headQuery] on name, code or department.
  List<DirectoryUser> get filteredHeadDirectory {
    final q = headQuery.value.trim().toLowerCase();
    if (q.isEmpty) return headDirectory;
    return headDirectory
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.key.toLowerCase().contains(q) ||
            u.department.toLowerCase().contains(q))
        .toList();
  }

  /// A new department starts the role choice over, so a role from another
  /// department cannot be submitted, and drops the Head outside Collection.
  void onDepartmentChanged(String? value) {
    final dept = (value ?? '').trim();
    if (dept == selectedDepartment.value) return;
    department.text = dept;
    selectedDepartment.value = dept;
    _resetRoles();
    if (!isCollection) clearHead();
  }

  void selectHead(DirectoryUser person) {
    headKey.value = person.key;
    headName.value = person.name;
  }

  void clearHead() {
    headKey.value = '';
    headName.value = '';
  }

  /// Loads the directory for the Head picker. Never fails the form: an
  /// unreadable directory is an empty list.
  Future<void> loadHeadDirectory() async {
    if (headDirectoryLoading.value) return;
    headDirectoryLoading.value = true;
    try {
      if (!Get.isRegistered<UserDirectoryRepository>()) {
        headDirectory.clear();
        return;
      }
      final result = await Get.find<UserDirectoryRepository>().load();
      if (result.isSuccess) {
        headDirectory.assignAll(result.value);
      } else {
        logDebug('SignupController: head directory unavailable: ${result.error}');
        headDirectory.clear();
      }
    } catch (e) {
      logDebug('SignupController: head directory error: $e');
      headDirectory.clear();
    } finally {
      headDirectoryLoading.value = false;
    }
  }

  void _resetRoles() {
    selectedRole.clear();
    for (final role in roles.value) {
      role.status = false;
    }
    roles.refresh();
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
    selectedDepartment.value = '';
    _resetRoles();
    clearHead();
    headQuery.value = '';
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
        headKey: isCollection ? headKey.value : '',
        headName: isCollection ? headName.value : '',
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
      // Attempt to resolve repository lazily if not already available and if
      // Firebase has been initialized.
      RoleRepository? repo = _roleRepository;
      try {
        if (repo == null && Firebase.apps.isNotEmpty && Get.isRegistered<RoleRepository>()) {
          repo = Get.find<RoleRepository>();
          _roleRepository = repo;
        }
      } catch (_) {}

      if (repo == null) {
        roles(List<RoleModel>.empty());
        return;
      }

      final roleList = await repo.getRoles();
      roles(roleList);
    } catch (e) {
      roles(List<RoleModel>.empty());
    } finally {
      roles.refresh();
    }
  }

  Future<void> fetchAllDepartments() async {
    try {
      DepartmentRepository? repo = _departmentRepository;
      try {
        if (repo == null && Firebase.apps.isNotEmpty && Get.isRegistered<DepartmentRepository>()) {
          repo = Get.find<DepartmentRepository>();
          _departmentRepository = repo;
        }
      } catch (_) {}

      if (repo == null) {
        departments(List<DepartmentModel>.empty());
        return;
      }

      final departmentList = await repo.getDepartments();
      departments(departmentList);
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
