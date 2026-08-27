import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

import '../../local/database_helper.dart';
import '../../models/mobile_model.dart';
import '../../repositories/app_data/mobile_repository.dart';

class MobileController extends GetxController {
  static MobileController get instance => Get.find();

  /// Mobile repo
  final mobileRepository = Get.find<MobileRepository>();

  /// mobile variables
  // final mobile = <Map<String, dynamic>>[].obs;
  final mobile = <Mobile>[].obs;
  final selectedMobile = TextEditingController();
  final mobileList = Rx<List<Map<String, dynamic>>>([]);
  final _dbHelper = DatabaseHelper.instance;

  /// Loading
  final isLoading = false.obs;

  /// Get Storage
  final box = GetStorage();

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();

    /// Fetch Mobile
    getAllMobile();
  }

  Future<void> getAllMobile() async {
    try {
      // Show loader while loading Pending Request
      isLoading.value = true;

      final localMobiles = await _dbHelper.getMobiles();

      if (localMobiles.isNotEmpty) {
        mobile.assignAll(localMobiles);
      } else if (await NetworkManager.instance.isConnected()) {
        final mobiles = await mobileRepository.getAllMobile();

        await _dbHelper.insertMobiles(mobiles);

        mobile.assignAll(mobiles);
      }
    } catch (e) {
      logDebug('MobileController.getAllMobile failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAllMobileInServer(bool isDisplay) async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      BLoaders.warningSnackBar(
          title: "Internet", message: "No Internet Connection");
      return;
    }
    try {
      isLoading.value = true;

      final mobiles = await mobileRepository.getAllMobile();

      await _dbHelper.insertMobiles(mobiles);

      mobile.assignAll(mobiles);
      if (isDisplay == true) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'Vehicle List Updated');
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: "Oh Snap!", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hardResetVehicles(bool isDisplay) async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      BLoaders.warningSnackBar(
          title: "Internet", message: "No Internet Connection");
      return;
    }

    try {
      isLoading.value = true;

      final mobiles = await mobileRepository.getAllMobile();

      await _dbHelper.deleteMobiles();
      if (mobiles.isNotEmpty) {
        await _dbHelper.insertMobiles(mobiles);
      }

      mobile.assignAll(mobiles);

      if (isDisplay == true) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'Vehicle List Updated');
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: "Oh Snap!", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
