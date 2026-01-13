# QA Overview – Pick-Up Request Form

## Scope / Overview

Screen name: Pick-Up Request Form

Purpose: Verify that a user can successfully create a **Pick-Up** request using this form and that the UI, validation, and submission behavior are correct, based only on what is visible in the app (no knowledge of the internal code is required).

This QA focuses on the **"Create Pick-Up Request"** flow, including:
- Opening the Pick-Up Request Form from the Request screen
- Filling out client information and document reference
- Selecting an Item Category
- Choosing a Pick-Up Date
- Submitting the form via the **Create Request** button and validating the outcome

---

## 1. Entry to the Pick-Up Request Form

1.1 **Navigation from Request screen**
- [ ] From the Request screen, select the category that corresponds to **Pick-Up** (according to the product design labels).
- [ ] Tap the **Add/New Request** button (floating action button or similar entry point).
- [ ] Confirm that the Pick-Up Request Form opens:
  - [ ] The app bar title clearly indicates a Pick-Up request form (e.g., "Pick-Up Request Form").
  - [ ] The content shows client information and document reference sections at the top.

1.2 **Back navigation from the form**
- [ ] A back arrow or similar control is visible in the top app bar.
- [ ] Tapping the back control returns to the previous screen (usually the Request screen) without crashing.
- [ ] Only one form instance is created per entry (pressing back once exits the form; there are no duplicate screens in the back stack).

---

## 2. App Bar & Overall Layout

2.1 **App bar content**
- [ ] The app bar title text clearly refers to a Pick-Up request form.
- [ ] The back arrow is clearly visible and functions correctly.

2.2 **Form layout and sections**
- [ ] The form content is vertically scrollable if it does not fit on a single screen.
- [ ] Sections appear in a clear, logical order:
  - [ ] Client Information
  - [ ] Document Reference
  - [ ] Item Category
  - [ ] Pick-Up Date
  - [ ] Create Request button (in the bottom area)
- [ ] There is consistent horizontal padding; no text or fields touch the screen edges.

2.3 **Keyboard behavior**
- [ ] Focusing into any text field (in client/document sections) brings up the keyboard without overlapping or breaking the UI.
- [ ] While the keyboard is visible, the user can still scroll to other fields and to the **Create Request** button.
- [ ] Dismissing the keyboard restores the layout without leaving large empty gaps.

---

## 3. Client Information Section

3.1 **Client search / selection**
- [ ] A **Client Information** section appears at the top of the form.
- [ ] It allows searching/selecting a client as defined by the UI (search field, list, etc.).
- [ ] When a client is selected:
  - [ ] The client’s details (name, code, address, or similar) are displayed.
  - [ ] Changing the client updates the displayed details accordingly.

3.2 **Client validation**
- [ ] Attempt to submit the form without selecting a client (if technically possible):
  - [ ] If client selection is required, a clear error message indicates that a client must be selected.

---

## 4. Document Reference Section

4.1 **Document reference presence**
- [ ] A **Document Reference** section appears under Client Information.
- [ ] Fields for document references (numbers/IDs) are visible and usable.

4.2 **Behavior and validation**
- [ ] You can enter or edit values in the document reference fields.
- [ ] If specific reference fields are required for Pick-Up requests, leaving them empty and submitting shows a clear error message near the relevant fields.

---

## 5. Item Category Selection

5.1 **Item Category dropdown visibility**
- [ ] A field labeled **"Item Category"** is visible.
- [ ] The field looks like a dropdown/selection widget (e.g., caret icon, tap to open list).

5.2 **Dropdown behavior**
- [ ] Tapping the Item Category field opens a list of available item categories (if any exist).
- [ ] Entries show readable category names.
- [ ] Selecting an item category closes the list and displays the chosen value in the field.

5.3 **Empty / no categories case (black-box)**
- [ ] If no item categories exist, opening the dropdown:
  - [ ] Shows an empty or "no items" state, or appears disabled, but does not crash the app.

5.4 **Validation**
- [ ] Attempt to submit the form without selecting an Item Category (if controls allow it):
  - [ ] A clear error message appears near this field, such as "Please select an item category".

---

## 6. Pick-Up Date Field

6.1 **Field visibility**
- [ ] A field labeled **"Pick-Up Date"** is visible.
- [ ] A calendar icon is shown to indicate date selection.

6.2 **Date picker behavior**
- [ ] Tapping the Pick-Up Date field opens a date picker.
- [ ] Selecting a date fills the field with the chosen date in the correct format.

6.3 **Canceling the picker**
- [ ] Canceling the date picker leaves the field unchanged (previous value or blank if none was selected before).

6.4 **Validation**
- [ ] Attempt to submit the form without selecting a Pick-Up Date:
  - [ ] A clear error appears near this field, such as "Please pick a pick-up date".

---

## 7. Create Request Button & Submission Flow

7.1 **Button visibility and placement**
- [ ] A full-width **Create Request** button is visible in the bottom area of the screen.
- [ ] The button label clearly indicates the action (e.g., "Create Request").

7.2 **Loading state and button behavior**
- [ ] When **Create Request** is tapped with valid input:
  - [ ] A loading indicator appears on or near the button (e.g., spinner), indicating that the request is being processed.
  - [ ] While loading, tapping the button again does not cause multiple submissions.

7.3 **Validation on submit**
- [ ] With missing required data (e.g., client, item category, or pick-up date), tapping **Create Request** shows relevant error messages and does not proceed with submission.

7.4 **Successful submission**
- [ ] Fill in the form with valid values for all required fields and tap **Create Request**:
  - [ ] A success message/snackbar appears, such as "Request created".
  - [ ] Form fields related to prepared by, item prepared at, item prepared end at, date pick-up, remarks, released by, and received by (if visible) are reset or cleared.
  - [ ] When returning to the Request screen or list, the new Pick-Up request appears in the appropriate category.

7.5 **Error handling (black-box)**
- [ ] Intentionally create an error scenario (e.g., offline network, server rejects data if reproducible):
  - [ ] A clear, user-friendly error message appears (e.g., "Failed to add request").
  - [ ] The user remains on the form and can adjust values and retry.
  - [ ] Repeated taps on **Create Request** after an error do not cause crashes or duplicate requests.

---

## 8. Regression & Edge Cases

8.1 **Leaving and returning to the form**
- [ ] Start filling in the Pick-Up form, navigate back, and then reopen it:
  - [ ] Confirm whether data is expected to reset or persist, and verify behavior matches requirements.

8.2 **Orientation changes**
- [ ] Rotate the device while fields are filled in:
  - [ ] Layout remains readable; labels and fields do not overlap or get cut off.
  - [ ] Previously entered values remain in place where expected.

8.3 **Multiple sequential submissions**
- [ ] Create multiple Pick-Up requests one after another:
  - [ ] Each new request is processed correctly with a fresh, empty form (as per design).
  - [ ] No data from a previous submission leaks into the next one.

8.4 **Background/foreground transitions**
- [ ] While the form is open, send the app to the background and then bring it back:
  - [ ] The screen remains in a consistent and usable state (no blank screens or corrupted layouts).

---

This checklist is intended for QA testers validating the Pick-Up Request creation flow based solely on visible behavior and UX, without any need to inspect the underlying Dart code, controllers, or repositories.

