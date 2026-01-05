# Local Storage Data Viewer - File Structure

```
lib/features/logistics/screens/data_test/
│
├── data_test.dart                         # Barrel export file
├── local_storage_data_viewer.dart         # Main UI widget (179 lines)
├── local_storage_data_controller.dart     # GetX controller (181 lines)
├── README.md                               # Feature documentation
└── IMPLEMENTATION_SUMMARY.md              # Implementation details

Related Modified Files:
│
├── lib/base/utils/routes/
│   ├── routes.dart                         # Added localStorageViewer route
│   └── app_routes.dart                     # Added GetPage configuration
│
└── lib/features/personalization/screens/settings/
    └── settings.dart                       # Added Developer Tools section
```

## Component Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     Settings Screen                         │
│  ┌───────────────────────────────────────────────────┐      │
│  │         Developer Tools Section                   │      │
│  │  ┌──────────────────────────────────────────┐     │      │
│  │  │  Local Storage Viewer Menu Item          │     │      │
│  │  └────────────────┬─────────────────────────┘     │      │
│  └───────────────────┼───────────────────────────────┘      │
└────────────────────┼─────────────────────────────────────────┘
                     │
                     │ Get.toNamed(BRoutes.localStorageViewer)
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          LocalStorageDataViewer (Widget)                    │
│  ┌───────────────────────────────────────────────────┐      │
│  │  App Bar with Clear Table Action                  │      │
│  ├───────────────────────────────────────────────────┤      │
│  │  Table Dropdown Selector (13 tables)              │      │
│  ├───────────────────────────────────────────────────┤      │
│  │  Row Count & Refresh Button                       │      │
│  ├───────────────────────────────────────────────────┤      │
│  │  ┌──────────────────────────────────────┐         │      │
│  │  │  ListView of Dismissible Cards       │         │      │
│  │  │  ┌────────────────────────────────┐  │         │      │
│  │  │  │  Row 1 - ExpansionTile         │  │         │      │
│  │  │  │  ├─ Column1: Value1            │  │         │      │
│  │  │  │  ├─ Column2: Value2            │  │         │      │
│  │  │  │  └─ Column3: Value3            │  │         │      │
│  │  │  └────────────────────────────────┘  │         │      │
│  │  │  ┌────────────────────────────────┐  │         │      │
│  │  │  │  Row 2 - ExpansionTile         │  │         │      │
│  │  │  └────────────────────────────────┘  │         │      │
│  │  └──────────────────────────────────────┘         │      │
│  └───────────────────────────────────────────────────┘      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Uses Obx() for reactivity
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│      LocalStorageDataController (GetX Controller)           │
│  ┌───────────────────────────────────────────────────┐      │
│  │  State:                                            │      │
│  │  • selectedTable (RxString)                        │      │
│  │  • tableData (RxList<Map<String, dynamic>>)       │      │
│  │  • isLoading (RxBool)                              │      │
│  ├───────────────────────────────────────────────────┤      │
│  │  Methods:                                          │      │
│  │  • selectTable(String)                             │      │
│  │  • loadTableData()                                 │      │
│  │  • deleteRow(Map<String, dynamic>)                 │      │
│  │  • clearTable()                                    │      │
│  │  • getColumnNames()                                │      │
│  │  • getTableStats()                                 │      │
│  └───────────────────────────────────────────────────┘      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Accesses via DatabaseHelper.instance
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              DatabaseHelper (Singleton)                     │
│  ┌───────────────────────────────────────────────────┐      │
│  │  SQLite Database Access                            │      │
│  │  • db.query(tableName)                             │      │
│  │  • db.delete(tableName, where: ...)               │      │
│  │  • db.rawQuery(...)                                │      │
│  └───────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Loading Data
```
User selects table
    ↓
Controller.selectTable(tableName)
    ↓
Controller.loadTableData()
    ↓
DatabaseHelper.instance.database
    ↓
db.query(tableName)
    ↓
tableData.addAll(result)
    ↓
UI updates via Obx()
```

### Deleting Row
```
User swipes row
    ↓
Confirmation dialog
    ↓
Controller.deleteRow(row)
    ↓
Find primary key
    ↓
db.delete(tableName, where: 'pk = ?')
    ↓
Controller.loadTableData() (refresh)
    ↓
UI updates
```

### Clear Table
```
User taps clear icon
    ↓
Confirmation dialog
    ↓
Controller.clearTable()
    ↓
db.delete(tableName)
    ↓
Controller.loadTableData() (refresh)
    ↓
UI updates
```

## Navigation Flow

```
App Start
    ↓
Navigation Menu
    ↓
Settings Tab
    ↓
[Data Settings Section]
    • Upload Data
    • Retrieve Request Data
    • Reload Client List
    • Reload Users List
    • Reload Vehicle List
    ↓
[Developer Tools Section]  ← NEW
    • Local Storage Viewer  ← NEW
        ↓
        LocalStorageDataViewer Screen
            • Table Selection
            • View Data
            • Delete Rows
            • Clear Table
```

## Dependencies Graph

```
LocalStorageDataViewer
    ├── flutter/material.dart
    ├── get/get.dart
    ├── local_storage_data_controller.dart
    ├── common/widgets/appbar/appbar.dart
    ├── base/utils/constants/sizes.dart
    └── base/utils/constants/colors.dart

LocalStorageDataController
    ├── flutter/material.dart
    ├── get/get.dart
    ├── sqflite/sqflite.dart
    ├── data/local/database_helper.dart
    └── base/utils/logger.dart

Routes Integration
    ├── base/utils/routes/routes.dart
    └── base/utils/routes/app_routes.dart

Settings Integration
    └── features/personalization/screens/settings/settings.dart
```

## Database Tables (13 Total)

```
Request-Related Tables (5):
├── a_tblRequest                      # Main delivery requests
├── a_tblRequestDocumentReference     # Document references
├── a_tblRequestReceiverSignature     # Receiver signatures
├── a_tblRequestImage                 # Request images
└── a_tblRequestRemarks               # Remarks/comments

Module-Specific Tables (2):
├── a_tblRequestPickUp                # Pick-up requests
└── a_tblRequestAirSea                # Air/Sea requests

Master Data Tables (4):
├── ACCMST_                           # Account master
├── a_tblMobile                       # Mobile/Vehicle data
├── CNTMST                            # Contact master
```
└── a_tblFormCategory                 # Form categories
├── a_tblItemCategory                 # Item categories
Category Tables (2):

└── Users                             # User accounts

