class CNTMSTModel {
  final String cntmid; // Primary Key
  final String? cntmln;
  final String? cntmmn;
  final String? cntmfn;
  final String? cntmnn;
  final String? cntnum;
  final String? cntdpt;
  final String? cntmcn;
  final String? cntmsx;
  final String? cntmpf;
  final String? cntmsf;
  final String? cntmbd;
  final String? cntare;
  final String? cntrth;
  final String? cntldr;
  final String? cnteps;
  final String? cntsts;
  final String? cntsec;
  final String? cnttgp;
  final String? cntegp;
  final String? cntmgp;
  final String? cntdhd;
  final String? cntfrm;

  CNTMSTModel({
    required this.cntmid,
    this.cntmln,
    this.cntmmn,
    this.cntmfn,
    this.cntmnn,
    this.cntnum,
    this.cntdpt,
    this.cntmcn,
    this.cntmsx,
    this.cntmpf,
    this.cntmsf,
    this.cntmbd,
    this.cntare,
    this.cntrth,
    this.cntldr,
    this.cnteps,
    this.cntsts,
    this.cntsec,
    this.cnttgp,
    this.cntegp,
    this.cntmgp,
    this.cntdhd,
    this.cntfrm,
  });

  /// Converts a [CNTMSTModel] instance to a JSON Map.
  /// This is useful for inserting data into the SQLite database.
  Map<String, dynamic> toJson() {
    return {
      'CNTMID': cntmid,
      'CNTMLN': cntmln,
      'CNTMMN': cntmmn,
      'CNTMFN': cntmfn,
      'CNTMNN': cntmnn,
      'CNTNUM': cntnum,
      'CNTDPT': cntdpt,
      'CNTMCN': cntmcn,
      'CNTMSX': cntmsx,
      'CNTMPF': cntmpf,
      'CNTMSF': cntmsf,
      'CNTMBD': cntmbd,
      'CNTARE': cntare,
      'CNTRTH': cntrth,
      'CNTLDR': cntldr,
      'CNTEPS': cnteps,
      'CNTSTS': cntsts,
      'CNTSEC': cntsec,
      'CNTTGP': cnttgp,
      'CNTEGP': cntegp,
      'CNTMGP': cntmgp,
      'CNTDHD': cntdhd,
      'CNTFRM': cntfrm,
    };
  }

  /// Creates a [CNTMSTModel] instance from a JSON Map.
  /// This is useful when retrieving data from the SQLite database.
  factory CNTMSTModel.fromJson(Map<String, dynamic> json) {
    return CNTMSTModel(
      cntmid: json['CNTMID'] as String,
      cntmln: json['CNTMLN'] as String?,
      cntmmn: json['CNTMMN'] as String?,
      cntmfn: json['CNTMFN'] as String?,
      cntmnn: json['CNTMNN'] as String?,
      cntnum: json['CNTNUM'] as String?,
      cntdpt: json['CNTDPT'] as String?,
      cntmcn: json['CNTMCN'] as String?,
      cntmsx: json['CNTMSX'] as String?,
      cntmpf: json['CNTMPF'] as String?,
      cntmsf: json['CNTMSF'] as String?,
      cntmbd: json['CNTMBD'] as String?,
      cntare: json['CNTARE'] as String?,
      cntrth: json['CNTRTH'] as String?,
      cntldr: json['CNTLDR'] as String?,
      cnteps: json['CNTEPS'] as String?,
      cntsts: json['CNTSTS'] as String?,
      cntsec: json['CNTSEC'] as String?,
      cnttgp: json['CNTTGP'] as String?,
      cntegp: json['CNTEGP'] as String?,
      cntmgp: json['CNTMGP'] as String?,
      cntdhd: json['CNTDHD'] as String?,
      cntfrm: json['CNTFRM'] as String?,
    );
  }
}

