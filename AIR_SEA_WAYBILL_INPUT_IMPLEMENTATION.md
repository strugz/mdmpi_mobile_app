# Waybill Input Feature for "Endorsed to Guard" Status

## Summary

Implemented a waybill input field that displays when an Air/Sea request has the status "Endorsed to Guard". The waybill number can be entered and saved during the status transition.

## Changes Made

### 1. Created New Widget: `AirSeaWaybillInputSection`
**File**: `lib/features/logistics/screens/air_sea/widgets/air_sea_waybill_input_section.dart`

- New widget that displays a waybill input field
- Uses existing `BTextFormField` component
- Auto-populates with existing waybill value if available
- Only shown when request status is "Endorsed to Guard"

### 2. Updated `AirSeaModal`
**File**: `lib/features/logistics/screens/air_sea/widgets/air_sea_modal.dart`

- Added import for `AirSeaWaybillInputSection`
- Conditionally renders waybill input section when status is "Endorsed to Guard"
- Updated status button text mapper to include "Endorsed to Guard" case

### 3. Updated `AirSeaModalHeader`
**File**: `lib/features/logistics/screens/air_sea/widgets/air_sea_modal_header.dart`

- Added waybill number display in Guard Endorsement section
- Shows waybill with clipboard icon when value exists
- Follows same styling as other fields (Guard Name, Endorsed At)

### 4. Updated `AirSeaDataManager`
**File**: `lib/features/logistics/helpers/air_sea_data_manager.dart`

- Modified `waybillNumber` field logic to save value from form controller
- Saves waybill when status transitions to "Endorsed to Guard"
- Preserves existing waybill value if form is empty

## User Flow

### When Status is "Endorsed to Guard":

1. User opens an Air/Sea request modal with status "Endorsed to Guard"
2. Waybill input section appears with a text field labeled "Waybill/Tracking Number"
3. User enters the waybill/tracking number
4. User clicks "Mark Received" button
5. Waybill number is saved to the request
6. Waybill number displays in the Guard Endorsement section on subsequent views

## Technical Details

### Form State
- Uses existing `waybillNumberController` from `AirSeaFormState` class
- Controller already existed but wasn't being used for Guard status
- No changes needed to form state class

### Data Persistence
- Waybill value is saved to both local SQLite and remote server
- Follows existing pattern for other status-specific fields
- Validated and synced via existing data manager logic

### UI Components
- Reused `BTextFormField` from common widgets
- Consistent with existing input fields in the app
- Uses Iconsax icons (clipboard_text) for visual consistency

## Files Modified

1. `lib/features/logistics/screens/air_sea/widgets/air_sea_modal.dart` - Added waybill section and button text
2. `lib/features/logistics/screens/air_sea/widgets/air_sea_waybill_input_section.dart` - New file
3. `lib/features/logistics/screens/air_sea/widgets/air_sea_modal_header.dart` - Added waybill display
4. `lib/features/logistics/helpers/air_sea_data_manager.dart` - Added waybill save logic

## Testing Recommendations

1. **Input Test**: Verify waybill field appears when status is "Endorsed to Guard"
2. **Save Test**: Enter waybill number and verify it saves correctly
3. **Display Test**: After saving, verify waybill displays in Guard Endorsement section
4. **Persistence Test**: Close and reopen modal to verify waybill persists
5. **Empty Test**: Verify behavior when waybill field is left empty
6. **Update Test**: Verify existing waybill can be updated if needed

## Notes

- Follows GetX architecture with controllers and reactive UI
- No breaking changes to existing functionality
- Backward compatible with requests that don't have waybill numbers
- Aligns with coding instructions (snake_case files, PascalCase classes, proper DI)

