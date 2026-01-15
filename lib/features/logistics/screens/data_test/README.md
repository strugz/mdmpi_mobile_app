# Local Storage Data Viewer

## Overview

The Local Storage Data Viewer is a debug/testing tool that allows developers to inspect and manage data stored in the app's SQLite database during development.

## Features

### 1. **Table Selection**
- Dropdown menu to select from all available database tables
- Automatically loads data when a table is selected

### 2. **Data Display**
- Shows all rows from the selected table
- Expandable cards with full row details
- Column names and values displayed in a formatted view
- Selectable text for easy copying

### 3. **Data Management**
- **Swipe to Delete**: Swipe left on any row to delete it (with confirmation)
- **Clear Table**: Button in the app bar to clear all data from the selected table
- **Refresh**: Reload data from the selected table

### 4. **Available Tables**
- `a_tblRequest` - Standard delivery requests
- `a_tblRequestDocumentReference` - Document references for requests
- `a_tblRequestReceiverSignature` - Receiver signatures
- `a_tblRequestImage` - Request images
- `a_tblRequestRemarks` - Request remarks/comments
- `a_tblRequestPickUp` - Pick-up requests
- `a_tblRequestAirSea` - Air/Sea requests
- `ACCMST_` - Account master data
- `a_tblMobile` - Mobile device data
- `Users` - User accounts
- `CNTMST` - Contact master data
- `a_tblItemCategory` - Item categories
- `a_tblFormCategory` - Form categories

## Usage

### Accessing the Viewer

Navigate to the Local Storage Data Viewer using:

```dart
// Recommended: Direct widget navigation
Get.to(() => const LocalStorageDataViewer());
```

**Note:** Use `Get.to()` instead of `Get.toNamed()` to avoid authentication redirect issues.

Or directly:

```dart
Get.to(() => const LocalStorageDataViewer());
```

### Viewing Data

1. Open the Local Storage Data Viewer
2. Select a table from the dropdown menu
3. Browse the list of rows
4. Tap on a row to expand and view all column details

### Deleting Data

**Single Row:**
1. Swipe left on a row
2. Confirm the deletion
3. The row will be removed from the database

**Clear Table:**
1. Tap the delete sweep icon in the app bar
2. Confirm the action
3. All data in the selected table will be deleted

## Architecture

### Files

- **`local_storage_data_viewer.dart`** - Main widget for displaying data
- **`local_storage_data_controller.dart`** - Controller managing state and database operations

### Controller Methods

```dart
// Select and load a table
void selectTable(String tableName);

// Reload current table data
Future<void> loadTableData();

// Get column names for a table
Future<List<String>> getColumnNames();

// Delete a specific row
Future<void> deleteRow(Map<String, dynamic> row);

// Clear all data from the selected table
Future<void> clearTable();

// Get table statistics
Future<Map<String, dynamic>> getTableStats();
```

## Implementation Details

### Database Access

The viewer uses `DatabaseHelper.instance` to access the SQLite database directly through raw queries:

```dart
final db = await _dbHelper.database;
final result = await db.query(selectedTable.value);
```

### State Management

Uses GetX for reactive state management:
- `selectedTable` - Currently selected table name
- `tableData` - List of rows from the selected table
- `isLoading` - Loading state indicator

### UI Components

- **BAppBar** - Custom app bar with actions
- **FilterDropdown** - Reusable dropdown for table selection
- **Card with ExpansionTile** - Expandable row display
- **Dismissible** - Swipe-to-delete functionality

## Best Practices

1. **Development Only**: This tool is intended for development and testing only
2. **Data Safety**: Always confirm before deleting data
3. **Performance**: Large tables may take time to load
4. **Refresh**: Use the refresh button after making changes elsewhere in the app

## Adding New Tables

To add a new table to the viewer:

1. Add the table name to `availableTables` in `LocalStorageDataController`:

```dart
final List<String> availableTables = [
  // ...existing tables...
  'your_new_table_name',
];
```

2. Ensure the table exists in `db_schema.dart`

## Troubleshooting

### Table Shows No Data
- Verify the table exists in the database
- Check if data has been inserted
- Use the refresh button to reload

### Delete Not Working
- Ensure the table has a primary key
- Check database constraints (foreign keys may prevent deletion)

### Performance Issues
- Large tables (1000+ rows) may be slow to load
- Consider adding pagination for very large tables

## Future Enhancements

Potential improvements:
- Search/filter within table data
- Export data to JSON/CSV
- Import data from files
- Pagination for large tables
- Query builder interface
- Data editing capabilities

## Related Files

- `lib/data/local/database_helper.dart` - Database helper singleton
- `lib/data/local/db_schema.dart` - Database schema definitions
- `lib/base/utils/routes/routes.dart` - Route constants
- `lib/base/utils/routes/app_routes.dart` - Route configurations

