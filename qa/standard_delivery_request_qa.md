# QA Overview – Standard Delivery Request Form

## Scope / Overview

Screen name: Standard Delivery Request Form

Purpose: Verify that a user can successfully create a **Standard Delivery** request using the form, and that the UI, validation, data selections, and submission behavior are correct, based only on what is visible in the app (no knowledge of the internal code is required).

This QA focuses on the **"Create Request" flow for Standard Delivery**, including:
- Opening the Standard Delivery form (from the Request screen or other entry point)
- Filling out client, document, and delivery details
- Selecting categories, shipping method, terms, dates, priority, and requester
- Submitting the form via the **Create Request** button

---

## 1. Entry to the Standard Delivery Request Form

1.1 **Navigation from Request screen**
- [ ] From the Request screen, select a category that corresponds to Standard Delivery (per product design).
- [ ] Tap the **Add/New Request** button (floating action button or other entry point).
- [ ] Confirm that the Standard Delivery Request Form opens (title and content indicate Standard Delivery).

1.2 **Back navigation from the form**
- [ ] A back arrow or similar control is visible in the top app bar.
- [ ] Tapping back returns to the previous screen (usually the Request screen) without crash.
- [ ] No duplicate forms are left in the back stack (back should not step through multiple identical forms after a single entry).

---

## 2. App Bar & Overall Layout

2.1 **App bar content**
- [ ] The app bar title clearly indicates that the user is on a **Request Form** for Standard Delivery (e.g., "Request Form" or equivalent, plus context from navigation).
- [ ] The back button is clearly visible and functional.

2.2 **Form layout and scrolling**
- [ ] The form content is vertically scrollable if it does not fit on the screen.
- [ ] All sections appear in a logical top-to-bottom order:
  - [ ] Client information
  - [ ] Document reference
  - [ ] Item and form categories
  - [ ] Shipping and delivery settings
  - [ ] Target delivery date
  - [ ] Priority
  - [ ] Requested By (user selection)
  - [ ] Create Request button
- [ ] There is consistent padding on left/right so fields are not flush with screen edges.

2.3 **Keyboard behavior**
- [ ] Focusing any text field brings up the keyboard without breaking the layout.
- [ ] While keyboard is open, you can still scroll to relevant fields and to the **Create Request** button.
- [ ] Dismissing the keyboard restores the layout without leaving large empty spaces.

---

## 3. Client Information Section

3.1 **Client search / selection**
- [ ] A **Client Information** area is visible near the top of the form.
- [ ] It allows searching or selecting a client (per design – search field, picker, etc.).
- [ ] When a client is selected:
  - [ ] The client’s main details are displayed (e.g., name, code, address depending on design).
  - [ ] Changing the client updates the displayed information accordingly.

3.2 **Validation for client**
- [ ] Attempt to submit the form without selecting a client (if allowed by controls):
  - [ ] If client is required, a clear error message shows that client selection is mandatory.

---

## 4. Document Reference Section

4.1 **Document reference fields**
- [ ] A **Document Reference** section is visible.
- [ ] Fields such as reference number, type, or related information appear as per requirements.

4.2 **Document reference behavior**
- [ ] You can type or select values for document reference fields.
- [ ] If there is any auto-generated or auto-filled value, it appears correctly when the form opens.

4.3 **Validation**
- [ ] If document reference fields are required, test submission with them empty:
  - [ ] Clear and understandable error messages are shown in the document reference area.

---

## 5. Item Category & Form Category Dropdowns

5.1 **Item Category dropdown**
- [ ] The **Item Category** dropdown is visible.
- [ ] When opened, it shows a list of available item categories (if any exist on the device/server).
- [ ] You can select an item category and see the selected value displayed in the field.
- [ ] If there are no item categories available, the field should appear empty and/or show an appropriate state (e.g., empty list, disabled behavior) but not crash.

5.2 **Form Category dropdown**
- [ ] The **Form Category** dropdown is visible below Item Category.
- [ ] It shows a list of form categories when opened (if any are configured).
- [ ] The selected category (if pre-selected from the Request screen) appears correctly when the form opens.
- [ ] You can change the category (if the design allows changes) and the displayed value updates.
- [ ] If no form categories are available, the field should appear empty/disabled but the form remains stable.

5.3 **Relationship with Request screen category**
- [ ] When opening the Standard Delivery form from a specific category in the Request screen:
  - [ ] The **Form Category** field reflects that selected category, if that is the expected behavior.

---

## 6. Shipping Method & Delivery Terms

6.1 **Shipping Method dropdown**
- [ ] A **Shipping Method** dropdown is visible.
- [ ] Its options include the expected methods (e.g., **Land**, **Air**, **Sea**).
- [ ] Selecting a method updates the selected value shown in the field.

6.2 **Delivery Terms dropdown**
- [ ] A **Delivery Terms** field is visible.
- [ ] Its options include the expected terms (e.g., **Partial**, **Full**).
- [ ] Selecting a term updates the displayed value.

6.3 **Validation**
- [ ] If Shipping Method and/or Delivery Terms are required, attempt to submit without choosing them:
  - [ ] Error messages appear clearly near these fields or in a consistent spot.

---

## 7. Delivery Date (Target Date)

7.1 **Delivery Date field**
- [ ] A **Delivery Date** field is visible.
- [ ] Tapping the field opens a date picker (calendar-style or platform-appropriate UI).

7.2 **Date selection behavior**
- [ ] You can select a valid date; the field shows the chosen date in the correct format.
- [ ] Canceling the date picker keeps the previous value (or empties it if none selected previously) without error.

7.3 **Validation**
- [ ] If a delivery date is required, attempt to submit without selecting a date:
  - [ ] A clear error is shown indicating that Delivery Date is required.

---

## 8. Priority Selection

8.1 **Priority dropdown**
- [ ] A **Priority** dropdown is visible.
- [ ] It offers typical options such as **High**, **Medium**, **Low**.
- [ ] Selecting a priority updates the displayed value.

8.2 **UI layout**
- [ ] Priority field is centered (if designed so) and laid out cleanly, with no cut-off text.

8.3 **Validation**
- [ ] If Priority is required, attempt to submit without selecting it:
  - [ ] An appropriate error indication appears.

---

## 9. Requested By (User Selection)

9.1 **Requested By dropdown**
- [ ] A **Requested By** field is visible.
- [ ] It shows a list of users or staff when opened.
- [ ] A search capability (if present) works correctly: typing filters the user list.
- [ ] Selecting a user updates the displayed name in the field.

9.2 **User list content (black-box)**
- [ ] The list appears populated with valid user names (no placeholder/dummy data visible).

9.3 **Validation**
- [ ] Attempt to submit with **Requested By** empty (if controls allow):
  - [ ] If required, an error clearly indicates that this field must be filled.

---

## 10. Create Request Button & Submission Flow

10.1 **Button visibility and label**
- [ ] A full-width **Create Request** button is visible at the bottom of the screen (as a bottom action).
- [ ] The button label is clearly readable and matches UX copy (e.g., "Create Request").

10.2 **Button enabled/disabled state**
- [ ] If the form enforces required fields before enabling the button, verify that:
  - [ ] The button is disabled initially.
  - [ ] It becomes enabled only when required fields are filled.
- [ ] Visual difference between disabled and enabled states is clear.

10.3 **Successful submission**
- [ ] Fill out the form with valid data in all required fields.
- [ ] Tap **Create Request**:
  - [ ] A loading indicator or progress feedback is shown if the operation takes time.
  - [ ] On success, the app navigates back to an appropriate screen (e.g., the Request list) or shows a success message.
  - [ ] The new request appears in the correct Standard Delivery list/category, if visible.

10.4 **Submission errors (black-box)**
- [ ] Intentionally cause an error (e.g., no network, or invalid required field if server rejects it):
  - [ ] A clear, user-friendly error message is shown.
  - [ ] The user remains on the form and can correct data and retry.
  - [ ] No duplicate submissions happen if the button is tapped multiple times during an error (if that is restricted by design).

---

## 11. Regression & Edge Cases

11.1 **Leaving and returning to the form**
- [ ] Start filling out a Standard Delivery request, then navigate back/cancel and reopen the form:
  - [ ] Confirm whether data is expected to reset or persist (per requirements) and that behavior matches expectations.

11.2 **Orientation changes**
- [ ] Rotate the device while the form is partially filled:
  - [ ] Layout remains clean; no overlapping or off-screen controls.
  - [ ] Fields preserve their values where expected.

11.3 **Multiple submissions**
- [ ] Try submitting multiple times:
  - [ ] The app does not create unintended duplicate requests.
  - [ ] Any safeguards (e.g., disabling the button while processing) behave correctly.

---

This checklist is intended for QA testers validating the Standard Delivery Request creation flow based solely on visible behavior and UX, without any need to inspect the underlying Dart code, controllers, or repositories.

