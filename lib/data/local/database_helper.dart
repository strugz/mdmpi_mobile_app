import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../features/logistics/models/standard_delivery_model.dart';
import '../../features/logistics/models/cancel_remarks_model.dart';
import '../../features/logistics/models/client_model.dart';
import '../../data/models/mobile_model.dart';
import '../../data/models/cnstmst_model.dart';
import '../../features/personalization/models/user_model.dart';

// DAO imports
import 'dao/standard_delivery/standard_delivery_dao.dart';
import 'dao/pick_up/pick_up_dao.dart';
import 'dao/air_sea/air_sea_dao.dart';
import 'dao/pull_out/pull_out_dao.dart';
import 'dao/common/document_reference_dao.dart';
import 'dao/common/remarks_dao.dart';
import 'dao/common/client_dao.dart';
import 'dao/common/mobile_dao.dart';
import 'dao/common/user_dao.dart';
import 'dao/common/cntmst_dao.dart';
import 'dao/common/item_category_dao.dart';
import 'dao/common/form_category_dao.dart';
import 'dao/common/client_contact_person_dao.dart';
import 'db_schema.dart';

/// Lightweight DatabaseHelper singleton that initializes the database,
/// provides cached DAO instances and forwards commonly used operations.
class DatabaseHelper {
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  Database? _database;

  // Cached DAO instances
  RequestDao? _requestDao;
  PickUpDao? _pickUpDao;
  AirSeaDao? _airSeaDao;
  PullOutDao? _pullOutDao;
  DocumentReferenceDao? _documentReferenceDao;
  RemarksDao? _remarksDao;
  ClientDao? _clientDao;
  MobileDao? _mobileDao;
  UserDao? _userDao;
  CntmstDao? _cntmstDao;
  ItemCategoryDao? _itemCategoryDao;
  FormCategoryDao? _formCategoryDao;
  ClientContactPersonDao? _clientContactPersonDao;

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
      version: 11,
      onCreate: (db, version) async {
        await createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add pick-up main table for version 2
          // Pick-up requests reuse the existing shared support tables:
          // - a_tblRequestDocumentReference
          // - a_tblRequestReceiverSignature
          // - a_tblRequestImage
          // - a_tblRequestRemarks
          await db.execute('''
            CREATE TABLE IF NOT EXISTS a_tblRequestPickUp (
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
        }
        if (oldVersion < 3) {
          // Add ItemCategory and FormCategory tables for version 3
          await db.execute('''
            CREATE TABLE IF NOT EXISTS a_tblItemCategory (
              ItemCategoryID TEXT PRIMARY KEY,
              ItemCategoryName TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS a_tblFormCategory (
              FormCategoryID TEXT PRIMARY KEY,
              FormCategoryName TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          // Add Air/Sea main table for version 4
          // Air/Sea requests reuse the existing shared support tables:
          // - a_tblRequestDocumentReference
          // - a_tblRequestReceiverSignature
          // - a_tblRequestImage
          // - a_tblRequestRemarks
          await db.execute('''
            CREATE TABLE IF NOT EXISTS a_tblRequestAirSea (
              RequestID INTEGER PRIMARY KEY,
              ClientID TEXT,
              ItemCategoryID TEXT,              MobileID INTEGER,
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
              Status TEXT,
              Remarks TEXT,
              CreatedBy TEXT,
              CreatedAt TEXT,
              UpdatedAt TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          // Version 5: Ensure all Air/Sea columns exist (fix for databases created with incomplete schema)
          // Add missing columns if they don't exist
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN EndorsedTo TEXT');
          } catch (_) {} // Column might already exist
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN EndorsedAt TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN EndorsedBy TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN WaybillNumber TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN ReceivedAt TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN ReceivedBy TEXT');
          } catch (_) {}
        }
        if (oldVersion < 6) {
          // Version 6: Add dispatch-related columns (TripTicketNumber, Driver, Helper, DispatchedAt, DropOffAt)
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN TripTicketNumber TEXT');
          } catch (_) {} // Column might already exist
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN Driver TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN Helper TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN DispatchedAt TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN DropOffAt TEXT');
          } catch (_) {}
        }
        if (oldVersion < 7) {
          // Version 7: Add ItemCategoryID and FormCategoryID columns to a_tblRequest
          try {
            await db.execute('ALTER TABLE a_tblRequest ADD COLUMN ItemCategoryID TEXT');
          } catch (_) {} // Column might already exist
          try {
            await db.execute('ALTER TABLE a_tblRequest ADD COLUMN FormCategoryID TEXT');
          } catch (_) {}
        }
        if (oldVersion < 8) {
          // Version 8: Ensure Air/Sea dispatch columns exist (fix for schema inconsistency)
          // These columns should have been added in version 6, but base schema was missing them
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN TripTicketNumber TEXT');
          } catch (_) {} // Column might already exist
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN Driver TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN Helper TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN DispatchedAt TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN DropOffAt TEXT');
          } catch (_) {}
        }
        if (oldVersion < 9) {
          // Version 9: Add CreatedBy column to Air/Sea table (missing from version 4 creation)
          try {
            await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN CreatedBy TEXT');
          } catch (_) {} // Column might already exist
        }
        if (oldVersion < 10) {
          // Version 10: Add Pull-Out/Return/Pick-Up table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS a_tblRequestPullOutReturnPickUp (
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
        }
        if (oldVersion < 11) {
          // Version 11: Add ClientContactPerson autocomplete table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS a_tblClientContactPerson (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              usageCount INTEGER DEFAULT 1,
              lastUsedAt TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  // --- DAO getters ---
  Future<RequestDao> get requestDao async {
    if (_requestDao != null) return _requestDao!;
    final db = await database;
    _requestDao = RequestDao(db);
    return _requestDao!;
  }

  Future<DocumentReferenceDao> get documentReferenceDao async {
    if (_documentReferenceDao != null) return _documentReferenceDao!;
    final db = await database;
    _documentReferenceDao = DocumentReferenceDao(db);
    return _documentReferenceDao!;
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

  Future<void> updateRequest({required StandardDeliveryModel requestModel}) async {
    final dao = await requestDao;
    return await dao.updateRequest(requestModel: requestModel);
  }

  Future<int> cancelRequestWithRemarks({
    required String requestID,
    required String remarks,
    required String newStatus,
  }) async {
    final dao = await requestDao;
    return await dao.cancelRequestWithRemarks(requestID: requestID, remarks: remarks, newStatus: newStatus);
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
  }

  // --- Signature/image helpers delegated to RequestDao ---
  Future<String?> getReceiverSignatureByRequestId(dynamic requestID) async {
    final dao = await requestDao;
    return await dao.getReceiverSignatureByRequestId(requestID);
  }

  Future<String?> getRequestImageByRequestId(dynamic requestID) async {
    final dao = await requestDao;
    return await dao.getRequestImageByRequestId(requestID);
  }

  Future<bool> hasReceiverSignature(dynamic requestID) async {
    final dao = await requestDao;
    return await dao.hasReceiverSignature(requestID);
  }

  Future<bool> hasRequestImage(dynamic requestID) async {
    final dao = await requestDao;
    return await dao.hasRequestImage(requestID);
  }

  /// Persist signature and/or image for a request via the RequestDao
  Future<void> saveRequestMedia({required dynamic requestID, String? signature, String? image}) async {
    final dao = await requestDao;
    return await dao.saveRequestMedia(requestID: requestID, signature: signature, image: image);
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

  // --- CNTMST helpers (delegated) ---
  Future<void> insertCntmsts(List<CNTMSTModel> cntmstList) async {
    final dao = await cntmstDao;
    await dao.insertCntmsts(cntmstList);
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
    _documentReferenceDao = null;
    _remarksDao = null;
    _clientDao = null;
    _mobileDao = null;
    _userDao = null;
    _cntmstDao = null;
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
      _pickUpDao = null;
      _airSeaDao = null;
      _documentReferenceDao = null;
      _remarksDao = null;
      _clientDao = null;
      _mobileDao = null;
      _userDao = null;
      _cntmstDao = null;
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
