import 'package:cloud_firestore/cloud_firestore.dart';

class PartsModel {
  String itemId;
  String itemCategory;
  String itemName;
  String itemDescription;
  bool isFeatured;

  PartsModel({
    required this.itemId,
    required this.itemCategory,
    required this.itemName,
    required this.itemDescription,
    required this.isFeatured,
  });

  /// Empty Helper Function
  static PartsModel empty() =>
      PartsModel(itemId: '', itemCategory: '', itemName: '', itemDescription: '', isFeatured: false);

  /// Convert model to Json structure so that you can store data in Firebase
  Map<String, dynamic> toJson() {
    return {
      'Name': itemName,
      'Category': itemCategory,
      'Description': itemDescription,
      'IsFeatured': isFeatured,
    };
  }

  /// Map Json oriented document snapshot from Firebase to UserModel
  factory PartsModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;

      //  Map JSON Record to the Model
      return PartsModel(
        itemId: document.id,
        itemCategory: data['Category'] ?? '',
        itemName: data['Name'] ?? '',
        itemDescription: data['Description'] ?? '',
        isFeatured: data['IsFeatured'] ?? false,
      );
    } else {
      return PartsModel.empty();
    }
  }
}
