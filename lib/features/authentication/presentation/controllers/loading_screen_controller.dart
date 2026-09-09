// data_loading_controller.dart
import 'package:get/get.dart';
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
  final RxString loadingProgressText = ''.obs;

  final clientController = Get.find<ClientController>();
  final userController = Get.find<UserController>();
  final userMDMPIController = Get.find<UserMdmpiController>();

  Future<void> loadInitialData() async {
    final steps = <({String label, Future<void> Function() run})>[
      (label: 'Clients', run: () => clientController.fetchClientFromDb(false)),
      (label: 'Users', run: () => userController.fetchUsersRecord(false)),
      (label: 'User Profile', run: () => userController.fetchUserRecord()),
      (
        label: 'Requesters',
        run: () => userMDMPIController.fetchUserMdmpiFromDb()
      ),
      (label: 'Item Categories', run: _loadItemCategories),
      (label: 'Form Categories', run: _loadFormCategories),
    ];

    try {
      //  Start Data Loading
      loadingProgressText.value = 'Data is Loading... (0/${steps.length})';
      BFullScreenLoader.openProgressLoadingDialog(
          loadingProgressText, BImages.docerAnimation);

      //  Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        BFullScreenLoader.stopLoading();
        return;
      }

      for (var i = 0; i < steps.length; i++) {
        loadingProgressText.value =
            'Loading ${steps[i].label}... (${i + 1}/${steps.length})';
        await steps[i].run();
      }

      BFullScreenLoader.stopLoading();

      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      logDebug("Error loading initial data: $e");
      BFullScreenLoader.stopLoading();
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
