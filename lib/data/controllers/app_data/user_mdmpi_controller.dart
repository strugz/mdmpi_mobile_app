import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
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

  /// Guards against the request forms calling [filterUserFromLocal] on every
  /// rebuild while a hydration round-trip is still in flight.
  bool _isHydrating = false;

  Future<void> fetchUserMdmpiFromDb() async {
    await _loadRequesters();
  }

  Future<void> hardResetUserMdmpiList(bool isDisplay) async {
    if (!await NetworkManager.instance.isConnected()) {
      BLoaders.warningSnackBar(
          title: "Internet", message: "No Internet Connection");
      return;
    }

    try {
      isLoading.value = true;

      final apiUser = await _userMdmpiRepository.getAllClientAPI();

      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteCntmsts();
      if (apiUser.isNotEmpty) {
        await dbHelper.insertCntmsts(apiUser);
      }

      // Same filter as the local-first path, so a hard reset and a normal
      // load never disagree about who can be picked as a requester.
      userList.assignAll(await dbHelper.getCntmstRequesters());

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
    await _loadRequesters();
  }

  /// Local-first load of the requester list, with an API re-hydration when the
  /// local cache is empty.
  ///
  /// CNTMST is a cache-backed table: a DB version bump drops and recreates it
  /// empty, and only the post-login loading screen used to refill it. A user
  /// who updates the app while still signed in therefore skipped the only
  /// refill there was, and "Requested By" stayed empty forever with no way to
  /// recover short of a manual hard reset. Re-fetching here is idempotent and
  /// self-healing, and also covers a first fetch that failed for one call.
  Future<void> _loadRequesters() async {
    if (_isHydrating) return;
    _isHydrating = true;
    try {
      isLoading.value = true;
      final dbHelper = DatabaseHelper.instance;

      final localUsers = await dbHelper.getCntmstRequesters();
      if (localUsers.isNotEmpty) {
        userList.assignAll(localUsers);
        return;
      }

      if (!await NetworkManager.instance.isConnected()) {
        logDebug(
            'UserMdmpiController: requester cache empty and device offline');
        return;
      }

      final apiUser = await _userMdmpiRepository.getAllClientAPI();
      if (apiUser.isEmpty) {
        logDebug('UserMdmpiController: API returned no requesters');
        return;
      }

      await dbHelper.insertCntmsts(apiUser);
      // Read back through the DAO so the same requester filter (no collectors,
      // no inactive records) applies to the freshly fetched rows.
      userList.assignAll(await dbHelper.getCntmstRequesters());
    } catch (e) {
      logDebug('UserMdmpiController._loadRequesters failed: $e');
    } finally {
      isLoading.value = false;
      _isHydrating = false;
    }
  }
}
