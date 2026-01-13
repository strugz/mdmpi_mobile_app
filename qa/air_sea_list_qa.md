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

### 6.1 Air/Sea Card (Tap)

**Component:** Each row is a tappable card (`AirSeaRequestCard`) wrapped in an `InkWell`.

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple/highlight respecting rounded corners).
- [ ] Tapping a card selects that Air/Sea request and opens the appropriate action or detail flow.

**Behavior summary (black-box, based on role & status):**
- When a card is tapped, the app:
  - [ ] Treats that Air/Sea request as the **current selection**.
  - [ ] Checks the request’s status (e.g., `New`, `In-progress`, `Received`, `Cancelled`).
  - [ ] Checks the logged-in user’s roles (Request, Release, Courier, Viewer, etc.).
  - [ ] Chooses the **most powerful applicable role** using the priority: Release > Courier > Request > Viewer.

From a tester’s perspective:
- **If status is `Received` or `Cancelled`:**
  - [ ] Tapping the card opens a default, read-only style handler (`AirSeaDefaultHandler` behavior), regardless of user role.
- **If status is not `Received`/`Cancelled`:**
  - [ ] With **Release** permissions, tapping shows actions for release/preparation around Air/Sea logistics.
  - [ ] With **Courier** permissions, tapping shows courier/transport-related actions where applicable.
  - [ ] With **Request-only** permissions, tapping allows only early-stage actions per UX.
  - [ ] With **Viewer-only** permissions, tapping shows a view-only detail (no state-changing actions).

> QA should use different test accounts to validate that tapping results in the correct dialog or screen for each role and status, without needing to know handler class names.

### 6.2 Air/Sea Card (Long Press – Remarks)

**Component:** Long-press gesture on each Air/Sea card (`onLongPress`).

**What it does:**
- [ ] Long-pressing a card with status **not** equal to `Received` and **not** equal to `Cancelled` opens a **Remarks** dialog.
- [ ] The Remarks dialog lets the user:
  - [ ] View existing remarks for that Air/Sea request.
  - [ ] Add or edit remarks according to design.
  - [ ] Save/apply remarks or cancel.
- [ ] Long-pressing a card where status is `Received` or `Cancelled` does **not** open the Remarks dialog.

QA should verify:
- [ ] Remarks dialog appears only for in-progress/non-final requests.
- [ ] The correct remarks are shown per request, and changes are preserved according to UX expectations.

### 6.3 Pull-to-Refresh

**Component:** `RefreshIndicator` around the list and empty state.

**What it does:**
- [ ] Pulling down from the top triggers `loadAirSeaRequests` and updates the Air/Sea list.
- [ ] A spinner is visible during the refresh and disappears once it completes.

### 6.4 Scroll Interactions

**Component:** Vertical scrolling (`ListView.separated` for non-empty, `SingleChildScrollView` for empty view).

**What it does:**
- [ ] Allows users to browse all available Air/Sea requests.
- [ ] Supports overscroll at the top for pull-to-refresh.
- [ ] Maintains a stable layout while switching between loading, list, and empty states.

### 6.5 Loading Lock (`AbsorbPointer`)

**Component:** Input blocking while data is loading.

**What it does:**
- [ ] While the controller’s `isLoading` flag is active, taps and long-presses on the list or empty view are ignored.
- [ ] Prevents users from triggering actions while data is refreshing.
- [ ] After loading finishes, interactions resume normally.

---

## 7. Role-Dependent Behavior (Black-Box)

The app parses the logged-in user’s roles and uses the `_rolePriority` map so that the highest capability role controls tap behavior.

7.1 **Recommended test accounts**
- [ ] Request-only user
- [ ] Release user
- [ ] Courier user
- [ ] Viewer-only user
- [ ] Multi-role users (e.g., Release + Courier)

7.2 **Expectations by role**
- [ ] **Viewer-only:** tapping any card shows view-only details; no editing or workflow progression actions.
- [ ] **Request-only:** tapping early-stage Air/Sea entries allows only limited request-level actions as defined by UX; no release or courier options.
- [ ] **Courier:** tapping transport-stage entries shows courier-relevant actions as per flow definitions.
- [ ] **Release:** tapping preparation/receiving-stage entries shows release/receive actions.
- [ ] **Multi-role:** when a user has more than one role, the UI behaves according to the highest-priority role (Release > Courier > Request > Viewer).

7.3 **Final-status behavior**
- [ ] For all roles, tapping an Air/Sea request with status `Received` or `Cancelled` results in a consistent, read-only handling (no further steps or state changes allowed).

---

## 8. Error Handling & Edge Cases

8.1 **Network/data load errors**
- [ ] If fetching Air/Sea data fails due to network issues, the app does not crash.
- [ ] After restoring connectivity, pull-to-refresh successfully reloads and displays Air/Sea requests.

8.2 **Rapid user actions**
- [ ] Quickly tapping multiple Air/Sea cards does not cause overlapping dialogs or crashes.
- [ ] Quickly long-pressing multiple cards does not show incorrect remarks or multiple stacked dialogs.

8.3 **Background/foreground transitions**
- [ ] While viewing the Air/Sea list, sending the app to background and then returning leaves the UI in a usable state.
- [ ] If the data reloads on resume, transitions between loading and content remain visually clean.

---

This checklist is intended for QA testers validating the Air/Sea list screen and its interaction behaviors (tap, long-press, scroll, refresh, role-based actions) based solely on what they see and can do in the app, without needing to inspect Dart code or GetX controllers.

