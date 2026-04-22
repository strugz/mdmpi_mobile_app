import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/models/cnstmst_model.dart';
import 'package:mdmpi_mobile_app/data/models/contact_model.dart';

class ContactRepository extends GetxController {
  static ContactRepository get instance => Get.find();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<ContactModel>> getContacts() async {
    final dao = await _databaseHelper.contactDao;
    return dao.getAll();
  }

  Future<List<CNTMSTModel>> getContactDirectoryOptions() async {
    return _databaseHelper.getCntmstRequesters();
  }

  Future<int> addContact({
    required String initial,
    required String department,
    required String contactNumber,
  }) async {
    final dao = await _databaseHelper.contactDao;
    final contact = ContactModel(
      initial: initial.trim(),
      department: department.trim(),
      contactNumber: contactNumber.trim(),
      createdAt: DateTime.now(),
    );

    return dao.insert(contact);
  }

  Future<int> deleteContact(int id) async {
    final dao = await _databaseHelper.contactDao;
    return dao.deleteById(id);
  }
}
