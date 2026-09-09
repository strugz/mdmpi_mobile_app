/// Central home for the server-assigned form category IDs
/// (rows of a_tblcategory with type 'Form').
///
/// These are pinned by data migrations on the server (see the MDMPI.App
/// migration files) and must stay in lockstep with the database — if a
/// migration ever pins a different id, update it here before building.
class FormCategoryIds {
  FormCategoryIds._();

  static const String pullOutReturn = '4';
  static const String standardDelivery = '6';
  static const String hotlineDirect = '8';
  static const String stockReceive = '9';

  /// 'Air / Sea / Land HD' — pinned by
  /// MDMPI.App/migration_20260909_add_air_sea_hd_category.sql.
  static const String airSeaHd = '21';
}

/// Which slice of the shared a_tblRequestAirSea data an Air/Sea controller
/// shows. Base and HD tabs share one table/endpoint, split by FormCategoryID —
/// mirroring how Standard Delivery ('6') and Hotline Direct ('8') split
/// a_tblRequest.
enum AirSeaCategoryScope {
  /// The base 'Air / Sea / Land' tab. Legacy rows have no FormCategoryID at
  /// all, so NULL/empty belongs here.
  base,

  /// The urgent 'Air / Sea / Land HD' tab.
  hotlineDirect;

  bool matches(String? formCategoryID) {
    final id = formCategoryID?.trim() ?? '';
    switch (this) {
      case AirSeaCategoryScope.base:
        return id.isEmpty || id != FormCategoryIds.airSeaHd;
      case AirSeaCategoryScope.hotlineDirect:
        return id == FormCategoryIds.airSeaHd;
    }
  }
}
