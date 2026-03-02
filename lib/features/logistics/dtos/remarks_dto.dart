class RemarksDto {
  final String? remarks;
  RemarksDto({this.remarks});

  factory RemarksDto.fromJson(Map<String, dynamic> json) => RemarksDto(remarks: json['Remarks']?.toString());
  Map<String, dynamic> toJson() => {'Remarks': remarks};
}

