# Air/Sea Item Packed Section - Proof Image Capture Feature

## Objective
Add proof image capture functionality to the `air_sea_item_packed_section.dart` widget, following the same pattern used in the `pick_up` and `request_transport` modules.

## Current State
The `AirSeaItemPackedSection` widget currently handles:
- Status dropdown selection ("Endorsed to Guard" or "Received")
- Guard name and signature capture (for "Endorsed to Guard")
- Receiver name, waybill number, and signature capture (for "Received")

## Requirements

### 1. Add Proof Image Capture Button
Add a camera icon button for capturing proof images, similar to the implementation in `b_request_details.dart` (request_transport module).

**Location**: Add the camera button in both status branches:
- **"Endorsed to Guard"**: After guard signature capture
- **"Received"**: After receiver signature capture and waybill number

### 2. UI Components Needed
Based on `b_request_details.dart` implementation (lines 70-88):

```dart
Center(
  child: Column(
    children: [
      IconButton(
        onPressed: () => Get.to(
          () => BDropOffCapture(
            title: 'Proof Picture',
            onCapture: (camera) async => camera.takePictureWithAnimation(
              requestModel.id, // Use current request ID
            ),
          ),
        ),
        icon: Icon(Iconsax.camera, size: 25, color: iconColor),
      ),
      BProductTitleText(
        title: cameraController.imageProofPath.value,
        maxLines: 1,
        smallSize: true,
        fontColor: textColor,
      ),
    ],
  ),
)
```

### 3. Dependencies to Add

Add the following imports to `air_sea_item_packed_section.dart`:

```dart
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart';
```

### 4. Controller Integration

Initialize `CameraHandlerController` in the build method:

```dart
final cameraController = Get.find<CameraHandlerController>();
```

### 5. Implementation Pattern

#### For "Endorsed to Guard" Status
Insert the camera capture section **after** the guard signature display and **before** the closing of `_buildGuardFields()`:

```dart
const SizedBox(height: BSizes.spaceBtwItems),

/// Proof Image Capture
Center(
  child: Obx(() {
    return Column(
      children: [
        IconButton(
          onPressed: () => Get.to(
            () => BDropOffCapture(
              title: 'Guard Receipt Proof',
              onCapture: (camera) async => camera.takePictureWithAnimation(
                requestModel.id,
              ),
            ),
          ),
          icon: Icon(Iconsax.camera, size: 25, color: dark ? BColors.light : BColors.black),
        ),
        if (cameraController.imageProofPath.value.isNotEmpty)
          BProductTitleText(
            title: cameraController.imageProofPath.value,
            maxLines: 1,
            smallSize: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
      ],
    );
  }),
),
```

#### For "Received" Status
Insert the camera capture section **after** the receiver signature display and **before** the closing of `_buildReceiverFields()`:

```dart
const SizedBox(height: BSizes.spaceBtwItems),

/// Proof Image Capture
Center(
  child: Obx(() {
    return Column(
      children: [
        IconButton(
          onPressed: () => Get.to(
            () => BDropOffCapture(
              title: 'Delivery Proof',
              onCapture: (camera) async => camera.takePictureWithAnimation(
                requestModel.id,
              ),
            ),
          ),
          icon: Icon(Iconsax.camera, size: 25, color: dark ? BColors.light : BColors.black),
        ),
        if (cameraController.imageProofPath.value.isNotEmpty)
          BProductTitleText(
            title: cameraController.imageProofPath.value,
            maxLines: 1,
            smallSize: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
      ],
    );
  }),
),
```

## Reference Implementation

### Source File
`lib/features/logistics/screens/request_transport/widgets/b_request_details.dart`

### Key Components Used
1. **BDropOffCapture**: Full-screen camera capture widget
   - Located at: `lib/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart`
   - Props: `title` (String), `onCapture` (callback function)

2. **CameraHandlerController**: Manages camera operations and image storage
   - Located at: `lib/common/controllers/camera_controller.dart`
   - Key property: `imageProofPath.value` (reactive path to captured image)

3. **BProductTitleText**: Text widget for displaying captured image path
   - Located at: `lib/common/widgets/texts/product_title_text.dart`

## Data Flow

### Image Capture Flow (Step-by-Step)

1. **User taps camera icon** in `air_sea_item_packed_section.dart`
2. **Navigate to BDropOffCapture** full-screen camera widget
3. **User captures image** by tapping the camera button
4. **CameraHandlerController.takePictureWithAnimation(requestId)** is called
5. **Image is saved** to: `BPaths.deliveryShots/$requestId.jpg`
6. **User returns** to the item packed section
7. **User submits the status update** (either "Endorsed to Guard" or "Received")
8. **AirSeaDataManager.updateRequestStatus()** is called
9. **BImageHelperFunctions.getDeliveryImageAsBase64()** reads the saved image file
10. **Image is uploaded** via `ImageRepository.instance.uploadFile()` with type 'Proof'

### Critical Flow Details

#### Image File Path
- **Save location**: `BPaths.deliveryShots/$requestId.jpg`
- **Filename**: Request ID with `.jpg` extension
- **Set by**: `CameraHandlerController.takePicture(requestId)`
- **Retrieved by**: `BImageHelperFunctions.getDeliveryImageAsBase64(status, requestId)`

#### Upload Trigger (in air_sea_data_manager.dart)
The image upload is triggered for **BOTH** statuses:
```dart
// Line ~298-334 in air_sea_data_manager.dart
if (newStatus == BTexts.statusEndorsedToGuard || newStatus == BTexts.statusReceived) {
  String? finalImageBase64 = await BImageHelperFunctions.getDeliveryImageAsBase64(
      newStatus, request.id);
  
  if (finalImageBase64 != null && finalImageBase64.isNotEmpty) {
    // Upload to server via ImageRepository
    await ImageRepository.instance.uploadFile(
      requestId: request.id,
      base64Image: finalImageBase64,
      type: 'Proof',
    );
  }
}
```

### Integration with Air/Sea Form State
The `AirSeaFormState` already has the infrastructure for image paths:
- `cameraDropOffPicture` (RxString)
- `cameraPickUpPicture` (RxString)

However, for this implementation:
- The captured image path is stored in `cameraController.imageProofPath.value`
- The image file is automatically associated with the request via the request ID
- No manual form state update is required—the file is saved with requestId as filename

## Styling Guidelines
- Use `Iconsax.camera` icon (size: 25)
- Icon color: `dark ? BColors.light : BColors.black`
- Spacing: `BSizes.spaceBtwItems` between sections
- Title variations:
  - "Guard Receipt Proof" for Endorsed to Guard status
  - "Delivery Proof" for Received status

## Important Constants

### Status Strings (from BTexts)
```dart
BTexts.statusEndorsedToGuard = "Endorsed to Guard"
BTexts.statusReceived = "Received"
BTexts.statusItemPacked = "Item Packed"
```

### Status Comparison in Code
When checking status in `air_sea_item_packed_section.dart`, use string literals:
```dart
if (selectedStatus == 'Endorsed to Guard') {
  // Guard fields with proof image capture
}
if (selectedStatus == 'Received') {
  // Receiver fields with proof image capture
}
```

When checking in `air_sea_data_manager.dart`, use BTexts constants:
```dart
if (newStatus == BTexts.statusEndorsedToGuard || newStatus == BTexts.statusReceived) {
  // Upload proof image
}
```

## Testing Checklist
- [ ] Camera icon appears in both "Endorsed to Guard" and "Received" status views
- [ ] Tapping camera icon navigates to `BDropOffCapture` screen
- [ ] Camera captures image successfully
- [ ] Image path displays below camera icon after capture
- [ ] Image is saved with correct request ID (verify in `BPaths.deliveryShots/`)
- [ ] Submitting "Endorsed to Guard" status uploads the captured image
- [ ] Submitting "Received" status uploads the captured image
- [ ] Upload works when online (check success message)
- [ ] Upload queues for sync when offline (check warning message)
- [ ] No build errors or warnings
- [ ] Obx reactivity works correctly (path updates after capture)

## Verification Points

### 1. Image File Creation
After capturing, verify the file exists:
```
File path: BPaths.deliveryShots/{requestId}.jpg
Example: BPaths.deliveryShots/12345-abcde.jpg
```

### 2. Upload Trigger Confirmation
Check logs for these messages:
- ✅ Success: "Request updated" snackbar
- ⚠️ No image: "No image to upload (finalImageBase64 is null or empty)"
- ❌ Upload failed: "Image upload failed: {error}"
- 📡 Offline: "Image saved locally. It will be uploaded when internet connection is available."

### 3. Status-Specific Behavior
- **Endorsed to Guard**: Image + Guard Signature uploaded
- **Received**: Image + Receiver Signature + Waybill Number uploaded

### 4. Data Manager Flow Validation
Ensure `AirSeaDataManager.updateRequestStatus()` correctly:
- Calls `BImageHelperFunctions.getDeliveryImageAsBase64(newStatus, request.id)`
- Uploads via `ImageRepository.instance.uploadFile()` with `type: 'Proof'`
- Handles both statuses: `statusEndorsedToGuard` and `statusReceived`

## Architecture Compliance
- ✅ Uses GetX reactive pattern (Obx)
- ✅ Controller accessed via `Get.find()`
- ✅ No business logic in UI
- ✅ Follows existing camera capture pattern
- ✅ Reuses common widgets from `lib/common/widgets`

## Notes
- The camera controller is already registered in the app's bindings
- The proof image is stored locally and will be synced with the server via the existing data manager logic
- No changes needed to `AirSeaFormState` or `AirSeaController` for basic capture functionality
- The image association with the request happens automatically via the request ID

## Related Files
- `lib/features/logistics/screens/air_sea/widgets/air_sea_item_packed_section.dart` (target file)
- `lib/features/logistics/screens/request_transport/widgets/b_request_details.dart` (reference)
- `lib/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart` (camera widget)
- `lib/common/controllers/camera_controller.dart` (camera controller)
- `lib/features/logistics/helpers/air_sea_form_state.dart` (form state)

