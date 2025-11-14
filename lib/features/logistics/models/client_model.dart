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
    // Helper to retrieve the first non-null value from a list of possible keys
    String _firstPresent(Map<String, dynamic> m, List<String> keys, {String fallback = ''}) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return fallback;
    }

    return ClientModel(
      id: _firstPresent(json, ['ACCMID', 'accmid', 'ClientID', 'clientID']),
      code: _firstPresent(json, ['ACCMSC', 'accmsc', 'Code', 'code']),
      name: _firstPresent(json, ['ACCMNM', 'accmnm', 'Name', 'name']),
      address: _firstPresent(json, ['ACCMAD', 'accmad', 'Address', 'address']),
      contact: _firstPresent(json, ['ACCMPH', 'accmph', 'Phone', 'phone', 'Contact', 'contact']),
      emailAddress: _firstPresent(json, ['ACCMEM', 'accmem', 'Email', 'email', 'EmailAddress', 'emailAddress']),
    );
  }
}
