import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/data/models/cntmst_model.dart';
import 'package:mdmpi_mobile_app/data/models/contact_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/contact_repository.dart';

class ContactDirectoryController extends GetxController {
  final ContactRepository _contactRepository = Get.find<ContactRepository>();

  final RxList<ContactModel> contacts = <ContactModel>[].obs;
  final RxList<CNTMSTModel> directoryOptions = <CNTMSTModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadContacts(),
      loadDirectoryOptions(),
    ]);
  }

  Future<void> loadContacts() async {
    try {
      isLoading.value = true;
      final result = await _contactRepository.getContacts();
      contacts.assignAll(result);
    } catch (e) {
      logDebug('ContactDirectoryController.loadContacts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDirectoryOptions() async {
    try {
      var result = await _contactRepository.getContactDirectoryOptions();
      // Signed in before CNTMST was preloaded for every department (or the
      // DB was reset): download it now rather than offer an empty search.
      if (result.isEmpty && Get.isRegistered<UserMdmpiController>()) {
        await Get.find<UserMdmpiController>().fetchUserMdmpiFromDb();
        result = await _contactRepository.getContactDirectoryOptions();
      }
      directoryOptions.assignAll(result);
    } catch (e) {
      logDebug('ContactDirectoryController.loadDirectoryOptions error: $e');
    }
  }

  Future<void> addContact({
    required String initial,
    required String department,
    required String contactNumber,
  }) async {
    await _contactRepository.addContact(
      initial: initial,
      department: department,
      contactNumber: contactNumber,
    );
    await loadContacts();
  }

  Future<void> deleteContact(ContactModel contact) async {
    final contactId = contact.id;
    if (contactId == null) {
      logDebug('ContactDirectoryController.deleteContact skipped: null id');
      return;
    }

    await _contactRepository.deleteContact(contactId);
    await loadContacts();
  }
}
