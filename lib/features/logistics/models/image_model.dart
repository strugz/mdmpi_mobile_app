class ImageModel {
  String id;
  String itemId;
  String image;

  ImageModel({required this.id, required this.itemId, required this.image});

  /// Empty Helper Function
  static ImageModel empty() => ImageModel(id: '', itemId: '', image: '');

  Map<String, dynamic> toJson() {
    return {'ID': id, 'ItemID': itemId, 'Image': image};
  }

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
        id: json['ID'], itemId: json['ItemID'], image: json['Image']);
  }
}
