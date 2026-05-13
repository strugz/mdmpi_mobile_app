import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

import '../../local/database_helper.dart';
import '../../models/cntmst_model.dart';
import '../../repositories/user/user_mdmpi_repository.dart';

class UserMdmpiController extends GetxController {
  static UserMdmpiController get instance => Get.find();

  /// Variables
  final isLoading = false.obs;
  final _userMdmpiRepository = Get.find<UserMDMPIRepository>();

  final userList = RxList<CNTMSTModel>([]);

  Future<void> fetchUserMdmpiFromDb() async {
    try {
      //  Show loader while loading user
      isLoading.value = true;

      List<CNTMSTModel> apiUser = await _userMdmpiRepository.getAllClientAPI();

      if (apiUser.isNotEmpty) {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.insertCntmsts(apiUser);
      } else {
        BLoaders.errorSnackBar(
            title: 'Oh Snap!', message: 'No User fetched from API');
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hardResetUserMdmpiList(bool isDisplay) async {
    try {
      isLoading.value = true;

      final apiUser = await _userMdmpiRepository.getAllClientAPI();

      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteCntmsts();
      if (apiUser.isNotEmpty) {
        await dbHelper.insertCntmsts(apiUser);
      }

      userList.assignAll(apiUser);

      if (isDisplay == true) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'User List Updated');
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filterUserFromLocal() async {
    try {
      isLoading.value = true;
      final dbHelper = DatabaseHelper.instance;
      final userListFromDb =
          await dbHelper.getCntmstRequesters();
      userList.assignAll(userListFromDb);
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
