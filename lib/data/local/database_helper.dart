
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../features/logistics/models/client_model.dart';
import '../../features/logistics/models/request_model.dart';
import '../../features/personalization/models/user_model.dart';
import '../models/cnstmst_model.dart';
import '../models/mobile_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String _dbName = 'CRM_DB.db';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // Increment this if you change the schema later
      onCreate: _createDB,
      // onConfigure: _onConfigure, // Optional: for enabling foreign keys if not enabled by default
    );
  }

  Future _createDB(Database db, int version) async {
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
        Receiver TEXT
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
      PhoneNumber Text,
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
  }

  /// --- CRUD Operation for CNTMST ---

  // Insert a list of Cntmst records
  Future<void> insertCntmstList(List<CNTMSTModel> cntmstList) async {
    final db = await instance.database;
    Batch batch = db.batch();

    for (var cntmst in cntmstList) {
      batch.insert(
        'CNTMST',
        cntmst.toJson(),
        conflictAlgorithm:
            ConflictAlgorithm.replace, // Or .ignore, depending on your needs
      );
    }
    await batch.commit(noResult: true);
  }

  // Get all Cntmst records by Department
  Future<List<CNTMSTModel>> getAllCntmstRequester() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('CNTMST',
        orderBy: 'CNTDPT',
        where:
            'CNTMNN IS NOT NULL AND CNTMNN != ? AND CNTDPT IS NOT ? AND CNTSTS IS NOT ?',
        whereArgs: ['', 'COLLECTOR', '0']);

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return CNTMSTModel.fromJson(maps[i]);
    });
  }

  // Get user Phone Number and their reporting manager's Phone Number
  Future<List<String>> getUserAndManagerPhoneNumbers(String cntmnn) async {
    final db = await instance.database;
    List<String> phoneNumbers = [];

    // Get the user's details including phone number and manager hierarchy (CNTTGP)
    final List<Map<String, dynamic>> userMaps = await db.query(
      'CNTMST',
      columns: ['CNTNUM', 'CNTTGP'], // Also select CNTTGP
      where:
          'CNTMNN = ?', // Assuming cntmnn is the value in CNTMNN for the user
      whereArgs: [cntmnn],
    );

    if (userMaps.isEmpty) {
      return []; // Return an empty list if user not found
    }

    final Map<String, dynamic> userRecord = userMaps.first;

    // Add user's phone number
    final String? userPhoneNumber = userRecord['CNTNUM'] as String?;

    if (userPhoneNumber != null && userPhoneNumber.isNotEmpty) {
      phoneNumbers.add(userPhoneNumber);
    }

    // Get the manager's hierarchy string
    final String? managerHierarchy = userRecord['CNTTGP'] as String?;
    List<String> hierarchySegments = managerHierarchy!.split('/');
    for (String managers in hierarchySegments) {
      if (managers != "EGL") {
        // Get the manager's phone number
        final List<Map<String, dynamic>> managerMaps = await db.query(
          'CNTMST',
          columns: ['CNTNUM'],
          where:
              'CNTMNN = ?', // Assuming the segments in CNTTGP are CNTMNN values
          whereArgs: [managers],
        );
        if (userPhoneNumber != null && userPhoneNumber.isNotEmpty) {
          phoneNumbers.add(managerMaps.first['CNTNUM'] as String);
        }
      }
    }
    return phoneNumbers;
  }

  // Get User full name by initial
  Future<String> getUserFullName(String cntmnn) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'CNTMST',
      columns: ['CNTMCN'], // Select first name, last name, and middle name
      where:
          'CNTMNN = ?', // Assuming CNTMNN is the column for initials or unique identifier
      whereArgs: [cntmnn],
    );

    if (maps.isEmpty) {
      return ''; // Return empty string if no user found
    }

    return maps.first['CNTMCN'];
  }

  /// --- CRUD Operations for Users ---
  // Insert a single user
  Future<void> insertUser(UserModel user) async {
    final db = await instance.database;
    await db.insert(
      'Users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple users
  Future<void> insertUsers(List<UserModel> users) async {
    final db = await instance.database;
    Batch batch = db.batch();

    for (var user in users) {
      batch.insert(
        'Users',
        user.toJson(), // Assuming your UserModel has a toJson() method
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(
        noResult:
            true); // Use noResult: true if you don't need the results of individual operations
  }

  // Get users
  Future<List<UserModel>> getUsers() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Users');
    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return UserModel.fromJson(maps[i]);
    });
  }

  // Get user Phone Number by initial
  Future<String> getUserPhoneNumberByUsername(String initial) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Users',
      columns: ['PhoneNumber'],
      where: 'Initial = ?',
      whereArgs: [initial],
    );
    if (maps.isEmpty) {
      return '';
    }
    return maps.first['PhoneNumber'] as String;
  }

  /// --- CRUD Operations for Request ---

  // Load Requests
  Future<List<RequestModel>> getRequests() async {
    final db = await instance.database;

    // Main query to get requests and join with signature and mobile name
    // Note: SQLite doesn't have a direct 'OUTER APPLY' like SQL Server.
    // We'll do LEFT JOINs.
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        r.*, 
        m.MobileName
      FROM a_tblRequest AS r
      LEFT JOIN a_tblMobile AS m ON r.MobileID = m.MobileID
      ORDER BY r.RequestID DESC
    ''');

    if (maps.isEmpty) {
      return [];
    }

    List<RequestModel> requests = [];

    for (var map in maps) {
      RequestModel request = RequestModel.fromDbJson(map);
      if (request.image.isNotEmpty) {
        final imageString = await db.query(
          'a_tblRequestImage',
          where: 'RequestID = ?',
          whereArgs: [request.requestID],
          columns: ['RequestImage'],
        ).then((value) =>
            value.isNotEmpty ? value.first['RequestImage'].toString() : '');
        request.image = imageString;
      }

      // Fetch Client Information (ACCMST_ or DLRMST)
      // This is less efficient than a JOIN if possible, but mimics your C# loop.
      // For better performance, consider if client info can be simplified or if a different
      // DB structure or more complex JOIN could retrieve this in the main query.
      if (request.clientID.isNotEmpty) {
        // Try ACCMST_ first
        List<Map<String, dynamic>> clientMaps = await db.query(
          'ACCMST_',
          where: 'ACCMID = ?',
          whereArgs: [request.clientID],
        );
        if (clientMaps.isNotEmpty) {
          request.client = ClientModel.fromJson(clientMaps.first);
        } else {
          // Try DLRMST if not found in ACCMST_
          clientMaps = await db.query(
            'DLRMST',
            where: 'DLRMID = ?', // Assuming DLRMID is the column name
            whereArgs: [request.clientID],
          );
          if (clientMaps.isNotEmpty) {
            request.client = ClientModel.fromJson(clientMaps.first);
          }
        }
      }

      // Fetch Document References
      final List<Map<String, dynamic>> docRefMaps = await db.query(
        'a_tblRequestDocumentReference',
        columns: ['Reference'],
        where: 'RequestID = ?',
        whereArgs: [request.requestID],
      );

      request.documentReference =
          docRefMaps.map((docMap) => docMap['Reference'] as String).toList();

      requests.add(request);
    }

    return requests;
  }

  // Insert New Request
  Future<int> insertRequest(RequestModel requestModel) async {
    final db = await instance.database;

    // Prepare data for a_tblRequest
    Map<String, dynamic> requestData = {
      'RequestID': requestModel.requestID,
      'RequestClientID': requestModel.clientID,
      'RequestShippingMethod': requestModel.shippingMethod,
      'RequestDeliveryTerms': requestModel.deliveryTerms,
      'RequestDeliveryDate': requestModel.targetDate,
      'RequestPreference': requestModel.preference,
      'RequestStatus': requestModel.status,
      'RequestBy': requestModel.requestedBy,
      'RequestCreatedBy': requestModel.createdBy,
      'RequestCreatedAt': requestModel.createdAt,
      'RequestItemPreparedBy': requestModel.itemPreparedBy,
      'RequestDeliveredBy': requestModel.deliveredBy,
      'RequestItemPreparedAt': requestModel.itemPreparedAt,
      'RequestItemPreparedEndAt': requestModel.itemPreparedEndAt,
      'RequestDeliveredAt': requestModel.deliveredAt,
      'RequestDeliveredEndAt': requestModel.deliveredEndAt,
      'LocationStartedAt': requestModel.locationStartedAt,
      'LocationEndAt': requestModel.locationEndAt,
      'MobileID': 0,
      'RequestDriverHelper': requestModel.helper,
      'Receiver': requestModel.receiver,
    };

    // Insert into a_tblRequest and get the generated RequestID
    // The `insert` method returns the ID of the last inserted row.
    final int requestId = await db.insert(
      'a_tblRequest',
      requestData,
      conflictAlgorithm: ConflictAlgorithm
          .ignore, // Or ConflictAlgorithm.fail if you don't want to replace
    );
    if (requestId == 0) {
      updateRequest(requestModel: requestModel);
      return 0; // Or handle as appropriate
    }

    // Insert Document References
    if (requestModel.documentReference.isNotEmpty) {
      for (String reference in requestModel.documentReference) {
        if (reference.isNotEmpty) {
          // Ensure reference is not empty
          await db.insert(
            'a_tblRequestDocumentReference',
            {
              'RequestID': requestModel.requestID,
              'Reference': reference,
              'RequestCreatedAt': requestModel.createdAt,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }
    return int.parse(requestModel.requestID);
  }

// Insert a list of requests using a batch operation for efficiency
  Future<void> insertRequests(List<RequestModel> requestModels) async {
    for (RequestModel requestModel in requestModels) {
      await insertRequest(requestModel);
    }
  }

  // Update Request
  Future<void> updateRequest({required RequestModel requestModel}) async {
    final db = await instance.database;

    // Fetch the current status of the request
    final List<Map<String, dynamic>> currentRequestData = await db.query(
      'a_tblRequest',
      columns: ['RequestStatus'],
      where: 'RequestID = ?',
      whereArgs: [requestModel.requestID],
    );

    if (currentRequestData.isEmpty) {
      return; // Or throw an exception
    }

    final String currentStatusString =
        currentRequestData.first['RequestStatus'] as String;
    final int? currentStatusInt = statusStringToInt[currentStatusString];
    final int? newStatusInt = statusStringToInt[requestModel.status];

    // --- Status Update Logic ---
    if (currentStatusInt != null && newStatusInt != null) {
      // If current status is 'For Delivery' (4) and new status is numerically lower
      if (newStatusInt < currentStatusInt) {
        return;
      }
    } else {}

    // Update a_tblRequest
    Map<String, dynamic> requestData = {
      'RequestClientID': requestModel.clientID,
      'RequestShippingMethod': requestModel.shippingMethod,
      'RequestDeliveryTerms': requestModel.deliveryTerms,
      'RequestDeliveryDate': requestModel.targetDate,
      'RequestPreference': requestModel.preference,
      'RequestStatus': requestModel.status,
      'RequestBy': requestModel.requestedBy,
      'RequestCreatedBy': requestModel.createdBy,
      'RequestItemPreparedBy': requestModel.itemPreparedBy,
      'RequestDeliveredBy': requestModel.deliveredBy,
      'RequestCreatedAt': requestModel.createdAt,
      'RequestItemPreparedAt': requestModel.itemPreparedAt,
      'RequestItemPreparedEndAt': requestModel.itemPreparedEndAt,
      'RequestDeliveredAt': requestModel.deliveredAt,
      'RequestDeliveredEndAt': requestModel.deliveredEndAt,
      'LocationStartedAt': requestModel.locationStartedAt,
      'LocationEndAt': requestModel.locationEndAt,
      'MobileID': requestModel.mobileID,
      'RequestDriverHelper': requestModel.helper,
      'Receiver': requestModel.receiver
    };

    await db.update('a_tblRequest', requestData,
        where: 'RequestID = ?', whereArgs: [requestModel.requestID]);

    // Conditionally insert into a_tblRequestReceiverSignature
    if (requestModel.status == BTexts.statusDoneDelivery &&
        requestModel.signature.isNotEmpty) {
      Map<String, dynamic> signatureData = {
        'RequestID': requestModel.requestID,
        'RequestReceiverSignature': requestModel.signature,
      };
      await db.insert(
        'a_tblRequestReceiverSignature',
        signatureData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    if (requestModel.status == BTexts.statusDoneDelivery &&
        requestModel.image.isNotEmpty) {
      Map<String, dynamic> imageData = {
        'RequestID': requestModel.requestID,
        'RequestImage': requestModel.image,
      };

      // Using insert with conflictAlgorithm.replace to handle potential existing signatures
      // This behaves like an "upsert" (insert or update if exists)
      await db.insert(
        'a_tblRequestImage',
        imageData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Check if the table request is not empty
  Future<bool> isRequestTableNotEmpty() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT COUNT(*) as count FROM a_tblRequest
  ''');

    if (result.isNotEmpty) {
      final count = result.first['count'] as int?;
      return count != null && count > 0;
    }
    return false;
  }

  // Delete Request by RequestID
  Future<void> deleteRequest() async {
    final db = await instance.database;
    await db.delete('a_tblRequest');
    await db.delete('a_tblRequestDocumentReference');
    await db.delete('a_tblRequestReceiverSignature');
    await db.delete('a_tblRequestImage');
  }

  /// --- CRUD Operations for Client ---

  // Insert a single client
  Future<int> insertClient(ClientModel client) async {
    final db = await instance.database;
    return await db.insert(
      'ACCMST_',
      client.toJson(), // Assuming your ClientModel has a toJson() method
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Or .ignore, or .fail depending on your needs
    );
  }

  // Insert a list of clients (useful for API fetched data)
  Future<void> insertClients(List<ClientModel> clients) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var client in clients) {
      // Ensure your ClientModel has a toJson() method that returns a Map<String, dynamic>
      // matching the columns in ACCMST_
      batch.insert(
        'ACCMST_',
        client.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace, // Or .ignore, or .fail
      );
    }
    await batch.commit(
        noResult:
            true); // Use noResult: true if you don't need the results of each operation
  }

  // Check if a ACCMST_ is has data
  Future<bool> hasACCMSTData() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('ACCMST_');
    return maps.isNotEmpty;
  }

  /// --- CRUD Operations for Mobile ---

  // Insert a list of Mobile devices
  Future<void> insertMobiles(List<Mobile> mobiles) async {
    final db = await instance.database;
    Batch batch = db.batch();

    for (var mobile in mobiles) {
      Map<String, dynamic> mobileData = {
        'MobileID': int.parse(mobile.mobileID),
        'MobileName': mobile.mobileName,
      };

      batch.insert(
        'a_tblMobile',
        mobileData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Load (Get) all Mobile devices
  Future<List<Mobile>> getMobiles() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('a_tblMobile');

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return Mobile.fromJson(maps[i]);
    });
  }

  // Delete all Mobile devices
  Future<void> deleteMobiles() async {
    final db = await instance.database;
    db.delete('a_tblMobile');
  }

  /// Search for clients in the local database
  Future<List<ClientModel>> searchClients(String query) async {
    try {
      final db = await instance.database;
      print(
          'DATABASE HELPER: Database object is valid. Searching for: "$query"');

      if (query.isEmpty) {
        // If the query is empty, you might want to return all clients
        // or an empty list, depending on your desired behavior.
        // For this example, let's return all clients.
        final List<Map<String, dynamic>> maps = await db.query('ACCMST_');
        print(
            'DATABASE HELPER: Search query executed. Number of results: ${maps.length}');
        return List.generate(maps.length, (i) {
          return ClientModel.fromJson(
              maps[i]); // Assuming ClientModel.fromJson exists
        });
      } else {
        final List<Map<String, dynamic>> maps = await db.query(
          'ACCMST_',
          where: 'ACCMNM LIKE ? OR ACCMSC LIKE ?',
          whereArgs: ['%$query%', '%$query%'],
        );

        print(
            'DATABASE HELPER: Search query executed. Number of results: ${maps.length}');
        if (maps.isEmpty) {
          // This condition should ideally never be true with sqflite
          print('DATABASE HELPER: maps IS NULL - THIS IS UNEXPECTED!');
          return [];
        }

        return List.generate(maps.length, (i) {
          return ClientModel.fromJson(maps[i]);
        });
      }
    } catch (e, stackTrace) {
      print('DATABASE HELPER: ERROR in searchClients: $e');
      print('DATABASE HELPER: StackTrace: $stackTrace');
      return []; // Return empty list or rethrow depending on error handling strategy
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
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
  'Delivered': 5, // Assuming 'Done Delivery' is 5 based on your sequence
};

const Map<int, String> statusIntToString = {
  1: 'New Request',
  2: 'Getting Supplies Ready',
  3: 'Item Prepared',
  4: 'For Delivery',
  5: 'Delivered',
};
