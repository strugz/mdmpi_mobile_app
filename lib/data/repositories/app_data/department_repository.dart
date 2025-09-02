import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../base/utils/exceptions/firebase_exceptions.dart';
import '../../../base/utils/exceptions/format_exceptions.dart';
import '../../models/department_model.dart';

class DepartmentRepository {
  static DepartmentRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DepartmentModel>> getDepartments() async {
    try {
      final documentSnapshot = await _db.collection("Departments").get();
      final departments = documentSnapshot.docs
          .map((document) => DepartmentModel.fromSnapshot(document))
          .toList();
      return departments;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}
