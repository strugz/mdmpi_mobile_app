// filepath: lib/data/models/form_category_model.dart
/// Form Category reference model used for dropdowns and validation.
class FormCategoryModel {
  final String id;
  final String name;

  const FormCategoryModel({required this.id, required this.name});

  factory FormCategoryModel.empty() => const FormCategoryModel(id: '', name: '');

  FormCategoryModel copyWith({String? id, String? name}) => FormCategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() => {
        'FormCategoryID': id,
        'FormCategoryName': name,
      };

  static String _firstPresent(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k].toString();
    }
    return '';
  }

  factory FormCategoryModel.fromJson(Map<String, dynamic> json) {
    return FormCategoryModel(
      id: _firstPresent(json, const ['FormCategoryID', 'formCategoryID', 'FormCategoryId', 'formCategoryId', 'ID', 'Id', 'id']),
      name: _firstPresent(json, const ['FormCategoryName', 'FormCategory', 'formCategory', 'Name', 'name', 'CategoryName', 'category', 'Category']),
    );
  }
}
