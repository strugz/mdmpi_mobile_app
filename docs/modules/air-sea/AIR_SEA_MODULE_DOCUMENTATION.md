# Air/Sea Module - Complete Documentation

**Module**: Air/Sea Logistics Request Management  
**Version**: 2.0  
**Last Updated**: December 17, 2025  
**Status**: ✅ Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Status Flow](#status-flow)
3. [Role-Based Access Control](#role-based-access-control)
4. [Data Model](#data-model)
5. [Architecture](#architecture)
6. [Feature Implementations](#feature-implementations)
7. [UI Components](#ui-components)
8. [API Integration](#api-integration)
9. [Testing Guide](#testing-guide)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Air/Sea module manages logistics requests for air and sea freight shipments. It provides a complete workflow from request creation through delivery, with role-based access control, digital signatures, proof images, and real-time status tracking.

### Key Features

- ✅ Multi-role access control (Request, Release, Courier, Viewer)
- ✅ Complete status lifecycle management
- ✅ Digital signature capture at key handoff points
- ✅ Proof image documentation
- ✅ Waybill number tracking
- ✅ Dispatch information management
- ✅ Drop-off confirmation workflow
- ✅ Offline-first architecture with sync
- ✅ Real-time UI updates with GetX reactive pattern

---

## Status Flow

### Complete Status Progression

```
┌─────────────────┐
│  New Request    │ ← User creates request
└────────┬────────┘
         ↓
┌─────────────────────────┐
│ Getting Supplies Ready  │ ← Preparing items
└────────┬────────────────┘
         ↓
┌─────────────────┐
│  Item Packed    │ ← **3-WAY DECISION POINT**
└────────┬────────┘
         │
    ┌────┴────┬────────────┐
    │         │            │
    ↓         ↓            ↓
┌──────────┐ ┌──────────┐ ┌──────────┐
│Endorsed  │ │Received  │ │Dispatch  │
│to Guard  │ │(COMPLETE)│ │          │
└────┬─────┘ └──────────┘ └────┬─────┘
     │                          │
     ↓                          ↓
┌──────────┐              ┌──────────┐
│Received  │              │Drop Off  │
│(COMPLETE)│              │(COMPLETE)│
└──────────┘              └──────────┘
```

**Three Completion Paths:**

1. **Path A - Direct Received**: Item Packed → **Received** ✅ (COMPLETE)
2. **Path B - Via Guard**: Item Packed → Endorsed to Guard → **Received** ✅ (COMPLETE)
3. **Path C - Dispatch Flow**: Item Packed → Dispatch → **Drop Off** ✅ (COMPLETE)

### Status Definitions

| Status | Description | Next Actions | Required Data | Completion |
|--------|-------------|--------------|---------------|------------|
| **New Request** | Initial request created | Mark as "Getting Supplies Ready" | None | - |
| **Getting Supplies Ready** | Items being prepared | Mark as "Item Packed" | None | - |
| **Item Packed** | Items ready - **3 paths available** | Choose: "Received" OR "Endorsed to Guard" OR "Dispatch" | Status selection | - |
| **Endorsed to Guard** | Guard holds item (courier late) | Mark as "Received" (completes request) | Guard name, signature, proof image | - |
| **Received** | Courier picked up item | **REQUEST COMPLETE** | Receiver name, waybill #, signature, proof image | ✅ Path A & B |
| **Dispatch** | In transit to destination | Mark as "Drop Off" (completes request) | Trip ticket, driver, helper, vehicle | - |
| **Drop Off** | Delivered to recipient | **REQUEST COMPLETE** | Recipient name, signature, timestamp, proof image | ✅ Path C |

---

## Role-Based Access Control

### Role Priority

Lower number = Higher priority (more capabilities)

```
1. Release Role     - Most powerful, full workflow access
2. Courier Role     - Dispatch and drop-off management
3. Request Role     - Can only advance from "New Request"
4. Viewer Role      - Read-only access
```

### Role Capabilities Matrix

| Status | Request Role | Release Role | Courier Role | Viewer Role |
|--------|-------------|--------------|--------------|-------------|
| New Request | ✅ Can advance | ✅ Can advance | ❌ View only | ❌ View only |
| Getting Supplies Ready | ❌ View only | ✅ Can advance | ❌ View only | ❌ View only |
| Item Packed | ❌ View only | ✅ Can advance | ❌ View only | ❌ View only |
| Endorsed to Guard | ❌ View only | ✅ Can advance | ❌ View only | ❌ View only |
| Received | ❌ View only | ✅ View only | ❌ View only | ❌ View only |
| Dispatch | ❌ View only | ❌ View only | ✅ Can advance | ❌ View only |
| Drop Off | ❌ View only | ❌ View only | ❌ View only | ❌ View only |

### Multi-Role Handling

Users with multiple roles will be assigned actions based on the **highest priority role**. Only one action handler is invoked per tap to avoid duplicate dialogs.

**Implementation**: `air_sea_list.dart` - `_handleAirSeaTap()` function

---

## Data Model

### AirSeaModel Structure

```dart
class AirSeaModel {
  // Core fields
  String id;
  String clientId;
  String itemCategoryId;
  int? mobileId;
  String datePickUp;
  
  // Item preparation phase
  String itemPreparedAt;      // Timestamp: Getting Supplies Ready
  String itemPreparedEndAt;   // Timestamp: Item Packed
  String preparedBy;          // User who prepared
  
  // Guard endorsement phase
  String endorsedBy;          // Guard name (for "Endorsed to Guard")
  
  // Receipt phase
  String receivedBy;          // Receiver name (for "Received")
  String waybillNumber;       // Tracking number
  String receivedAt;          // Receipt timestamp
  
  // Dispatch phase
  String tripTicketNumber;    // Trip identifier
  String driver;              // Driver name
  String helper;              // Helper name
  String dispatchedAt;        // Dispatch timestamp
  String dropOffAt;           // Drop-off timestamp
  
  // Metadata
  String status;              // Current status
  String remarks;             // Additional notes
  String createdBy;           // Creator initial
  String createdAt;           // Creation timestamp
  String updatedAt;           // Last update timestamp
  
  // Aggregates
  ClientModel client;
  List<String> documentReference;
  CancelRemarksModel cancelRemarks;
}
```

### Field Usage by Status

| Field | Used At Status | Controller | Auto/Manual |
|-------|---------------|------------|-------------|
| `itemPreparedAt` | Getting Supplies Ready | - | Auto (timestamp) |
| `itemPreparedEndAt` | Item Packed | - | Auto (timestamp) |
| `endorsedBy` | Endorsed to Guard | `receivedByController` | Manual (guard name) |
| `receivedBy` | Received | `receivedByController` | Manual (receiver name) |
| `waybillNumber` | Received | `waybillNumberController` | Manual |
| `tripTicketNumber` | Dispatch | `tripTicketNumberController` | Manual |
| `driver` | Dispatch | `driverController` | Manual |
| `helper` | Dispatch | `helperController` | Manual |
| `dispatchedAt` | Dispatch | - | Auto (timestamp) |
| `dropOffAt` | Drop Off | - | Auto (timestamp) |

---

## Architecture

### GetX Architecture Pattern

```
┌───────────────┐
│   UI Layer    │  (Screens & Widgets)
│   - air_sea_  │
│     list.dart │
│   - air_sea_  │
│     modal.dart│
└───────┬───────┘
        │ Obx()
        ↓
┌───────────────┐
│  Controller   │  (State Management)
│   air_sea_    │
│   controller  │
│   .dart       │
└───────┬───────┘
        │
        ↓
┌───────────────┐
│   Helpers     │  (Business Logic)
│   - data_     │
│     manager   │
│   - filter_   │
│     manager   │
│   - form_state│
└───────┬───────┘
        │
        ↓
┌───────────────┐
│  Repository   │  (Data Access)
│   air_sea_    │
│   repository  │
│   .dart       │
└───────┬───────┘
        │
    ┌───┴───┐
    ↓       ↓
┌────────┐ ┌────────┐
│  API   │ │  DAO   │
│ Remote │ │ Local  │
└────────┘ └────────┘
```

### Key Components

#### 1. **Controller** (`air_sea_controller.dart`)
- Manages reactive state with GetX Rx types
- Coordinates between UI and business logic
- Handles form state and validation

#### 2. **Data Manager** (`air_sea_data_manager.dart`)
- Contains core business logic for status updates
- Handles signature and image uploads
- Manages timestamp auto-capture
- Coordinates API and database operations

#### 3. **Filter Manager** (`air_sea_filter_manager.dart`)
- Handles request filtering by status
- Manages search functionality

#### 4. **Form State** (`air_sea_form_state.dart`)
- Centralizes form controllers
- Manages signature bytes and base64 encoding
- Handles form cleanup

#### 5. **Role Handlers** (`air_sea_role_handler.dart`)
- Implements role-specific action logic
- Strategy pattern for different user roles
- Prevents duplicate dialogs for multi-role users

#### 6. **Repository** (`air_sea_repository.dart`)
- Abstracts data sources (API + Local DB)
- Handles offline/online sync
- Manages CRUD operations

#### 7. **DAO** (`air_sea_dao.dart`)
- Direct database access layer
- SQLite operations
- Data persistence

---

## Feature Implementations

### 1. Item Packed Status - Three Path Selection

**Location**: `lib/features/logistics/screens/air_sea/widgets/air_sea_item_packed_section.dart`

When status is "Item Packed", users can choose between **three paths**:

#### Path A: Direct Received (Completes Request)
**Use Case**: Courier arrives on time; direct pickup and immediate completion

**Required Fields**:
- Receiver name (text input)
- Waybill number (text input)
- Receiver signature (digital capture)
- Proof image (camera capture)

**Implementation**:
```dart
if (selectedStatus == 'Received') {
  return _buildReceiverFields();
}
```

**Data Flow**:
```
User selects "Received"
  ↓
Enters receiver name → formState.receivedByController
Enters waybill number → formState.waybillNumberController
  ↓
Captures signature → formState.receiverSignatureBytes
  ↓
Captures proof image → CameraController.imageProofPath
  ↓
Submits → Updates status to "Received"
  ↓
Saves receivedBy = receiver name, waybillNumber
  ↓
✅ REQUEST COMPLETE (Path A)
```

#### Path B: Endorsed to Guard → Received (Completes Request)
**Use Case**: Courier is late; guard holds item temporarily, then courier picks up later

**Required Fields (Endorsed to Guard)**:
- Guard name (text input)
- Guard signature (digital capture)
- Proof image (camera capture)

**Implementation**:
```dart
if (selectedStatus == 'Endorsed to Guard') {
  return _buildGuardFields();
}
```

**Data Flow**:
```
User selects "Endorsed to Guard"
  ↓
Enters guard name → formState.receivedByController
  ↓
Captures signature → formState.receiverSignatureBytes
  ↓
Captures proof image → CameraController.imageProofPath
  ↓
Submits → Updates status to "Endorsed to Guard"
  ↓
Saves endorsedBy = guard name
  ↓
(Later) User marks as "Received" with waybill number
  ↓
✅ REQUEST COMPLETE (Path B)
```

#### Path C: Dispatch → Drop Off (Completes Request)
**Use Case**: Item needs to be dispatched for delivery to final destination

**Required Fields (Dispatch)**:
- Trip ticket number
- Driver name
- Helper name
- Vehicle information (optional)

**Implementation**:
```dart
if (selectedStatus == 'Dispatch') {
  return AirSeaDispatchInfoSection(requestModel: requestModel);
}
```

**Data Flow**:
```
User selects "Dispatch"
  ↓
Enters trip ticket → tripTicketNumberController
Enters driver → driverController
Enters helper → helperController
  ↓
Auto-captures dispatchedAt timestamp
  ↓
Updates status to "Dispatch"
  ↓
(Later) User marks as "Drop Off" at destination
  ↓
Captures recipient signature and proof image
  ↓
✅ REQUEST COMPLETE (Path C)
```

---

### 2. Waybill Number Input

**Location**: `lib/features/logistics/screens/air_sea/widgets/air_sea_waybill_input_section.dart`

**Purpose**: Capture waybill tracking number when transitioning from "Endorsed to Guard" to "Received"

**Implementation**:
```dart
if (requestModel.status == BTexts.statusEndorsedToGuard) {
  AirSeaWaybillInputSection(requestModel: requestModel)
}
```

**Features**:
- Text input field for waybill number
- Scanner button integration (future enhancement)
- Validation for required field
- Auto-focus on display

---

### 3. Signature Capture

**Locations**:
- `lib/base/utils/popups/signature_capture_dialog.dart` (Dialog)
- `lib/base/utils/popups/full_screen_loader.dart` (Air/Sea specific method)

**Statuses Using Signatures**:
- Endorsed to Guard (guard signature)
- Received (receiver signature)
- Drop Off (recipient signature)

**Implementation Pattern**:
```dart
TextButton.icon(
  onPressed: () => BFullScreenLoader.showSignatureDialogForAirSea(
    context,
    controller,
  ),
  icon: Icon(hasSignature ? Iconsax.document_upload : Iconsax.edit),
  label: Text(hasSignature 
    ? 'Signature Captured (Tap to Redo)' 
    : 'Capture Signature'),
)
```

**Data Storage**:
- Local: `formState.receiverSignatureBytes` (Uint8List)
- Base64: `formState.receiverSignatureBase64` (String)
- Upload: API endpoint with type = 'Signature'

---

### 4. Proof Image Capture

**Location**: `lib/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart`

**Statuses Using Proof Images**:
- Endorsed to Guard (guard receipt proof)
- Received (delivery proof)
- Drop Off (drop-off proof)

**Implementation Pattern**:
```dart
IconButton(
  onPressed: () => Get.to(
    () => BDropOffCapture(
      title: 'Proof Picture',
      onCapture: (camera) async => 
        camera.takePictureWithAnimation(requestModel.id),
    ),
  ),
  icon: Icon(Iconsax.camera, size: 25),
)
```

**Image Storage**:
- Local file: `BPaths.deliveryShots/{requestId}.jpg`
- Controller: `CameraHandlerController.imageProofPath`
- Upload: API endpoint with type = 'Proof'

---

### 5. Dispatch Information

**Location**: `lib/features/logistics/screens/air_sea/widgets/air_sea_dispatch_info_section.dart`

**Purpose**: Capture dispatch details when status is "Received"

**Required Fields**:
- Trip ticket number
- Driver name
- Helper name
- Vehicle information (optional)

**Implementation**:
```dart
if (requestModel.status == BTexts.statusReceived) {
  AirSeaDispatchInfoSection(requestModel: requestModel)
}
```

**Data Flow**:
```
User marks as "Dispatch"
  ↓
Enters trip ticket → tripTicketNumberController
Enters driver → driverController
Enters helper → helperController
  ↓
Auto-captures dispatchedAt timestamp
  ↓
Updates status to "Dispatch"
```

---

### 6. Drop Off Confirmation

**Location**: `lib/features/logistics/screens/air_sea/widgets/air_sea_drop_off_section.dart`

**Purpose**: Confirm delivery with recipient details

**Required Fields** (4 Total):
1. ✅ ReceivedBy Name (manual input)
2. ✅ Receiver Signature (digital capture)
3. ✅ DropOffAt Timestamp (auto-captured)
4. ✅ Proof Image (camera capture)

**Implementation**:
```dart
if (requestModel.status == 'Drop Off') {
  AirSeaDropOffSection(requestModel: requestModel)
}
```

**Visual Layout**:
```
╔═══════════════════════════════════╗
║  === Drop Off Confirmation ===   ║
╠═══════════════════════════════════╣
║        📷 Camera Icon             ║
║    "Proof of Drop Off"           ║
║   (image path if captured)       ║
╠═══════════════════════════════════╣
║  Received By: [Text Input]       ║
╠═══════════════════════════════════╣
║   [Capture Signature Button]     ║
║   (Signature preview if exists)  ║
╚═══════════════════════════════════╝
```

---

### 7. Modal Display - Signature & Proof Image Viewing

**Location**: `lib/features/logistics/screens/air_sea/widgets/air_sea_modal_header.dart`

**Purpose**: Display captured signatures and proof images in modal view

**Implementation for Guard Endorsement**:
```dart
if (requestModel.status == BTexts.statusEndorsedToGuard) {
  const BTextDivider(text: 'Guard Endorsement'),
  BLabelValueText(
    label: 'Endorsed To (Guard)',
    value: requestModel.receivedBy,  // Note: Uses receivedBy field
    icon: Iconsax.user_octagon,
  ),
  BLabelValueText(
    label: 'Endorsed at',
    value: _formatDate(requestModel.updatedAt),
    icon: Iconsax.calendar_1,
  ),
  CapturedSignatureImage(requestId: requestModel.id),
  ViewDeliveredItemButton(
    labelTitle: 'View Guard Receipt Proof',
    onPressed: () => showRequestImageDialog(...)
  )
}
```

**Image Loading Strategy**:
1. Try loading from local database first
2. If not found, load from API
3. Display loading indicator while fetching
4. Show error widget if failed

---

## UI Components

### Widget Hierarchy

```
AirSeaList
├── AirSeaRequestCard (for each request)
│   └── InkWell (handles tap → opens modal)
│
Modal (opened on tap)
├── AirSeaModal
│   ├── AirSeaModalHeader (displays request info)
│   │   ├── Status badge
│   │   ├── Client info
│   │   ├── Guard Endorsement section (conditional)
│   │   ├── Receipt Details section (conditional)
│   │   ├── Dispatch Details section (conditional)
│   │   ├── CapturedSignatureImage (conditional)
│   │   └── ViewDeliveredItemButton (conditional)
│   │
│   └── AirSeaRequestModalFooter (status actions)
│       ├── AirSeaItemPackedSection (if Item Packed)
│       ├── AirSeaWaybillInputSection (if Endorsed to Guard)
│       ├── AirSeaDispatchInfoSection (if Received)
│       ├── AirSeaDropOffSection (if Drop Off)
│       └── Action buttons
```

### Reusable Widgets

| Widget | Location | Purpose |
|--------|----------|---------|
| `BDropdown` | `lib/common/widgets/dropdown/dropdown.dart` | Status selection dropdown |
| `BTextFormField` | `lib/common/widgets/form/b_text_form_field.dart` | Text input fields |
| `BTextDivider` | `lib/common/widgets/` | Section dividers |
| `BSignatureCaptureDialog` | `lib/base/utils/popups/signature_capture_dialog.dart` | Signature capture |
| `BDropOffCapture` | `lib/features/logistics/screens/request_transport/widgets/` | Camera capture |
| `CapturedSignatureImage` | `lib/features/logistics/screens/standard_delivery/widgets/` | Signature display |
| `ViewDeliveredItemButton` | `lib/common/widgets/` | Proof image button |

---

## API Integration

### Endpoints

#### 1. Get Air/Sea Requests
```
GET /api4/RequestAirSea
Response: List<AirSeaDTO>
```

#### 2. Create Request
```
POST /api4/RequestAirSea
Body: AirSeaInsertDTO
Response: AirSeaModel
```

#### 3. Update Request Status
```
PUT /api4/RequestAirSea/{id}
Body: AirSeaUpdateDTO
Response: Success/Error
```

#### 4. Upload Signature
```
POST /api4/Request/image
Query Params:
  - requestid: String
  - type: 'Signature'
Body: Base64 encoded image
Response: Success/Error
```

#### 5. Upload Proof Image
```
POST /api4/Request/image
Query Params:
  - requestid: String
  - type: 'Proof'
Body: Base64 encoded image
Response: Success/Error
```

#### 6. Get Image
```
GET /api4/Request/image
Query Params:
  - requestid: String
  - type: 'Signature' | 'Proof'
Response: Image bytes (JPEG/PNG)
```

### DTO Structure

#### AirSeaUpdateDTO
```dart
class AirSeaUpdateDTO {
  final String id;
  final String? status;
  final String? endorsedBy;
  final String? receivedBy;
  final String? waybillNumber;
  final String? tripTicketNumber;
  final String? driver;
  final String? helper;
  final String? receivedAt;
  final String? dispatchedAt;
  final String? dropOffAt;
  final String? remarks;
  final String updatedAt;
}
```

### Sync Strategy

#### Online Mode
```
User action
  ↓
Update local database
  ↓
Send API request
  ↓
Upload signature (if present)
  ↓
Upload proof image (if present)
  ↓
Show success message
```

#### Offline Mode
```
User action
  ↓
Update local database
  ↓
Queue for sync
  ↓
Show "Saved locally" message
  ↓
When connection restored:
  ↓
Auto-sync queued updates
  ↓
Upload images
```

---

## Testing Guide

### Unit Test Scenarios

#### 1. Status Flow Testing
```dart
test('Status progresses from New Request to Getting Supplies Ready', () {
  // Arrange
  final request = AirSeaModel(status: BTexts.statusNewRequest);
  
  // Act
  controller.updateStatusWithInputs(request, BTexts.statusGettingSuppliesReady);
  
  // Assert
  expect(request.status, equals(BTexts.statusGettingSuppliesReady));
  expect(request.itemPreparedAt, isNotEmpty);
});
```

#### 2. Role Handler Testing
```dart
test('Request role can only advance from New Request', () {
  // Arrange
  final handler = AirSeaRequestRoleHandler();
  final request = AirSeaModel(status: BTexts.statusItemPacked);
  
  // Act
  handler.handleAction(context, request, controller, userController, 'USR');
  
  // Assert
  // Verify modal opens in read-only mode
});
```

#### 3. Signature Upload Testing
```dart
test('Signature uploads with correct type', () async {
  // Arrange
  final bytes = Uint8List.fromList([1, 2, 3]);
  final base64 = base64Encode(bytes);
  
  // Act
  await ImageRepository.instance.uploadFile(
    requestId: 'test-id',
    base64Image: base64,
    type: 'Signature',
  );
  
  // Assert
  verify(apiCall).called(1);
});
```

### Integration Test Scenarios

#### Scenario 1: Path A - Direct Received (Complete)
```
1. Create request (status: New Request)
2. Mark as "Getting Supplies Ready"
3. Mark as "Item Packed"
4. Select "Received" from dropdown
5. Enter receiver name
6. Enter waybill number
7. Capture receiver signature
8. Capture proof image
9. Submit
10. Verify status = "Received"
11. Verify all fields saved
12. Verify images uploaded
13. ✅ Verify request is COMPLETE (Path A)
```

#### Scenario 2: Path B - Via Guard then Received (Complete)
```
1. Create request (status: New Request)
2. Mark as "Getting Supplies Ready"
3. Mark as "Item Packed"
4. Select "Endorsed to Guard" from dropdown
5. Enter guard name
6. Capture guard signature
7. Capture proof image
8. Submit
9. Verify status = "Endorsed to Guard"
10. Open request again
11. Enter waybill number
12. Mark as "Received"
13. Capture receiver signature
14. Capture proof image
15. Submit
16. Verify status = "Received"
17. Verify all fields saved (guard + receiver data)
18. ✅ Verify request is COMPLETE (Path B)
```

#### Scenario 3: Path C - Dispatch then Drop Off (Complete)
```
1. Create request (status: New Request)
2. Mark as "Getting Supplies Ready"
3. Mark as "Item Packed"
4. Select "Dispatch" from dropdown
5. Enter dispatch details:
   - Trip ticket number
   - Driver name
   - Helper name
6. Submit
7. Verify status = "Dispatch"
8. Verify dispatchedAt timestamp set
9. Open request again (as Courier role)
10. Capture drop-off proof image
11. Enter recipient name
12. Capture recipient signature
13. Submit
14. Verify status = "Drop Off"
15. Verify dropOffAt timestamp set
16. Verify all fields saved
17. ✅ Verify request is COMPLETE (Path C)
```

### Manual Testing Checklist

#### UI Testing
- [ ] All status cards display correctly
- [ ] Pull-to-refresh works
- [ ] Long press shows remarks dialog
- [ ] Modal opens on tap
- [ ] Status badge shows correct color
- [ ] Signatures display properly
- [ ] Proof images open in fullscreen
- [ ] Dark mode compatibility
- [ ] Loading indicators show during operations
- [ ] Error messages display appropriately

#### Role-Based Testing
- [ ] Request role: Can only advance "New Request"
- [ ] Release role: Full workflow access
- [ ] Courier role: Can handle Dispatch → Drop Off
- [ ] Viewer role: Read-only access
- [ ] Multi-role users: Highest priority role applies

#### Data Integrity Testing
- [ ] Timestamps auto-capture correctly
- [ ] Signatures persist in database
- [ ] Images save to correct file paths
- [ ] Waybill number saves correctly
- [ ] Dispatch info persists
- [ ] Status transitions follow rules
- [ ] No data loss on app restart

#### Offline Testing
- [ ] Can create requests offline
- [ ] Can update status offline
- [ ] Signatures save locally
- [ ] Images save locally
- [ ] Sync queue works when back online
- [ ] No duplicate uploads after sync

---

## Troubleshooting

### Common Issues

#### 1. Signature Not Displaying
**Symptoms**: Empty space where signature should be

**Possible Causes**:
- Image not uploaded to API
- Local database entry missing
- Network error during load

**Solutions**:
```dart
// Check local database
final localSig = await AirSeaDao.instance.getSignature(requestId);

// Check API response
final apiSig = await ImageRepository.instance.getImage(requestId, 'Signature');

// Verify base64 encoding
final isValidBase64 = RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(base64String);
```

#### 2. Proof Image Upload Failed
**Symptoms**: Error message "Image upload failed"

**Possible Causes**:
- Image file not found
- Base64 encoding error
- API timeout
- Network connectivity

**Solutions**:
```dart
// Verify file exists
final file = File('${BPaths.deliveryShots}/$requestId.jpg');
final exists = await file.exists();

// Check file size (max 5MB)
final size = await file.length();

// Retry upload with exponential backoff
await retry(() => uploadImage(), maxAttempts: 3);
```

#### 3. Status Update Not Reflecting
**Symptoms**: UI doesn't update after status change

**Possible Causes**:
- Reactive state not triggered
- Controller not refreshing list
- Database update failed

**Solutions**:
```dart
// Force refresh
controller.loadAirSeaRequests();

// Check reactive state
print('Status: ${controller.currentSelectedAirSea.value.status}');

// Verify database
final dbStatus = await AirSeaDao.instance.getById(requestId);
print('DB Status: ${dbStatus.status}');
```

#### 4. Multiple Dialogs Opening
**Symptoms**: Dialog appears multiple times for one tap

**Possible Causes**:
- Multi-role user triggering multiple handlers
- Missing role priority logic

**Solution**:
- Verify `_handleAirSeaTap()` in `air_sea_list.dart` uses priority selection
- Only invoke highest-priority handler

#### 5. Waybill Number Not Saving
**Symptoms**: Waybill field empty after save

**Possible Causes**:
- Controller text not read before submit
- DTO not including waybill field
- Database column missing

**Solutions**:
```dart
// Check controller before submit
print('Waybill: ${controller.formState.waybillNumberController.text}');

// Verify DTO
final dto = AirSeaUpdateDTO(
  waybillNumber: controller.formState.waybillNumberController.text,
  // ...
);

// Check database schema
SELECT waybillNumber FROM request_air_sea WHERE id = ?;
```

---

## Performance Optimization

### Best Practices

#### 1. Lazy Loading
```dart
// Load requests on demand
Get.lazyPut(() => AirSeaController(), fenix: true);
```

#### 2. Image Caching
```dart
// Use CachedNetworkImage for signatures
CachedNetworkImage(
  imageUrl: apiUrl,
  cacheKey: 'sig_$requestId',
  memCacheWidth: 300,
  memCacheHeight: 150,
);
```

#### 3. Minimal Obx Wrappers
```dart
// ❌ Bad: Wraps entire list
Obx(() => ListView(...))

// ✅ Good: Wraps only changing part
ListView.builder(
  itemBuilder: (_, index) {
    return Obx(() => 
      AirSeaRequestCard(item: items[index])
    );
  }
)
```

#### 4. Debounce Search
```dart
// Prevent excessive filtering
Timer? _debounce;
void onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 500), () {
    controller.filterRequests(query);
  });
}
```

---

## Future Enhancements

### Planned Features

1. **QR Code Scanner for Waybill**
   - Integrate barcode scanner
   - Auto-fill waybill number

2. **GPS Tracking**
   - Capture location on drop-off
   - Show delivery map

3. **Push Notifications**
   - Notify on status changes
   - Alert for overdue deliveries

4. **Analytics Dashboard**
   - Delivery time metrics
   - Courier performance stats

5. **Batch Operations**
   - Mark multiple requests
   - Bulk status updates

6. **OCR for Documents**
   - Scan waybill from image
   - Extract data automatically

---

## Appendix

### Constants Reference

**Status Constants** (`lib/base/utils/constants/text_string.dart`):
```dart
static const String statusNewRequest = 'New Request';
static const String statusGettingSuppliesReady = 'Getting Supplies Ready';
static const String statusItemPacked = 'Item Packed';
static const String statusEndorsedToGuard = 'Endorsed to Guard';
static const String statusReceived = 'Received';
static const String statusDispatch = 'Dispatch';
static const String statusDropOff = 'Drop Off';
```

**Role Constants**:
```dart
static const String roleRequest = 'Request';
static const String roleRelease = 'Release';
static const String roleCourier = 'Courier';
static const String roleViewer = 'Viewer';
```

### Database Schema

**Table: request_air_sea**
```sql
CREATE TABLE request_air_sea (
  id TEXT PRIMARY KEY,
  clientId TEXT NOT NULL,
  itemCategoryId TEXT NOT NULL,
  mobileId INTEGER,
  datePickUp TEXT,
  itemPreparedAt TEXT,
  itemPreparedEndAt TEXT,
  preparedBy TEXT,
  endorsedBy TEXT,
  receivedBy TEXT,
  waybillNumber TEXT,
  receivedAt TEXT,
  tripTicketNumber TEXT,
  driver TEXT,
  helper TEXT,
  dispatchedAt TEXT,
  dropOffAt TEXT,
  status TEXT NOT NULL,
  remarks TEXT,
  createdBy TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
```

### File Structure

```
lib/features/logistics/
├── controllers/
│   └── air_sea_controller.dart
├── models/
│   └── air_sea_model.dart
├── dtos/air_sea/
│   ├── air_sea_dto.dart
│   ├── air_sea_insert_dto.dart
│   └── air_sea_update_dto.dart
├── helpers/
│   ├── air_sea_data_manager.dart
│   ├── air_sea_filter_manager.dart
│   └── air_sea_form_state.dart
├── mappers/
│   └── air_sea_mapper.dart
├── screens/air_sea/
│   ├── air_sea_list.dart
│   ├── air_sea_request_card.dart
│   └── widgets/
│       ├── air_sea_modal.dart
│       ├── air_sea_modal_header.dart
│       ├── air_sea_request_modal_footer.dart
│       ├── air_sea_item_packed_section.dart
│       ├── air_sea_waybill_input_section.dart
│       ├── air_sea_dispatch_info_section.dart
│       └── air_sea_drop_off_section.dart
├── services/implementations/
│   └── air_sea_role_handler.dart
└── screens/request_forms/widgets/
    └── air_sea_form.dart

lib/data/
├── repositories/air_sea/
│   └── air_sea_repository.dart
└── local/dao/air_sea/
    └── air_sea_dao.dart
```

---

## Support & Contribution

### Getting Help

1. Check this documentation first
2. Review related module implementations (Pick Up, Pull Out)
3. Check the troubleshooting section
4. Contact the development team

### Contributing

When modifying the Air/Sea module:

1. **Follow Architecture**:
   - Use GetX reactive pattern
   - Keep UI pure (no business logic in build methods)
   - Use dependency injection

2. **Code Quality**:
   - Run `flutter analyze` before commit
   - Add unit tests for new features
   - Update this documentation

3. **Documentation**:
   - Add `///` doc comments for public methods
   - Update this file with new features
   - Document breaking changes

4. **Testing**:
   - Test all status transitions
   - Test with multiple roles
   - Test offline functionality
   - Verify image uploads

---

**End of Documentation**

*This document consolidates all Air/Sea module implementation details, workflows, and best practices.*

*Last Reviewed: December 17, 2025*
*Module Version: 2.0*
*Status: ✅ Production Ready*

