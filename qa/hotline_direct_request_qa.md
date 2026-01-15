# QA Overview – Hotline Direct Request Form

## Scope / Overview

Screen name: Hotline Direct Request Form

Purpose: Verify that a user can successfully create a **Hotline Direct** logistics request using this form, and that the UI, validation, and submission behavior are correct, based only on what is visible in the app (no knowledge of the internal code is required).

This QA focuses on the **"Create Hotline Direct Request"** flow, including:
- Opening the Hotline Direct Request Form from the Request screen
- Filling out client information and document reference
- Selecting Shipping Method, Delivery Terms, Delivery Date, Priority, and Requested By
- Submitting the form via the **Create Request** button and validating the outcome

---

## 1. Entry to the Hotline Direct Request Form

1.1 **Navigation from Request screen**
- [ ] From the Request screen, select the category that corresponds to **Hotline Direct** (according to product labels).
- [ ] Tap the **Add/New Request** button (floating action button or similar entry point).
- [ ] Confirm that the Hotline Direct Request Form opens:
  - [ ] The app bar title shows a generic request form title (e.g., "Request Form") consistent with other forms.
  - [ ] Client Information and Document Reference sections are visible at the top.

1.2 **Back navigation from the form**
- [ ] A back arrow or similar control is visible in the top app bar.
- [ ] Tapping the back control returns to the previous screen (usually the Request screen) without crashing.
- [ ] Only one form instance is created per entry (a single back press should exit this form).

---

## 2. App Bar & Overall Layout

2.1 **App bar content**
- [ ] The app bar title text matches the expected request title (e.g., "Request Form") and is consistent with other request forms.
- [ ] The back arrow is clearly visible and functions correctly.

2.2 **Form layout and sections**
- [ ] The form content is vertically scrollable if it does not fit in the viewport.
- [ ] Sections appear in a clear, logical order:
  - [ ] Client Information
  - [ ] Document Reference
  - [ ] Shipping Method
  - [ ] Delivery Terms
  - [ ] Delivery Date
  - [ ] Priority
  - [ ] Requested By
  - [ ] Create Request button (bottom area)
- [ ] There is consistent horizontal padding; no fields or text touch the screen edges.

2.3 **Keyboard behavior**
- [ ] Focusing into any text field (e.g., in client or document reference sections) brings up the keyboard without breaking the layout.
- [ ] While the keyboard is visible, the user can still scroll to all fields and the **Create Request** button.
- [ ] Dismissing the keyboard restores the layout cleanly.

---

## 3. Client Information Section

3.1 **Client search / selection**
- [ ] A **Client Information** section appears at the top of the form.
- [ ] It allows searching/selecting a client (search field, list, or other UI as designed).
- [ ] When a client is selected:
  - [ ] The client’s information (name, code, etc.) appears clearly.
  - [ ] Changing the client updates the displayed information accordingly.

3.2 **Client validation**
- [ ] Attempt to submit the form without selecting a client (if technically possible):
  - [ ] If client selection is required, a clear error message indicates that a client must be selected.

---

## 4. Document Reference Section

4.1 **Document reference presence**
- [ ] A **Document Reference** section appears immediately under Client Information.
- [ ] Fields for document references (numbers/IDs) are visible and usable.

4.2 **Behavior and validation**
- [ ] You can enter or edit values in the document reference fields.
- [ ] If any document reference fields are required, leaving them empty and submitting shows a clear error message near the relevant fields.

---

## 5. Shipping Method Selection

5.1 **Field visibility**
- [ ] A field labeled **"Shipping Method"** is visible.
- [ ] It looks like a dropdown or selection widget (with an arrow icon or similar indicator).

5.2 **Dropdown options and behavior**
- [ ] Tapping **Shipping Method** opens a list with these options:
  - [ ] "Land"
  - [ ] "Air"
  - [ ] "Sea"
- [ ] Selecting an option closes the dropdown and shows the chosen value in the field.

5.3 **Validation**
- [ ] Attempt to submit the form without selecting a shipping method (if allowed):
  - [ ] A clear error is shown near this field if shipping method is required.

---

## 6. Delivery Terms Selection

6.1 **Field visibility**
- [ ] A field labeled **"Delivery Terms"** is visible.
- [ ] An icon indicating delivery/transport (e.g., a truck) appears inside the field.

6.2 **Dropdown behavior**
- [ ] Tapping **Delivery Terms** opens a list of options:
  - [ ] "Partial"
  - [ ] "Full"
- [ ] Selecting an option closes the dropdown and displays the chosen value.

6.3 **Validation**
- [ ] Attempt to submit without choosing delivery terms (if allowed):
  - [ ] If required, a clear error appears indicating that delivery terms must be selected.

---

## 7. Delivery Date Field

7.1 **Field visibility**
- [ ] A field labeled **"Delivery Date"** is visible.
- [ ] A time/clock icon appears inside the field.

7.2 **Date picker behavior**
- [ ] Tapping the Delivery Date field opens a date (and possibly time) picker.
- [ ] Selecting a date confirms and fills the field with the chosen date in the correct format.

7.3 **Cancel behavior**
- [ ] Canceling the picker leaves the previous value unchanged (or keeps it blank if none was selected earlier).

7.4 **Validation**
- [ ] Attempt to submit the form without selecting a Delivery Date:
  - [ ] A clear error message appears near this field, such as "Please pick a delivery date".

---

## 8. Priority Selection

8.1 **Field visibility**
- [ ] A field labeled **"Priority"** is visible, possibly centered in the form.
- [ ] An icon indicating status/priority appears in the field.

8.2 **Dropdown options and behavior**
- [ ] Tapping **Priority** opens a list of options:
  - [ ] "High"
  - [ ] "Medium"
  - [ ] "Low"
- [ ] Selecting an option closes the list and displays the chosen priority.

8.3 **Validation**
- [ ] If Priority is required, attempt to submit without selecting it:
  - [ ] An error message clearly indicates that a priority must be selected.

---

## 9. Requested By Selection

9.1 **Field visibility**
- [ ] A field labeled **"Requested By"** is visible near the bottom of the form.
- [ ] An icon representing a person or ID card appears in the field.

9.2 **Dropdown behavior**
- [ ] Tapping **Requested By** opens a list of users/staff.
- [ ] Each list entry shows the user’s display name.
- [ ] Selecting a user closes the dropdown and displays the chosen name in the field.

9.3 **User list content (black-box)**
- [ ] The list appears to contain real user records (no placeholder text or obviously invalid entries).

9.4 **Validation**
- [ ] Attempt to submit without selecting a requester (if allowed):
  - [ ] If required, a clear error message indicates that "Requested By" must be selected.

---

## 10. Create Request Button & Submission Flow

10.1 **Button visibility and placement**
- [ ] A full-width **Create Request** button is visible in the bottom area of the screen (bottom navigation bar area).
- [ ] The label clearly indicates the action (e.g., "Create Request").

10.2 **Validation on submit**
- [ ] With missing required data (e.g., client, shipping method, delivery date, requested by), tapping **Create Request**:
  - [ ] Shows clear error messages near the relevant fields.
  - [ ] Does not proceed with an invalid submission.

10.3 **Loading state**
- [ ] When all required fields are valid and **Create Request** is tapped:
  - [ ] A loading indicator or progress state is visible (e.g., button shows a spinner).
  - [ ] The button does not allow repeated submissions while loading.

10.4 **Successful submission**
- [ ] On success:
  - [ ] A confirmation feedback appears (e.g., a snackbar or toast indicating that the request was created).
  - [ ] The form either resets for a new request or navigates back to the Request screen, depending on product behavior.
  - [ ] If returning to the Request screen, the new Hotline Direct request is visible in the appropriate list/category.

10.5 **Error scenarios (black-box)**
- [ ] In case of network/server errors or validation failures from the backend:
  - [ ] A clear, user-friendly error message (not technical) appears.
  - [ ] The user stays on the form and can adjust inputs and retry.
  - [ ] Repeated taps after an error do not crash the app or create duplicates.

---

## 11. Regression & Edge Cases

11.1 **Leaving and returning to the form**
- [ ] Start filling the Hotline Direct form, navigate back, then reopen the form:
  - [ ] Confirm whether data is expected to reset or persist and verify behavior matches requirements.

11.2 **Orientation changes**
- [ ] Rotate the device while the form is partially filled:
  - [ ] Layout remains clean and readable; labels and fields do not overlap or get cut off.
  - [ ] Field values remain populated where expected.

11.3 **Multiple sequential submissions**
- [ ] Create multiple Hotline Direct requests one after another:
  - [ ] Each new request uses a fresh form state (unless persistence is explicitly intended).
  - [ ] No data from a previous submission appears unexpectedly in the next.

11.4 **Background/foreground transitions**
- [ ] While the form is open, send the app to the background and then bring it back:
  - [ ] The form remains in a usable state (no blank screens or corrupt layouts).

---

This checklist is intended for QA testers validating the Hotline Direct Request creation flow based solely on visible behavior and UX, without any need to inspect the underlying Dart code, controllers, or repositories.

