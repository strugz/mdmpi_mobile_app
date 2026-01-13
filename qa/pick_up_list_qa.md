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

### 6.1 Request Card (Tap)

**Component:** Each row is a tappable card (`PickUpRequestCard`) wrapped in an `InkWell`.

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple/highlight within rounded corners).
- [ ] Tapping a card selects that Pick-Up request and opens the appropriate action or detail flow.

**Behavior summary (black-box, based on role & status):**
- When a card is tapped, the app:
  - [ ] Interprets this request as the **current selection**.
  - [ ] Checks the request status (e.g., `New Request`, `In-progress`, `Received`, `Cancelled`).
  - [ ] Checks the logged-in user’s roles (Request, Release, Courier, Viewer, etc.).
  - [ ] Chooses the **most powerful applicable role** using the priority: Release > Courier > Request > Viewer.
  - [ ] Opens a handler/action UI appropriate for that role and status.

From a tester perspective:
- **If status is `Received` or `Cancelled`:**
  - [ ] Tapping the card opens a default, read-only handler or detail view (no further workflow actions).
- **If status is not `Received`/`Cancelled`:**
  - [ ] With **Release** privileges, tapping shows actions for preparing/releasing Pick-Up items.
  - [ ] With **Courier** privileges, tapping shows delivery/pick-up related actions.
  - [ ] With **Request-only** privileges, tapping allows only early-stage actions (e.g., advancing new requests) as defined in UX.
  - [ ] With **Viewer-only** privileges, tapping shows view-only details without state-changing actions.

> QA should use different test accounts to validate that the resulting dialog/screen and actions differ correctly per role and request status, without needing to know handler class names.

### 6.2 Request Card (Long Press – Remarks)

**Component:** Long-press gesture on each request card (`onLongPress`).

**What it does:**
- [ ] Long-pressing a card with status **not** equal to `Received` and **not** equal to `Cancelled` opens a **Remarks** dialog.
- [ ] The Remarks dialog allows the user to view and/or add remarks related to that Pick-Up request.
- [ ] The dialog has actions to save/apply remarks or to cancel/close.
- [ ] Long-pressing a card where status is `Received` or `Cancelled` does **not** open the Remarks dialog.

QA should verify:
- [ ] Long-press behavior is consistent across different statuses.
- [ ] Correct remarks are shown for each request.

### 6.3 Pull-to-Refresh

**Component:** Pull-down gesture handled by `RefreshIndicator` around the list and empty state.

**What it does:**
- [ ] Pulling down from the top triggers `loadPickUps` and updates the Pick-Up list.
- [ ] Spinner appears during reload and hides when done.

### 6.4 Scroll Interactions

**Component:** Vertical scroll (`ListView` for list, `SingleChildScrollView` for empty view).

**What it does:**
- [ ] Enables scrolling through all available Pick-Up requests.
- [ ] Works smoothly while respecting the top overscroll used by the pull-to-refresh gesture.

### 6.5 Loading Lock (`AbsorbPointer`)

**Component:** Input blocking while data is loading.

**What it does:**
- [ ] While `isLoading` is true, taps and long-presses over the list or empty state do nothing.
- [ ] Prevents accidental actions during refresh or initial load.
- [ ] After loading completes, interactions on cards function again.

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

