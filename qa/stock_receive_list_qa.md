# QA Overview – Stock Receive List

## Scope / Overview

Screen name: Stock Receive List

Purpose: Verify that the **Stock Receive list** (`StockReceiveList`) correctly displays, refreshes, and responds to all interaction components (tap, long-press, pull-to-refresh, loading/empty states, role-based actions) based only on what is visible in the app. This QA also summarizes what each interaction component does from a black-box perspective, grounded in the behavior of `StockReceiveList`.

This QA focuses on:
- Loading and empty states for Stock Receive requests
- List behavior when requests exist (scrolling, separators)
- Pull-to-refresh behavior
- Card tap and long-press behavior, including remarks
- Role-based behavior when a Stock Receive request is tapped

---

## 1. Entry & Embedding

1.1 **Visibility within Request flow**
- [ ] From the logistics/Request area, navigate to the **Stock Receive** category/tab.
- [ ] Confirm that a vertical list of Stock Receive requests appears when data is available.
- [ ] Confirm that the list appears under relevant filters/tabs and respects padding from the screen edges.

1.2 **Back navigation (screen-level)**
- [ ] Using the host screen’s back navigation (app bar back or system back) returns to the previous screen correctly.
- [ ] No lingering dialogs, overlays, or partial UI remain after backing out.

---

## 2. Loading State (Shimmer Placeholder)

> When data is loading and no filtered Stock Receive requests are currently visible.

2.1 **Initial loading**
- [ ] On first entering the Stock Receive tab while data is still loading, a loading placeholder appears instead of a blank screen.
- [ ] The placeholder is a shimmer-style rectangular card (`BShimmerEffect`), approximately the size of one list item.

2.2 **Transition from loading**
- [ ] Once loading completes:
  - [ ] If there are Stock Receive requests, the shimmer disappears and the list of cards appears.
  - [ ] If there are no requests, the shimmer disappears and the empty state appears.
- [ ] There is no overlap/flicker where shimmer and real content are shown together.

---

## 3. Non-Empty List Behavior

> When `filteredStockReceives` has one or more entries.

3.1 **List layout**
- [ ] The list shows one Stock Receive request per row as a card (re-using the same visual card style as Pull Out requests).
- [ ] There is consistent vertical spacing (`BSizes.xxs`) between cards.
- [ ] The list scrolls vertically when there are more items than fit on the screen.

3.2 **Scroll behavior**
- [ ] Scrolling up/down is smooth, with no visible jump as data refreshes.
- [ ] You can pull down at the top of the list to trigger pull-to-refresh (see Section 4).

3.3 **Request card content (black-box)**
- [ ] Each card shows key information for a Stock Receive request (e.g., client, reference, status, date) according to UX design.
- [ ] Text and icons are legible; no text is clipped or overlapping.

3.4 **Interaction lock during loading**
- [ ] While the list is in a loading state (e.g., after a refresh), taps and long-presses on the list are temporarily disabled (via a touch-absorbing layer).
- [ ] After loading completes, user interactions on cards are active again.

---

## 4. Pull-to-Refresh Behavior

**Interaction Component:** Pull-down gesture on the list or empty area (`RefreshIndicator`).

4.1 **Gesture and indicator**
- [ ] When at the top of the list, pulling down shows a refresh spinner at the top.
- [ ] Releasing after the pull triggers a refresh of Stock Receive requests (invoking the same reload as other lists).

4.2 **Post-refresh behavior**
- [ ] After refresh, any new or updated Stock Receive requests appear in the list.
- [ ] If there is still no data, the empty state remains.
- [ ] The refresh spinner disappears once loading is complete.

4.3 **Refresh from empty state**
- [ ] When the list is empty, you can still pull down on the empty state to refresh.
- [ ] Refresh triggers data reload and updates the display accordingly.

---

## 5. Empty State (No Stock Receive Requests)

> When there are no Stock Receive requests after loading and applying filters.

5.1 **Empty state contents**
- [ ] A centered empty state appears instead of a blank list, containing:
  - [ ] An inbox outline icon.
  - [ ] A primary message: **"No Stock Receive requests found"**.
  - [ ] A secondary message: **"Try adjusting your filters"**.

5.2 **Theming and readability**
- [ ] In light mode, icon and text use appropriate darker colors (e.g., dark grey) and are clearly readable.
- [ ] In dark mode, icon and text switch to light colors so they remain visible on dark backgrounds.

5.3 **Scroll & refresh from empty**
- [ ] The empty-state view is wrapped in a scrollable container, allowing pull-to-refresh from empty.

---

## 6. Interaction Components & What They Do

### 6.1 Stock Receive Card (Tap)

**Component:** Each row is a tappable card (`PullOutRequestCard` reused for Stock Receive) wrapped in an `InkWell`.

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple/highlight respecting rounded corners).
- [ ] Tapping a card selects that Stock Receive entry and opens the appropriate action or detail flow.

**Behavior summary (black-box, based on role & status):**
- When a card is tapped, the app:
  - [ ] Treats that Stock Receive as the **current selection**.
  - [ ] Checks the request’s status (e.g., `New`, `In-progress`, `Picked-up`, `Cancelled`).
  - [ ] Checks the logged-in user’s roles (Request, Release, Courier, Viewer, etc.).
  - [ ] Chooses the **most powerful applicable role** using the priority: Release > Courier > Request > Viewer.
  - [ ] Uses that role to determine which actions/flows to show.

From a tester’s perspective:
- **If status is `Picked-up` or `Cancelled`:**
  - [ ] Tapping the card opens a default, read-only style handler or detail view (no further workflow actions).
- **If status is not `Picked-up`/`Cancelled`:**
  - [ ] With **Release** permissions, tapping shows actions for release/preparation around Stock Receive.
  - [ ] With **Courier** permissions, tapping shows actions relevant to dispatch/transport (if applicable for Stock Receive flows).
  - [ ] With **Request-only** permissions, tapping allows only limited early-stage actions per UX.
  - [ ] With **Viewer-only** permissions, tapping shows a view-only detail (no state-changing actions).

> QA should use different test accounts to validate that tapping results in the correct dialog or screen for each role and status, without needing to know handler class names.

### 6.2 Stock Receive Card (Long Press – Remarks)

**Component:** Long-press gesture on each Stock Receive card (`onLongPress`).

**What it does:**
- [ ] Long-pressing a Stock Receive card with status **not** equal to `Picked-up` and **not** equal to `Cancelled` opens a **Remarks** dialog.
- [ ] The Remarks dialog lets the user:
  - [ ] View existing remarks for that Stock Receive.
  - [ ] Add or edit remarks according to design.
  - [ ] Save/apply remarks or cancel.
- [ ] Long-pressing a card where status is `Picked-up` or `Cancelled` does **not** open the Remarks dialog.

QA should verify:
- [ ] Remarks dialog appears only for in-progress/non-final requests.
- [ ] The correct remarks are shown per request, and changes are preserved according to UX expectations.

### 6.3 Pull-to-Refresh

**Component:** `RefreshIndicator` around the list and the empty state.

**What it does:**
- [ ] Pulling down from the top triggers a reload of Stock Receive requests.
- [ ] A spinner is visible during the refresh and disappears once complete.

### 6.4 Scroll Interactions

**Component:** Vertical scrolling (`ListView` for non-empty, `SingleChildScrollView` for empty).

**What it does:**
- [ ] Allows users to browse all available Stock Receive requests.
- [ ] Supports overscroll at the top for pull-to-refresh.
- [ ] Maintains a stable layout while switching between loading, list, and empty states.

### 6.5 Loading Lock (`AbsorbPointer`)

**Component:** Input blocking while data is loading.

**What it does:**
- [ ] While the controller’s loading flag is active, taps and long-presses on the list or empty view are ignored.
- [ ] Prevents users from triggering actions while data is refreshing.
- [ ] After loading finishes, interactions resume normally.

---

## 7. Role-Dependent Behavior (Black-Box)

The app parses the logged-in user’s roles and uses a priority mapping so that the highest capability role controls tap behavior.

7.1 **Recommended test accounts**
- [ ] Request-only user
- [ ] Release user
- [ ] Courier user
- [ ] Viewer-only user
- [ ] Multi-role users (e.g., Release + Courier)

7.2 **Expectations by role**
- [ ] **Viewer-only:** tapping a Stock Receive card shows view-only details; no state-changing actions are available.
- [ ] **Request-only:** tapping early-stage Stock Receive entries allows only limited request-level actions as defined by UX; no release or courier options.
- [ ] **Courier:** tapping transport-stage entries shows courier-relevant actions as per flow definitions.
- [ ] **Release:** tapping preparation/receiving-stage entries shows release/receive actions.
- [ ] **Multi-role:** when a user has more than one role, the UI acts according to the highest-priority role (Release > Courier > Request > Viewer).

7.3 **Final-status behavior**
- [ ] For all roles, tapping a Stock Receive request with status `Picked-up` or `Cancelled` results in a consistent, read-only handling (no further steps or state changes allowed).

---

## 8. Error Handling & Edge Cases

8.1 **Network/data load errors**
- [ ] If fetching Stock Receive data fails due to network issues, the app does not crash.
- [ ] After restoring connectivity, pull-to-refresh successfully reloads and displays Stock Receive requests.

8.2 **Rapid user actions**
- [ ] Quickly tapping multiple Stock Receive cards does not cause overlapping dialogs or crashes.
- [ ] Quickly long-pressing multiple cards does not show incorrect remarks or multiple stacked dialogs.

8.3 **Background/foreground transitions**
- [ ] While viewing the Stock Receive list, sending the app to background and then returning leaves the UI in a usable state.
- [ ] If the data reloads on resume, transitions between loading and content remain visually clean.

---

This checklist is intended for QA testers validating the Stock Receive list screen and its interaction behaviors (tap, long-press, scroll, refresh, role-based actions) based solely on what they see and can do in the app, without needing to inspect Dart code or GetX controllers.

