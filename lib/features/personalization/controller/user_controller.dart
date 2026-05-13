import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/login/login.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/widgets/re_authenticate_user_login_form.dart';

import '../../../data/local/database_helper.dart';
import '../models/user_model.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final profileLoading = false.obs;
  final user = UserModel.empty().obs;

  final hidePassword = false.obs;
  final imageUploading = false.obs;
  final verifyEmail = TextEditingController();
  final verifyPassword = TextEditingController();
  // UserRepository is Firebase-backed. Resolve it lazily in onInit only if
  // Firebase has been initialized and the repository is registered. This
  // prevents accessing Firebase services on unsupported platforms.
  UserRepository? userRepository;
  final dbHelper = DatabaseHelper.instance;
  final _storage = GetStorage();

  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();

  @override
  Future<void> onInit() async {
    // Load cached user synchronously so AppRouter has the department
    // immediately on cold start, before the async Firebase fetch completes.
    _loadCachedUser();
    // Resolve repository only when Firebase is initialized and repository
    // registration exists. This avoids triggering Firestore access on
    // platforms where Firebase was intentionally not initialized.
    try {
      if (Firebase.apps.isNotEmpty && Get.isRegistered<UserRepository>()) {
        userRepository = Get.find<UserRepository>();
      }
    } catch (e) {
      // Ignore; repository will remain null and methods should handle it.
    }
    await fetchUserRecord();
    super.onInit();
  }

  /// Load cached current user from GetStorage (synchronous).
  void _loadCachedUser() {
    try {
      final cachedJson = _storage.read('CurrentUser');
      if (cachedJson != null && cachedJson is Map<String, dynamic>) {
        user(UserModel.fromJson(cachedJson));
        logDebug('Loaded cached user: ${user.value.department}');
      }
    } catch (e) {
      logDebug('Error loading cached user: $e');
    }
  }

  /// Persist current user to GetStorage for cold-start routing.
  void _cacheCurrentUser() {
    try {
      if (user.value.id.isNotEmpty) {
        _storage.write('CurrentUser', user.value.toLocalJson());
      }
    } catch (e) {
      logDebug('Error caching user: $e');
    }
  }

  @override
  void dispose() {
    verifyEmail.dispose();
    verifyPassword.dispose();
    user.close();
    super.dispose();
  }

  /// Fetch user record
  Future<void> fetchUserRecord() async {
    try {
      profileLoading.value = true;

      // If repository is not available (Firebase not initialized), skip
      // remote fetch and keep cached/local user only.
      if (userRepository == null) {
        profileLoading.value = false;
        return;
      }

      /// Get user data
      final users = await userRepository!.fetchUserDetails();

      /// Update Rx User
      user(users);

      /// Cache to GetStorage for cold-start routing
      _cacheCurrentUser();

      /// Update Rx User
      profileLoading.value = false;
    } catch (e) {
      user(UserModel.empty());
    } finally {
      profileLoading.value = false;
    }
  }

  /// Fetch Users record
  Future<void> fetchUsersRecord(bool isDisplay) async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      BLoaders.errorSnackBar(
          title: "Internet", message: "No Internet Connection");
      return;
    }
    try {
      profileLoading.value = true;

      // If no Firebase repo is available, skip remote fetch.
      if (userRepository == null) {
        profileLoading.value = false;
        return;
      }

      /// Get user data
      final users = await userRepository!.fetchAllUsers();

      final usersFromLocal = await dbHelper.getUsers();

      if (users.length != usersFromLocal.length) {
        /// Insert Users to Database
        await dbHelper.insertUsers(users);
      }
      if (isDisplay == true) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'User List Updated');
      }
      /// Update Rx User
      profileLoading.value = false;
    } catch (e) {
      logDebug('Error ${e.toString()}');
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> hardResetUsers(bool isDisplay) async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      BLoaders.errorSnackBar(
          title: "Internet", message: "No Internet Connection");
      return;
    }

    try {
      profileLoading.value = true;

      if (userRepository == null) {
        BLoaders.warningSnackBar(
          title: 'Unavailable',
          message: 'User sync is not available on this platform.',
        );
        return;
      }

      final users = await userRepository!.fetchAllUsers();

      await dbHelper.deleteUsers();
      if (users.isNotEmpty) {
        await dbHelper.insertUsers(users);
      }

      if (isDisplay == true) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'User List Updated');
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      profileLoading.value = false;
    }
  }

  /// Save user Record from any Registration provided
  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      //  First Update Rx User and then check if user data is already stored. If not store new data
      await fetchUserRecord();

      //  If no record already stored.
      if (user.value.id.isEmpty) {
        if (userCredentials != null) {
          //  Convert Name to First and Last Name
          final nameParts =
              UserModel.nameParts(userCredentials.user!.displayName ?? '');
          final username = UserModel.generateUsername(
              userCredentials.user!.displayName ?? '');

          //  Map Data
          final user = UserModel(
            id: userCredentials.user!.uid,
            firstName: nameParts[0],
            lastName:
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            username: username,
            email: userCredentials.user!.email ?? '',
            phoneNumber: userCredentials.user!.phoneNumber ?? '',
            profilePicture: userCredentials.user!.photoURL ?? '',
          );

          //   Save user data (skip if no repository available)
          if (userRepository != null) {
            await userRepository!.saveUserRecord(user);
          }
        }
      }
    } catch (e) {
      BLoaders.warningSnackBar(
          title: 'Data not saved',
          message:
              'Something went wrong while saving your information. You can re-save your data in your Profile.');
    }
  }

  /// Delete Account Warning
  void deleteAccountWarningPopup() {
    Get.defaultDialog(
        contentPadding: const EdgeInsets.all(BSizes.md),
        title: 'Delete Account',
        middleText:
            'Are you sure you want to delete your account permanently? This action is not reversible and all of your data will be removed permanently.',
        confirm: ElevatedButton(
          onPressed: () async => deleteUserAccount(),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              side: const BorderSide(color: Colors.red)),
          child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: BSizes.lg),
              child: Text('Delete')),
        ),
        cancel: OutlinedButton(
            onPressed: () => Navigator.of(Get.overlayContext!).pop(),
            child: const Text('Cancel')));
  }

  /// Delete User Account
  void deleteUserAccount() async {
    try {
      BFullScreenLoader.openLoadingDialog(
          'Processing...', BImages.docerAnimation);

      /// First re-authenticate user
      final auth = AuthenticationRepository.instance;
      final provider =
          auth.authUser!.providerData.map((e) => e.providerId).first;
      if (provider.isNotEmpty) {
        //  Re Verify Auth Email
        if (provider == 'google.com') {
          final result = await auth.loginWithGoogle();
          if (result.isSuccess) {
            final deleteResult = await auth.deleteAccount();
            if (deleteResult.isSuccess) {
              BFullScreenLoader.stopLoading();
              Get.offAll(() => const LoginScreen());
            } else {
              BFullScreenLoader.stopLoading();
              BLoaders.errorSnackBar(title: 'Error', message: deleteResult.error);
            }
          } else {
            BFullScreenLoader.stopLoading();
            BLoaders.errorSnackBar(title: 'Authentication Failed', message: result.error);
          }
        } else if (provider == 'password') {
          BFullScreenLoader.stopLoading();
          Get.to(() => const ReAuthLoginForm());
        }
      }
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.warningSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }

  /// --RE-AUTHENTICATE before deleting
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      BFullScreenLoader.openLoadingDialog('Processing', BImages.docerAnimation);

      //  Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        BFullScreenLoader.stopLoading();
        return;
      }

      if (!reAuthFormKey.currentState!.validate()) {
        BFullScreenLoader.stopLoading();
        return;
      }

      final reAuthResult = await AuthenticationRepository.instance.reAuthenticate(
        email: verifyEmail.text.trim(),
        password: verifyPassword.text.trim(),
      );

      if (reAuthResult.isFailure) {
        BFullScreenLoader.stopLoading();
        BLoaders.errorSnackBar(title: 'Authentication Failed', message: reAuthResult.error);
        return;
      }

      final deleteResult = await AuthenticationRepository.instance.deleteAccount();

      if (deleteResult.isFailure) {
        BFullScreenLoader.stopLoading();
        BLoaders.errorSnackBar(title: 'Delete Failed', message: deleteResult.error);
        return;
      }

      BFullScreenLoader.stopLoading();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.warningSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }

  /// Upload Profile Image
  Future<void> uploadUserProfilePicture() async {
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxHeight: 512,
          maxWidth: 512);
      if (image != null) {
        imageUploading.value = true;

        //  Upload Image (requires Firebase-backed repo)
        if (userRepository == null) {
          BLoaders.errorSnackBar(title: 'Error', message: 'Upload not available on this platform');
          return;
        }

        //  Upload Image
        final imageUrl =
            await userRepository!.uploadImage('Users/Images/Profile/', image);

        //  Update User Image Record
        Map<String, dynamic> json = {'ProfilePicture': imageUrl};
        await userRepository!.updateSingleField(json);

        user.value.profilePicture = imageUrl;
        user.refresh();

        BLoaders.successSnackBar(
            title: 'Congratulations',
            message: 'Your Profile Image has been updated!');
      }
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Oh Snap', message: 'Something went wrong: $e');
    } finally {
      imageUploading.value = false;
    }
  }

  Future<String?> fetchUserPhoneNumber(String initial) async {
    try {
      profileLoading.value = true;
      if (userRepository == null) {
        profileLoading.value = false;
        return null;
      }

      final user = await userRepository!.fetchUserPhoneNumber(initial);
      profileLoading.value = false;
      return user.phoneNumber;
    } catch (e) {
      return user(UserModel.empty()).phoneNumber;
    } finally {
      profileLoading.value = false;
    }
  }

  Future<String> fetchUserPhoneNumberForDriver(String initial) async {
    final dbHelper = DatabaseHelper.instance;
    try {
      profileLoading.value = true;
      final user = await dbHelper.getUserPhoneNumberByUsername(initial);
      profileLoading.value = false;
      return user;
    } catch (e) {
      return user(UserModel.empty()).phoneNumber;
    } finally {
      profileLoading.value = false;
    }
  }
}
