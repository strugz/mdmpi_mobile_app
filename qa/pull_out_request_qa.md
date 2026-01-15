# QA Overview – Pull Out Request Form

## Scope / Overview

Screen name: Pull Out Request Form

Purpose: Verify that a user can successfully create a **Pull Out** request using this form and that the UI, validation, data selections, and submission behavior are correct, based only on what is visible in the app (no knowledge of the internal code is required).

This QA focuses on the **"Create Pull Out Request"** flow, including:
- Opening the Pull Out form (from the Request screen or other entry point)
- Filling out client, document, and pull-out-specific details
- Selecting form and item categories
- Setting IRRF details, reason, pull out date, and requester
- Submitting the form via the **Create Request** button

---

## 1. Entry to the Pull Out Request Form

1.1 **Navigation from Request screen**
- [ ] From the Request screen, select the category that corresponds to **Pull Out** (per product design).
- [ ] Tap the **Add/New Request** button (floating action button or equivalent entry point).
- [ ] Confirm that the Pull Out Request Form opens (title and content indicate a request form for Pull Out).

1.2 **Back navigation from the form**
- [ ] A back arrow or similar control is visible in the top app bar.
- [ ] Tapping the back control returns to the previous screen (usually the Request screen) without crashing.
- [ ] Only a single form instance is in the back stack (pressing back does not step through multiple identical forms from a single entry).

---

## 2. App Bar & Overall Layout

2.1 **App bar content**
- [ ] The app bar title clearly indicates a request form context (e.g., "Request Form").
- [ ] The back button is clearly visible and functions correctly.

2.2 **Form layout and sections**
- [ ] The form content is scrollable vertically if it does not fit on the screen.
- [ ] Sections appear in a clear, logical order:
  - [ ] Client Information
  - [ ] Document Reference
  - [ ] Form Category (read-only, pre-selected)
  - [ ] Item Category
  - [ ] Client Contact Person
  - [ ] IRRF Number
  - [ ] IRRF Date
  - [ ] Reason for Return
  - [ ] Pull Out Date
  - [ ] Requested By
  - [ ] Create Request button
- [ ] Left/right padding ensures that no field touches the screen edges.

2.3 **Keyboard behavior**
- [ ] Focusing into any text field brings up the keyboard without overlapping or breaking the UI.
- [ ] While the keyboard is visible, the user can still scroll to the remaining fields and to the **Create Request** button.
- [ ] Dismissing the keyboard restores the layout to normal without large empty gaps.

---

## 3. Client Information Section

3.1 **Client search / selection**
- [ ] A **Client Information** section is visible at the top of the form.
- [ ] It allows searching/selecting a client (per design: search bar, list, etc.).
- [ ] When a client is selected:
  - [ ] The client’s details (e.g., name, code, address) appear in the section.
  - [ ] Changing the client updates the displayed information.

3.2 **Client validation**
- [ ] Attempt to submit the form without selecting a client (if technically possible):
  - [ ] If a client is required, a clear error message indicates that client selection is mandatory.

---

## 4. Document Reference Section

4.1 **Document reference presence**
- [ ] A **Document Reference** section is visible under Client Information.
- [ ] It contains fields appropriate for referencing related documents (e.g., numbers, IDs) based on design.

4.2 **Behavior and validation**
- [ ] Values can be entered or selected in the document reference area.
- [ ] If any of these fields are required for a Pull Out request, leaving them empty and attempting submission shows clear, readable error messages.

---

## 5. Form Category (Read-Only)

5.1 **Form Category field visibility**
- [ ] A **Form Category** dropdown-like field is shown.
- [ ] The field displays the Pull Out form category name.
- [ ] The field appears read-only (cannot be changed by the user) as per design.

5.2 **Pre-selection behavior**
- [ ] When opening the form from a Pull Out category in the Request screen, **Form Category** shows the correct category automatically.
- [ ] If opened not from the Request screen, check that the default Form Category still makes sense or matches requirements.

5.3 **Empty / error state**
- [ ] In case no category is loaded, the field shows an appropriate empty or error display instead of causing a crash.

---

## 6. Item Category

6.1 **Item Category dropdown**
- [ ] An **Item Category** dropdown is visible under Form Category.
- [ ] Opening the dropdown shows available item categories (if any exist).
- [ ] Selecting a category updates the displayed value.

6.2 **Validation**
- [ ] Attempt to submit the form without selecting an Item Category (if controls allow it):
  - [ ] If required, an error such as "Please select an item category" is displayed clearly.

6.3 **No categories available (black-box)**
- [ ] If no item categories exist, the dropdown appears empty or disabled but does not break the form layout.

---

## 7. Client Contact Person

7.1 **Field behavior**
- [ ] A **Client Contact Person** text field is visible.
- [ ] You can type a name or contact person into the field.
- [ ] Text is fully visible within the field without clipping.

7.2 **Validation (if required)**
- [ ] If the contact person is required, try submitting without a value:
  - [ ] A clear error message is shown near this field or in a consistent error area.

---

## 8. IRRF Number

8.1 **Field behavior**
- [ ] An **IRRF Number** text field is visible.
- [ ] Only numeric input is accepted (letters should not be allowed if the design expects digits only).
- [ ] Large numbers are still visible and scrollable horizontally (if needed) inside the field.

8.2 **Validation**
- [ ] If IRRF Number is required, submitting without it triggers a clear error.
- [ ] If specific formatting rules apply (e.g., length), invalid values show a user-friendly error.

---

## 9. IRRF Date

9.1 **Field and picker**
- [ ] An **IRRF Date** field is visible with an appropriate calendar icon.
- [ ] Tapping the field opens a date picker.

9.2 **Date selection**
- [ ] Selecting a date fills the field with the chosen date in the correct format.
- [ ] Canceling the date picker leaves the previous value unchanged (or blank if none selected).

9.3 **Validation**
- [ ] If IRRF Date is required, trying to submit without it triggers a clear error.

---

## 10. Reason for Return

10.1 **Field behavior**
- [ ] A **Reason for Return** multi-line text field is visible.
- [ ] You can type multiple lines of text (e.g., more than one sentence).
- [ ] The field grows or scrolls as needed so text is visible.

10.2 **Validation**
- [ ] If a reason is required, submitting with an empty field shows a clear error message.

---

## 11. Pull Out Date

11.1 **Field and picker**
- [ ] A **Pull Out Date** field is visible, with an appropriate time/date icon.
- [ ] Tapping the field opens a date picker.

11.2 **Date selection and display**
- [ ] Selecting a date populates the field with the chosen date.
- [ ] Canceling leaves the field unchanged.

11.3 **Required validation**
- [ ] Attempt to submit without selecting a Pull Out Date:
  - [ ] A clear error message appears, such as "Please pick a pull out date".

---

## 12. Requested By

12.1 **Requested By dropdown**
- [ ] A **Requested By** dropdown field is visible near the bottom of the form.
- [ ] It shows a list of user/staff names when opened.
- [ ] Selecting a user updates the displayed name in the field.

12.2 **User list content (black-box)**
- [ ] The dropdown list appears to reflect actual users from the app environment (no obvious placeholder or junk values).

12.3 **Validation**
- [ ] Attempt to submit without selecting a requester (if allowed):
  - [ ] If required, an error such as "Please select requestor" is shown clearly.

---

## 13. Create Request Button & Submission Flow

13.1 **Button visibility and label**
- [ ] A full-width **Create Request** button is visible in a fixed bottom area of the screen.
- [ ] The label text is clearly readable and matches UX copy.

13.2 **Loading state**
- [ ] When tapping **Create Request**, if processing takes time, a loading state or spinner is visible.
- [ ] While loading, the button should visually indicate that the action is in progress (and may be temporarily disabled).

13.3 **Successful submission**
- [ ] Fill in all required fields with valid data.
- [ ] Tap **Create Request**:
  - [ ] A success message or snackbar appears (e.g., informing that the request was created).
  - [ ] The form clears or resets where expected (e.g., fields are emptied for a new entry).
  - [ ] Optionally, the user is returned to the Request screen or a list view; if so, the new Pull Out request appears in the relevant list.

13.4 **Error scenarios (black-box)**
- [ ] Intentionally cause an error (e.g., missing required field, no network):
  - [ ] A clear, user-friendly error message is shown, not just a generic or technical error.
  - [ ] The user remains on the form and can fix inputs and retry.
  - [ ] Multiple taps while an error is present do not crash the app or create duplicates.

---

## 14. Regression & Edge Cases

14.1 **Leave and return to the form**
- [ ] Start filling in the Pull Out form, navigate back, and then reopen the form:
  - [ ] Confirm whether data is expected to reset or persist, and verify behavior matches the requirements.

14.2 **Orientation changes**
- [ ] Rotate the device while the form has data filled in:
  - [ ] Layout remains readable and fields do not overlap.
  - [ ] Previously entered values remain intact where expected.

14.3 **Multiple submissions**
- [ ] Attempt to tap **Create Request** multiple times quickly:
  - [ ] The app does not create unintended duplicate requests.
  - [ ] Any safeguards (e.g., disabling the button while saving) behave correctly from a user perspective.

---

This checklist is intended for QA testers validating the Pull Out Request creation flow based solely on visible behavior and UX, without any need to inspect the underlying Dart code, controllers, or repositories.

