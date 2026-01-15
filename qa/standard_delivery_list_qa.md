# QA Overview – Standard Delivery List

## Scope / Overview

Screen name: Standard Delivery List (BList)

Purpose: Verify that the **Standard Delivery list** screen correctly displays, refreshes, and reacts to user interactions with delivery requests, based only on what is visible in the app (no knowledge of internal code is required), while the behavior of taps and long-presses is described at a high level.

This QA focuses on:
- How the list behaves with data, while loading, and when empty
- Pull-to-refresh and loading indicator behavior
- Tapping and long-pressing on Standard Delivery requests
- Role-dependent behavior when a request is tapped (from a black-box POV)
- **Status-based modal dialogs** for preparation-stage statuses ("New Request", "Getting Supplies Ready", "Item Prepared")
- **Request Transport screen** (map, dispatcher panel, dispatch/drop-off flows) when tapping "Item Prepared" or "For Delivery" requests

---

## 1. Entry & Embedding

1.1 **Visibility in the Request flow**
- [ ] From the logistics/Request screens, navigate to the **Standard Delivery** tab/category.
- [ ] Confirm that a vertical list of Standard Delivery requests appears when data is available.
- [ ] Confirm that the list occupies the expected area on the screen (e.g., under filters/tabs), with proper padding.

1.2 **Back navigation (screen-level)**
- [ ] Using the screen’s back navigation (app bar back or system back) returns to the previous screen correctly and does not leave orphan overlays or dialogs.

---

## 2. Loading State (Shimmer)

2.1 **Initial loading**
- [ ] When navigating to the Standard Delivery list and data is still loading, a loading placeholder is shown instead of a blank area.
- [ ] This placeholder appears as a shimmer-like rectangle sized similar to a list item (approx. card-sized).
- [ ] Only the shimmer placeholder is visible (no old/incorrect data) while loading.

2.2 **End of loading**
- [ ] Once loading completes and data is available, the shimmer disappears and the list of requests is shown.
- [ ] There is no momentary flash of both shimmer and list overlapping.

---

## 3. Non-Empty List Behavior

> When there are one or more Standard Delivery requests matching the current filters.

3.1 **List layout**
- [ ] The list shows one card per Standard Delivery request, arranged vertically.
- [ ] There is consistent vertical spacing between request cards.
- [ ] The list is scrollable when there are more items than fit on the screen.

3.2 **Pull-to-refresh interaction**
- [ ] Pulling down from the top of the list triggers a refresh spinner.
- [ ] After releasing, new data is fetched and the list updates accordingly.
- [ ] Refresh can be triggered even if the list is long (scroll to top and pull down).

3.3 **Loading lock-out behavior**
- [ ] While a loading/refresh operation is in progress, list items and interactions are temporarily disabled (no accidental multiple actions).
- [ ] Once loading finishes, items become interactive again.

3.4 **Request item contents (black-box)**
- [ ] Each card shows key information for a Standard Delivery request (e.g., ID, client, date, status) based on design.
- [ ] Text is readable and does not overflow or overlap.

---

## 4. Empty State (No Requests Found)

> When filters result in zero Standard Delivery requests.

4.1 **Empty state UI**
- [ ] Instead of an empty list, an **empty state** is shown in the center of the available space.
- [ ] Elements include:
  - [ ] An inbox-style icon.
  - [ ] A primary message like **"No Delivery requests found"**.
  - [ ] A secondary message like **"Try adjusting your filters"**.

4.2 **Theming**
- [ ] In light mode, icon and text colors are readable (e.g., dark grey on light background).
- [ ] In dark mode, icon and text colors remain readable (e.g., light colors on dark background).

4.3 **Pull-to-refresh from empty state**
- [ ] You can still pull down to refresh from the empty state (scrollable area allows pull-to-refresh).
- [ ] A refresh spinner appears, and new data is loaded if available.
- [ ] After refresh, either the list shows new items or the empty state persists if there are still none.

4.4 **Loading vs empty**
- [ ] When there are no requests *and* data is loading, only a loading indication is shown (not the empty state) until loading completes.

---

## 5. Interaction Components & What They Do

### 5.1 Request Card (Tap)

**Component:** Each list row is a tappable card representing a Standard Delivery request.

**What QA sees & should verify:**
- [ ] Cards show hover/press feedback when tapped (ripple or highlight).
- [ ] Tapping a card opens the appropriate **request action flow** or **detail dialog** depending on the user’s role and the request’s status.
- [ ] The exact dialog or actions offered may differ by user role and status, but from QA’s perspective:
  - [ ] For users with edit or action permissions (e.g., Release/Courier roles), tapping should show the appropriate actions (e.g., update status, record events) for that status.
  - [ ] For viewer-only roles, tapping should show a read-only view or limited actions.
  - [ ] For completed or cancelled requests, tapping shows a view appropriate for done/cancelled items (e.g., view-only summary, no mutating actions).

**Behavior summary (black-box by role & status):**
- **Statuses like "Done Delivery" / "Cancelled"**
  - [ ] Tapping shows a default view of request details with no further workflow steps (detailed in Section 5.4.3 and 5.4.4).
- **Preparation-stage statuses (e.g., "New Request", "Getting Supplies Ready", "Item Prepared")**
  - [ ] Users with "Release" permission should see actions relevant to preparing and releasing items.
  - [ ] Users with only "Request"/viewer rights see limited or view-only interactions.
  - [ ] Tapping a request with these statuses opens a **modal bottom sheet** (detailed QA below in Section 5.4).
- **Delivery-stage statuses (e.g., "Item Prepared", "For Delivery")**
  - [ ] Users with "Courier" permission should see delivery-related actions.
  - [ ] If no Courier role exists for the user, but Release role does, Release-level actions may still be surfaced.
  - [ ] Tapping a request with **"Item Prepared"** or **"For Delivery"** status opens the **Request Transport screen** (detailed QA below in Section 5.5).

> QA does not need to know exact role names internally; instead, log in with test accounts that simulate different permissions and validate that tapping a request shows only the appropriate options for each account type and status.

### 5.2 Request Card (Long Press)

**Component:** Long-press gesture on each request card.

**What QA sees & should verify:**
- [ ] Long-pressing a request card that is **not** in a final status (e.g., not "Done Delivery" and not "Cancelled") opens a dialog to **add or view remarks**.
- [ ] The remarks dialog:
  - [ ] Shows current remarks (if any) for that request.
  - [ ] Allows adding or editing remarks as per design.
  - [ ] Has clear actions to save/apply changes or cancel.
- [ ] Long-pressing a request card that **is** in a final status ("Done Delivery" or "Cancelled") should **not** open the remarks dialog.
- [ ] There is clear visual feedback when long-press is recognized (e.g., card briefly highlights before dialog appears).

### 5.3 Pull-to-Refresh Gesture

**Component:** Pull-down gesture on the list or empty area.

**What it does:**
- [ ] When pulled down from the top and released, it refreshes the Standard Delivery requests from the data source.
- [ ] A refresh spinner appears at the top until refresh completes.
- [ ] New or updated requests appear after refresh, or the empty state remains if still no data.

### 5.4 Status-Based Modal Dialogs (Preparation Stage)

**Component:** Bottom sheet modal dialog that opens when tapping requests with preparation-stage statuses: "New Request", "Getting Supplies Ready", or "Item Prepared" (when viewed by non-Courier roles).

**Entry:**
- [ ] Tapping a request card with one of these statuses opens a modal bottom sheet.
- [ ] The modal loads without crashes, blank screens, or delays.

#### 5.4.1 Modal Layout & Design

**Overall appearance:**
- [ ] A modal bottom sheet slides up from the bottom of the screen, covering approximately 60-80% of the screen.
- [ ] The modal has rounded top corners (curved design).
- [ ] Background color adapts to theme:
  - [ ] Light mode: White or light background
  - [ ] Dark mode: Black or dark background
- [ ] The modal content is scrollable if it exceeds the visible area.
- [ ] A safe area is respected (no content is cut off by device notches or system UI).

**Modal header:**
- [ ] The top of the modal displays request information (client name, address, dates, etc.).
- [ ] Text is readable with appropriate color contrast.
- [ ] Information is organized logically (typically: client details, request dates, status).

#### 5.4.2 Document References Section

**Display:**
- [ ] Below the header, a **Document References** section is visible (if the request has document references).
- [ ] Document references are displayed as tappable items or expandable sections.
- [ ] A divider line separates the document references from the content below.

**Interaction:**
- [ ] Tapping a document reference (if interactive) opens details or performs the expected action (e.g., viewing images, downloading documents).

#### 5.4.3 Status-Specific Content

> The content displayed in the modal varies based on the request status and user role.

**For "Done Delivery" status (all roles):**
- [ ] A label "Received By: [Receiver Name]" is displayed at the center.
- [ ] The receiver's captured signature image is displayed below the label.
- [ ] A **"View Delivered Item"** button is visible.
- [ ] Tapping the button opens a dialog showing the proof of delivery image.
- [ ] No action buttons are visible at the bottom (read-only view).

**For "Cancelled" status (all roles):**
- [ ] A **"Cancel Remarks"** section is displayed.
- [ ] The section shows:
  - [ ] The cancellation remarks text.
  - [ ] The date of cancellation.
  - [ ] The user who cancelled the request.
- [ ] A divider separates the cancel remarks from the footer.
- [ ] No action buttons are visible at the bottom (read-only view).

#### 5.4.4 Modal Footer

**Display:**
- [ ] At the bottom of the modal, a footer section displays additional request information:
  - [ ] Prepared by (user initial and timestamp)
  - [ ] Delivered by (user initial and timestamp, if applicable)
  - [ ] Helper (user initial, if applicable)
  - [ ] Other relevant metadata
- [ ] The footer is consistently styled and readable.

#### 5.4.5 Action Buttons (Role & Status Dependent)

**Button placement:**
- [ ] If an action button is present, it appears at the bottom of the modal (below the footer).
- [ ] The button is full-width with appropriate padding.
- [ ] The button stands out visually (elevated or primary style).

**Button labels based on status:**

**"New Request" status:**
- [ ] For users with **Release** permission:
  - [ ] Button is visible and labeled **"Prepare Item"** (or similar, e.g., "Start Preparing").
  - [ ] Tapping the button:
    - [ ] Shows a loading indicator on the button.
    - [ ] Updates the request status to **"Getting Supplies Ready"**.
    - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
    - [ ] On failure: Shows an error message, button returns to enabled state.
- [ ] For users with **Request** role only (no Release):
  - [ ] Button is **not visible** (modal is view-only).
  - [ ] Modal shows request details but no action can be taken.
- [ ] For users with **Courier** role only (no Release):
  - [ ] Button is **not visible** (modal is view-only).
  - [ ] Couriers cannot act on "New Request" status.
- [ ] For users with **Viewer** role:
  - [ ] Button is **not visible** (view-only).

**"Getting Supplies Ready" status:**
- [ ] For users with **Release** permission AND who prepared the item (itemPreparedBy == userInitial):
  - [ ] Button is visible and labeled **"Packed and Ready"** (or similar, e.g., "Mark as Prepared").
  - [ ] Tapping the button:
    - [ ] Shows a loading indicator on the button.
    - [ ] Updates the request status to **"Item Prepared"**.
    - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
    - [ ] On failure: Shows an error message, button returns to enabled state.
- [ ] For users with **Release** permission BUT who did NOT prepare the item (itemPreparedBy != userInitial):
  - [ ] Button is **not visible** (modal is view-only).
  - [ ] Users can view details but cannot change the status (prevents unauthorized status changes).
- [ ] For users with **Request** role only:
  - [ ] Button is **not visible** (view-only).
- [ ] For users with **Courier** role only:
  - [ ] Button is **not visible** (view-only).
- [ ] For users with **Viewer** role:
  - [ ] Button is **not visible** (view-only).

**"Item Prepared" status (non-Courier users):**
- [ ] For users with **Release** permission (no Courier role):
  - [ ] Button is **not visible** (view-only).
  - [ ] Modal shows request details, but Couriers are expected to handle the next step.
- [ ] For users with **Request** role:
  - [ ] Button is **not visible** (view-only).
- [ ] For users with **Viewer** role:
  - [ ] Button is **not visible** (view-only).
- [ ] For users with **Courier** permission:
  - [ ] The **Request Transport screen** opens instead of this modal (see Section 5.5).

#### 5.4.6 Modal Interaction & Behavior

**Scrolling:**
- [ ] If the modal content is long, you can scroll within the modal to see all information.
- [ ] Scrolling is smooth without jank or lag.

**Closing the modal:**
- [ ] Tapping outside the modal (on the dimmed background) closes the modal and returns to the list.
- [ ] Using the system back button or gesture closes the modal.
- [ ] After closing, the list remains in a consistent state (no duplicated items or broken layout).

**Loading state:**
- [ ] When an action button is tapped and processing, the button shows a loading spinner.
- [ ] The modal remains open during processing.
- [ ] Other interactive elements are disabled during loading (cannot tap close or interact with content).

**Success state:**
- [ ] On successful status update, a success message (toast/snackbar) is displayed.
- [ ] The modal automatically closes.
- [ ] The list updates to reflect the new status (the request card shows the updated status).

**Error state:**
- [ ] On failure, an error message is displayed (toast/snackbar with a clear description).
- [ ] The modal remains open.
- [ ] The action button returns to the enabled state (user can retry).

#### 5.4.7 Theme & Visual Consistency

**Light mode:**
- [ ] Modal background is light (white or light grey).
- [ ] Text and icons are dark with good contrast.
- [ ] Action buttons are clearly visible.

**Dark mode:**
- [ ] Modal background is dark (black or dark grey).
- [ ] Text and icons are light with good contrast.
- [ ] Action buttons are clearly visible.

**Consistency:**
- [ ] Typography, spacing, and colors match the app's design system.
- [ ] Modal design is consistent with other modals/dialogs in the app.

#### 5.4.8 Role-Based Behavior Summary (Quick Reference)

| Request Status | Release User (Preparer) | Release User (Not Preparer) | Request Role | Courier Role | Viewer Role |
|---|---|---|---|---|---|
| **New Request** | ✅ "Prepare Item" button visible | ❌ View-only | ❌ View-only | ❌ View-only | ❌ View-only |
| **Getting Supplies Ready** | ✅ "Packed and Ready" button (if preparer) | ❌ View-only (not preparer) | ❌ View-only | ❌ View-only | ❌ View-only |
| **Item Prepared** | ❌ View-only (Courier's turn) | ❌ View-only (Courier's turn) | ❌ View-only | ✅ Opens Request Transport screen | ❌ View-only |
| **For Delivery** | ❌ View-only | ❌ View-only | ❌ View-only | ✅ Opens Request Transport screen (if assigned) | ❌ View-only |
| **Done Delivery** | 👁️ View signature & proof | 👁️ View signature & proof | 👁️ View signature & proof | 👁️ View signature & proof | 👁️ View signature & proof |
| **Cancelled** | 👁️ View cancel remarks | 👁️ View cancel remarks | 👁️ View cancel remarks | 👁️ View cancel remarks | 👁️ View cancel remarks |

#### 5.4.9 Edge Cases & Validations

**Rapid tapping:**
- [ ] Rapidly tapping the action button does not trigger multiple status updates.
- [ ] The button disables or shows loading immediately on first tap.

**Network issues:**
- [ ] If the network is unavailable when tapping the action button, an appropriate error message is shown.
- [ ] The modal remains open, allowing the user to retry after resolving the network issue.

**Permission edge cases:**
- [ ] Users with multiple roles (e.g., both Release and Courier) see the appropriate action based on status priority:
  - [ ] For "New Request" and "Getting Supplies Ready": Release actions are shown.
  - [ ] For "Item Prepared" and "For Delivery": Courier actions (Request Transport screen) are shown.

**Status transition edge cases:**
- [ ] If another user updates the request status while the modal is open, closing and reopening the modal shows the updated status.
- [ ] The list refreshes correctly after successful status changes (pull-to-refresh or automatic refresh).

---

### 5.5 Request Transport Screen (Item Prepared / For Delivery Status)

**Component:** Full-screen map and dispatcher interface that opens when tapping a request with "Item Prepared" or "For Delivery" status.

**Entry:**
- [ ] Tapping a request card with **"Item Prepared"** status opens the Request Transport screen.
- [ ] Tapping a request card with **"For Delivery"** status opens the Request Transport screen.
- [ ] The screen loads without crashes, blank screens, or long delays.

#### 5.5.1 Map Display & Layout

**Top section - Google Map (60% of screen height):**
- [ ] A Google Map occupies approximately the top 60% of the screen.
- [ ] The map displays the user's current location (if location permission is granted).
- [ ] The map is interactive:
  - [ ] You can pan/drag the map.
  - [ ] You can zoom in/out using pinch gestures.
  - [ ] Traffic is enabled and visible (traffic overlay shows on the map).
- [ ] The map shows the initial camera position centered on:
  - [ ] User's current location if available, OR
  - [ ] Default location (Philippines region) if location is unavailable.
- [ ] **"My Location" blue dot** is visible on the map when location permission is granted.

**Markers on map:**
- [ ] A **destination marker** is visible showing the client's delivery address.
- [ ] If a custom destination has been set, that marker is displayed instead.
- [ ] Markers are clearly visible and distinguishable.

**Route polyline (if route is available):**
- [ ] If a route has been calculated, a **polyline** (route path) is drawn from the current location to the destination.
- [ ] The polyline color is visible and contrasts with the map background.
- [ ] The route updates if the destination changes.

#### 5.5.2 Search & Address Input (Top Overlay)

**Search bar (positioned at top of map):**
- [ ] A rounded search bar is visible at the top of the map (with appropriate top and side margins).
- [ ] The search bar displays the destination address:
  - [ ] If a custom destination was set previously (saved in storage), that address is displayed.
  - [ ] Otherwise, the client's address from the request is displayed.
  - [ ] If the client's address is empty, the client's name is displayed.
- [ ] The search bar is tappable.

**Tapping the search bar:**
- [ ] Tapping the search bar activates search mode.
- [ ] The search bar expands or transforms to show a text input field.
- [ ] A cursor appears in the input field, and the keyboard opens.
- [ ] The input field is focused and ready for typing.

**Searching for a location:**
- [ ] You can type a place name or address into the search field.
- [ ] Pressing "Enter" or "Submit" on the keyboard:
  - [ ] Searches for the entered location.
  - [ ] Updates the destination marker on the map to the searched location.
  - [ ] Updates the address text in the search bar.
  - [ ] Closes the keyboard.
- [ ] If the search is invalid or no results are found, appropriate feedback is given (e.g., error message or no change).

**Tapping outside the search field:**
- [ ] Tapping outside the search field (on the map or other areas) closes the keyboard and deactivates search mode.
- [ ] The search bar returns to its default display state.

#### 5.5.3 Map Interaction & Destination Selection

**Tapping on the map (only for "Item Prepared" status):**
- [ ] When the request status is **"Item Prepared"**, tapping anywhere on the map:
  - [ ] Places a new destination marker at the tapped location.
  - [ ] Updates the address in the search bar to the address of the tapped location (reverse geocoding).
  - [ ] Clears any existing route polyline.
  - [ ] Clears any previously selected destination marker.
- [ ] When the request status is **"For Delivery"**, tapping on the map does NOT change the destination (map taps are ignored or have no effect on destination selection).

**Floating Action Button (FAB) - My Location:**
- [ ] A white floating action button with a "my location" icon is visible on the right side of the screen.
- [ ] The FAB is positioned above the bottom sheet (dispatcher panel) with appropriate padding.
- [ ] Tapping the FAB:
  - [ ] Centers the map on the user's current location.
  - [ ] Clears any custom destination marker.
  - [ ] Resets the destination to the default (client's address).
  - [ ] Clears any route polylines.
  - [ ] Updates the map camera to show the user's current location.

**FAB visibility:**
- [ ] The FAB remains visible and accessible even when the bottom sheet (dispatcher panel) is visible.
- [ ] The FAB does not overlap with the bottom sheet content.

#### 5.5.4 Bottom Sheet - Dispatcher Panel (Draggable)

**Layout & appearance:**
- [ ] A bottom sheet occupies approximately 45% of the screen height.
- [ ] The bottom sheet has rounded top corners (curved design).
- [ ] The bottom sheet background color adapts to the theme:
  - [ ] In light mode: Light background (white or light grey).
  - [ ] In dark mode: Dark background (black or dark grey).
- [ ] A **drag handle** (small horizontal bar) is visible at the top center of the bottom sheet, indicating it can be dragged.

**Draggable behavior:**
- [ ] You can drag the bottom sheet up and down by swiping the drag handle or any part of the bottom sheet.
- [ ] The bottom sheet has defined min/max sizes (45% of screen height in this case).
- [ ] Dragging behavior is smooth without jank or stuttering.

**Content scrolling:**
- [ ] The content inside the bottom sheet is scrollable if it exceeds the visible area.
- [ ] Scrolling within the bottom sheet does not accidentally drag the sheet itself (scroll behavior is properly separated).

#### 5.5.5 Request Details Section (Inside Bottom Sheet)

**Client information:**
- [ ] The client's **name** is displayed prominently at the top, in bold.
- [ ] The client's **address** is displayed below the name in smaller text.
- [ ] Text is readable with appropriate color contrast based on the theme.
- [ ] Long client names or addresses are truncated with ellipsis (no overflow).

**ETA (Estimated Time of Arrival):**
- [ ] An **"ETA: [time]"** line is displayed.
- [ ] The ETA updates dynamically if the route changes or the current location changes.
- [ ] If no route is available, the ETA shows a placeholder or "Calculating...".

**Document Reference:**
- [ ] A **Document Reference** component is visible, showing associated documents for the request.
- [ ] The document reference is tappable/expandable if applicable (per its own design).

#### 5.5.6 Delivery-Specific Fields (For "For Delivery" Status Only)

> These fields only appear when the request status is **"For Delivery"**.

**Proof Picture (Camera Icon):**
- [ ] A camera icon button is displayed at the center.
- [ ] Tapping the camera icon:
  - [ ] Opens a camera capture screen titled **"Proof Picture"**.
  - [ ] Allows the user to take a photo as proof of delivery.
  - [ ] After taking the photo, the screen returns to the Request Transport screen.
- [ ] Below the camera icon, the file path or name of the captured image is displayed (if an image was captured).
- [ ] If no image is captured yet, a placeholder text or empty state is shown.

**Receiver Name Field:**
- [ ] A text input field labeled **"Receiver"** is visible.
- [ ] The field has a user icon prefix.
- [ ] You can type into the field to enter the receiver's name.
- [ ] The field supports autocorrect-off behavior (no auto-corrections while typing).

**Signature Capture Button:**
- [ ] A button labeled **"Capture Signature"** (with an edit/pen icon) is visible if no signature has been captured yet.
- [ ] Tapping the button opens a **signature capture dialog/screen**.
- [ ] The signature dialog allows the user to draw a signature using touch gestures.
- [ ] After capturing the signature:
  - [ ] The button label changes to **"Signature Captured (Tap to Redo)"** (with a document upload icon).
  - [ ] The signature dialog closes and returns to the Request Transport screen.

**Signature Preview:**
- [ ] After capturing a signature, a **"Captured Signature:"** label is displayed.
- [ ] Below the label, the captured signature is shown as an image preview.
- [ ] The signature preview has a border for visual separation.
- [ ] The signature image is clear and properly sized (approximately 200 pixels in height).
- [ ] Tapping the "Signature Captured (Tap to Redo)" button allows re-capturing the signature (opens the signature dialog again).

**Divider:**
- [ ] A horizontal divider line separates the main request details from the delivery-specific fields.

#### 5.5.7 Prepared By & Dispatcher Information

**Display:**
- [ ] A section showing **"Prepared By"** and **"Dispatcher"** information is visible below the request details.
- [ ] This section shows who prepared the items and who dispatched them (with names/initials).
- [ ] The information is displayed in a readable format with appropriate labels.

#### 5.5.8 Action Button (Bottom of Bottom Sheet)

**Button appearance:**
- [ ] A full-width elevated button is displayed at the bottom of the bottom sheet.
- [ ] The button is clearly visible and stands out from other content.
- [ ] The button has appropriate padding from the bottom sheet edges.

**Button label based on status:**
- [ ] When the request status is **"Item Prepared"**, the button label is **"Dispatch"**.
- [ ] When the request status is **"For Delivery"**, the button label is **"Drop Off"**.

**Button state - enabled:**
- [ ] When all required fields are filled (if applicable), the button is enabled and tappable.
- [ ] The button shows a visual effect (ripple, highlight) when tapped.

**Button state - loading:**
- [ ] While processing an action (dispatch or drop-off), the button shows a loading spinner/circular progress indicator.
- [ ] The button text is replaced by the spinner during loading.
- [ ] The button is disabled during loading (tapping has no effect).

**Button state - disabled:**
- [ ] If required fields are not filled, the button may be disabled (depending on validation logic).
- [ ] Disabled state is visually distinct (e.g., greyed out or reduced opacity).

#### 5.5.9 Dispatch Flow (Item Prepared Status)

**Scenario:** Request status is "Item Prepared", user has Courier or Release permission.

**What QA sees:**
- [ ] The button label is **"Dispatch"**.
- [ ] No delivery-specific fields (camera, receiver, signature) are visible.
- [ ] Only client info, ETA, document reference, and prepared by/dispatcher info are shown.

**Tapping "Dispatch":**
- [ ] Tapping the "Dispatch" button:
  - [ ] Shows a loading spinner on the button.
  - [ ] Processes the dispatch action (updates the request status in the system).
  - [ ] On success:
    - [ ] Shows a success message (toast/snackbar).
    - [ ] Closes the Request Transport screen and returns to the Standard Delivery list.
    - [ ] The request's status in the list updates to the next stage (e.g., "For Delivery").
  - [ ] On failure:
    - [ ] Shows an error message with a clear description.
    - [ ] The button returns to the enabled state (user can retry).
    - [ ] The screen does not close; user remains on the Request Transport screen.

#### 5.5.10 Drop-Off Flow (For Delivery Status)

**Scenario:** Request status is "For Delivery", user has Courier permission.

**What QA sees:**
- [ ] The button label is **"Drop Off"**.
- [ ] Delivery-specific fields are visible: Camera icon, Receiver field, Signature button.
- [ ] All request details and prepared by/dispatcher info are shown.

**Validation before drop-off:**
- [ ] Attempting to tap "Drop Off" without entering a receiver name:
  - [ ] Shows a snackbar/toast message: **"Please enter the receiver's name."**
  - [ ] The drop-off action is not processed.
  - [ ] The screen remains open.
- [ ] Attempting to tap "Drop Off" without capturing a signature:
  - [ ] Shows a snackbar/toast message: **"Please capture the receiver's signature."**
  - [ ] The drop-off action is not processed.
  - [ ] The screen remains open.

**Tapping "Drop Off" (with all required fields filled):**
- [ ] Tapping the "Drop Off" button:
  - [ ] Shows a loading spinner on the button.
  - [ ] Processes the drop-off action (records proof photo, receiver name, signature, and updates request status).
  - [ ] On success:
    - [ ] Shows a success message (toast/snackbar).
    - [ ] Closes the Request Transport screen and returns to the Standard Delivery list.
    - [ ] The request's status in the list updates to a final stage (e.g., "Done Delivery").
  - [ ] On failure:
    - [ ] Shows an error message with a clear description.
    - [ ] The button returns to the enabled state (user can retry).
    - [ ] The screen does not close; user remains on the Request Transport screen.

#### 5.5.11 Back Navigation from Request Transport

**Back button (app bar or system back):**
- [ ] Tapping the back button (if an app bar back is present) or using system back navigation:
  - [ ] Closes the Request Transport screen.
  - [ ] Returns to the Standard Delivery list.
  - [ ] Any unsaved changes (destination changes, entered receiver name, captured signature) are **not** automatically saved (unless the design specifies otherwise).
- [ ] Closing the screen does not cause crashes or leave the list in a broken state.

#### 5.5.12 Theme & Visual Consistency

**Light mode:**
- [ ] Map, search bar, bottom sheet, and all text are clearly visible with appropriate colors.
- [ ] Icons and buttons have good contrast against light backgrounds.

**Dark mode:**
- [ ] Map remains visible (map tiles adjust to dark mode if applicable).
- [ ] Bottom sheet background is dark (black or dark grey).
- [ ] Text and icons are light-colored for readability.
- [ ] Search bar and FAB colors are appropriate for dark mode.

**Consistency:**
- [ ] Fonts, icon styles, and spacing match the rest of the app.
- [ ] Button styles (Dispatch/Drop Off) are consistent with other primary action buttons in the app.

#### 5.5.13 Permissions & Error Handling

**Location permission:**
- [ ] If location permission is not granted, the map shows a default location (not the user's location).
- [ ] The "My Location" blue dot does not appear.
- [ ] Tapping the FAB (my location button) may prompt for location permission or show an appropriate message.

**Camera permission (for proof picture):**
- [ ] If camera permission is not granted, tapping the camera icon prompts for permission.
- [ ] If permission is denied, an appropriate message is shown.

**Network errors:**
- [ ] If route calculation fails (e.g., network unavailable), an appropriate error message is shown.
- [ ] The screen does not crash; user can retry or continue with other actions.

#### 5.5.14 Multi-Device & Orientation

**Small screens:**
- [ ] The map and bottom sheet layout adapts to smaller screens without overlap or content cutoff.
- [ ] All interactive elements remain accessible.

**Large screens:**
- [ ] The layout scales appropriately without excessive white space or stretched elements.

**Portrait:**
- [ ] Map occupies ~60% of screen height, bottom sheet ~45% (with overlap as designed).
- [ ] All elements are visible and accessible.

**Landscape:**
- [ ] The layout adapts to landscape orientation.
- [ ] The map and bottom sheet remain usable.
- [ ] The FAB remains above the bottom sheet and accessible.

---

### 5.6 Scroll Interactions (List)

**Component:** Scrolling up/down in the list.

**What it does:**
- [ ] Allows the user to browse all requests in the list.
- [ ] Ensures that there is no scroll "jank" (sudden jumps or flickers) even when loading flags change.

---

## 6. Role-Dependent Behavior (Black-Box)

> Internally, the app derives the user’s roles from their profile. QA only needs to validate the behavior per test account type.

6.1 **Test accounts**
- [ ] Use at least the following account types for testing, as defined by your QA setup (names may vary):
  - [ ] Request-only user
  - [ ] Release user
  - [ ] Courier user
  - [ ] Viewer-only user

6.2 **Behavior expectations**
- [ ] For each account type, tapping requests in various statuses surfaces only the actions appropriate for that combination of **role** and **status**.
- [ ] In no case should a user without permissions see high-privilege actions (e.g., a Viewer should not see release/delivery actions).
- [ ] When a user has multiple roles, validate that the UI presents the most appropriate set of actions for each status (e.g., courier actions on delivery-stage requests; release actions on preparation-stage requests).

6.3 **Final-status behavior**
- [ ] For all roles, tapping a request that is in a final status (e.g., Done, Cancelled) always shows a consistent, read-only style of interaction (no edits, no state changes).

---

## 7. Error Handling & Edge Cases

7.1 **Empty vs loading vs error**
- [ ] If there is an error fetching Standard Delivery requests (e.g., network failure), the screen shows an error message (if implemented separately from empty state) or at least does not crash.
- [ ] After fixing the error condition (e.g., restoring network), pulling to refresh loads data correctly.

7.2 **Rapid interactions**
- [ ] Repeatedly tapping and long-pressing different request cards does not cause crashes or stale dialogs.
- [ ] Changing filters on the parent screen while the list is visible causes the list content and empty/loading states to update correctly.

7.3 **Background/foreground**
- [ ] While viewing the list, send the app to the background and bring it back:
  - [ ] The list remains in a usable state.
  - [ ] If the data is refreshed automatically, no flickering/broken layouts occur.

---

This checklist is intended for QA testers validating the Standard Delivery list behavior and all user interactions (tap, long-press, scroll, pull-to-refresh) based solely on visible behavior and available account roles, without any need to inspect the underlying Dart code or GetX controllers.

