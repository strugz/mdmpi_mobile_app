import 'package:sqflite/sqflite.dart';

/// NOTE: This project intentionally keeps the database column names for the
/// `a_tblRequest` table prefixed with `Request*` (for example: RequestID,
/// RequestClientID, RequestShippingMethod, ...). The API/DTO layer uses
/// model-style keys (ID, ClientID, ShippingMethod, ...). Mapping between the
/// two layers is performed in these places:
///
/// - API JSON -> `StandardDeliveryDto`  : `lib/features/logistics/dtos/standard_delivery_dto.dart`
/// - DTO -> `StandardDeliveryModel`     : `lib/features/logistics/mappers/standard_delivery_mapper.dart`
/// - DB (Request-prefixed columns) -> `StandardDeliveryModel` :
///     `StandardDeliveryModel.fromDbJson` in
///     `lib/features/logistics/models/standard_delivery_model.dart`
///
/// Keeping the Request-prefixed columns is a conservative choice that avoids
/// an immediate DB migration while preserving a clear mapping layer between
/// API DTOs and DB rows.

/// Central place for creating database schema. Keeps SQL out of DatabaseHelper.
Future<void> createAllTables(Database db) async {
  // Table: a_tblRequest
  await db.execute('''
    CREATE TABLE a_tblRequest (
      RequestID INTEGER PRIMARY KEY,
      RequestClientID TEXT,
      RequestShippingMethod TEXT,
      RequestDeliveryTerms TEXT,
      RequestDeliveryDate TEXT,
      RequestPreference TEXT,
      RequestStatus TEXT,
      RequestBy TEXT,
      RequestCreatedBy TEXT,
      RequestItemPreparedBy TEXT,
      RequestDeliveredBy TEXT,
      RequestCreatedAt TEXT,
      RequestItemPreparedAt TEXT,
      RequestItemPreparedEndAt TEXT,
      RequestDeliveredAt TEXT,
      RequestDeliveredEndAt TEXT,
      LocationStartedAt TEXT,
      LocationEndAt TEXT,
      MobileID INTEGER DEFAULT 0,
      RequestDriverHelper TEXT,
      Receiver TEXT,
      TripTicketNumber TEXT
    )
  ''');

  // Table: a_tblRequestDocumentReference
  await db.execute('''
    CREATE TABLE a_tblRequestDocumentReference (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      RequestID INTEGER,
      Reference TEXT,
      RequestCreatedAt TEXT,
      FOREIGN KEY (RequestID) REFERENCES a_tblRequest (RequestID) ON DELETE CASCADE
    )
  ''');

  // Table: a_tblRequestReceiverSignature
  await db.execute('''
    CREATE TABLE a_tblRequestReceiverSignature (
      RequestID INTEGER UNIQUE,
      RequestReceiverSignature TEXT,
      FOREIGN KEY (RequestID) REFERENCES a_tblRequest (RequestID) ON DELETE CASCADE
    )
  ''');

  // Table: a_tblRequestImage
  await db.execute('''
    CREATE TABLE a_tblRequestImage (
      RequestID INTEGER UNIQUE,
      RequestImage TEXT,
      FOREIGN KEY (RequestID) REFERENCES a_tblRequest (RequestID) ON DELETE CASCADE
    )
  ''');

  // Table: a_tblRequestRemarks
  await db.execute('''
    CREATE TABLE  a_tblRequestRemarks (
      RequestID TEXT PRIMARY KEY,
      Remarks TEXT,
      Date TEXT
    )
  ''');

  // Table: ACCMST_
  await db.execute('''
    CREATE TABLE ACCMST_ (
      ACCMID TEXT PRIMARY KEY,
      ACCMSC TEXT,
      ACCMNM TEXT,
      ACCMBC TEXT,
      ACCMAD TEXT,
      ACCMPH TEXT,
      ACCMEM TEXT,
      ACCMWS TEXT
    )
  ''');

  // Table: a_tblMobile
  await db.execute('''
    CREATE TABLE a_tblMobile (
      MobileID INTEGER PRIMARY KEY,
      MobileName TEXT
    )
  ''');

  // Table: Users
  await db.execute('''
    CREATE TABLE Users (
      Initial TEXT PRIMARY KEY,
      FirstName TEXT,
      LastName TEXT,
      Department TEXT,
      Email TEXT,
      Password TEXT,
      Role TEXT,
      PhoneNumber TEXT,
      Username TEXT,
      ProfilePicture TEXT,
      Status BOOLEAN
    )
  ''');

  // Table: CNTMST
  await db.execute('''
    CREATE TABLE CNTMST (
      CNTMID TEXT PRIMARY KEY,
      CNTMLN TEXT,
      CNTMMN TEXT,
      CNTMFN TEXT,
      CNTMNN TEXT,
      CNTNUM TEXT,
      CNTDPT TEXT,
      CNTMCN TEXT,
      CNTMSX TEXT,
      CNTMPF TEXT,
      CNTMSF TEXT,
      CNTMBD TEXT,
      CNTARE TEXT,
      CNTRTH TEXT,
      CNTLDR TEXT,
      CNTEPS TEXT,
      CNTSTS TEXT,
      CNTSEC TEXT,
      CNTTGP TEXT,
      CNTEGP TEXT,
      CNTMGP TEXT,
      CNTDHD TEXT,
      CNTFRM TEXT
    )
  ''');

  // Table: a_tblRequestPickUp
  await db.execute('''
    CREATE TABLE a_tblRequestPickUp (
      RequestID INTEGER PRIMARY KEY,
      ClientID TEXT,
      ItemCategoryID TEXT,
      ItemCategoryName TEXT,
      PreparedBy TEXT,
      ItemPreparedAt TEXT,
      ItemPreparedEndAt TEXT,
      DatePickUp TEXT,
      Remarks TEXT,
      Status TEXT,
      ReleasedBy TEXT,
      ReceivedBy TEXT,
      CreatedBy TEXT,
      CreatedAt TEXT,
      UpdatedAt TEXT
    )
  ''');

  // Table: a_tblItemCategory
  await db.execute('''
    CREATE TABLE a_tblItemCategory (
      ItemCategoryID TEXT PRIMARY KEY,
      ItemCategoryName TEXT
    )
  ''');

  // Table: a_tblFormCategory
  await db.execute('''
    CREATE TABLE a_tblFormCategory (
      FormCategoryID TEXT PRIMARY KEY,
      FormCategoryName TEXT
    )
  ''');

  // Table: a_tblRequestAirSea
  await db.execute('''
    CREATE TABLE a_tblRequestAirSea (
      RequestID INTEGER PRIMARY KEY,
      ClientID TEXT,
      ItemCategoryID TEXT,
      MobileID INTEGER,
      DatePickUp TEXT,
      ItemPreparedAt TEXT,
      ItemPreparedEndAt TEXT,
      PreparedBy TEXT,
      EndorsedTo TEXT,
      EndorsedAt TEXT,
      EndorsedBy TEXT,
      WaybillNumber TEXT,
      ReceivedAt TEXT,
      ReceivedBy TEXT,
      Status TEXT,
      Remarks TEXT,
      CreatedBy TEXT,
      CreatedAt TEXT,
      UpdatedAt TEXT
    )
  ''');
}
