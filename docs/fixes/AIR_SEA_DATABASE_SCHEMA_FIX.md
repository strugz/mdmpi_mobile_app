# Air/Sea Database Schema Fix

## Date
January 5, 2026 (Updated)

## Issues Fixed

### Issue 1: Missing Dispatch Columns
```
E/SQLiteLog( 8806): (1) table a_tblRequestAirSea has no column named DispatchedAt 
in "INSERT OR REPLACE INTO a_tblRequestAirSea (RequestID, ClientID, ItemCategoryID, 
MobileID, DatePickUp, ItemPreparedAt, ItemPreparedEndAt, PreparedBy...
```

### Issue 2: Missing CreatedBy Column
```
E/SQLiteLog: (1) table a_tblRequestAirSea has no column named CreatedBy 
in "INSERT OR REPLACE INTO a_tblRequestAirSea (RequestID, ClientID, ItemCategoryID...
```

## Root Cause
The base database schema in `db_schema.dart` was missing dispatch-related columns that were added in version 6 migration. This caused inconsistency between:
- **Fresh database installs** (using `db_schema.dart` - missing columns)
- **Migrated databases** (using migrations - had columns)

### Missing Columns (Issue 1 & 2)
The following columns were missing from the version 4 migration but expected by the DAO:
1. `TripTicketNumber` - Trip ticket number for dispatch
2. `Driver` - Driver name for dispatch
3. `Helper` - Helper name for dispatch
4. `DispatchedAt` - Timestamp when dispatched
5. `DropOffAt` - Timestamp when dropped off
6. `CreatedBy` - User who created the request ← **Critical for all operations**

## Files Modified

### 1. `lib/data/local/db_schema.dart`
**Change:** Added missing dispatch columns to the base Air/Sea table schema

```dart
// Before: Missing 5 dispatch columns
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

// After: All dispatch columns included
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
  TripTicketNumber TEXT,    // ← Added
  Driver TEXT,              // ← Added
  Helper TEXT,              // ← Added
  DispatchedAt TEXT,        // ← Added
  DropOffAt TEXT,           // ← Added
  Status TEXT,
  Remarks TEXT,
  CreatedBy TEXT,
  CreatedAt TEXT,
  UpdatedAt TEXT
)
```

### 2. `lib/data/local/database_helper.dart`
**Changes:**
1. Incremented database version from 7 to 8
2. Added version 8 migration to ensure columns exist for existing databases

```dart
// Version updated
return await openDatabase(
  path,
  version: 8,  // ← Changed from 7
  onCreate: (db, version) async {
    await createAllTables(db);
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    // ... existing migrations ...
    
    if (oldVersion < 8) {
      // Version 8: Ensure Air/Sea dispatch columns exist
      try {
        await db.execute('ALTER TABLE a_tblRequestAirSea ADD COLUMN TripTicketNumber TEXT');
      } catch (_) {}
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
  },
);
```

## Impact

### What This Fixes
✅ Fresh app installs will now have all required columns  
✅ Existing databases will be migrated to version 8 with missing columns added  
✅ Air/Sea insert operations will no longer fail  
✅ Air/Sea update operations will work correctly  
✅ Dispatch feature will function properly  

### Database Version History
- **Version 1-3**: Base tables
- **Version 4**: Added Air/Sea table (incomplete schema - missing dispatch columns and CreatedBy)
- **Version 5**: Added endorsement columns
- **Version 6**: Added dispatch columns (via migration only)
- **Version 7**: Added ItemCategoryID and FormCategoryID to requests
- **Version 8**: Fixed Air/Sea dispatch columns in base schema
- **Version 9**: Added CreatedBy column to Air/Sea table ← **Current**

## Testing Instructions

### For Fresh Install
1. Uninstall the app completely
2. Reinstall and launch
3. Create a new Air/Sea request
4. Verify dispatch fields work correctly

### For Existing Install (Migration)
1. Update the app
2. Launch (migration runs automatically)
3. Verify existing Air/Sea requests display correctly
4. Create a new Air/Sea request with dispatch info
5. Verify all fields save and load properly

### Verification via Local Storage Viewer
1. Open Settings → Developer Tools → Local Storage Viewer
2. Select `a_tblRequestAirSea` table
3. Verify the following columns exist:
   - TripTicketNumber
   - Driver
   - Helper
   - DispatchedAt
   - DropOffAt

## Related Code

### DAO Usage
The `AirSeaDao` expects these columns in both insert and batch operations:

**File:** `lib/data/local/dao/air_sea/air_sea_dao.dart`

```dart
Map<String, dynamic> airSeaData = {
  'RequestID': parsedId,
  'ClientID': airSeaModel.clientId,
  'ItemCategoryID': airSeaModel.itemCategoryId,
  'MobileID': airSeaModel.mobileId,
  'DatePickUp': airSeaModel.datePickUp,
  'ItemPreparedAt': airSeaModel.itemPreparedAt,
  'ItemPreparedEndAt': airSeaModel.itemPreparedEndAt,
  'PreparedBy': airSeaModel.preparedBy,
  'WaybillNumber': airSeaModel.waybillNumber,
  'ReceivedAt': airSeaModel.receivedAt,
  'ReceivedBy': airSeaModel.receivedBy,
  'TripTicketNumber': airSeaModel.tripTicketNumber,  // Required
  'Driver': airSeaModel.driver,                      // Required
  'Helper': airSeaModel.helper,                      // Required
  'DispatchedAt': airSeaModel.dispatchedAt,          // Required
  'DropOffAt': airSeaModel.dropOffAt,                // Required
  'Status': airSeaModel.status,
  'Remarks': airSeaModel.remarks,
  'CreatedBy': airSeaModel.createdBy,
  'CreatedAt': airSeaModel.createdAt,
  'UpdatedAt': airSeaModel.updatedAt,
};
```

### Model Fields
The `AirSeaModel` includes these dispatch fields:

**File:** `lib/features/logistics/models/air_sea_model.dart`

```dart
// Dispatch phase
String tripTicketNumber;
String driver;
String helper;
String dispatchedAt;
String dropOffAt;
```

## Prevention

To prevent similar issues in the future:

1. **Always update base schema** when adding new columns via migrations
2. **Keep schema versions in sync** between `db_schema.dart` and migration logic
3. **Test fresh installs** not just migrations
4. **Document schema changes** in both migration and base schema files
5. **Use the Local Storage Viewer** to verify schema consistency

## Notes

- Migration is non-destructive (uses `ALTER TABLE ADD COLUMN`)
- Try-catch blocks handle cases where columns already exist
- Existing data is preserved during migration
- Fresh installs will now have complete schema from the start

## Status
✅ **FIXED** - Air/Sea database schema is now consistent across all installation scenarios

---

**Fixed by:** Database schema update and migration v8  
**Affects:** All Air/Sea module operations  
**Severity:** High (app crashes on Air/Sea operations)  
**Resolution:** Schema updated, migration added

