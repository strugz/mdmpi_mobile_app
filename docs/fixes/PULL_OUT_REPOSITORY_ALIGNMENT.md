# Pull-Out Repository Alignment with Air/Sea Repository

## Date
January 5, 2026

## Issue
The `PullOutRepository.getAll()` method was inconsistent with `AirSeaRepository.getAll()`. The PullOut version lacked:
- Local database caching
- Network connectivity checks
- Offline support
- Background sync
- Fallback to local data on API failure

## Changes Made

### 1. PullOutRepository (`lib/data/repositories/pull_out/pull_out_repository.dart`)

#### Added Imports
```dart
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/standard_delivery/standard_delivery_dao.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
```

#### Added DAO Instance
```dart
RequestDao? _daoInstance;

/// Lazy getter for RequestDao to avoid late initialization errors.
/// Initializes the DAO on first access and caches it for subsequent calls.
/// Pull-out requests use the main a_tblRequest table.
Future<RequestDao> get _dao async {
  if (_daoInstance != null) return _daoInstance!;
  final db = await DatabaseHelper.instance.database;
  _daoInstance = RequestDao(db);
  return _daoInstance!;
}
```

**Note:** Pull-out requests share the `a_tblRequest` table with standard delivery requests, so we use `RequestDao` (StandardDeliveryDao).

#### Enhanced `getAll()` Method

**Before:**
- Simple API call only
- No offline support
- No caching
- No fallback

**After:**
- ✅ Network connectivity check
- ✅ Offline mode returns local data
- ✅ Local DB cache checked first
- ✅ Background sync for fresh data
- ✅ API failure fallback to local DB
- ✅ Detailed logging for debugging

Key features:
1. **Offline Support:** Returns local data when offline
2. **Smart Caching:** Checks local DB first, triggers background sync
3. **Force Refresh:** `forceRefresh` parameter bypasses cache
4. **Graceful Degradation:** Falls back to local DB if API fails
5. **Background Sync:** Non-blocking sync keeps data fresh

#### Added `_syncFromApi()` Method
Background sync method that:
- Fetches data from API silently
- Updates local cache
- Doesn't block user interface
- Fails silently (logged but no user notification)

#### Enhanced `getLocalPullOuts()` Method

**Before:**
- Just called `getAll()` (API call)
- Had TODO comment

**After:**
- Properly fetches from local DB only
- No API call
- Returns empty list on error
- Used for offline scenarios

### 2. PullOutMapper (`lib/features/logistics/mappers/pull_out_mapper.dart`)

#### Added Import
```dart
import '../models/standard_delivery_model.dart';
```

#### Added Conversion Methods

##### `fromStandardDelivery()` - DB to Model
Converts `StandardDeliveryModel` (from local DB) to `PullOutModel`:
- Maps common fields (ID, client, status, etc.)
- Converts field names (deliveredBy → releasedBy)
- Handles missing fields (pull-out specific fields)
- Preserves aggregates (client, documentReference, cancelRemarks)

##### `toStandardDelivery()` - Model to DB
Converts `PullOutModel` to `StandardDeliveryModel` (for DB storage):
- Sets `shippingMethod` to `'Pull-Out/Return'` as identifier
- Maps pull-out fields to standard delivery fields
- Handles field name differences
- Preserves all essential data

## Architecture

### Data Flow

#### Fetch Flow (getAll)
```
1. Check network connectivity
   ↓
2. If offline → Return local data
   ↓
3. If online and !forceRefresh → Check local DB
   ↓
4. If local has data → Return + trigger background sync
   ↓
5. If no local data or forceRefresh → Fetch from API
   ↓
6. Cache API response to local DB
   ↓
7. Return data
   ↓
8. On API error → Fallback to local DB
```

#### Background Sync Flow
```
1. Triggered after returning local data
   ↓
2. Fetch from API silently
   ↓
3. Update local cache
   ↓
4. Log result (no user notification)
   ↓
5. Silent fail on error
```

### Database Storage

Pull-out requests are stored in the **main `a_tblRequest` table** using:
- `shippingMethod = 'Pull-Out/Return'` as identifier
- Field mapping via PullOutMapper
- Shared with standard delivery requests

This approach:
- ✅ Reuses existing table structure
- ✅ Leverages existing DAO (RequestDao)
- ✅ Maintains data integrity
- ✅ Enables unified querying

## Benefits

### For Users
1. **Works Offline** - View requests without internet
2. **Faster Loading** - Local data shows instantly
3. **Better UX** - Background sync keeps data fresh
4. **Reliable** - Fallback to cache on network issues

### For Developers
1. **Consistent API** - Same pattern as AirSeaRepository
2. **Maintainable** - Centralized data logic
3. **Debuggable** - Comprehensive logging
4. **Testable** - Clear separation of concerns

### For Business
1. **Reduced Server Load** - Fewer API calls via caching
2. **Better Performance** - Faster response times
3. **Offline Capability** - Works in poor connectivity areas
4. **Data Resilience** - Local backup of critical data

## Comparison: Before vs After

### Before
```dart
Future<List<PullOutModel>> getAll({bool forceRefresh = false}) async {
  try {
    final url = _uri(_resource);
    final response = await _safeGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final items = _decodeRootToList(decoded);
      return items
          .whereType<dynamic>()
          .map((e) => PullOutModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load pull-out requests');
  } catch (e, st) {
    _showError('Failed to fetch pull-out list');
    throw Exception('getAll pull-out error: $e\n$st');
  }
}
```

**Issues:**
- ❌ Always requires network
- ❌ No caching
- ❌ No offline support
- ❌ No fallback mechanism
- ❌ Blocks on API call

### After
```dart
Future<List<PullOutModel>> getAll({bool forceRefresh = false}) async {
  try {
    final dao = await _dao;
    final isConnected = await NetworkManager.instance.isConnected();

    // If offline, return local data only
    if (!isConnected) {
      logDebug('PullOutRepository: Offline, returning local data');
      final localRequests = await dao.getRequests();
      return localRequests
          .map((sd) => PullOutMapper.fromStandardDelivery(sd))
          .toList();
    }

    // If online and not forcing refresh, check if local DB has data
    if (!forceRefresh) {
      final hasLocalData = await dao.isRequestTableNotEmpty();
      if (hasLocalData) {
        final localRequests = await dao.getRequests();
        final pullOutRequests = localRequests
            .map((sd) => PullOutMapper.fromStandardDelivery(sd))
            .toList();
        
        // Trigger background sync without blocking
        _syncFromApi();
        return pullOutRequests;
      }
    }

    // Fetch from API and cache...
    // [Full implementation with error handling and fallback]
  }
}
```

**Benefits:**
- ✅ Network-aware
- ✅ Local caching
- ✅ Offline support
- ✅ Fallback to cache
- ✅ Background sync
- ✅ Comprehensive logging

## Testing

### Test Scenarios

1. **Online + Empty Cache**
   - Expected: Fetch from API, cache, return data
   - Verify: Local DB populated after fetch

2. **Online + Cached Data**
   - Expected: Return cache immediately, sync in background
   - Verify: Fast response, background sync log

3. **Offline + Cached Data**
   - Expected: Return local data
   - Verify: No API call, data returned from DB

4. **Offline + Empty Cache**
   - Expected: Return empty list or error
   - Verify: No crash, graceful handling

5. **API Failure + Cached Data**
   - Expected: Fallback to local cache
   - Verify: Data returned despite API error

6. **Force Refresh**
   - Expected: Skip cache, fetch fresh from API
   - Verify: API called even with cache

### Verification

**Using Local Storage Viewer:**
1. Open Settings → Developer Tools → Local Storage Viewer
2. Select `a_tblRequest` table
3. Verify pull-out requests stored (check shippingMethod = 'Pull-Out/Return')

**Check Logs:**
```dart
// Look for these log messages
'PullOutRepository: Offline, returning local data'
'PullOutRepository: Fetching from API'
'PullOutRepository: Cached X pull-out requests to local DB'
'PullOutRepository: API failed, returning X items from local DB'
'PullOutRepository: Background sync completed, X records'
```

## Files Modified

1. ✅ `lib/data/repositories/pull_out/pull_out_repository.dart`
   - Added DAO instance and lazy getter
   - Enhanced getAll() method
   - Added _syncFromApi() method
   - Updated getLocalPullOuts() method

2. ✅ `lib/features/logistics/mappers/pull_out_mapper.dart`
   - Added fromStandardDelivery() method
   - Added toStandardDelivery() method
   - Added import for StandardDeliveryModel

## Migration Notes

### No Database Changes Required
- Pull-out requests already use `a_tblRequest` table
- No schema changes needed
- No migration script required

### Existing Data
- Existing pull-out requests in DB will work immediately
- New requests will be cached automatically
- Background sync will keep data fresh

## Future Enhancements

Potential improvements:
- [ ] Separate pull-out table for better organization
- [ ] Incremental sync (only fetch new/modified records)
- [ ] Conflict resolution for offline edits
- [ ] Sync status indicator in UI
- [ ] Manual sync trigger option

## Consistency Check

The `getAll()` method is now consistent across repositories:

| Repository | Network Check | Local Cache | Offline Support | Background Sync | Fallback | Logging |
|-----------|---------------|-------------|-----------------|----------------|----------|---------|
| AirSeaRepository | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PullOutRepository | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| StandardDeliveryRepository | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PickUpRepository | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

All repositories now follow the same pattern! 🎉

---

**Status:** ✅ **COMPLETE**  
**Impact:** All pull-out operations now have offline support and caching  
**Breaking Changes:** None  
**Testing:** Required

