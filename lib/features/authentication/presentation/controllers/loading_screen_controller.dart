// data_loading_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import '../../../../../../base/utils/constants/image_strings.dart';
import '../../../../../../base/utils/helpers/network_manager.dart';
import '../../../../data/controllers/client_controller.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/common/item_category_repository.dart';
import '../../../../data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class LoadingScreenController extends GetxController {
  var isLoading = false.obs; // Observable boolean to track loading state

  final clientController = Get.find<ClientController>();
  final userController = Get.find<UserController>();
  final userMDMPIController = Get.find<UserMdmpiController>();

  /// Box to store data
  final box = GetStorage();

  Future<void> loadInitialData() async {
    try {
      //  Start Data Loading
      BFullScreenLoader.openLoadingDialog(
          'Data is Loading...', BImages.docerAnimation);

      //  Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        BFullScreenLoader.stopLoading();
        return;
      }

      await clientController.fetchClientFromDb(false);

      await userController.fetchUsersRecord(false);

      await userController.fetchUserRecord();

      await userMDMPIController.fetchUserMdmpiFromDb();

      // Load ItemCategory and FormCategory to local DB
      await _loadItemCategories();
      await _loadFormCategories();

      BFullScreenLoader.stopLoading();

      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      logDebug("Error loading initial data: $e");
    }
  }

  /// Load ItemCategory data to local database
  Future<void> _loadItemCategories() async {
    try {
      final repo = Get.find<ItemCategoryRepository>();
      // This will check local DB first, and fetch from API if needed
      await repo.getAll();
      logDebug("ItemCategory data loaded successfully");
    } catch (e) {
      logDebug("Error loading ItemCategory data: $e");
      // Non-critical, continue loading other data
    }
  }

  /// Load FormCategory data to local database
  Future<void> _loadFormCategories() async {
    try {
      final repo = Get.find<FormCategoryRepository>();
      // This will check local DB first, and fetch from API if needed
      await repo.getAll();
      logDebug("FormCategory data loaded successfully");
    } catch (e) {
      logDebug("Error loading FormCategory data: $e");
      // Non-critical, continue loading other data
    }
  }
}
