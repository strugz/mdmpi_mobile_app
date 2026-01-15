# Quick Start Guide - Local Storage Data Viewer

## 5-Minute Setup ✅

The Local Storage Data Viewer is **already set up and ready to use!**

## How to Access

### Method 1: Through Settings (Recommended)
1. Launch the app
2. Navigate to **Settings** tab
3. Scroll down to **"Developer Tools"** section
4. Tap **"Local Storage Viewer"**

### Method 2: Direct Navigation (For Developers)
```dart
// Recommended: Direct widget navigation
Get.to(() => const LocalStorageDataViewer());

// Alternative: Named route (if configured)
Get.toNamed(BRoutes.localStorageViewer);
```

## Basic Usage

### View Table Data
1. Select a table from the dropdown
2. Data loads automatically
3. Tap any row to expand details

### Delete a Row
1. Swipe left on any row
2. Tap "Delete" in confirmation dialog

### Clear Entire Table
1. Tap the 🗑️ icon in the top-right
2. Confirm action

### Refresh Data
1. Tap the 🔄 icon next to row count

## Available Tables

| Table Name | Description |
|-----------|-------------|
| `a_tblRequest` | Standard delivery requests |
| `a_tblRequestPickUp` | Pick-up requests |
| `a_tblRequestAirSea` | Air/Sea shipment requests |
| `a_tblRequestDocumentReference` | Document references |
| `a_tblRequestRemarks` | Remarks and comments |
| `Users` | User accounts |
| `ACCMST_` | Account master data |
| `CNTMST` | Contact information |
| `a_tblMobile` | Vehicle/mobile data |
| `a_tblItemCategory` | Item categories |
| `a_tblFormCategory` | Form categories |
| `a_tblRequestReceiverSignature` | Receiver signatures |
| `a_tblRequestImage` | Request images |

## Common Tasks

### Check if local data exists
```
1. Open Local Storage Viewer
2. Select "a_tblRequest"
3. Check row count at top
```

### Clear all local requests
```
1. Select "a_tblRequest" table
2. Tap delete icon (top-right)
3. Confirm "Clear"
```

### View specific request details
```
1. Select appropriate table
2. Find the row by RequestID
3. Tap to expand
4. View all column values
```

### Debug synchronization issues
```
1. Check local data in viewer
2. Compare with server data
3. Clear table if needed
4. Re-sync from Settings > "Retrieve Request Data"
```

## Tips & Tricks

💡 **Pro Tips:**
- Long-press on any value to copy it
- Use the row count to verify sync status
- Clear tables before major testing
- Keep viewer open during development

⚠️ **Important:**
- Deleting data is permanent (no undo)
- Foreign key constraints may prevent deletion
- Large tables may take time to load

## Troubleshooting

### "No data in table"
**Solution:** Check if data was synced from server via Settings

### "Cannot delete row"
**Solution:** Check for foreign key constraints or dependency

### Table not updating
**Solution:** Tap the refresh button (🔄)

### App crashes when opening
**Solution:** Check if DatabaseHelper is initialized

### Navigation redirects to Home screen
**Solution:** 
- Use `Get.to(() => const LocalStorageDataViewer())` instead of `Get.toNamed()`
- The app's authentication middleware may interfere with named routes
- Direct widget navigation bypasses route guards

## Integration Examples

### Add Button to Your Screen
```dart
IconButton(
  icon: const Icon(Icons.storage),
  onPressed: () => Get.toNamed(BRoutes.localStorageViewer),
)
```

### Programmatic Access
```dart
// Import
import 'package:mdmpi_mobile_app/features/logistics/screens/data_test/data_test.dart';

// Navigate
Get.to(() => const LocalStorageDataViewer());

// Or with route
Get.toNamed(BRoutes.localStorageViewer);
```

### Check Table Before Operation
```dart
final controller = Get.put(LocalStorageDataController());
controller.selectTable('a_tblRequest');
await controller.loadTableData();
print('Row count: ${controller.tableData.length}');
```

## Next Steps

📚 **Learn More:**
- Read [README.md](./README.md) for detailed features
- Check [ARCHITECTURE.md](./ARCHITECTURE.md) for system design
- See [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) for technical details

🎯 **Common Workflows:**
1. **Testing sync:** Clear local → Sync from server → Verify in viewer
2. **Debugging issues:** View local data → Compare with API → Clear if needed
3. **Data inspection:** Select table → Browse rows → Copy values for testing

---

**Need Help?** Check the README.md file or contact the development team.

**Found a Bug?** Create an issue with steps to reproduce.

**Want to Contribute?** See the Future Enhancements section in README.md.

