import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../features/logistics/models/standard_delivery_model.dart';
import '../../features/logistics/models/cancel_remarks_model.dart';
import '../../features/logistics/models/client_model.dart';
import '../../data/models/mobile_model.dart';
import '../../data/models/cntmst_model.dart';
import '../../features/personalization/models/user_model.dart';

// DAO imports
import 'dao/standard_delivery/standard_delivery_dao.dart';
import 'dao/pick_up/pick_up_dao.dart';
import 'dao/air_sea/air_sea_dao.dart';
import 'dao/pull_out/pull_out_dao.dart';
import 'dao/common/document_reference_dao.dart';
import 'dao/common/signature_dao.dart';
import 'dao/common/image_outbox_dao.dart';
import 'dao/common/backload_dao.dart';
import 'dao/common/remarks_dao.dart';
import 'dao/common/client_dao.dart';
import 'dao/common/mobile_dao.dart';
import 'dao/common/user_dao.dart';
import 'dao/common/cntmst_dao.dart';
import 'dao/common/item_category_dao.dart';
import 'dao/common/form_category_dao.dart';
import 'dao/common/client_contact_person_dao.dart';
import 'dao/common/contact_dao.dart';
import 'db_schema.dart';

/// Lightweight DatabaseHelper singleton that initializes the database,
/// provides cached DAO instances and forwards commonly used operations.
class DatabaseHelper {
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  Database? _database;

  // Cached DAO instances
  RequestDao? _requestDao;
  SignatureDao? _signatureDao;
  ImageOutboxDao? _imageOutboxDao;
  PickUpDao? _pickUpDao;
  AirSeaDao? _airSeaDao;
  PullOutDao? _pullOutDao;
  DocumentReferenceDao? _documentReferenceDao;
  BackLoadDao? _backLoadDao;
  RemarksDao? _remarksDao;
  ClientDao? _clientDao;
  MobileDao? _mobileDao;
  UserDao? _userDao;
  CntmstDao? _cntmstDao;
  ItemCategoryDao? _itemCategoryDao;
  FormCategoryDao? _formCategoryDao;
  ClientContactPersonDao? _clientContactPersonDao;
  ContactDao? _contactDao;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 18,
      onCreate: (db, version) async {
        await createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Keep legacy behavior for cache-backed tables while preserving the
        // user-entered `contacts` table across version bumps.
        await _upgradeSchema(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Contacts are user-entered local data. Always ensure the table exists via
    // non-destructive migration logic.
    await _ensureContactsTable(db);

    // Version 12 consolidated the cache-backed schema in db_schema.dart and
    // relies on a destructive rebuild for those tables.
    if (oldVersion < 12) {
      await _recreateAllTables(db);
    } else if (oldVersion < newVersion) {
      // Maintain existing cache-table rebuild behavior for future upgrades,
      // but explicitly keep contacts (local user data) out of the destructive
      // path by excluding it in _recreateAllTables.
      await _recreateAllTables(db);
    }

    // Ensure ApiStatus column exists on the signature table for older DBs.
    // This is safe and idempotent: on fresh installs the canonical schema
    // already includes the column; on upgrade we ALTER only if missing.
    await _addColumnIfNotExists(db, 'a_tblRequestReceiverSignature',
        'ApiStatus', "TEXT DEFAULT 'Pending'");
    await _ensureImageOutboxTable(db);
  }

  /// Drop cache-backed tables and recreate from the canonical schema.
  /// The `contacts` table is intentionally excluded to preserve user-entered
  /// data across app upgrades.
  Future<void> _recreateAllTables(Database db) async {
    const tables = [
      'a_tblRequest',
      'a_tblRequestDocumentReference',
      'a_tblRequestReceiverSignature',
      'a_tblRequestImage',
      'a_tblRequestImageOutbox',
      'a_tblRequestRemarks',
      'ACCMST_',
      'a_tblMobile',
      'Users',
      'CNTMST',
      'a_tblRequestPickUp',
      'a_tblItemCategory',
      'a_tblFormCategory',
      'a_tblRequestAirSea',
      'a_tblRequestPullOutReturnPickUp',
      'a_tblLocationAlternative',
      'a_tblClientContactPerson',
      'a_tblRequestBackload',
    ];
    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    await createAllTables(db);
  }

  Future<void> _ensureContactsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        initial TEXT NOT NULL,
        department TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureImageOutboxTable(Database db) async {
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

  /// Adds a column to a table if it does not already exist. This is idempotent
  /// and safe to call during upgrades to avoid destructive migrations.
  Future<void> _addColumnIfNotExists(
      Database db, String table, String columnName, String definition) async {
    try {
      final List<Map<String, Object?>> info =
          await db.rawQuery('PRAGMA table_info($table)');
      final exists = info.any((row) => (row['name'] as String?) == columnName);
      if (!exists) {
        await db
            .execute('ALTER TABLE $table ADD COLUMN $columnName $definition');
      }
    } catch (e) {
      // Swallow errors to avoid blocking upgrades; callers should log if needed.
    }
  }

  // --- DAO getters ---
  Future<RequestDao> get requestDao async {
    if (_requestDao != null) return _requestDao!;
    final db = await database;
    _requestDao = RequestDao(db);
    return _requestDao!;
  }

  Future<SignatureDao> get signatureDao async {
    if (_signatureDao != null) return _signatureDao!;
    final db = await database;
    _signatureDao = SignatureDao(db);
    return _signatureDao!;
  }

  Future<ImageOutboxDao> get imageOutboxDao async {
    if (_imageOutboxDao != null) return _imageOutboxDao!;
    final db = await database;
    _imageOutboxDao = ImageOutboxDao(db);
    return _imageOutboxDao!;
  }

  Future<DocumentReferenceDao> get documentReferenceDao async {
    if (_documentReferenceDao != null) return _documentReferenceDao!;
    final db = await database;
    _documentReferenceDao = DocumentReferenceDao(db);
    return _documentReferenceDao!;
  }

  Future<BackLoadDao> get backLoadDao async {
    if (_backLoadDao != null) return _backLoadDao!;
    final db = await database;
    _backLoadDao = BackLoadDao(db);
    return _backLoadDao!;
  }

  Future<RemarksDao> get remarksDao async {
    if (_remarksDao != null) return _remarksDao!;
    final db = await database;
    _remarksDao = RemarksDao(db);
    return _remarksDao!;
  }

  Future<ClientDao> get clientDao async {
    if (_clientDao != null) return _clientDao!;
    final db = await database;
    _clientDao = ClientDao(db);
    return _clientDao!;
  }

  Future<MobileDao> get mobileDao async {
    if (_mobileDao != null) return _mobileDao!;
    final db = await database;
    _mobileDao = MobileDao(db);
    return _mobileDao!;
  }

  Future<UserDao> get userDao async {
    if (_userDao != null) return _userDao!;
    final db = await database;
    _userDao = UserDao(db);
    return _userDao!;
  }

  Future<CntmstDao> get cntmstDao async {
    if (_cntmstDao != null) return _cntmstDao!;
    final db = await database;
    _cntmstDao = CntmstDao(db);
    return _cntmstDao!;
  }

  Future<PickUpDao> get pickUpDao async {
    if (_pickUpDao != null) return _pickUpDao!;
    final db = await database;
    _pickUpDao = PickUpDao(db);
    return _pickUpDao!;
  }

  Future<AirSeaDao> get airSeaDao async {
    if (_airSeaDao != null) return _airSeaDao!;
    final db = await database;
    _airSeaDao = AirSeaDao(db);
    return _airSeaDao!;
  }

  Future<PullOutDao> get pullOutDao async {
    if (_pullOutDao != null) return _pullOutDao!;
    final db = await database;
    _pullOutDao = PullOutDao(db);
    return _pullOutDao!;
  }

  Future<ItemCategoryDao> get itemCategoryDao async {
    if (_itemCategoryDao != null) return _itemCategoryDao!;
    final db = await database;
    _itemCategoryDao = ItemCategoryDao(db);
    return _itemCategoryDao!;
  }

  Future<FormCategoryDao> get formCategoryDao async {
    if (_formCategoryDao != null) return _formCategoryDao!;
    final db = await database;
    _formCategoryDao = FormCategoryDao(db);
    return _formCategoryDao!;
  }

  Future<ClientContactPersonDao> get clientContactPersonDao async {
    if (_clientContactPersonDao != null) return _clientContactPersonDao!;
    final db = await database;
    _clientContactPersonDao = ClientContactPersonDao(db);
    return _clientContactPersonDao!;
  }

  Future<ContactDao> get contactDao async {
    if (_contactDao != null) return _contactDao!;
    final db = await database;
    _contactDao = ContactDao(db);
    return _contactDao!;
  }

  Future<List<String>> getContactPhoneNumbers() async {
    final dao = await contactDao;
    return await dao.getAllPhoneNumbers();
  }

  // --- Request operations (delegated to RequestDao) ---
  Future<List<StandardDeliveryModel>> getRequests() async {
    final dao = await requestDao;
    return await dao.getRequests();
  }

  Future<int> insertRequest(StandardDeliveryModel requestModel) async {
    final dao = await requestDao;
    return await dao.insertRequest(requestModel);
  }

  Future<void> insertRequests(List<StandardDeliveryModel> requestModels) async {
    final dao = await requestDao;
    return await dao.insertRequests(requestModels);
  }

  Future<void> updateRequest(
      {required StandardDeliveryModel requestModel}) async {
    final dao = await requestDao;
    return await dao.updateRequest(requestModel: requestModel);
  }

  Future<int> cancelRequestWithRemarks({
    required String requestID,
    required String remarks,
    required String newStatus,
  }) async {
    final dao = await requestDao;
    return await dao.cancelRequestWithRemarks(
        requestID: requestID, remarks: remarks, newStatus: newStatus);
  }

  Future<CancelRemarksModel> getRequestRemarks(String requestID) async {
    final dao = await requestDao;
    return await dao.getRequestRemarks(requestID);
  }

  Future<bool> isRequestRemarkExisting(String requestID) async {
    final dao = await requestDao;
    return await dao.isRequestRemarkExisting(requestID);
  }

  Future<bool> isRequestTableNotEmpty() async {
    final dao = await requestDao;
    return await dao.isRequestTableNotEmpty();
  }

  /// Delete Request-related tables (used for refresh)
  Future<void> deleteRequest() async {
    final db = await database;
    await db.delete('a_tblRequest');
    await db.delete('a_tblRequestDocumentReference');
    await db.delete('a_tblRequestReceiverSignature');
    await db.delete('a_tblRequestImage');
    await db.delete('a_tblRequestImageOutbox');
  }

  // --- Signature/image helpers delegated to RequestDao ---
  Future<String?> getReceiverSignatureByRequestId(dynamic requestID) async {
    final dao = await signatureDao;
    return await dao.getReceiverSignatureByRequestId(requestID);
  }

  Future<String?> getRequestImageByRequestId(dynamic requestID) async {
    final dao = await requestDao;
    return await dao.getRequestImageByRequestId(requestID);
  }

  Future<bool> hasRequestImage(dynamic requestID) async {
    final dao = await requestDao;
    return await dao.hasRequestImage(requestID);
  }

  /// Persist signature and/or image for a request via the RequestDao
  Future<void> saveRequestMedia(
      {required dynamic requestID, String? signature, String? image}) async {
    final dao = await requestDao;
    return await dao.saveRequestMedia(
        requestID: requestID, signature: signature, image: image);
  }

  /// Load saved request image as bytes (Uint8List) or null if not found/invalid.
  Future<Uint8List?> loadSavedRequestImageBytes(dynamic requestID) async {
    try {
      final base64Str = await getRequestImageByRequestId(requestID);
      if (base64Str == null || base64Str.isEmpty) return null;
      return base64Decode(base64Str);
    } catch (e) {
      // If decoding fails, return null to let caller handle fallback
      return null;
    }
  }

  /// Load saved receiver signature as bytes (Uint8List) or null if not found/invalid.
  Future<Uint8List?> loadSavedSignatureBytes(dynamic requestID) async {
    try {
      final base64Str = await getReceiverSignatureByRequestId(requestID);
      if (base64Str == null || base64Str.isEmpty) return null;
      return base64Decode(base64Str);
    } catch (e) {
      return null;
    }
  }

  /// Insert (or replace) a receiver signature row with optional ApiStatus.
  /// Use `apiStatus = 'Pending'` for initial local saves and
  /// `apiStatus = 'Failed'` when creating an outbox entry after a transaction
  /// succeeded but signature upload failed.
  Future<void> insertReceiverSignature(
      {required dynamic requestID,
      required String signature,
      String apiStatus = 'Pending'}) async {
    final dao = await signatureDao;
    return await dao.insertReceiverSignature(
        requestID: requestID, signature: signature, apiStatus: apiStatus);
  }

  /// Delete a receiver signature row by request ID. This is used to clear
  /// outbox entries after a successful upload via the Signature Outbox UI.
  Future<int> deleteReceiverSignatureByRequestId(dynamic requestID) async {
    final dao = await signatureDao;
    return await dao.deleteReceiverSignatureByRequestId(requestID);
  }

  Future<void> insertImageOutboxItem({
    required String requestId,
    required String imageType,
    required String imageLookupKey,
    required String imageBase64,
    String apiStatus = 'Pending',
    String? capturedAt,
  }) async {
    final dao = await imageOutboxDao;
    return dao.insertImageOutboxItem(
      requestId: requestId,
      imageType: imageType,
      imageLookupKey: imageLookupKey,
      imageBase64: imageBase64,
      apiStatus: apiStatus,
      capturedAt: capturedAt,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingImageOutboxItems() async {
    final dao = await imageOutboxDao;
    return dao.getPendingImageOutboxItems();
  }

  Future<int> deleteImageOutboxItem({
    required String requestId,
    required String imageType,
    required String imageLookupKey,
  }) async {
    final dao = await imageOutboxDao;
    return dao.deleteImageOutboxItem(
      requestId: requestId,
      imageType: imageType,
      imageLookupKey: imageLookupKey,
    );
  }

  Future<int> clearImageOutbox() async {
    final dao = await imageOutboxDao;
    return dao.clearImageOutbox();
  }

  // --- CNTMST helpers (delegated) ---
  Future<void> insertCntmsts(List<CNTMSTModel> cntmstList) async {
    final dao = await cntmstDao;
    await dao.insertCntmsts(cntmstList);
  }

  Future<void> deleteCntmsts() async {
    final db = await database;
    await db.delete('CNTMST');
  }

  Future<List<CNTMSTModel>> getCntmstRequesters() async {
    final dao = await cntmstDao;
    return await dao.getRequesters();
  }

  Future<List<String>> getUserAndManagerPhoneNumbers(String cntmnn) async {
    final dao = await cntmstDao;
    return await dao.getUserAndManagerPhoneNumbers(cntmnn);
  }

  Future<String> getUserFullName(String cntmnn) async {
    final dao = await cntmstDao;
    return await dao.getUserFullName(cntmnn);
  }

  // --- Users delegate ---
  Future<void> insertUser(UserModel user) async {
    final dao = await userDao;
    await dao.insertUser(user);
  }

  Future<void> insertUsers(List<UserModel> users) async {
    final dao = await userDao;
    await dao.insertUsers(users);
  }

  Future<void> deleteUsers() async {
    final db = await database;
    await db.delete('Users');
  }

  Future<List<UserModel>> getUsers() async {
    final dao = await userDao;
    return await dao.getUsers();
  }

  Future<String> getUserPhoneNumberByUsername(String initial) async {
    final dao = await userDao;
    return await dao.getUserPhoneNumberByUsername(initial);
  }

  // --- Client helpers ---
  Future<int> insertClient(ClientModel client) async {
    final dao = await clientDao;
    return await dao.insertClient(client);
  }

  Future<void> insertClients(List<ClientModel> clients) async {
    final dao = await clientDao;
    await dao.insertClients(clients);
  }

  Future<void> deleteClients() async {
    final db = await database;
    await db.delete('ACCMST_');
  }

  Future<bool> hasACCMSTData() async {
    final dao = await clientDao;
    return await dao.hasData();
  }

  Future<List<ClientModel>> searchClients(String query) async {
    final dao = await clientDao;
    return await dao.search(query);
  }

  // --- Mobile helpers ---
  Future<void> insertMobiles(List<Mobile> mobiles) async {
    final dao = await mobileDao;
    await dao.insertMobiles(mobiles);
  }

  Future<List<Mobile>> getMobiles() async {
    final dao = await mobileDao;
    return await dao.getMobiles();
  }

  Future<void> deleteMobiles() async {
    final dao = await mobileDao;
    await dao.deleteAll();
  }

  // Close DB and clear cached DAOs
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;

    _requestDao = null;
    _signatureDao = null;
    _imageOutboxDao = null;
    _documentReferenceDao = null;
    _remarksDao = null;
    _clientDao = null;
    _mobileDao = null;
    _userDao = null;
    _cntmstDao = null;
    _backLoadDao = null;
  }

  /// Delete the database file and reset the instance.
  /// WARNING: This will delete all local data!
  /// Use only for debugging or testing purposes.
  Future<void> deleteDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'app.db');
      await databaseFactory.deleteDatabase(path);

      // Clear all cached DAOs
      _requestDao = null;
      _signatureDao = null;
      _imageOutboxDao = null;
      _pickUpDao = null;
      _airSeaDao = null;
      _documentReferenceDao = null;
      _remarksDao = null;
      _clientDao = null;
      _mobileDao = null;
      _userDao = null;
      _cntmstDao = null;
      _backLoadDao = null;
      _itemCategoryDao = null;
      _formCategoryDao = null;
    } catch (e) {
      // Ignore errors during deletion
    }
  }
}

enum RequestStatusEnum {
  newRequest,
  gettingSuppliesReady,
  itemPrepared,
  forDelivery,
  doneDelivery,
}

const Map<String, int> statusStringToInt = {
  'New Request': 1,
  'Getting Supplies Ready': 2,
  'Item Prepared': 3,
  'For Delivery': 4,
  'Delivered': 5,
};

const Map<int, String> statusIntToString = {
  1: 'New Request',
  2: 'Getting Supplies Ready',
  3: 'Item Prepared',
  4: 'For Delivery',
  5: 'Delivered',
};
