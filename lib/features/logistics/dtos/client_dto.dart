class ClientDto {
  final String? clientID;
  final String? name;

  ClientDto({this.clientID, this.name});

  factory ClientDto.fromJson(Map<String, dynamic> json) {
    // helper to pull first available key
    String? _first(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return null;
    }

    return ClientDto(
      clientID: _first(json, ['ClientID', 'clientID', 'ACCMID', 'accmid']),
      name: _first(json, ['Name', 'name', 'ACCMNM', 'accmnm']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ClientID': clientID,
        'Name': name,
      };
}
