import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/models/cnstmst_model.dart';
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
      final result = await _contactRepository.getContactDirectoryOptions();
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
}
