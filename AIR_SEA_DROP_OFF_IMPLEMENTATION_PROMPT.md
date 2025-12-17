# Air Sea Drop Off Widget Implementation Prompt

## Overview
Create a Drop Off section widget for the Air Sea module that captures **4 REQUIRED FIELDS** for proof of delivery when the status transitions to "Drop Off". This should follow the same pattern as the existing "Endorsed to Guard" and "Received" status transitions.

---

## 🎯 4 Required Drop Off Fields

| # | Field Name | Type | Source | Auto/Manual |
|---|------------|------|--------|-------------|
| 1 | **ReceivedBy Name** | String | Text Input | Manual |
| 2 | **Receiver Signature** | Image (Base64) | Signature Pad | Manual |
| 3 | **DropOffAt Timestamp** | DateTime (ISO) | Auto-capture | **Automatic** |
| 4 | **Proof Image** | Image File | Camera | Manual |

**All 4 fields are REQUIRED for successful Drop Off completion.**

---

## Current Status Flow
```
New Request 
  → Getting Supplies Ready (itemPreparedAt)
  → Item Packed (itemPreparedEndAt)
  → Endorsed to Guard (receivedBy + signature + camera)
  → Received (receivedBy + waybillNumber + signature + camera)
  → Dispatch (tripTicketNumber + driver + helper + vehicle + dispatchedAt)
  → **Drop Off** ← NEW STATUS TO IMPLEMENT
      Required Fields:
      ✅ ReceivedBy Name (who received the delivery)
      ✅ Receiver Signature (digital signature capture)
      ✅ DropOffAt Timestamp (auto-captured on status change)
      ✅ Proof Image (photo of delivered item/location)
```

---

## Requirements

### 1. **New Widget: `air_sea_drop_off_section.dart`**
**Location:** `lib/features/logistics/screens/air_sea/widgets/air_sea_drop_off_section.dart`

**Purpose:** Display drop-off fields when status is "Drop Off" in the modal footer

**Required Fields (4 Total):**
1. ✅ **ReceivedBy Name** - Text input field for the person who received the delivery
   - Controller: `controller.formState.receivedByController`
   - Validation: Required field
   - Icon: `Iconsax.user`

2. ✅ **Receiver Signature** - Digital signature capture with preview
   - Storage: `controller.formState.receiverSignatureBytes`
   - Base64: `controller.formState.receiverSignatureBase64`
   - Dialog: `BFullScreenLoader.showSignatureDialogForAirSea()`
   - Preview: Display captured signature with redo option

3. ✅ **DropOffAt Timestamp** - Auto-captured when status changes to "Drop Off"
   - Field: `dropOffAt` in model
   - **AUTO-CAPTURED** by `air_sea_data_manager.dart` (already implemented)
   - Format: ISO datetime string
   - No UI input needed (automatic)

4. ✅ **Proof Image** - Photo evidence of delivery/drop-off location
   - Widget: `BDropOffCapture` (camera screen)
   - Storage: `cameraController.imageProofPath`
   - Upload: Via `camera.takePictureWithAnimation(requestModel.id)`
   - Display: Shows file path after capture

**Pattern Reference:**
- Similar to `air_sea_item_packed_section.dart` (for structure)
- Use `BDropOffCapture` widget (already exists at `lib/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart`)
- Use signature dialog pattern from `_buildGuardFields()` and `_buildReceiverFields()` methods

---

### 2. **Integration Points**

#### **A. Modal Footer (`air_sea_request_modal_footer.dart`)**
**Current Code:**
```dart
if (requestModel.status == BTexts.statusItemPacked) ...[
  AirSeaItemPackedSection(requestModel: requestModel),
],
```

**Add After:**
```dart
/// -- Drop Off Status Section --
if (requestModel.status == 'Drop Off') ...[
  AirSeaDropOffSection(requestModel: requestModel),
],
```

#### **B. Modal (`air_sea_modal.dart`)**
**Current Status Button Mapping:**
```dart
case 'Dispatch':
  return 'Mark Drop Off';
case 'Received':
  return '';
```

**Update to:**
```dart
case 'Dispatch':
  return 'Mark Drop Off';
case 'Drop Off':
  return 'Mark Completed'; // or appropriate text
case 'Received':
  return '';
```

---

### 3. **Widget Structure**

```dart
class AirSeaDropOffSection extends StatelessWidget {
  const AirSeaDropOffSection({super.key, required this.requestModel});

  final AirSeaModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<AirSeaController>();
    final cameraController = Get.find<CameraHandlerController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.sm),
        const BTextDivider(text: 'Drop Off Confirmation'),
        
        // Proof of Drop Off Image Capture
        Obx(() => Center(
          child: Column(
            children: [
              IconButton(
                onPressed: () => Get.to(
                  () => BDropOffCapture(
                    title: 'Proof of Drop Off',
                    onCapture: (camera) async =>
                        camera.takePictureWithAnimation(requestModel.id),
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
        )),
        
        const SizedBox(height: BSizes.spaceBtwItems),
        
        // Receiver Name Field
        BTextFormField(
          controller: controller.formState.receivedByController,
          label: 'Received By',
          prefixIcon: Iconsax.user,
          keyboardType: TextInputType.text,
        ),
        
        const SizedBox(height: BSizes.spaceBtwItems),
        
        // Signature Capture Button
        Center(
          child: Obx(() {
            final sig = controller.formState.receiverSignatureBytes.value;
            final hasSignature = sig != null && sig.isNotEmpty;
            
            return Column(
              children: [
                TextButton.icon(
                  onPressed: () => BFullScreenLoader.showSignatureDialogForAirSea(
                    context,
                    controller,
                  ),
                  icon: Icon(
                    hasSignature ? Iconsax.document_upload : Iconsax.edit,
                    color: textColor,
                  ),
                  label: Text(
                    hasSignature
                        ? 'Signature Captured (Tap to Redo)'
                        : 'Capture Signature',
                    style: TextStyle(color: textColor),
                  ),
                ),
                
                // Signature Preview
                if (hasSignature) ...[
                  const SizedBox(height: BSizes.sm),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: BColors.grey),
                    ),
                    child: Image.memory(sig, fit: BoxFit.contain),
                  ),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}
```

---

### 4. **Existing Components to Reuse**

✅ **Already Available:**
- `BDropOffCapture` - Camera capture widget
- `CameraHandlerController` - Camera management
- `BFullScreenLoader.showSignatureDialogForAirSea()` - Signature dialog
- `controller.formState.receivedByController` - Text controller
- `controller.formState.receiverSignatureBytes` - Signature storage
- `BTextDivider`, `BTextFormField`, `BProductTitleText` - UI widgets

---

### 5. **Data Flow**

```
User clicks "Mark Drop Off" button
  ↓
Modal shows AirSeaDropOffSection
  ↓
User captures photo (BDropOffCapture)
  → Stores in CameraController.imageProofPath
  → **FIELD 1: Proof Image** ✅
  ↓
User enters receiver name
  → Stores in formState.receivedByController
  → **FIELD 2: ReceivedBy Name** ✅
  ↓
User captures signature
  → Stores in formState.receiverSignatureBytes
  → **FIELD 3: Receiver Signature** ✅
  ↓
User submits
  ↓
updateRequestStatus() captures:
  - status: 'Drop Off'
  - **FIELD 4: dropOffAt** (current timestamp - AUTO) ✅
  - receivedBy: from controller (FIELD 2)
  - signature: from receiverSignatureBytes (FIELD 3)
  - proof image: from imageProofPath (FIELD 1)
  ↓
All 4 fields uploaded to API/storage
```

**Summary of 4 Required Fields:**
1. ✅ ReceivedBy Name (manual input)
2. ✅ Receiver Signature (digital capture)
3. ✅ DropOffAt Timestamp (auto-captured)
4. ✅ Proof Image (camera capture)

---

### 6. **Form State (Already Has Required Controllers)**

**✅ Existing Controllers:**
```dart
// In air_sea_form_state.dart
final TextEditingController receivedByController = TextEditingController();
final TextEditingController dropOffAtController = TextEditingController();
final Rx<Uint8List?> receiverSignatureBytes = Rx<Uint8List?>(null);
final RxString receiverSignatureBase64 = RxString("");
```

**✅ Camera Controller:**
```dart
// From CameraHandlerController
final RxString imageProofPath = RxString("");
```

---

### 7. **Visual Design Reference**

Follow the same layout pattern as:
- **Pull Out Module:** `pull_out_request_modal_footer.dart` (lines 41-100)
- **Air Sea Guard Section:** `air_sea_item_packed_section.dart` → `_buildGuardFields()`

**Layout:**
```
┌──────────────────────────────────┐
│  === Drop Off Confirmation ===   │
├──────────────────────────────────┤
│        📷 Camera Icon             │
│    "Proof of Drop Off"           │
│   (image path if captured)       │
├──────────────────────────────────┤
│  Received By: [Text Input]       │
├──────────────────────────────────┤
│   [Capture Signature Button]     │
│   (Signature preview if exists)  │
└──────────────────────────────────┘
```

---

### 8. **Status Constants**

**Check if status constant exists:**
```dart
// In lib/base/utils/constants/text_string.dart
static const String statusDropOff = 'Drop Off';
```

If not, add it or use string literal `'Drop Off'` consistently.

---

### 9. **Testing Checklist**

**Widget Display:**
- [ ] Widget displays only when `requestModel.status == 'Drop Off'`
- [ ] Section title shows "Drop Off Confirmation"

**Field 1: Proof Image**
- [ ] Camera button opens `BDropOffCapture` with correct title
- [ ] Image capture stores path in `cameraController.imageProofPath`
- [ ] Captured image path displays below camera icon

**Field 2: ReceivedBy Name**
- [ ] Text input field displays with "Received By" label
- [ ] Input stores in `receivedByController`
- [ ] Field accepts text input correctly

**Field 3: Receiver Signature**
- [ ] Signature button opens signature dialog
- [ ] Signature preview displays after capture
- [ ] Signature redo functionality works
- [ ] Captured signature stores in `receiverSignatureBytes`

**Field 4: DropOffAt Timestamp**
- [ ] `dropOffAt` timestamp is auto-captured on submit (no UI needed)
- [ ] Timestamp is in ISO datetime format

**Submission:**
- [ ] All 4 fields are included when submitting status update
- [ ] Data saves to API successfully
- [ ] Data persists in local DB correctly
- [ ] Modal button shows correct text for "Drop Off" status

---

### 10. **Files to Create/Modify**

**Create:**
1. ✅ `air_sea_drop_off_section.dart` - New widget

**Modify:**
2. ✅ `air_sea_request_modal_footer.dart` - Add drop-off section
3. ✅ `air_sea_modal.dart` - Update status button text mapping
4. ⚠️ `text_string.dart` - Add constant (if needed)

**No Changes Needed (Already Implemented):**
- ✅ Model fields (`dropOffAt`)
- ✅ DTO fields
- ✅ DAO persistence
- ✅ Database columns
- ✅ Form state controllers
- ✅ Data manager timestamp capture

---

### 11. **Implementation Steps**

1. **Create `air_sea_drop_off_section.dart`**
   - Import required dependencies
   - Build layout with camera, text field, and signature
   - Use Obx for reactive updates
   - Follow existing color/spacing patterns

2. **Update `air_sea_request_modal_footer.dart`**
   - Add conditional rendering for Drop Off status
   - Import new widget

3. **Update `air_sea_modal.dart`**
   - Update `statusToTextMapper` for Drop Off status
   - Ensure button shows correct text

4. **Test End-to-End Flow**
   - Create/fetch Air Sea request
   - Progress through statuses
   - Verify Drop Off section appears
   - Capture image, enter name, capture signature
   - Submit and verify data saved

---

## Success Criteria

✅ Drop Off section appears when status is "Drop Off"

**All 4 Required Fields Working:**
1. ✅ **ReceivedBy Name** - User can enter receiver name
2. ✅ **Receiver Signature** - User can capture and preview signature
3. ✅ **DropOffAt Timestamp** - Automatically recorded on submit
4. ✅ **Proof Image** - User can capture photo via camera

**Data Persistence:**
✅ All 4 fields saved to API on submit
✅ All 4 fields persisted in local DB
✅ Image uploaded to storage successfully
✅ Signature uploaded/encoded correctly

**UI/UX:**
✅ UI follows existing design patterns and spacing
✅ Signature preview displays correctly
✅ Image path shows after capture
✅ No console errors or warnings
✅ Flutter analyze passes cleanly

---

## Related Files for Reference

**Widget Patterns:**
- `lib/features/logistics/screens/air_sea/widgets/air_sea_item_packed_section.dart`
- `lib/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_request_modal_footer.dart`

**Reusable Components:**
- `lib/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart`
- `lib/common/controllers/camera_controller.dart`
- `lib/base/utils/popups/full_screen_loader.dart` (for signature dialog)

**Data Layer (Already Complete):**
- `lib/features/logistics/models/air_sea_model.dart` (has `dropOffAt`)
- `lib/features/logistics/helpers/air_sea_form_state.dart` (has controllers)
- `lib/features/logistics/helpers/air_sea_data_manager.dart` (has timestamp logic)

---

## Notes

- The `dropOffAt` field is already implemented in the model, DTO, DAO, and database
- The data manager already captures the timestamp when status changes to "Drop Off"
- Reuse existing controllers (`receivedByController`, `receiverSignatureBytes`) for consistency
- Follow the same signature capture pattern as "Endorsed to Guard" and "Received"
- The camera proof image is handled by `CameraHandlerController.takePictureWithAnimation()`

---

**Last Updated:** December 17, 2025
**Module:** Air Sea / Logistics
**Priority:** High - Completes the full delivery workflow

