class ClientModel {
  String id;
  String code;
  String name;
  String address;
  String contact;
  String emailAddress;

  ClientModel(
      {required this.id,
       this.code = "",
      required this.name,
      required this.address,
      required this.contact,
      required this.emailAddress});

  /// Empty Model
  static ClientModel empty() => ClientModel(
      id: '',
      code: '',
      name: 'Client',
      address: 'Address',
      contact: 'Phone Number',
      emailAddress: '');

  Map<String, dynamic> toJson() {
    return {
      'ACCMID': id,
      'ACCMSC': code,
      'ACCMNM': name,
      'ACCMAD': address,
      'ACCMPH': contact,
      'ACCMEM': emailAddress
    };
  }
  Map<String, dynamic> toJsonInsert() {
    return {
      'ACCMID': id,
      'ACCMSC': code,
      'ACCMNM': name,
      'ACCMAD': address,
      'ACCMPH': contact,
      'ACCMEM': emailAddress
    };
  }


  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
        id: json['ACCMID'],
        code: json['ACCMSC'],
        name: json['ACCMNM'],
        address: json['ACCMAD'],
        contact: json['ACCMPH'],
        emailAddress: json['ACCMEM']);
  }
}
