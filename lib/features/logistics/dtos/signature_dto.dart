class SignatureDto {
  final String? path;
  SignatureDto({this.path});
  factory SignatureDto.fromJson(Map<String, dynamic> json) => SignatureDto(path: json['Path']?.toString());
  Map<String, dynamic> toJson() => {'Path': path};
}

