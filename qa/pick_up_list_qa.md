# QA Overview – Pick-Up List

## Scope / Overview

Screen name: Pick-Up List

Purpose: Verify that the **Pick-Up list** correctly displays, refreshes, and responds to all interaction components (tap, long-press, pull-to-refresh, loading/empty states, role-based actions) based only on what is visible in the app. This QA also summarizes what each interaction component does from a black-box perspective, grounded in the behavior of `PickUpList`.

This QA focuses on:
- Loading and empty states for Pick-Up requests
- List behavior when requests exist (scrolling, separators)
- Pull-to-refresh behavior
- Card tap and long-press behavior, including remarks
- Role-based behavior when a request is tapped

---

## Status Explanation – Pick-Up Request Lifecycle

This section describes the lifecycle of a Pick-Up request from creation to completion. Understanding these statuses helps QA testers verify that the correct actions and UI elements appear at each stage.

### Status Flow Overview

```
New Request 
    ↓
Getting Supplies Ready 
    ↓
Item Packed 
    ↓
Received (Final)
```

**Alternative Final Status:** `Cancelled` (can occur at any stage)

### Status Definitions

#### 1. **New Request**
- **Description:** The initial status when a Pick-Up request is first created in the system.
- **What it means:** The request has been submitted but no action has been taken yet. Items for pick-up have not been prepared.
- **Who can advance it:**
  - **Request role users:** Can mark the request as "Getting Supplies Ready" to start the preparation process.
  - **Release role users:** Can also mark the request as "Getting Supplies Ready".
- **Visual indicators:** The request appears in the list with "New Request" status badge/label.
- **Available actions:**
  - **Request/Release users:** Tapping opens a modal with a button (e.g., **"Mark Preparing"** or **"Prepare Item"**).
  - **Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 2. **Getting Supplies Ready**
- **Description:** Items for the pick-up request are being gathered and prepared.
- **What it means:** The preparation phase is active. Someone is collecting the items and preparing them for pick-up by the customer.
- **Who can advance it:**
  - **Release role users:** Can mark the request as "Item Packed" once all items are ready and packed.
- **Visual indicators:** The request shows "Getting Supplies Ready" status.
- **Available actions:**
  - **Release users:** Tapping opens a modal with a button (e.g., **"Mark Item Packed"** or **"Packed and Ready"**).
  - **Request/Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 3. **Item Packed**
- **Description:** All items have been packed and are ready for customer pick-up.
- **What it means:** Items are prepared and awaiting collection by the customer or designated person.
- **Who can advance it:**
  - **Release role users:** Can mark the request as "Received" once the customer has picked up the items.
- **Visual indicators:** The request shows "Item Packed" status.
- **Available actions:**
  - **Release users:** Tapping opens a modal with a button (e.g., **"Mark Received"** or **"Mark as Picked Up"**).
  - **Request/Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 4. **Received** (Final Status)
- **Description:** The customer has successfully picked up the items.
- **What it means:** The Pick-Up request lifecycle is complete. Items are now in the customer's possession.
- **Who can advance it:** No one. This is a final status.
- **Visual indicators:** The request shows "Received" status, possibly with a completion indicator.
- **Available actions:**
  - **All roles:** Tapping opens a view-only modal showing completion details (who received it, when, any final notes).
- **Long-press:** No Remarks dialog (final status - long-press is disabled).

---

#### 5. **Cancelled**
- **Description:** The request has been cancelled and will not be fulfilled.
- **What it means:** The Pick-Up request was terminated before completion. Cancellation remarks should explain why.
- **Who can cancel it:** Typically users with appropriate permissions (Release or Request roles, depending on system rules).
- **Visual indicators:** The request shows "Cancelled" status, often with a distinct color (e.g., red or grey).
- **Available actions:**
  - **All roles:** Tapping opens a view-only modal showing:
    - Cancellation remarks (reason for cancellation)
    - Date of cancellation
    - User who cancelled the request
- **Long-press:** No Remarks dialog (final status - long-press is disabled).

---

### Status Summary Table (Quick Reference)

| Status | Description | Who Can Advance | Next Status | Action Button Label |
|---|---|---|---|---|
| **New Request** | Request created, items not yet prepared | Request, Release | Getting Supplies Ready | "Mark Preparing" / "Prepare Item" |
| **Getting Supplies Ready** | Items being gathered/prepared | Release | Item Packed | "Mark Item Packed" / "Packed and Ready" |
| **Item Packed** | Items packed, ready for pick-up | Release | Received | "Mark Received" / "Mark as Picked Up" |
| **Received** | ✅ Final: Customer picked up items | None (final) | N/A | View-only |
| **Cancelled** | ❌ Request cancelled | None (final) | N/A | View-only (shows remarks) |

---

### Role-Based Status Advancement (Quick Reference)

| Role | Can Advance From → To |
|---|---|
| **Request** | New Request → Getting Supplies Ready |
| **Release** | New Request → Getting Supplies Ready<br>Getting Supplies Ready → Item Packed<br>Item Packed → Received |
| **Courier** | None (view-only for Pick-Up requests) |
| **Viewer** | None (view-only) |

---

### Key Characteristics of Pick-Up Workflow

**Pick-Up vs Standard Delivery:**
- **Customer collects items:** Pick-Up is for customers coming to collect items, not delivery to them
- **Simpler flow:** Only 4 active statuses (New Request → Getting Supplies Ready → Item Packed → Received)
- **No courier involvement:** Courier role has view-only access; this is handled by Request and Release roles
- **No delivery proof:** Unlike Standard Delivery, no photos or signatures are required (customer picks up in person)

**Pick-Up vs Air/Sea:**
- **Shorter lifecycle:** Air/Sea has more steps (Endorsed to Guard, Dispatch paths)
- **Different purpose:** Pick-Up is for customer collection, not shipping or long-distance transport

**Pick-Up vs Pull Out / Return:**
- **Similar flow length:** Both have simple 3-4 step workflows
- **Different direction:** Pick-Up is customer collecting items; Pull Out is items being removed/returned

---

## 1. Entry & Embedding

1.1 **Visibility within Request flow**
- [ ] From the logistics/Request screens, navigate to the **Pick-Up** category/tab.
- [ ] Confirm that a vertical list of Pick-Up requests appears when data is available.
- [ ] Confirm that the list appears under any filters/tabs and respects expected padding from the screen edges.

1.2 **Back navigation (screen-level)**
- [ ] Using the host screen’s back navigation (app bar back or system back) returns to the previous screen correctly.
- [ ] No lingering dialogs, overlays, or partial UI remain after backing out.

---

## 2. Loading State (Shimmer Placeholder)

> When data is loading and no filtered Pick-Up requests are currently visible.

2.1 **Initial loading**
- [ ] When you first navigate to the Pick-Up tab and data is still loading, a loading placeholder appears rather than a blank screen.
- [ ] The placeholder is a shimmer-style rectangular card, approximately the size of one list item.

2.2 **Transition from loading**
- [ ] Once loading completes:
  - [ ] If there are requests, the shimmer disappears and the list of cards appears.
  - [ ] If there are no requests, the shimmer disappears and the empty state is shown.
- [ ] There is no flicker or overlap between shimmer and real content.

---

## 3. Non-Empty List Behavior

> When `Pick-Up` requests exist for the current filters.

3.1 **List layout**
- [ ] The list shows one **Pick-Up** request per row as a card.
- [ ] There is consistent vertical spacing between cards.
- [ ] The list scrolls vertically when there are more items than fit on the screen.

3.2 **Scroll behavior**
- [ ] Scroll is smooth; no visible jumping when new data loads or when switching between tabs.
- [ ] You can pull down at the top of the list to trigger pull-to-refresh (see Section 4).

3.3 **Request card content (black-box)**
- [ ] Each card shows key information for the Pick-Up request (e.g., request ID, client, date/time, status), according to UX design.
- [ ] Text and icons on cards are readable and are not clipped or overlapping.

3.4 **Interaction lock during loading**
- [ ] While the list is loading (e.g., after a refresh), taps and long-presses on the list are temporarily disabled.
- [ ] After loading completes, user interactions on cards work as expected.

---

## 4. Pull-to-Refresh Behavior

**Interaction Component:** Pull-down gesture on the list or empty area (`RefreshIndicator`).

4.1 **Gesture and indicator**
- [ ] When at the top of the list, pulling down shows a refresh spinner.
- [ ] Releasing after the pull triggers a refresh of Pick-Up requests.

4.2 **Post-refresh behavior**
- [ ] After refresh, new or updated Pick-Up requests appear in the list if available.
- [ ] If no data is returned, the empty state is shown instead.
- [ ] The refresh spinner disappears once loading is complete.

4.3 **Refresh from empty state**
- [ ] When the list is empty, you can still pull down on the empty area to refresh.
- [ ] Refresh triggers the same data reload and updates the display accordingly.

---

## 5. Empty State (No Pick-Up Requests)

> When there are no Pick-Up requests after loading and filtering.

5.1 **Empty state contents**
- [ ] A centered empty state appears instead of a blank list, containing:
  - [ ] An inbox outline icon.
  - [ ] A primary message: **"No Pick Up requests found"**.
  - [ ] A secondary message: **"Try adjusting your filters"**.

5.2 **Theming and readability**
- [ ] In light mode, icon and text colors are readable and appropriately subdued.
- [ ] In dark mode, icon and text adapt so they remain visible (light on dark background).

5.3 **Scroll & refresh from empty**
- [ ] The empty state is wrapped in a scrollable container, allowing pull-to-refresh.

---

## 6. Interaction Components & What They Do

### 6.1 Request Card (Tap) - Overview

**Component:** Each row is a tappable card (`PickUpRequestCard`) wrapped in an `InkWell`.

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple/highlight within rounded corners).
- [ ] Tapping a card opens a **modal bottom sheet** showing request details and status-appropriate actions.

**Behavior summary:**
- Tapping a request card opens a modal dialog with content and actions that vary based on:
  1. The request's current **status** (New Request, Getting Supplies Ready, Item Packed, Received, Cancelled)
  2. The logged-in user's **role** (Request, Release, Courier, Viewer)

**Detailed modal behavior by status is documented in Section 6.1.1 below.**

---

### 6.1.1 Status-Based Modal Dialogs (Pick-Up)

**Component:** Bottom sheet modal dialog that opens when tapping any Pick-Up request.

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
  - [ ] Request type (Pick-Up)
  - [ ] Client or customer name
  - [ ] Client address or contact details
  - [ ] Request date and time
  - [ ] Current status
- [ ] Text is readable with appropriate color contrast.
- [ ] Information is organized logically and aligned properly.

#### Document References Section

**Display:**
- [ ] Below the header, a **Document References** section is visible (if the request has document references).
- [ ] Document references are displayed as tappable items or expandable sections.
- [ ] Tapping a document reference (if interactive) opens details or performs the expected action (e.g., viewing images, downloading documents).

#### Modal Footer

**Display:**
- [ ] At the bottom of the modal content (above the action button), a footer section displays additional request information:
  - [ ] Prepared by (user initial and timestamp)
  - [ ] Item packed by (user initial and timestamp, if applicable)
  - [ ] Received by (user initial and timestamp, if applicable)
  - [ ] Other relevant metadata
- [ ] The footer is consistently styled and readable.

---

### 6.1.2 Action Buttons & Role-Based Behavior by Status

#### **Status: New Request**

**For Request Role Users:**
- [ ] Button is visible and labeled **"Mark Preparing"** or **"Prepare Item"**.
- [ ] Tapping the button:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"Getting Supplies Ready"**.
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Release Role Users:**
- [ ] Button is visible and labeled **"Mark Preparing"** or **"Prepare Item"**.
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
- [ ] Only Release users can mark as received.

**For Release Role Users:**
- [ ] Button is visible and labeled **"Mark Received"** or **"Mark as Picked Up"**.
- [ ] Tapping the button:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"Received"** (final status).
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Courier Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: Received (Final Status)**

**For All Roles (Request, Release, Courier, Viewer):**
- [ ] Button is **not visible** (this is a final status).
- [ ] Modal displays completion details:
  - [ ] Who picked up the items (customer/receiver name, if recorded)
  - [ ] Who marked it as received (user initial)
  - [ ] When it was received/picked up (timestamp)
  - [ ] Any final notes or metadata
- [ ] Modal is **read-only** for all users.
- [ ] Closing the modal returns to the list.

---

#### **Status: Cancelled (Final Status)**

**For All Roles (Request, Release, Courier, Viewer):**
- [ ] Button is **not visible** (this is a final status).
- [ ] Modal displays cancellation information:
  - [ ] **"Cancel Remarks"** section with a divider (if applicable)
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

**Dark mode:**
- [ ] Modal background is dark (black or dark grey).
- [ ] Text and icons are light with good contrast.
- [ ] Action buttons are clearly visible.

**Consistency:**
- [ ] Typography, spacing, and colors match the app's design system.
- [ ] Modal design is consistent with other modals/dialogs in the app (Standard Delivery, Air/Sea, Pull Out, etc.).

---

### 6.1.5 Role-Based Behavior Summary (Quick Reference Table)

| Request Status | Request Role | Release Role | Courier Role | Viewer Role |
|---|---|---|---|---|
| **New Request** | ✅ "Mark Preparing" button | ✅ "Mark Preparing" button | ❌ View-only | ❌ View-only |
| **Getting Supplies Ready** | ❌ View-only | ✅ "Mark Item Packed" button | ❌ View-only | ❌ View-only |
| **Item Packed** | ❌ View-only | ✅ "Mark Received" button | ❌ View-only | ❌ View-only |
| **Received** | 👁️ View completion details | 👁️ View completion details | 👁️ View completion details | 👁️ View completion details |
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
- [ ] Users with multiple roles (e.g., both Request and Release) see the appropriate action based on their highest role capability.
- [ ] For "New Request": Both Request and Release roles can advance to "Getting Supplies Ready".
- [ ] For "Getting Supplies Ready" and "Item Packed": Only Release role can advance.

**Status transition edge cases:**
- [ ] If another user updates the request status while the modal is open, closing and reopening the modal shows the updated status.
- [ ] The list refreshes correctly after successful status changes (pull-to-refresh or automatic refresh).

---

## 7. Role-Dependent Behavior (Black-Box)

The app uses role priority mapping such that the **highest capability role** a user has determines how taps are handled.

7.1 **Recommended test accounts**
- [ ] Request-only
- [ ] Release
- [ ] Courier
- [ ] Viewer
- [ ] Combined roles (e.g., Release + Courier)

7.2 **Expectations by role**
- [ ] **Viewer-only:** tapping any card shows view-only details (no editing or workflow progression).
- [ ] **Request-only:** tapping early-stage requests allows only request-level actions; no release or courier actions are visible.
- [ ] **Courier:** tapping delivery-stage requests shows courier actions (e.g., marking pick-up states) per UX.
- [ ] **Release:** tapping preparation-stage requests shows release actions (e.g., preparing or authorizing pick-ups).
- [ ] **Users with multiple roles:** the UI reflects the role with highest priority (Release > Courier > Request > Viewer) for that request and status.

7.3 **Final-status behavior**
- [ ] For all roles, tapping a request with status `Received` or `Cancelled` results in a consistent, read-only handling (no further state changes allowed).

---

## 8. Error Handling & Edge Cases

8.1 **Network/data load errors**
- [ ] If fetching Pick-Up requests fails (e.g., offline), the app should not crash.
- [ ] Pull-to-refresh after restoring connectivity should successfully reload data.

8.2 **Rapid user actions**
- [ ] Quickly tapping multiple cards in sequence should not cause overlapping dialogs or crashes.
- [ ] Quickly long-pressing multiple cards should not cause incorrect remarks to appear or multiple dialogs to stack.

8.3 **Background/foreground transitions**
- [ ] While viewing the Pick-Up list, send the app to the background and return:
  - [ ] The list remains usable and displays current data.
  - [ ] If auto-refresh occurs, transitions remain visually clean (no flickering or half-rendered lists).

---

This checklist is intended for QA testers validating the Pick-Up list screen and its interaction behaviors (tap, long-press, scroll, refresh, role-based actions) based solely on what they see and can do in the app, without needing to inspect Dart code or GetX controllers.
