# Pull-Out Table & DAO Implementation

## Date
January 5, 2026

## Overview
Created dedicated database table `a_tblRequestPullOutReturnPickUp` and corresponding `PullOutDao` for pull-out requests, matching the pattern used by Air/Sea requests.

## What Was Done

### 1. Database Schema (`lib/data/local/db_schema.dart`)

Added `a_tblRequestPullOutReturnPickUp` table:

```sql
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
```

**Fields Mapped from PullOutModel:**
- All model properties mapped to corresponding DB columns
- Proper data types (INTEGER for IDs, TEXT for strings)
- Primary key on RequestID

### 2. Database Migration (`lib/data/local/database_helper.dart`)

**Version Updated:** 9 → 10

**Migration Added:**
```dart
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
```

**DatabaseHelper Updates:**
1. Added `PullOutDao?_pullOutDao` instance variable
2. Added `import 'dao/pull_out/pull_out_dao.dart';`
3. Added `pullOutDao` getter method

### 3. PullOutDao (`lib/data/local/dao/pull_out/pull_out_dao.dart`)

Created complete DAO matching AirSeaDao pattern:

**Methods:**
- `getPullOutRequests()` - Fetch all pull-out requests with joined data
- `insertPullOut(PullOutModel)` - Insert single request
- `insertPullOutRequests(List<PullOutModel>)` - Batch insert
- `updatePullOut({required PullOutModel})` - Update request
- `deleteAll()` - Clear all pull-out requests
- `isPullOutTableNotEmpty()` - Check if table has data

**Features:**
- ✅ Loads document references from `a_tblRequestDocumentReference`
- ✅ Loads cancel remarks from `a_tblRequestRemarks`
- ✅ Loads client info via `ClientDao`
- ✅ Handles batch operations efficiently
- ✅ Proper conflict handling (ignore on insert, update if exists)
- ✅ Persists related data (documents, client)

### 4. PullOutModel (`lib/features/logistics/models/pull_out_model.dart`)

Added `fromDbJson` factory method:

```dart
/// Parse from local database JSON (DB column names)
factory PullOutModel.fromDbJson(Map<String, dynamic> json) {
  return PullOutModel(
    id: json['RequestID']?.toString() ?? '',
    clientId: json['ClientID']?.toString() ?? '',
    clientContactPerson: json['ClientContactPerson']?.toString() ?? '',
    // ... all fields mapped from DB column names
  );
}
```

**Purpose:**
- Deserializes database rows to PullOutModel
- Handles DB column naming (RequestID, ClientID, etc.)
- Different from `fromJson` which handles API responses

### 5. Local Storage Viewer (`lib/features/logistics/screens/data_test/local_storage_data_controller.dart`)

Updated available tables list to include:
```dart
'a_tblRequestPullOutReturnPickUp',
```

Now pull-out table is viewable in the Local Storage Viewer tool.

## Files Created

1. ✅ `lib/data/local/dao/pull_out/pull_out_dao.dart` (320 lines)

## Files Modified

1. ✅ `lib/data/local/db_schema.dart` - Added table schema
2. ✅ `lib/data/local/database_helper.dart` - Added migration v10, DAO getter, import
3. ✅ `lib/features/logistics/models/pull_out_model.dart` - Added fromDbJson method
4. ✅ `lib/features/logistics/screens/data_test/local_storage_data_controller.dart` - Added table to list

## Changes Reverted

Removed incorrect implementation that tried to use `a_tblRequest`:
1. ❌ Reverted `PullOutRepository` - removed StandardDeliveryDao usage
2. ❌ Reverted `PullOutMapper` - removed conversion methods
3. ❌ Removed wrong imports (NetworkManager, logger, DatabaseHelper from repository)

## Architecture

Pull-out requests now follow the **same pattern as Air/Sea**:

```
PullOutModel (model)
    ↓
PullOutDao (database access)
    ↓
a_tblRequestPullOutReturnPickUp (dedicated table)
    +
a_tblRequestDocumentReference (shared)
    +
a_tblRequestRemarks (shared)
    +
ACCMST_ (shared - client data)
```

## Comparison: Pull-Out vs Air/Sea

| Feature | Air/Sea | Pull-Out |
|---------|---------|----------|
| Dedicated Table | ✅ a_tblRequestAirSea | ✅ a_tblRequestPullOutReturnPickUp |
| Dedicated DAO | ✅ AirSeaDao | ✅ PullOutDao |
| Document References | ✅ Shared table | ✅ Shared table |
| Cancel Remarks | ✅ Shared table | ✅ Shared table |
| Client Data | ✅ Via ClientDao | ✅ Via ClientDao |
| fromDbJson | ✅ Yes | ✅ Yes |
| Batch Insert | ✅ Yes | ✅ Yes |
| Update Support | ✅ Yes | ✅ Yes |

**Both modules now use identical patterns!** ✅

## Database Version History

- **Version 1-3**: Base tables
- **Version 4**: Added Air/Sea table
- **Version 5**: Added endorsement columns to Air/Sea
- **Version 6**: Added dispatch columns to Air/Sea (migration)
- **Version 7**: Added ItemCategoryID and FormCategoryID
- **Version 8**: Fixed Air/Sea dispatch columns in base schema
- **Version 9**: Added CreatedBy to Air/Sea
- **Version 10**: Added Pull-Out table ← **Current**

## Testing

### Verify Table Creation

**Using Local Storage Viewer:**
1. Settings → Developer Tools → Local Storage Viewer
2. Select `a_tblRequestPullOutReturnPickUp` from dropdown
3. ✅ Should show table (empty or with data)

**Using SQL:**
```sql
SELECT * FROM a_tblRequestPullOutReturnPickUp;
```

### Verify DAO Operations

**Test Insert:**
```dart
final dao = await DatabaseHelper.instance.pullOutDao;
final pullOut = PullOutModel(
  id: '123',
  clientId: 'CLIENT001',
  requestStatus: 'New Request',
  // ... other fields
);
await dao.insertPullOut(pullOut);
```

**Test Fetch:**
```dart
final dao = await DatabaseHelper.instance.pullOutDao;
final pullOuts = await dao.getPullOutRequests();
print('Pull-outs: ${pullOuts.length}');
```

## Next Steps for PullOutRepository

The PullOutRepository still needs to be updated to use the new DAO. This should follow the exact pattern as AirSeaRepository:

1. **Add DAO instance:**
```dart
PullOutDao? _daoInstance;

Future<PullOutDao> get _dao async {
  if (_daoInstance != null) return _daoInstance!;
  final db = await DatabaseHelper.instance.database;
  _daoInstance = PullOutDao(db);
  return _daoInstance!;
}
```

2. **Update getAll() method:**
- Check network connectivity
- Return local data if offline
- Use local cache + background sync when online
- Fetch from API on force refresh
- Fallback to local on API error

3. **Add _syncFromApi() method:**
- Background sync without blocking
- Silent failure handling

4. **Update other methods:**
- `insert()` - save to both API and local DB
- `update()` - update both API and local DB
- `getLocalPullOuts()` - fetch from DAO only

## Benefits

### Separation of Concerns
- ✅ Pull-out data isolated in own table
- ✅ No mixing with standard delivery data
- ✅ Clear data boundaries

### Consistency
- ✅ Matches Air/Sea and PickUp patterns
- ✅ Same DAO interface across modules
- ✅ Predictable behavior

### Performance
- ✅ Dedicated table = faster queries
- ✅ No filtering needed (no shared table)
- ✅ Optimized indexes possible

### Maintenance
- ✅ Easier to modify pull-out schema
- ✅ No impact on other request types
- ✅ Clear ownership

## Migration Safety

- ✅ Non-destructive (CREATE TABLE IF NOT EXISTS)
- ✅ Existing data untouched
- ✅ Automatic on app launch
- ✅ Version tracking prevents re-execution

## Status

✅ **COMPLETE** - Database table and DAO created  
⏳ **TODO** - Update PullOutRepository to use the new DAO (follow AirSeaRepository pattern)

---

**Database Version:** 10  
**Table:** `a_tblRequestPullOutReturnPickUp`  
**DAO:** `PullOutDao`  
**Pattern:** Matches AirSeaDao exactly

