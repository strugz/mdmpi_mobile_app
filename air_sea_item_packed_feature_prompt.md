# Air/Sea "Item Packed" Status Enhancement - Implementation Prompt

## Overview
Enhance the Air/Sea request modal to display conditional UI when the status is "Item Packed". The UI should allow users to:
1. Select a status transition (Endorsed to Guard OR Received by courier)
2. Capture relevant information based on the selected transition
3. Capture signatures appropriately

---

## Requirements

### When `status == "Item Packed"`:

#### 1. **Status Dropdown**
- Display a dropdown with two options:
  - "Endorsed to Guard"
  - "Received"
- Use existing `BTexts.statusEndorsedToGuard` constant (already exists)
- Check if `BTexts.statusReceived` constant exists, if not create it: `static const String statusReceived = "Received";` in `lib/base/utils/constants/text_string.dart`
- **Use the existing `BDropdown` component** from `lib/common/widgets/dropdown/dropdown.dart`
- **BDropdown items:** `['Endorsed to Guard', 'Received']`

#### 2. **If "Endorsed to Guard" is selected:**
- **Guard Name TextField**
  - Label: "Guard Name"
  - Validation: Required, non-empty
  - Use existing `BTextFormField` widget from `lib/common/widgets/form/b_text_form_field.dart`
  
- **Guard Signature**
  - Button to capture guard's signature
  - Use existing `BSignatureCaptureDialog` from `lib/base/utils/popups/signature_capture_dialog.dart`
  - Display captured signature using similar pattern to `CapturedSignatureImage`
  - Store signature bytes in controller/state for submission

#### 3. **If "Received" is selected:**
- **Receiver Name TextField**
  - Label: "Receiver Name"
  - Validation: Required, non-empty
  - Use existing `BTextFormField` widget
  
- **Receiver Signature**
  - Button to capture receiver's signature
  - Use existing `BSignatureCaptureDialog`
  - Display captured signature
  - Store signature bytes in controller/state for submission

---

## Technical Implementation Steps

### Step 1: Update Constants
**File:** `lib/base/utils/constants/text_string.dart`
- Check if `BTexts.statusReceived` exists (should already exist as "Received")
- If not, add: `static const String statusReceived = "Received";`

### Step 2: Update AirSeaModel (if needed)
**File:** `lib/features/logistics/models/air_sea_model.dart`
- Check if we need new fields:
  - `String guardName` (for endorsed to guard)
  - `String receiverName` (for received)
  - Or reuse existing `receivedBy` field
- Add to constructor, copyWith, toJson, fromJson, fromDbJson if new fields are added

### Step 3: Update AirSeaController
**File:** `lib/features/logistics/controllers/air_sea_controller.dart`
- Add reactive variables:
  ```dart
  final RxString selectedPackedStatus = ''.obs;
  final RxString guardName = ''.obs;
  final RxString receiverName = ''.obs;
  Rx<Uint8List?> guardSignature = Rx<Uint8List?>(null);
  Rx<Uint8List?> receiverSignature = Rx<Uint8List?>(null);
  ```
- Add TextEditingController for BDropdown:
  ```dart
  final packedStatusController = TextEditingController();
  ```
- Add listener to packedStatusController in onInit:
  ```dart
  packedStatusController.addListener(() {
    selectedPackedStatus.value = packedStatusController.text;
  });
  ```
- Add methods:
  - `setGuardName(String name)` - to update guard name
  - `setReceiverName(String name)` - to update receiver name
  - `setGuardSignature(Uint8List? bytes)` - to store guard signature
  - `setReceiverSignature(Uint8List? bytes)` - to store receiver signature
  - `submitPackedTransition()` - to validate and submit the status change

### Step 4: Create UI Widget for Item Packed Section
**File:** `lib/features/logistics/screens/air_sea/widgets/air_sea_item_packed_section.dart` (NEW)

Create a new stateless widget that:
- Shows a divider with "Item Packed - Update Status"
- Displays dropdown using **`BDropdown`** component (from `lib/common/widgets/dropdown/dropdown.dart`)
- Uses `Obx` to reactively show:
  - Guard fields when "Endorsed to Guard" is selected
  - Receiver fields when "Received" is selected
- Reuses existing components:
  - **`BDropdown`** for status selection dropdown
  - `BTextFormField` for name inputs
  - `BSignatureCaptureDialog.show()` for signature capture
  - `BTextDivider` for section headers
  - Standard icon buttons for signature capture (similar to pick_up_request_modal_footer.dart pattern)

**Key UI Elements:**
```dart
// Import BDropdown
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';

// Dropdown - Use BDropdown component
final controller = Get.find<AirSeaController>();

BDropdown(
  controller: controller.packedStatusController,
  label: 'Select Status',
  icon: Iconsax.status_up,
  dropdownList: [
    'Endorsed to Guard',
    'Received',
  ],
)

// React to controller.selectedPackedStatus changes with Obx
Obx(() {
  final selectedStatus = controller.selectedPackedStatus.value;
  
  if (selectedStatus == 'Endorsed to Guard') {
    // Show guard fields
    return Column(
      children: [
        BTextFormField(
          labelText: 'Guard Name',
          icon: Iconsax.user,
          onChanged: (value) => controller.setGuardName(value),
        ),
        // Guard signature button & display
      ],
    );
  } else if (selectedStatus == 'Received') {
    // Show receiver fields
    return Column(
      children: [
        BTextFormField(
          labelText: 'Receiver Name',
          icon: Iconsax.user,
          onChanged: (value) => controller.setReceiverName(value),
        ),
        // Receiver signature button & display
      ],
    );
  }
  return SizedBox.shrink();
})

// Text field example
BTextFormField(
  labelText: 'Guard Name',
  icon: Iconsax.user,
  onChanged: (value) => controller.setGuardName(value),
)

// Signature button example
ElevatedButton.icon(
  icon: Icon(Iconsax.pen_add),
  label: Text('Capture Guard Signature'),
  onPressed: () => BSignatureCaptureDialog.show(
    context: context,
    onSave: (bytes) => controller.setGuardSignature(bytes),
  ),
)

// Display captured signature (if exists)
Obx(() {
  final sig = controller.guardSignature.value;
  if (sig != null && sig.isNotEmpty) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: BColors.grey)),
      child: Image.memory(sig, height: 100, width: 150, fit: BoxFit.fill),
    );
  }
  return SizedBox.shrink();
})
```

**BDropdown Component Details:**
- **Location:** `lib/common/widgets/dropdown/dropdown.dart`
- **Usage Pattern:** (See examples in `standard_delivery_form.dart` and `hotline_direct_form.dart`)
  ```dart
  BDropdown(
    controller: textEditingController,  // Required: TextEditingController
    label: 'Label Text',                // Required: String
    icon: Iconsax.icon_name,           // Optional: IconData (default: Iconsax.airplane)
    dropdownList: ['Option 1', 'Option 2'], // Required: List<String>
    validator: (value) => ...,         // Optional: validation function
  )
  ```
- **How it works:**
  - Takes a `TextEditingController` and updates its `text` property when selection changes
  - Automatically deduplicates options
  - Handles empty lists gracefully
  - Adapts to dark/light mode
  - Returns null if controller.text is empty or doesn't match any option

### Step 5: Update Air/Sea Modal Footer or Header
**File:** `lib/features/logistics/screens/air_sea/widgets/air_sea_request_modal_footer.dart`
- Add conditional section for "Item Packed" status
- Check if `requestModel.status == BTexts.statusItemPacked`
- If true, import and display the new `AirSeaItemPackedSection` widget
- Pass `requestModel` to the widget

**Integration point:**
```dart
// In the footer widget, after remarks section
if (requestModel.status == BTexts.statusItemPacked) ...[
  const SizedBox(height: BSizes.sm),
  const BTextDivider(text: 'Update Status'),
  AirSeaItemPackedSection(requestModel: requestModel),
],
```

### Step 6: Update Repository/DAO (if needed)
**Files to check:**
- `lib/data/repositories/air_sea/air_sea_repository.dart`
- `lib/data/local/dao/air_sea/air_sea_dao.dart`

Update methods to:
- Handle new fields (guardName, receiverName) if added to model
- Store signature bytes in local database
- Submit to API with proper payload structure

### Step 7: Update API Integration
- Check existing endorse methods in air_sea_repository.dart
- May need to add new API endpoint for "Received" status
- Ensure signature bytes are properly encoded (base64) for API submission
- Include guardName or receiverName in the payload

---

## Architecture Notes

### Design Principles (from copilot-instructions.md)
- ✅ Use GetX with Rx for reactive state
- ✅ Keep UI pure - no business logic in build methods
- ✅ Controllers call repositories/services
- ✅ **Reuse existing widgets from `lib/common/widgets` (like `BDropdown`) and `lib/base/utils`**
- ✅ Use dependency injection via `Get.find()`
- ✅ Follow naming conventions: PascalCase for classes, camelCase for methods/vars
- ✅ Add `///` docs for public methods
- ✅ Wrap minimal subtrees in `Obx`

### Similar Implementation References
- **Pick-up module:** `lib/features/logistics/screens/pick_up/widgets/pick_up_request_modal_footer.dart`
  - Shows how to handle "Item Packed" status with image capture
- **Signature capture:** `lib/base/utils/popups/signature_capture_dialog.dart`
  - Reusable dialog for signature capture
- **Signature display:** `lib/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart`
  - Pattern for displaying signatures (network + local fallback)
- **BDropdown usage:** `lib/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart` (lines 64-91)
  - Shows how to use BDropdown with TextEditingController
- **BDropdown component:** `lib/common/widgets/dropdown/dropdown.dart`
  - Existing reusable dropdown component

---

## Validation & Quality Gates

After implementation:
1. Run `flutter analyze` - must be clean
2. Test both dropdown options show correct fields
3. Test signature capture works for both guard and receiver
4. Test form validation (required fields)
5. Test submission to API
6. Test local database storage
7. Verify UI adapts to dark/light mode
8. Check that existing "Received" status display still works
9. Verify BDropdown controller updates reactive state correctly

---

## Open Questions / Decisions Needed

1. **Field Reuse:** Should we reuse existing `receivedBy` field or add separate `guardName`/`courierName` fields?
   - Recommendation: Check API schema first
   
2. **Signature Storage:** Where to store signature in database?
   - Check existing signature tables/columns used for standard_delivery
   - May need to add signature type column ('guard' vs 'courier')

3. **Submit Button:** Should submission be:
   - Automatic when all fields are filled?
   - Manual via "Submit" button?
   - Part of existing modal action buttons?
   - Recommendation: Add a submit button in the section itself

4. **Validation Timing:** When to validate?
   - On field change (reactive)?
   - On submit button press?
   - Recommendation: On submit, with visual feedback

---

## File Structure Summary

### Files to CREATE:
1. `lib/features/logistics/screens/air_sea/widgets/air_sea_item_packed_section.dart`

### Files to MODIFY:
1. `lib/base/utils/constants/text_string.dart` - Add constant
2. `lib/features/logistics/models/air_sea_model.dart` - Add fields (if needed)
3. `lib/features/logistics/controllers/air_sea_controller.dart` - Add state & methods
4. `lib/features/logistics/screens/air_sea/widgets/air_sea_request_modal_footer.dart` - Integrate widget
5. `lib/data/repositories/air_sea/air_sea_repository.dart` - Add/update methods (if needed)
6. `lib/data/local/dao/air_sea/air_sea_dao.dart` - Handle new fields (if needed)

### Files to REFERENCE (existing components):
1. `lib/common/widgets/dropdown/dropdown.dart` - **BDropdown component**
2. `lib/common/widgets/form/b_text_form_field.dart` - BTextFormField component
3. `lib/base/utils/popups/signature_capture_dialog.dart` - Signature capture dialog
4. `lib/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart` - BDropdown usage examples

---

## Next Steps

1. ✅ Review this prompt with user for approval
2. Confirm API schema and field names
3. Implement in the order listed above
4. Test thoroughly
5. Run quality gates

---

## Notes
- Follow the existing pattern from Pick-up module which already handles "Item Packed" status
- Maintain consistency with existing Air/Sea modal styling
- Ensure accessibility (semantics labels for signature buttons)
- Keep reactive state minimal and focused
- **IMPORTANT: Use `BDropdown` component instead of raw `DropdownButtonFormField` for consistency with the rest of the app**

