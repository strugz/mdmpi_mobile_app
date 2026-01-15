# QA Overview – Air/Sea List

## Scope / Overview

Screen name: Air/Sea List (`AirSeaList`)

Purpose: Verify that the **Air/Sea list** correctly displays, refreshes, and responds to all interaction components (tap, long-press, pull-to-refresh, loading/empty states, role-based actions) based only on what is visible in the app. This QA also summarizes what each interaction component does from a black-box perspective, grounded in the behavior of `AirSeaList`.

This QA focuses on:
- Loading and empty states for Air/Sea requests
- List behavior when requests exist (scrolling, separators)
- Pull-to-refresh behavior
- Card tap and long-press behavior, including remarks
- Role-based behavior when an Air/Sea request is tapped

---

## Status Explanation – Air/Sea Request Lifecycle

This section describes the lifecycle of an Air/Sea request from creation to completion. Understanding these statuses helps QA testers verify that the correct actions and UI elements appear at each stage.

### Status Flow Overview

```
New Request 
    ↓
Getting Supplies Ready 
    ↓
Item Packed 
    ↓
Endorsed to Guard (OR) Received (OR) Dispatch
    ↓
Received (from Endorsed to Guard)
```

### Status Definitions

#### 1. **New Request**
- **Description:** The initial status when an Air/Sea request is first created in the system.
- **What it means:** The request has been submitted but no action has been taken yet. Items are not yet being prepared.
- **Who can advance it:**
  - **Request role users:** Can mark the request as "Getting Supplies Ready" to start the preparation process.
  - **Release role users:** Can also mark the request as "Getting Supplies Ready".
- **Visual indicators:** The request appears in the list with "New Request" status badge/label.
- **Available actions:**
  - **Request/Release users:** Tapping opens a modal with a button labeled **"Prepare Item"** or similar.
  - **Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 2. **Getting Supplies Ready**
- **Description:** Items for this Air/Sea request are being gathered and prepared for shipping.
- **What it means:** The preparation phase is active. Someone is collecting the items, packaging them, or performing necessary prep work.
- **Who can advance it:**
  - **Release role users:** Can mark the request as "Item Packed" once all items are ready and packed.
- **Visual indicators:** The request shows "Getting Supplies Ready" status.
- **Available actions:**
  - **Release users:** Tapping opens a modal with a button labeled **"Packed and Ready"** or similar (to advance to "Item Packed").
  - **Request/Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 3. **Item Packed**
- **Description:** All items have been packed and are ready for the next step.
- **What it means:** Items are prepared and awaiting handover or dispatch. The Release user must decide the next action.
- **Who can advance it:**
  - **Release role users:** Can choose one of three paths:
    1. **Endorsed to Guard:** Items are handed over to a guard for safekeeping before final receipt.
    2. **Received:** Items are directly received (skip guard endorsement).
    3. **Dispatch:** Items are dispatched for courier delivery (triggers courier workflow).
- **Visual indicators:** The request shows "Item Packed" status.
- **Available actions:**
  - **Release users:** Tapping opens a modal with a **dropdown or selection** allowing the user to choose:
    - "Endorsed to Guard"
    - "Received"
    - "Dispatch"
  - **Request/Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 4. **Endorsed to Guard**
- **Description:** Items have been handed over to a guard for temporary safekeeping.
- **What it means:** The items are with security/guard personnel, awaiting final receipt by the end recipient.
- **Who can advance it:**
  - **Release role users:** Can mark the request as "Received" once the items are picked up from the guard.
- **Visual indicators:** The request shows "Endorsed to Guard" status.
- **Available actions:**
  - **Release users:** Tapping opens a modal with a button labeled **"Mark as Received"** or similar (to advance to "Received").
  - **Request/Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 5. **Dispatch** (Alternative path from Item Packed)
- **Description:** Items have been dispatched for courier delivery.
- **What it means:** The request has entered the courier/delivery workflow. A courier will handle the drop-off.
- **Who can advance it:**
  - **Courier role users:** Can mark the request as "Drop Off" once delivery is completed (with proof photo, receiver name, signature).
- **Visual indicators:** The request shows "Dispatch" status.
- **Available actions:**
  - **Courier users:** Tapping opens a modal or transport screen with a button labeled **"Drop Off"** (with fields for proof capture, receiver name, signature).
  - **Release/Request/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 6. **Drop Off** (Final status from Dispatch)
- **Description:** The courier has completed delivery and captured proof.
- **What it means:** The items have been dropped off at the destination. Proof of delivery (photo, signature) has been recorded.
- **Who can advance it:** No one. This is a final status.
- **Visual indicators:** The request shows "Drop Off" status.
- **Available actions:**
  - **All roles:** Tapping opens a view-only modal showing delivery proof (photo, receiver name, signature).
- **Long-press:** No Remarks dialog (final status).

---

#### 7. **Received** (Final status)
- **Description:** Items have been successfully received by the intended recipient.
- **What it means:** The Air/Sea request lifecycle is complete. Items are in the hands of the recipient.
- **Who can advance it:** No one. This is a final status.
- **Visual indicators:** The request shows "Received" status.
- **Available actions:**
  - **All roles:** Tapping opens a view-only modal showing received status and any relevant details (receiver info, proof if applicable).
- **Long-press:** No Remarks dialog (final status).

---

#### 8. **Cancelled**
- **Description:** The request has been cancelled and will not be fulfilled.
- **What it means:** The Air/Sea request was terminated before completion. Cancellation remarks should explain why.
- **Who can cancel it:** Typically users with appropriate permissions (Release or Request roles, depending on system rules).
- **Visual indicators:** The request shows "Cancelled" status, often with a distinct color (e.g., red or grey).
- **Available actions:**
  - **All roles:** Tapping opens a view-only modal showing:
    - Cancellation remarks (reason for cancellation)
    - Date of cancellation
    - User who cancelled the request
- **Long-press:** No Remarks dialog (final status).

---

### Status Summary Table (Quick Reference)

| Status | Description | Who Can Advance | Next Status(es) | Action Button Label |
|---|---|---|---|---|
| **New Request** | Request created, not yet prepared | Request, Release | Getting Supplies Ready | "Prepare Item" |
| **Getting Supplies Ready** | Items being gathered/prepared | Release | Item Packed | "Packed and Ready" |
| **Item Packed** | Items packed, awaiting next step | Release | Endorsed to Guard, Received, Dispatch | Dropdown selection |
| **Endorsed to Guard** | Items with guard, awaiting pickup | Release | Received | "Mark as Received" |
| **Dispatch** | Items dispatched for courier delivery | Courier | Drop Off | "Drop Off" |
| **Drop Off** | ✅ Final: Courier completed delivery | None (final) | N/A | View-only |
| **Received** | ✅ Final: Items received by recipient | None (final) | N/A | View-only |
| **Cancelled** | ❌ Request cancelled | None (final) | N/A | View-only (shows remarks) |

---

### Role-Based Status Advancement (Quick Reference)

| Role | Can Advance From → To |
|---|---|
| **Request** | New Request → Getting Supplies Ready |
| **Release** | New Request → Getting Supplies Ready<br>Getting Supplies Ready → Item Packed<br>Item Packed → Endorsed to Guard / Received / Dispatch<br>Endorsed to Guard → Received |
| **Courier** | Dispatch → Drop Off |
| **Viewer** | None (view-only) |

---

## 1. Entry & Embedding

1.1 **Visibility within Request flow**
- [ ] From the logistics/Request area, navigate to the **Air/Sea** category/tab.
- [ ] Confirm that a vertical list of Air/Sea requests appears when data is available.
- [ ] Confirm that the list appears under relevant filters/tabs and respects padding from the screen edges.

1.2 **Back navigation (screen-level)**
- [ ] Using the host screen’s back navigation (app bar back or system back) returns to the previous screen correctly.
- [ ] No lingering dialogs, overlays, or partial UI remain after backing out.

---

## 2. Loading State (Shimmer Placeholder)

> When data is loading and no filtered Air/Sea requests are currently visible.

2.1 **Initial loading**
- [ ] When you first navigate to the Air/Sea tab and data is still loading, a loading placeholder appears rather than a blank screen.
- [ ] The placeholder is a shimmer-style rectangular card (`BShimmerEffect`), approximately the size of one list item.

2.2 **Transition from loading**
- [ ] Once loading completes:
  - [ ] If there are Air/Sea requests, the shimmer disappears and the list of cards appears.
  - [ ] If there are no requests, the shimmer disappears and the empty state is shown.
- [ ] There is no flicker or overlap between shimmer and real content.

---

## 3. Non-Empty List Behavior

> When `filteredAirSeaRequests` has one or more entries.

3.1 **List layout**
- [ ] The list shows one **Air/Sea** request per row as an `AirSeaRequestCard`.
- [ ] There is consistent vertical spacing (`BSizes.xxs`) between cards.
- [ ] The list scrolls vertically when there are more items than fit on the screen.

3.2 **Scroll behavior**
- [ ] Scrolling up/down is smooth, with no visible jump as data refreshes.
- [ ] You can pull down at the top of the list to trigger pull-to-refresh (see Section 4).

3.3 **Request card content (black-box)**
- [ ] Each card shows key information for an Air/Sea request (e.g., client, reference, status, date) according to UX design.
- [ ] Text and icons are legible; no text is clipped or overlapping.

3.4 **Interaction lock during loading**
- [ ] While the list is in a loading state (e.g., after a refresh), taps and long-presses on the list are temporarily disabled (via a touch-absorbing layer).
- [ ] After loading completes, user interactions on cards are active again.

---

## 4. Pull-to-Refresh Behavior

**Interaction Component:** Pull-down gesture on the list or empty area (`RefreshIndicator`).

4.1 **Gesture and indicator**
- [ ] When at the top of the list, pulling down shows a refresh spinner at the top.
- [ ] Releasing after the pull triggers a refresh of Air/Sea requests (`loadAirSeaRequests`).

4.2 **Post-refresh behavior**
- [ ] After refresh, any new or updated Air/Sea requests appear in the list.
- [ ] If there is still no data, the empty state remains.
- [ ] The refresh spinner disappears once loading is complete.

4.3 **Refresh from empty state**
- [ ] When the list is empty, you can still pull down on the empty state to refresh.
- [ ] Refresh triggers data reload and updates the display accordingly.

---

## 5. Empty State (No Air/Sea Requests)

> When there are no Air/Sea requests after loading and applying filters.

5.1 **Empty state contents**
- [ ] A centered empty state appears instead of a blank list, containing:
  - [ ] An inbox outline icon.
  - [ ] A primary message: **"No Air / Sea requests found"**.
  - [ ] A secondary message: **"Try adjusting your filters"**.

5.2 **Theming and readability**
- [ ] In light mode, icon and text use appropriate darker colors (e.g., dark grey) and are clearly readable.
- [ ] In dark mode, icon and text switch to light colors so they remain visible on dark backgrounds.

5.3 **Scroll & refresh from empty**
- [ ] The empty-state view is wrapped in a scrollable container, allowing pull-to-refresh from empty.

---

## 6. Interaction Components & What They Do

### 6.1 Air/Sea Card (Tap) - Overview

**Component:** Each row is a tappable card (`AirSeaRequestCard`) wrapped in an `InkWell`.

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple/highlight respecting rounded corners).
- [ ] Tapping a card opens a **modal bottom sheet** showing request details and status-appropriate actions.

**Behavior summary:**
- Tapping a request card opens a modal dialog with content and actions that vary based on:
  1. The request's current **status** (New Request, Getting Supplies Ready, Item Packed, Endorsed to Guard, Dispatch, Drop Off, Received, Cancelled)
  2. The logged-in user's **role** (Request, Release, Courier, Viewer)

**Detailed modal behavior by status is documented in Section 6.1.1 below.**

---

### 6.1.1 Status-Based Modal Dialogs (Air/Sea)

**Component:** Bottom sheet modal dialog that opens when tapping any Air/Sea request.

**Entry:**
- [ ] Tapping any request card opens a modal bottom sheet.
- [ ] The modal loads without crashes, blank screens, or delays.

#### Modal Layout & Design

**Overall appearance:**
- [ ] A modal bottom sheet slides up from the bottom of the screen.
- [ ] The modal has rounded top corners (curved design).
- [ ] Background color adapts to theme:
  - [ ] Light mode: White or light background
  - [ ] Dark mode: Black or dark background
- [ ] The modal content is scrollable if it exceeds the visible area.
- [ ] A safe area is respected (no content is cut off by device notches or system UI).

**Modal header:**
- [ ] The top of the modal displays request information:
  - [ ] Request type (Air/Sea)
  - [ ] Client name
  - [ ] Client address
  - [ ] Request date and time
  - [ ] Current status
- [ ] Text is readable with appropriate color contrast.
- [ ] Information is organized logically and aligned properly.

#### Document References Section

**Display:**
- [ ] Below the header, a **Document References** section is visible (if the request has document references).
- [ ] Document references are displayed as tappable items or expandable sections.
- [ ] Tapping a document reference (if interactive) opens details or performs the expected action (e.g., viewing images, downloading documents).

#### Waybill Number Section

**Display (when applicable):**
- [ ] If the request has a waybill number, it is displayed with:
  - [ ] Label: "Waybill Number"
  - [ ] Icon (clipboard/document icon)
  - [ ] The waybill number value
  - [ ] A copy button/icon to copy the waybill number to clipboard
- [ ] Tapping the copy icon copies the waybill number and shows a confirmation (toast/snackbar).

#### Waybill Input Section (For "Endorsed to Guard" Status)

**Display:**
- [ ] When the status is **"Endorsed to Guard"**, a waybill input field is visible in the modal.
- [ ] The field allows the user to enter or update the waybill number before marking as received.

#### Dispatch Information Section

**Display (when applicable):**
- [ ] If dispatch-related fields are populated (dispatcher name, dispatch date, etc.), a "Dispatch Information" section is visible.
- [ ] Shows relevant dispatch metadata in a readable format.

#### Modal Footer

**Display:**
- [ ] At the bottom of the modal content (above the action button), a footer section displays additional request information:
  - [ ] Prepared by (user initial and timestamp)
  - [ ] Item packed by (user initial and timestamp, if applicable)
  - [ ] Endorsed by (user initial and timestamp, if applicable)
  - [ ] Received by (user initial and timestamp, if applicable)
  - [ ] Other relevant metadata
- [ ] The footer is consistently styled and readable.

---

### 6.1.2 Action Buttons & Role-Based Behavior by Status

#### **Status: New Request**

**For Request Role Users:**
- [ ] Button is visible and labeled **"Mark Preparing"** or similar.
- [ ] Tapping the button:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"Getting Supplies Ready"**.
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Release Role Users:**
- [ ] Button is visible and labeled **"Mark Preparing"** or similar.
- [ ] Same behavior as Request role (can advance the status).

**For Courier Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: Getting Supplies Ready**

**For Request Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Only Release users can advance from "Getting Supplies Ready" to "Item Packed".

**For Release Role Users:**
- [ ] Button is visible and labeled **"Mark Item Packed"** or **"Packed and Ready"**.
- [ ] Tapping the button:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"Item Packed"**.
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Courier Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: Item Packed**

**For Request Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Only Release users can choose the next path.

**For Release Role Users:**
- [ ] A **dropdown or selection field** is visible, allowing the user to choose one of three options:
  - [ ] **"Endorsed to Guard"** - Items will be handed to a guard
  - [ ] **"Received"** - Items are directly received (skip guard)
  - [ ] **"Dispatch"** - Items are dispatched for courier delivery
- [ ] Button is visible (label may vary, e.g., **"Proceed"** or **"Confirm Selection"**).
- [ ] Tapping the button:
  - [ ] Validates that a selection has been made from the dropdown.
  - [ ] If no selection, shows an error message prompting to select an option.
  - [ ] If selection is made, shows a loading indicator on the button.
  - [ ] Updates the request status based on the selection:
    - [ ] **"Endorsed to Guard"** → Status becomes "Endorsed to Guard"
    - [ ] **"Received"** → Status becomes "Received" (final status)
    - [ ] **"Dispatch"** → Status becomes "Dispatch"
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Courier Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: Endorsed to Guard**

**For Request Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Only Release users can mark as received.

**For Release Role Users:**
- [ ] A **waybill input field** is visible, allowing the user to enter or update the waybill number.
- [ ] Button is visible and labeled **"Mark Received"** or **"Mark as Received"**.
- [ ] Tapping the button:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"Received"** (final status).
  - [ ] Saves the waybill number if entered.
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Courier Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: Dispatch**

**For Request Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Only Courier users can mark as drop-off.

**For Release Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Couriers handle dispatch → drop-off.

**For Courier Role Users:**
- [ ] Button is visible and labeled **"Mark Drop Off"** or **"Drop Off"**.
- [ ] Tapping the button may open additional fields or screens for:
  - [ ] Proof of delivery photo
  - [ ] Receiver name
  - [ ] Receiver signature
- [ ] After capturing all required information:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"Drop Off"** (final status).
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: Drop Off (Final Status)**

**For All Roles (Request, Release, Courier, Viewer):**
- [ ] Button is **not visible** (this is a final status).
- [ ] Modal displays delivery completion details:
  - [ ] Proof of delivery photo (if applicable)
  - [ ] Receiver name
  - [ ] Receiver signature (if applicable)
  - [ ] Delivery timestamp
  - [ ] Courier who completed the delivery
- [ ] Modal is **read-only** for all users.
- [ ] Closing the modal returns to the list.

---

#### **Status: Received (Final Status)**

**For All Roles (Request, Release, Courier, Viewer):**
- [ ] Button is **not visible** (this is a final status).
- [ ] Modal displays received status and details:
  - [ ] Waybill number (if applicable)
  - [ ] Who received the items (user initial)
  - [ ] When it was received (timestamp)
  - [ ] Any final notes or metadata
- [ ] Modal is **read-only** for all users.
- [ ] Closing the modal returns to the list.

---

#### **Status: Cancelled (Final Status)**

**For All Roles (Request, Release, Courier, Viewer):**
- [ ] Button is **not visible** (this is a final status).
- [ ] Modal displays cancellation information:
  - [ ] **"Cancel Remarks"** section with a divider
  - [ ] Cancellation remarks text (reason for cancellation)
  - [ ] Date of cancellation
  - [ ] User who cancelled the request
- [ ] Modal is **read-only** for all users.
- [ ] Closing the modal returns to the list.

---

### 6.1.3 Modal Interaction & Behavior

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

---

### 6.1.4 Theme & Visual Consistency

**Light mode:**
- [ ] Modal background is light (white or light grey).
- [ ] Text and icons are dark with good contrast.
- [ ] Action buttons are clearly visible.
- [ ] Dropdown selections and input fields are styled appropriately.

**Dark mode:**
- [ ] Modal background is dark (black or dark grey).
- [ ] Text and icons are light with good contrast.
- [ ] Action buttons are clearly visible.
- [ ] Dropdown selections and input fields are styled appropriately.

**Consistency:**
- [ ] Typography, spacing, and colors match the app's design system.
- [ ] Modal design is consistent with other modals/dialogs in the app (Standard Delivery, Pull Out, etc.).

---

### 6.1.5 Role-Based Behavior Summary (Quick Reference Table)

| Request Status | Request Role | Release Role | Courier Role | Viewer Role |
|---|---|---|---|---|
| **New Request** | ✅ "Mark Preparing" button | ✅ "Mark Preparing" button | ❌ View-only | ❌ View-only |
| **Getting Supplies Ready** | ❌ View-only | ✅ "Mark Item Packed" button | ❌ View-only | ❌ View-only |
| **Item Packed** | ❌ View-only | ✅ Dropdown selection (3 paths) | ❌ View-only | ❌ View-only |
| **Endorsed to Guard** | ❌ View-only | ✅ "Mark Received" button + waybill input | ❌ View-only | ❌ View-only |
| **Dispatch** | ❌ View-only | ❌ View-only | ✅ "Mark Drop Off" button | ❌ View-only |
| **Drop Off** | 👁️ View delivery proof | 👁️ View delivery proof | 👁️ View delivery proof | 👁️ View delivery proof |
| **Received** | 👁️ View received details | 👁️ View received details | 👁️ View received details | 👁️ View received details |
| **Cancelled** | 👁️ View cancel remarks | 👁️ View cancel remarks | 👁️ View cancel remarks | 👁️ View cancel remarks |

---

### 6.1.6 Edge Cases & Validations

**Rapid tapping:**
- [ ] Rapidly tapping the action button does not trigger multiple status updates.
- [ ] The button disables or shows loading immediately on first tap.

**Network issues:**
- [ ] If the network is unavailable when tapping the action button, an appropriate error message is shown.
- [ ] The modal remains open, allowing the user to retry after resolving the network issue.

**Permission edge cases:**
- [ ] Users with multiple roles (e.g., both Release and Courier) see the appropriate action based on status and role priority:
  - [ ] For "New Request", "Getting Supplies Ready", "Item Packed", "Endorsed to Guard": Release actions are shown.
  - [ ] For "Dispatch": Courier actions are shown.
- [ ] The highest-priority role handler is selected (Release > Courier > Request > Viewer).

**Dropdown validation (Item Packed status):**
- [ ] If Release user tries to proceed from "Item Packed" without selecting a path from the dropdown, an error message is shown.
- [ ] The error message is clear and instructs the user to make a selection.

**Waybill number (Endorsed to Guard status):**
- [ ] Waybill input field accepts alphanumeric input.
- [ ] If waybill is required, attempting to proceed without entering it shows an appropriate error message.
- [ ] Waybill number is saved correctly when marking as received.

**Status transition edge cases:**
- [ ] If another user updates the request status while the modal is open, closing and reopening the modal shows the updated status.
- [ ] The list refreshes correctly after successful status changes (pull-to-refresh or automatic refresh).

---
