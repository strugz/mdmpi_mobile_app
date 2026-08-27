
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

import '../../../base/utils/popups/loaders.dart';
import '../../local/database_helper.dart';
import '../../repositories/app_data/user_initial_repository.dart';
import '../../repositories/user/user_repository.dart';

class UserInitialController extends GetxController {
  static UserInitialController get instance => Get.find();

  /// User Initial
  final userInitialRepository = Get.find<UserInitialRepository>();
  // Resolve UserRepository lazily in onInit to avoid creating Firestore
  // instances on platforms where Firebase was intentionally not initialized.
  UserRepository? userRepository;

  /// user variables
  final selectedUserInitial = TextEditingController();
  RxList<UserModel> userList = <UserModel>[].obs;

  /// user API variables
  final userInitialList = Rx<List<Map<String, dynamic>>>([]);
  final userInitials = <Map<String, dynamic>>[].obs;

  /// Loading
  final isLoading = false.obs;

  /// Get Storage
  final box = GetStorage();

  final dbHelper = DatabaseHelper.instance;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    // Resolve userRepository only if Firebase has been initialized and the
    // repository is registered in Get (GeneralBindings).
    try {
      if (Firebase.apps.isNotEmpty && Get.isRegistered<UserRepository>()) {
        userRepository = Get.find<UserRepository>();
      }
    } catch (_) {}

    /// Fetch User Initial
    getAllUserFromLocal('Logistics');
  }

  Future<void> getAllUserFromLocal(String department) async {
    try {
      isLoading.value = true;

      final userInitials = await dbHelper.getUsers();

      if (userInitials.isEmpty) {
        await getAllUserList(department);
      } else {
        userInitials.where((user) => user.department == department);
        userList.assignAll(userInitials);
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: "Oh Snap!", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAllUserList(String department) async {
    try {
      // Show loader while loading Pending Request
      isLoading.value = true;

      // Fetch pending request from data source ( API )
      if (userRepository == null) {
        return;
      }

      final initials = await userRepository!.fetchAllUsers();

      initials.where((user) => user.department == department);

      // Update the pending Request List
      userList.assignAll(initials);
    } catch (e) {
      BLoaders.errorSnackBar(title: "Oh Snap!", message: e.toString());
    } finally {
      // Remove Loader
      isLoading.value = false;
    }
  }

  Future<void> getAllUserInitial() async {
    try {
      // Show loader while loading Pending Request
      isLoading.value = false;

      // Fetch pending request from data source ( API )
      final initials = await userInitialRepository.getAllUserInitial();

      // Convert the initials from List<UserInitialModel> to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> initialMaps =
          initials.map((initial) => initial.toJson()).toList();

      // Update the pending Request List
      userInitials.assignAll(initialMaps);

      // Optionally store or use the converted list
      box.write('userInitials', initialMaps);
    } catch (e) {
      BLoaders.errorSnackBar(title: "Oh Snap!", message: e.toString());
    } finally {
      // Remove Loader
      isLoading.value = false;
    }
  }
}
