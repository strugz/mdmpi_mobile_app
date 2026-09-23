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
      RecipientContactDetails TEXT,
      RecipientName TEXT,
      TripTicketNumber TEXT,
      ItemCategoryID TEXT,
      FormCategoryID TEXT
    )
  ''');

  // Table: a_tblRequestDocumentReference
  await db.execute('''
    CREATE TABLE a_tblRequestDocumentReference (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      RequestID INTEGER,
      Reference TEXT,
      RequestCreatedAt TEXT,
      UNIQUE(RequestID, Reference),
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
      ItemCategoryIDs TEXT,
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
      TripTicketNumber TEXT,
      Driver TEXT,
      Helper TEXT,
      DispatchedAt TEXT,
      DropOffAt TEXT,
      ProvincialPickUpBy TEXT DEFAULT '',
      ProvincialPickUpAt TEXT DEFAULT '',
      ProvincialInTransitAt TEXT DEFAULT '',
      ProvincialInTransitLocation TEXT DEFAULT '',
      ProvincialDeliveredEndAt TEXT DEFAULT '',
      ProvincialDeliveredLocation TEXT DEFAULT '',
      ProvincialReceiverName TEXT DEFAULT '',
      Status TEXT,
      Remarks TEXT,
      CreatedBy TEXT,
      CreatedAt TEXT,
      UpdatedAt TEXT,
      FormCategoryID TEXT,
      ShippingMethod TEXT
    )
  ''');

  // Table: a_tblRequestPullOutReturnPickUp
  await db.execute('''
    CREATE TABLE a_tblRequestPullOutReturnPickUp (
      RequestID INTEGER PRIMARY KEY,
      ClientID TEXT,
      ClientContactPerson TEXT,
      FormCategoryID TEXT,
      ItemCategoryID TEXT,
      IRRFNumber TEXT,
      IRRFDate TEXT,
      ReasonForReturn TEXT,
      ReleasedBy TEXT,
      PullOutDate TEXT,
      PullOutDateStartAt TEXT,
      PullOutDateEndAt TEXT,
      RequestStatus TEXT,
      TripTicketNumber TEXT,
      Driver TEXT,
      Helper TEXT,
      MobileID INTEGER,
      MobileName TEXT,
      CreatedAt TEXT,
      UpdatedAt TEXT,
      CreatedBy TEXT,
      RequestedBy TEXT
    )
  ''');

  // Table: a_tblLocationAlternative
  // Stores alternative delivery locations when user corrects wrong address
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblLocationAlternative (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      RequestID INTEGER NOT NULL,
      Latitude REAL NOT NULL,
      Longitude REAL NOT NULL,
      Address TEXT NOT NULL,
      CreatedAt TEXT NOT NULL,
      Notes TEXT,
      FOREIGN KEY (RequestID) REFERENCES a_tblRequest (RequestID) ON DELETE CASCADE
    )
  ''');

  // Table: a_tblClientContactPerson
  // Stores client contact person names for autocomplete functionality
  await db.execute('''
    CREATE TABLE a_tblClientContactPerson (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      usageCount INTEGER DEFAULT 1,
      lastUsedAt TEXT NOT NULL
    )
  ''');

  // Table: a_tblRequestBackload
  // Stores back-load entries per request (multiple entries allowed).
  await db.execute('''
    CREATE TABLE a_tblRequestBackload (
      BackLoadID TEXT PRIMARY KEY,
      RequestID TEXT NOT NULL,
      Remarks TEXT,
      DeliveryDate TEXT,
      DateReported TEXT
    )
  ''');
  // Table: contacts
  await db.execute('''
    CREATE TABLE IF NOT EXISTS contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      initial TEXT NOT NULL,
      department TEXT NOT NULL,
      contact_number TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  // Proof-upload tables (captured signatures and the queued-image outbox).
  await ensureProofUploadTables(db);

  // Collection tables (bucket cache, engagement history, pending upload queue).
  await ensureCollectionTables(db);
}

/// Creates the proof-upload tables idempotently.
///
/// These hold work the device has captured but not yet uploaded: receiver
/// signatures awaiting retry, and the queued proof-image outbox. They are
/// created with `CREATE TABLE IF NOT EXISTS` and are deliberately EXCLUDED
/// from the destructive `_recreateAllTables` rebuild in [DatabaseHelper], so a
/// routine app upgrade cannot discard a driver's un-uploaded signatures and
/// photos. Nothing else holds that image data once the picker temp file is
/// gone, so a wipe here is unrecoverable.
///
/// Same reasoning as [ensureCollectionTables]; keep the two in step.
Future<void> ensureProofUploadTables(Database db) async {
  // Table: a_tblRequestReceiverSignature
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblRequestReceiverSignature (
      RequestID INTEGER UNIQUE,
      RequestReceiverSignature TEXT,
      ApiStatus TEXT DEFAULT 'Failed',
      FOREIGN KEY (RequestID) REFERENCES a_tblRequest (RequestID) ON DELETE CASCADE
    )
  ''');

  // Table: a_tblRequestImageOutbox
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblRequestImageOutbox (
      RequestID TEXT NOT NULL,
      ImageType TEXT NOT NULL,
      ImageLookupKey TEXT NOT NULL,
      RequestImage TEXT,
      ApiStatus TEXT DEFAULT 'Pending',
      CapturedAt TEXT,
      UNIQUE(RequestID, ImageType, ImageLookupKey)
    )
  ''');
}

/// Creates the Collection tables idempotently.
///
/// These hold the collector's offline field work (downloaded bucket, recorded
/// engagements, and the pending upload queue). They are created with
/// `CREATE TABLE IF NOT EXISTS` and are deliberately EXCLUDED from the
/// destructive `_recreateAllTables` rebuild in [DatabaseHelper], so un-uploaded
/// work survives app upgrades. Columns match `CollectionDao` and
/// `CollectionPendingDao`.
Future<void> ensureCollectionTables(Database db) async {
  // Table: a_tblCollectionItems (downloaded bucket + in-progress edits)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionItems (
      id TEXT PRIMARY KEY,
      clientId TEXT,
      clientName TEXT,
      clientAddress TEXT,
      documentReferences TEXT,
      bankName TEXT,
      toBeCollected REAL DEFAULT 0,
      totalCollected REAL DEFAULT 0,
      remarks TEXT,
      documentDate TEXT,
      bpCode TEXT,
      poNumber TEXT,
      postingDate TEXT,
      dueDate TEXT,
      status TEXT,
      lastOutcome TEXT,
      assignedAt TEXT,
      collectorName TEXT,
      createdAt TEXT,
      updatedAt TEXT
    )
  ''');
  // The customer's P.O. number (SAP "BP Ref. No."), added 2026-09-22. Devices
  // that created the table before then get it by ALTER; see
  // docs/application/COLLECTION_ADR_001_PO_NUMBER.md.
  await _addColumnIfMissing(db, 'a_tblCollectionItems', 'poNumber', 'TEXT');

  // Table: a_tblCollectionHistory (engagement history per item)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      itemId TEXT NOT NULL,
      date TEXT,
      collectorName TEXT,
      status TEXT,
      remarks TEXT,
      totalCollected REAL DEFAULT 0,
      bankName TEXT,
      checkNumber TEXT,
      checkDate TEXT,
      purposeOfVisit TEXT,
      FOREIGN KEY (itemId) REFERENCES a_tblCollectionItems (id) ON DELETE CASCADE
    )
  ''');

  // Table: a_tblCollectionPending (offline change queue for end-of-day upload)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionPending (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      itemId TEXT,
      createdAt TEXT NOT NULL,
      retryCount INTEGER DEFAULT 0,
      lastRetryAt TEXT
    )
  ''');

  // Table: a_tblCollectionBank (the company bank list, cached)
  //
  // Reference data from the server, but cached like field work rather than
  // like a lookup: a collector standing in front of a customer with a check
  // in their hand has no guarantee of signal, and an empty bank picker would
  // send them back to typing the name by hand.
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionBank (
      mid TEXT PRIMARY KEY,
      bankcode TEXT,
      bank TEXT
    )
  ''');

  // --- Stage C2: concepts that previously lived only in memory -------------

  // Table: a_tblCollectionActivity (Deposit / CWT Pick-up / Reconciliation)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionActivity (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      clientId TEXT,
      clientName TEXT,
      date TEXT,
      amount REAL DEFAULT 0,
      bankName TEXT,
      checkNumber TEXT,
      remarks TEXT,
      documentIds TEXT,
      collectorName TEXT,
      localRef TEXT
    )
  ''');

  // Table: a_tblCollectionAdvance (Advanced Payments awaiting an invoice)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionAdvance (
      externalRef TEXT PRIMARY KEY,
      clientId TEXT,
      clientName TEXT,
      amount REAL DEFAULT 0,
      date TEXT,
      remarks TEXT,
      collectorName TEXT,
      assignedDocumentId TEXT
    )
  ''');

  // Table: a_tblCollectionAccountHistory (Deferred Engagement reasons per account)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionAccountHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clientId TEXT NOT NULL,
      date TEXT,
      reason TEXT,
      remarks TEXT,
      collectorName TEXT
    )
  ''');

  // Table: a_tblCollectionTarget (monthly target, keyed yyyy-MM)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionTarget (
      yearMonth TEXT PRIMARY KEY,
      amount REAL DEFAULT 0
    )
  ''');

  // Table: a_tblCollectionEngagement (the collector's own field-work archive)
  //
  // Every other collection table is a cache of what the server currently says,
  // and is truncated and rewritten on each download: a_tblCollectionHistory by
  // deleteAllCollectionItems, the rest by _replaceAccountLevelData. That is
  // correct for a cache and fatal for a record of work — an engagement was
  // erased minutes after it was recorded, because uploading triggers a refresh,
  // and a settled invoice takes its history with it when the server stops
  // returning it. This table is the one that is never rewritten. It is the
  // collector's own account of their days, and it outlives the invoice.
  //
  // No foreign key to a_tblCollectionItems: sqflite leaves PRAGMA foreign_keys
  // off, so the constraint would be inert anyway, and outliving that row is the
  // entire point.
  //
  // localRef is 'kind|subjectId|engagedAt' (CollectionEngagementRecord
  // .buildLocalRef). Deriving the key from the engagement rather than using an
  // AUTOINCREMENT id is what makes a re-save idempotent: a retry, a re-sync, a
  // double tap or a second run of the backfill updates one row instead of
  // leaving two. The two sibling tables that do use AUTOINCREMENT are exactly
  // the two that duplicate on re-save.
  //
  // engagedOn is the local calendar day, stored rather than derived, so the day
  // a row belongs to is decided once by the device that recorded it. Deriving
  // it on read is how engagements before 08:00 ended up on the previous day's
  // cell: a server 'Z' stamp parses to a UTC DateTime, whose y/m/d fields are
  // still UTC.
  await db.execute('''
    CREATE TABLE IF NOT EXISTS a_tblCollectionEngagement (
      localRef       TEXT PRIMARY KEY,
      collectorCode  TEXT NOT NULL,
      collectorName  TEXT NOT NULL DEFAULT '',
      kind           TEXT NOT NULL,
      itemId         TEXT NOT NULL DEFAULT '',
      clientId       TEXT NOT NULL DEFAULT '',
      clientName     TEXT NOT NULL DEFAULT '',
      engagedAt      TEXT NOT NULL,
      engagedOn      TEXT NOT NULL,
      status         TEXT NOT NULL DEFAULT '',
      remarks        TEXT NOT NULL DEFAULT '',
      amount         REAL NOT NULL DEFAULT 0,
      bankName       TEXT,
      checkNumber    TEXT,
      checkDate      TEXT,
      purposeOfVisit TEXT,
      documentIds    TEXT NOT NULL DEFAULT '',
      createdAt      TEXT NOT NULL,
      source         TEXT NOT NULL DEFAULT 'LOCAL'
    )
  ''');
  // source says where the row came from, and it is what makes the "never
  // rewritten" rule survivable.
  //
  // 'LOCAL' is an engagement this device recorded. Nothing may rewrite it;
  // that is the whole point of the table.
  //
  // 'SERVER' is a copy of the collector's history as the server told it,
  // written by the backfill. Those rows are a projection, not a record, and
  // they used to be indistinguishable from real work and just as permanent —
  // so when collection data was deleted on the server, the archive went on
  // reporting it and "Collected this Month" stayed at a figure nothing could
  // explain. They are now refreshed with each download instead.
  await _addColumnIfMissing(
      db, 'a_tblCollectionEngagement', 'source', "TEXT NOT NULL DEFAULT 'LOCAL'");
  // IF NOT EXISTS on the indexes too: this whole function re-runs on every
  // database open, not just on create and upgrade (see DatabaseHelper._initDB).
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_collection_engagement_day
      ON a_tblCollectionEngagement (collectorCode, engagedOn)
  ''');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_collection_engagement_client
      ON a_tblCollectionEngagement (collectorCode, clientId)
  ''');
}

/// Every table this app made, newest schema included, in name order.
///
/// Asking SQLite is what keeps the Local Storage Data Viewer honest: its table
/// list used to be typed out by hand and had fallen three tables behind, so
/// the tool for seeing what is on the device could not see the engagement
/// archive — the one table somebody debugging stale data most needs to read.
///
/// `sqlite_%` is SQLite's own bookkeeping (`sqlite_sequence` and friends) and
/// is not ours to show or clear.
Future<List<String>> listUserTables(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  return rows.map((r) => (r['name'] ?? '').toString()).toList();
}

/// Adds a column to an existing collection table, once.
///
/// The collection tables are never dropped and rebuilt — that is what keeps
/// un-uploaded field work alive across upgrades — so a new column has to
/// arrive by ALTER. Safe to call on every open: it asks first.
Future<void> _addColumnIfMissing(
  Database db,
  String table,
  String column,
  String definition,
) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  if (info.any((row) => (row['name'] as String?) == column)) return;
  await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
}
