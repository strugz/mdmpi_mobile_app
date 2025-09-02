import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../base/utils/exceptions/firebase_exceptions.dart';
import '../../../base/utils/exceptions/format_exceptions.dart';
import '../../models/role_model.dart';

class RoleRepository {
  static RoleRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<RoleModel>> getRoles() async {
    try {
      final documentSnapshot = await _db.collection("Roles").get();
      final roles = documentSnapshot.docs
          .map((document) => RoleModel.fromSnapshot(document))
          .toList();
      return roles;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}
