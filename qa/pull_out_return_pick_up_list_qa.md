# QA Overview – Pull Out / Return / Pick-Up List

## Scope / Overview

Screen name: Pull Out / Return / Pick-Up List

Purpose: Verify that the **Pull Out / Return / Pick-Up** list correctly displays, refreshes, and responds to all interaction components (tap, long-press, pull-to-refresh, loading/empty states, role-based actions) based only on what is visible in the app. This QA also summarizes what each interaction component does from a black-box perspective.

This QA focuses on:
- Loading and empty states for Pull Out / Return / Pick-Up requests
- List behavior when requests exist (scrolling, separators)
- Pull-to-refresh behavior
- Card tap and long-press behavior, including remarks
- Role-based behavior when a request is tapped

---

## Status Explanation – Pull Out / Return / Pick-Up Request Lifecycle

This section describes the lifecycle of a Pull Out / Return / Pick-Up request from creation to completion. Understanding these statuses helps QA testers verify that the correct actions and UI elements appear at each stage.

### Status Flow Overview

```
New Request 
    ↓
In Transit 
    ↓
Taken Out (Final)
```

**Alternative Final Status:** `Cancelled` (can occur at any stage)

### Status Definitions

#### 1. **New Request**
- **Description:** The initial status when a Pull Out / Return / Pick-Up request is first created in the system.
- **What it means:** The request has been submitted but no action has been taken yet. Items have not been moved or picked up.
- **Who can advance it:**
  - **Request role users:** Can mark the request as "In Transit" to indicate items are being moved.
  - **Release role users:** Can also mark the request as "In Transit".
- **Visual indicators:** The request appears in the list with "New Request" status badge/label.
- **Available actions:**
  - **Request/Release users:** Tapping opens a modal with an action button (e.g., **"Mark In Transit"** or similar).
  - **Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 2. **In Transit**
- **Description:** Items are currently being moved, picked up, or in the process of being pulled out or returned.
- **What it means:** The request is active and items are in motion. Someone is handling the physical movement of items.
- **Who can advance it:**
  - **Release role users:** Can mark the request as "Taken Out" once the items have been successfully removed or picked up.
- **Visual indicators:** The request shows "In Transit" status.
- **Available actions:**
  - **Release users:** Tapping opens a modal with an action button (e.g., **"Mark as Taken Out"** or **"Complete Pickup"**).
  - **Request/Courier/Viewer users:** Tapping opens a view-only modal (no action buttons).
- **Long-press:** Opens Remarks dialog (can add/view remarks).

---

#### 3. **Taken Out** (Final Status)
- **Description:** Items have been successfully pulled out, picked up, or returned.
- **What it means:** The request lifecycle is complete. Items have been physically removed from the location or successfully returned.
- **Who can advance it:** No one. This is a final status.
- **Visual indicators:** The request shows "Taken Out" status, possibly with a completion indicator.
- **Available actions:**
  - **All roles:** Tapping opens a view-only modal showing completion details (who completed it, when, any final notes).
- **Long-press:** No Remarks dialog (final status - long-press is disabled).

**Note:** The code references "Picked-up" as an alternative term for final status, which is functionally equivalent to "Taken Out".

---

#### 4. **Cancelled**
- **Description:** The request has been cancelled and will not be fulfilled.
- **What it means:** The Pull Out / Return / Pick-Up request was terminated before completion. Cancellation remarks should explain why.
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
| **New Request** | Request created, items not yet moved | Request, Release | In Transit | "Mark In Transit" |
| **In Transit** | Items being moved/picked up | Release | Taken Out | "Mark as Taken Out" / "Complete Pickup" |
| **Taken Out** | ✅ Final: Items successfully removed/returned | None (final) | N/A | View-only |
| **Cancelled** | ❌ Request cancelled | None (final) | N/A | View-only (shows remarks) |

---

### Role-Based Status Advancement (Quick Reference)

| Role | Can Advance From → To |
|---|---|
| **Request** | New Request → In Transit |
| **Release** | New Request → In Transit<br>In Transit → Taken Out |
| **Courier** | None (view-only for Pull Out requests) |
| **Viewer** | None (view-only) |

---

### Key Differences from Other Request Types

**Pull Out / Return / Pick-Up vs Standard Delivery:**
- **Simpler flow:** Only 3 active statuses (New Request → In Transit → Taken Out)
- **No courier involvement:** Courier role has view-only access; this is primarily handled by Request and Release roles
- **Focus on removal:** Rather than delivering items to a destination, this tracks items being taken out or returned

**Pull Out / Return / Pick-Up vs Air/Sea:**
- **Shorter lifecycle:** Air/Sea has more intermediate steps (Getting Supplies Ready, Item Packed, Endorsed to Guard)
- **Different purpose:** Pull Out is about removing/returning items, not shipping them long distance

---

## 1. Entry & Embedding

1.1 **Visibility within logistics flow**
- [ ] From the logistics/Request area, navigate to the **Pull Out / Return / Pick-Up** category/tab.
- [ ] Confirm that this list appears under the appropriate filters/tabs.
- [ ] The list area has appropriate padding from the screen edges.

1.2 **Back navigation (screen-level)**
- [ ] Using the app bar back button or system back from the screen that hosts this list returns to the previous screen correctly.
- [ ] No lingering overlays, dialogs, or partial UI remain after backing out.

---

## 2. Loading State (Shimmer Placeholder)

> When data is being loaded and no filtered pull-out/return requests are currently shown.

2.1 **Initial loading**
- [ ] After navigating into the Pull Out / Return / Pick-Up list and before data loads, a loading placeholder appears instead of a blank area.
- [ ] The placeholder appears as a shimmer-style rectangle/card (approx. a request card size).

2.2 **Transition to content**
- [ ] Once data has been loaded:
  - [ ] If there are requests, the shimmer disappears and the list of cards appears.
  - [ ] If there are no requests, the shimmer disappears and the empty state appears.
- [ ] There is no overlap or flicker where shimmer and real content show at the same time.

---

## 3. Non-Empty List Behavior

> When at least one Pull Out / Return / Pick-Up request matches the current filters.

3.1 **List layout and scroll**
- [ ] The list displays one **Pull Out / Return / Pick-Up** request per row as a card.
- [ ] There is consistent vertical spacing between rows.
- [ ] The list scrolls vertically when there are more items than fit on the screen.

3.2 **Scroll physics**
- [ ] You can overscroll slightly at the top to trigger pull-to-refresh (see Section 4).
- [ ] Scrolling is smooth with no jitter, even when loading state changes.

3.3 **Request card content (black-box)**
- [ ] Each `Pull Out / Return / Pick-Up` card shows key information such as:
  - [ ] Type (Pull Out / Return / Pick-Up), if indicated.
  - [ ] Client or location information.
  - [ ] Request status (e.g., New Request, Picked-up, Cancelled, etc.).
  - [ ] Any other summary data required by design.
- [ ] Text is fully readable; no fields are cut off or overlapping.

3.4 **Interaction lock during loading**
- [ ] When the list is in a loading state (e.g., after a refresh), taps and long-presses on the list are temporarily disabled.
- [ ] Once loading completes, cards become interactive again.

---

## 4. Pull-to-Refresh Behavior

**Interaction Component:** Pull-down gesture on the list or empty area.

4.1 **Gesture and feedback**
- [ ] When you are at the top of the list and pull down, a refresh indicator/spinner appears at the top.
- [ ] Releasing after the pull triggers a data refresh.

4.2 **Post-refresh behavior**
- [ ] After refresh, the list updates with the latest Pull Out / Return / Pick-Up requests.
- [ ] If new data is available, new or updated records appear; otherwise the list/empty state remains unchanged.
- [ ] The refresh indicator disappears once loading completes.

4.3 **Refresh from empty state**
- [ ] When the list is empty but not loading, you can still pull down on the empty area to refresh.
- [ ] The same refresh indicator appears and the list updates as above.

---

## 5. Empty State (No Requests)

> When there are no pull-out/return requests after loading completes and filters are applied.

5.1 **Empty state contents**
- [ ] A centered empty state appears instead of a blank list, containing:
  - [ ] An inbox-style outline icon.
  - [ ] A primary message: **"No Pull out / Return requests found"**.
  - [ ] A secondary message: **"Try adjusting your filters"**.

5.2 **Theming and readability**
- [ ] In light mode, icon and text colors are clearly visible (no low contrast).
- [ ] In dark mode, icon and text adjust correctly (e.g., are light on a dark background).

5.3 **Scroll and refresh**
- [ ] The empty state is inside a scrollable container so you can still perform pull-to-refresh.

---

## 6. Interaction Components & What They Do

### 6.1 Request Card (Tap) - Overview

**Component:** Each row is a tappable card representing a Pull Out / Return / Pick-Up request (`InkWell` around a `PullOutRequestCard`).

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple or highlight within the card's rounded corners).
- [ ] Tapping a card opens a **modal bottom sheet** showing request details and status-appropriate actions.

**Behavior summary:**
- Tapping a request card opens a modal dialog with content and actions that vary based on:
  1. The request's current **status** (New Request, In Transit, Taken Out, Cancelled)
  2. The logged-in user's **role** (Request, Release, Courier, Viewer)

**Detailed modal behavior by status is documented in Section 6.1.1 below.**

---

### 6.1.1 Status-Based Modal Dialogs (Pull Out / Return / Pick-Up)

**Component:** Bottom sheet modal dialog that opens when tapping any Pull Out / Return / Pick-Up request.

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
  - [ ] Request type (Pull Out / Return / Pick-Up)
  - [ ] Client or location name
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

#### Modal Footer

**Display:**
- [ ] At the bottom of the modal content (above the action button), a footer section displays additional request information:
  - [ ] Prepared by (user initial and timestamp)
  - [ ] In transit by (user initial and timestamp, if applicable)
  - [ ] Taken out by (user initial and timestamp, if applicable)
  - [ ] Other relevant metadata
- [ ] The footer is consistently styled and readable.

---

### 6.1.2 Action Buttons & Role-Based Behavior by Status

#### **Status: New Request**

**For Request Role Users:**
- [ ] Button is visible and labeled **"Set In Transit"**.
- [ ] Tapping the button:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"In Transit"**.
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Release Role Users:**
- [ ] Button is visible and labeled **"Set In Transit"**.
- [ ] Same behavior as Request role (can advance the status).

**For Courier Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: In Transit**

**For Request Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Only Release users can advance from "In Transit" to "Taken Out".

**For Release Role Users:**
- [ ] Button is visible and labeled **"Mark Taken Out"** or **"Complete Pickup"**.
- [ ] Tapping the button:
  - [ ] Shows a loading indicator on the button.
  - [ ] Updates the request status to **"Taken Out"** (final status).
  - [ ] On success: Shows a success message and closes the modal, returning to the list with the updated status.
  - [ ] On failure: Shows an error message, button returns to enabled state.

**For Courier Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

**For Viewer Role Users:**
- [ ] Button is **not visible** (modal is view-only).
- [ ] Modal shows request details but no action can be taken.

---

#### **Status: Taken Out (Final Status)**

**For All Roles (Request, Release, Courier, Viewer):**
- [ ] Button is **not visible** (this is a final status).
- [ ] Modal displays completion details:
  - [ ] Who completed the pickup/pull-out (user initial)
  - [ ] When it was completed (timestamp)
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

**Dark mode:**
- [ ] Modal background is dark (black or dark grey).
- [ ] Text and icons are light with good contrast.
- [ ] Action buttons are clearly visible.

**Consistency:**
- [ ] Typography, spacing, and colors match the app's design system.
- [ ] Modal design is consistent with other modals/dialogs in the app (Standard Delivery, Air/Sea, etc.).

---

### 6.1.5 Role-Based Behavior Summary (Quick Reference Table)

| Request Status | Request Role | Release Role | Courier Role | Viewer Role |
|---|---|---|---|---|
| **New Request** | ✅ "Set In Transit" button | ✅ "Set In Transit" button | ❌ View-only | ❌ View-only |
| **In Transit** | ❌ View-only | ✅ "Mark Taken Out" button | ❌ View-only | ❌ View-only |
| **Taken Out** | 👁️ View completion details | 👁️ View completion details | 👁️ View completion details | 👁️ View completion details |
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
- [ ] For "New Request": Both Request and Release roles can advance to "In Transit".
- [ ] For "In Transit": Only Release role can advance to "Taken Out".

**Status transition edge cases:**
- [ ] If another user updates the request status while the modal is open, closing and reopening the modal shows the updated status.
- [ ] The list refreshes correctly after successful status changes (pull-to-refresh or automatic refresh).

---

## 7. Role-Dependent Behavior (Black-Box)

The app selects the highest-priority role handler (Release > Courier > Request > Viewer) for the logged-in user.

7.1 **Test with different account types**
- [ ] QA should use test accounts that reflect the following role setups (names may vary):
  - [ ] Request-only
  - [ ] Release
  - [ ] Courier
  - [ ] Viewer
  - [ ] Accounts with multiple roles (e.g., Release + Courier)

7.2 **Expectations by role**
- [ ] **Viewer-only:** Tapping a card opens a view-only presentation of the request; no state-changing actions are available.
- [ ] **Request-only:** Tapping a new or early-stage request may allow limited actions (e.g., create/advance new requests) but not release/courier steps.
- [ ] **Courier:** Tapping a delivery-stage request triggers courier-relevant actions (e.g., mark picked-up, in-transit, delivered) as defined by UX.
- [ ] **Release:** Tapping a preparation-stage request shows actions around releasing or preparing items.
- [ ] **Multiple roles:** The screen uses the role with the highest capability available and shows actions that match that role’s capabilities.

7.3 **Final-status behavior**
- [ ] For any role, tapping a request with status `Picked-up` or `Cancelled` always behaves like a final, read-only case (default handler – no additional workflow steps).

---

## 8. Error Handling & Edge Cases

8.1 **Network or data load errors**
- [ ] If a data load fails (e.g., offline), the screen should not crash.
- [ ] Pull-to-refresh after restoring network should fetch data and update the list/empty state.

8.2 **Rapid user interactions**
- [ ] Quickly tapping different items in sequence does not crash the app or open multiple overlapping dialogs.
- [ ] Quickly long-pressing different items also does not lead to overlapping dialogs or inconsistent remarks being shown.

8.3 **Background/foreground transitions**
- [ ] While viewing the Pull Out / Return / Pick-Up list, send the app to the background and then return:
  - [ ] The list remains usable; if it reloads, the loading and content transition remains clean.

---

This checklist is intended for QA testers validating the Pull Out / Return / Pick-Up list based on visible behavior and multi-role interactions, without needing to inspect the Dart code or GetX controllers.
