class ImageDto {
  final String? path;
  ImageDto({this.path});
  factory ImageDto.fromJson(Map<String, dynamic> json) => ImageDto(path: json['Path']?.toString());
  Map<String, dynamic> toJson() => {'Path': path};
}

