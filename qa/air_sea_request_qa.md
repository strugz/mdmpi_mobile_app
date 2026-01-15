# QA Overview – Air/Sea Request Form

## Scope / Overview

Screen name: Air/Sea Request Form

Purpose: Verify that a user can successfully create an **Air/Sea** logistics request using this form, and that the UI, validation, and submission behavior are correct, based only on what is visible in the app (no knowledge of the internal code is required).

This QA focuses on the **"Create Air/Sea Request"** flow, including:
- Opening the Air/Sea Request Form from the Request screen (Air/Sea category)
- Filling out client information and document reference
- Selecting an Item Category
- Choosing a Pick-Up Date
- Submitting the form via the **Create Request** button and verifying post-submit behavior

---

## 1. Entry to the Air/Sea Request Form

1.1 **Navigation from Request screen**
- [ ] From the Request screen, select the category that corresponds to **Air/Sea** (per product design).
- [ ] Tap the **Add/New Request** button (floating action button or equivalent entry point).
- [ ] Confirm that the Air/Sea Request Form opens:
  - [ ] App bar title clearly indicates Air/Sea request form (e.g., "Air/Sea Request Form").
  - [ ] The content shows client information and document reference sections.

1.2 **Back navigation from the form**
- [ ] A back arrow or similar control is visible in the top app bar.
- [ ] Tapping back returns to the previous screen (usually the Request screen) without crashing.
- [ ] Pressing back from the form does not require multiple presses to exit a single visit (no duplicate screens in stack).

---

## 2. App Bar & Overall Layout

2.1 **App bar content**
- [ ] The app bar title text explicitly refers to Air/Sea requests (e.g., "Air/Sea Request Form").
- [ ] Back arrow is clearly visible and functional.

2.2 **Form layout and scroll behavior**
- [ ] The form content is vertically scrollable if it doesn’t fit on-screen.
- [ ] Sections appear in a clear order:
  - [ ] Client Information
  - [ ] Document Reference
  - [ ] Item Category
  - [ ] Pick-Up Date
  - [ ] Create Request button (in bottom area)
- [ ] There is consistent horizontal padding; no field or text is flush against screen edges.

2.3 **Keyboard behavior**
- [ ] Focusing into text inputs within client or document reference areas brings up the keyboard without overlapping or breaking layout.
- [ ] While the keyboard is visible, the user can still scroll the form and reach other fields.
- [ ] Dismissing the keyboard restores layout without large gaps or misaligned elements.

---

## 3. Client Information Section

3.1 **Client search / selection**
- [ ] A **Client Information** section appears near the top of the form.
- [ ] It allows searching/selecting a client (e.g., via a search field or selection widget), as defined by design.
- [ ] When a client is selected:
  - [ ] Client details (name, identifier, etc.) are displayed.
  - [ ] Changing the client updates the displayed information.

3.2 **Client validation**
- [ ] Attempt to submit the form without selecting a client (if technically possible):
  - [ ] If Client is required, a clear error message indicates that selecting a client is mandatory.

---

## 4. Document Reference Section

4.1 **Document reference presence**
- [ ] A **Document Reference** section appears immediately after the Client Information section.
- [ ] Input fields for reference numbers or related document details are visible.

4.2 **Behavior**
- [ ] You can enter or edit reference values.
- [ ] If multiple reference fields exist, all are functional and scrollable as needed.

4.3 **Validation**
- [ ] If document reference is required, attempt to submit with this section empty:
  - [ ] Clear error messages or indicators appear for the missing required values.

---

## 5. Item Category Selection

5.1 **Item Category dropdown visibility**
- [ ] A field labeled **"Item Category"** is visible in the form.
- [ ] The field looks like a dropdown or selection widget (with caret icon or similar).

5.2 **Dropdown behavior**
- [ ] Tapping the Item Category field opens a list of available item categories (if any exist).
- [ ] Each entry in the list displays a readable category name.
- [ ] Selecting an item category closes the list and shows the chosen value in the field.

5.3 **Empty / no categories case (black-box)**
- [ ] If there are no item categories available, opening the dropdown:
  - [ ] Shows an empty state or no items, but does not crash.
  - [ ] The field may appear disabled or show an informative message.

5.4 **Validation**
- [ ] Attempt to submit the form without selecting an Item Category (if controls allow it):
  - [ ] A clear error message appears near this field, such as "Please select an item category".

---

## 6. Pick-Up Date Field

6.1 **Field visibility**
- [ ] A field labeled **"Pick-Up Date"** is visible.
- [ ] A calendar icon (or similar date icon) is shown within the field.

6.2 **Date picker behavior**
- [ ] Tapping the Pick-Up Date field opens a date picker.
- [ ] You can select a date from the date picker and confirm.
- [ ] The chosen date appears in the field in the correct format.

6.3 **Canceling the picker**
- [ ] If you cancel the date picker, the previous date remains unchanged (or field stays blank if no date was selected previously).

6.4 **Validation**
- [ ] Attempt to submit the form without selecting a Pick-Up Date:
  - [ ] A clear error message appears near the field, such as "Please pick a pick-up date".

---

## 7. Create Request Button & Submission Flow

7.1 **Button visibility and placement**
- [ ] A full-width **Create Request** button is visible in the bottom area of the screen (bottom navigation bar area).
- [ ] The label clearly states the action (e.g., "Create Request").

7.2 **Button enabled/disabled state**
- [ ] If required fields are empty, verify whether the button remains tappable or not (depends on design):
  - [ ] If it is disabled until valid, ensure the disabled state is visibly different from enabled.
  - [ ] If always enabled but relies on validation on tap, ensure error messages appear when data is missing.

7.3 **Loading state**
- [ ] Tap **Create Request** with all required fields filled:
  - [ ] A loading indicator or progress state is shown on the button (e.g., spinner replacing the label or next to it).
  - [ ] While loading, the button does not trigger duplicate submissions when tapped again.

7.4 **Successful submission**
- [ ] On success, the app shows feedback such as a success message/snackbar (e.g., "Request created").
- [ ] Relevant form fields are cleared for a new entry (e.g., prepared by, pick-up date, remarks) or the screen navigates away as per design.
- [ ] If the user is returned to the Request screen or list, the new Air/Sea request appears in the appropriate category list.

7.5 **Error cases (black-box)**
- [ ] Intentionally trigger an error scenario (e.g., disconnect network or violate server-side rules if known):
  - [ ] A clear, user-friendly error message is shown (e.g., "Failed to add request").
  - [ ] The user remains on the form and can adjust data and retry.
  - [ ] Repeatedly tapping Create Request after an error does not crash the app or create duplicates.

---

## 8. Regression & Edge Cases

8.1 **Leave and return to the form**
- [ ] Start filling in the Air/Sea form, navigate back, then reopen it:
  - [ ] Confirm whether data is expected to reset or persist, and verify behavior matches product requirements.

8.2 **Orientation changes**
- [ ] Rotate the device while part of the form is filled:
  - [ ] Layout remains clean; fields and labels do not overlap or get cut off.
  - [ ] Previously entered values remain present where expected.

8.3 **Multiple sequential submissions**
- [ ] Create multiple Air/Sea requests in succession:
  - [ ] Each request is handled correctly without data from previous submissions leaking into the next.
  - [ ] No gradually increasing lag or visual glitches appear.

8.4 **Background/foreground transitions**
- [ ] While the form is open, send the app to the background and bring it back:
  - [ ] The form remains in a reasonable state.
  - [ ] No blank screen or half-rendered UI appears.

---

This checklist is intended for QA testers validating the Air/Sea Request creation flow based solely on visible behavior and UX, without any need to inspect the underlying Dart code, controllers, or repositories.

