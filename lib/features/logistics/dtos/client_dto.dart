class ClientDto {
  final String? clientID;
  final String? name;

  ClientDto({this.clientID, this.name});

  factory ClientDto.fromJson(Map<String, dynamic> json) {
    // helper to pull first available key
    String? first(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return null;
    }

    return ClientDto(
      clientID: first(json, ['ClientID', 'clientID', 'ACCMID', 'accmid']),
      name: first(json, ['Name', 'name', 'ACCMNM', 'accmnm']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ClientID': clientID,
        'Name': name,
      };
}
