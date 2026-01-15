// filepath: lib/data/models/item_category_model.dart
/// Item Category reference model used for dropdowns and validation.
class ItemCategoryModel {
  final String id;
  final String name;

  const ItemCategoryModel({required this.id, required this.name});

  factory ItemCategoryModel.empty() => const ItemCategoryModel(id: '', name: '');

  ItemCategoryModel copyWith({String? id, String? name}) => ItemCategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() => {
        'ItemCategoryID': id,
        'ItemCategoryName': name,
      };

  static String _firstPresent(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k].toString();
    }
    return '';
  }

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) {
    return ItemCategoryModel(
      id: _firstPresent(json, const ['ItemCategoryID', 'itemCategoryID', 'ItemCategoryId', 'itemCategoryId', 'ID', 'Id', 'id']),
      name: _firstPresent(json, const ['ItemCategoryName', 'ItemCategory', 'itemCategory', 'Name', 'name', 'CategoryName', 'category', 'Category']),
    );
  }
}
