# QA Overview – Hotline Direct List

## Scope / Overview

Screen name: Hotline Direct List

Purpose: Verify that the **Hotline Direct list** (`HotlineDirectList`) correctly displays, refreshes, and responds to all interaction components (tap, long-press, pull-to-refresh, loading/empty states, role-based actions) based only on what is visible in the app. This QA also summarizes what each interaction component does from a black-box perspective, grounded in the behavior of `HotlineDirectList`.

This QA focuses on:
- Loading and empty states for Hotline Direct requests
- List behavior when requests exist (scrolling, separators)
- Pull-to-refresh behavior
- Card tap and long-press behavior, including remarks
- Role-based behavior when a Hotline Direct request is tapped

---

## 1. Entry & Embedding

1.1 **Visibility within Request flow**
- [ ] From the logistics/Request area, navigate to the **Hotline Direct** category/tab.
- [ ] Confirm that a vertical list of Hotline Direct requests appears when data is available.
- [ ] Confirm that the list appears under relevant filters/tabs and respects padding from the screen edges.

1.2 **Back navigation (screen-level)**
- [ ] Using the host screen’s back navigation (app bar back or system back) returns to the previous screen correctly.
- [ ] No lingering dialogs, overlays, or partial UI remain after backing out.

---

## 2. Loading State (Shimmer Placeholder)

> When data is loading and no filtered Hotline Direct requests are currently visible.

2.1 **Initial loading**
- [ ] On first entering the Hotline Direct tab while data is still loading, a loading placeholder appears instead of a blank screen.
- [ ] The placeholder is a shimmer-style rectangular area (`BShimmerEffect`) taking a reasonable portion of the screen (for example, full width and about 300px tall).

2.2 **Transition from loading**
- [ ] Once loading completes:
  - [ ] If there are Hotline Direct requests, the shimmer disappears and the list of cards appears.
  - [ ] If there are no requests, the shimmer disappears and the empty state appears.
- [ ] There is no overlap/flicker where shimmer and real content are shown together.

---

## 3. Non-Empty List Behavior

> When `filterManager.filteredRequests` has one or more entries.

3.1 **List layout**
- [ ] The list shows one Hotline Direct request per row as a card (`BRequestCardHorizontal`).
- [ ] There is consistent vertical spacing (`BSizes.spaceBtwItems`) between cards.
- [ ] The list scrolls vertically when there are more items than fit on the screen.

3.2 **Scroll behavior**
- [ ] Scrolling up/down is smooth, with no visible jump as data refreshes.
- [ ] You can pull down at the top of the list to trigger pull-to-refresh (see Section 4).

3.3 **Request card content (black-box)**
- [ ] Each card shows key information for a Hotline Direct request (e.g., request ID, client, date, status) according to UX design.
- [ ] Text and icons are legible; no text is clipped or overlapping.

3.4 **Interaction lock during loading**
- [ ] While the list is in a loading state (e.g., after a refresh), taps and long-presses on the list are temporarily disabled (via a touch-absorbing layer).
- [ ] After loading completes, user interactions on cards are active again.

---

## 4. Pull-to-Refresh Behavior

**Interaction Component:** Pull-down gesture on the list (`RefreshIndicator`).

4.1 **Gesture and indicator**
- [ ] When at the top of the list, pulling down shows a refresh spinner at the top.
- [ ] Releasing after the pull triggers a refresh of Hotline Direct requests.

4.2 **Post-refresh behavior**
- [ ] After refresh, any new or updated Hotline Direct requests appear in the list.
- [ ] If there is still no data, the empty state remains.
- [ ] The refresh spinner disappears once loading is complete.

---

## 5. Empty State (No Hotline Direct Requests)

> When there are no Hotline Direct requests after loading and applying filters.

5.1 **Empty state contents**
- [ ] A centered empty state appears instead of a blank list, containing:
  - [ ] An inbox outline icon.
  - [ ] A primary message: **"No Hotline Direct requests found"**.
  - [ ] A secondary message: **"Try adjusting your filters"**.

5.2 **Theming and readability**
- [ ] In light mode, icon and text use appropriate darker colors (e.g., dark grey) and are clearly readable.
- [ ] In dark mode, icon and text switch to light colors so they remain visible on dark backgrounds.

---

## 6. Interaction Components & What They Do

### 6.1 Hotline Direct Card (Tap)

**Component:** Each row is a tappable card (`BRequestCardHorizontal`) wrapped in an `InkWell`.

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple/highlight respecting rounded corners).
- [ ] Tapping a card selects that Hotline Direct request and opens the appropriate action or detail flow.

**Behavior summary (black-box, based on role & status):**
- When a card is tapped, the app:
  - [ ] Treats that request as the **current selection**.
  - [ ] Checks the request’s status (e.g., `New Request`, `Getting Supplies Ready`, `Item Prepared`, `For Delivery`, `Done Delivery`, `Cancelled`).
  - [ ] Checks the logged-in user’s roles (Request, Release, Courier, Viewer, etc.).
  - [ ] Chooses an **active role** according to these rules:
    - For **delivery-stage statuses** (e.g., `Item Prepared`, `For Delivery`):
      - Prefer **Courier** role if available.
      - Fallback to **Release** role if Courier is not available.
    - For **preparation-stage statuses** (e.g., `New Request`, `Getting Supplies Ready`):
      - Prefer **Release** role.
      - Fallback to **Request** role if Release is not available.
    - Otherwise:
      - Pick the **highest-priority role** using this priority: Release > Courier > Request > Viewer.
- **Done/Cancelled statuses:**
  - [ ] If request status is `Done Delivery` or `Cancelled`, tapping always opens a **default, view-only handler** (no further workflow steps), regardless of user role.
- **No valid role:**
  - [ ] If no valid role is found for the user, tapping still opens a **view-only** dialog via the default handler.

From a tester’s perspective:
- [ ] Users with stronger roles (Release, Courier) see more powerful actions appropriate to that status.
- [ ] Viewer-only or request-only users see limited or view-only actions.
- [ ] Completed or cancelled requests always open in a read-only fashion without state-changing actions.

> QA should use different test accounts to validate that the resulting dialog/screen and actions differ correctly per combination of status and user role, without needing to know handler class names.

### 6.2 Hotline Direct Card (Long Press – Remarks)

**Component:** Long-press gesture (`onLongPress`) on each card.

**What it does:**
- [ ] Long-pressing a card with status **not** equal to `Done Delivery` and **not** equal to `Cancelled` opens a **Remarks** dialog.
- [ ] The Remarks dialog allows the user to:
  - [ ] View existing remarks associated with that Hotline Direct request.
  - [ ] Add or edit remarks as per UX design.
  - [ ] Save/apply changes or cancel.
- [ ] Long-pressing a card where status is `Done Delivery` or `Cancelled` does **not** open the Remarks dialog.

QA should verify:
- [ ] Remarks dialog appears only for in-progress/non-final requests.
- [ ] The correct remarks are shown for each request, and changes are preserved as expected.

### 6.3 Pull-to-Refresh

**Component:** `RefreshIndicator` around the list.

**What it does:**
- [ ] Pulling down from the top triggers a reload of Hotline Direct requests (`loadRequests`).
- [ ] A spinner is visible during refresh and disappears once complete.

### 6.4 Scroll Interactions

**Component:** Vertical scrolling (`ListView.separated`).

**What it does:**
- [ ] Allows users to browse all available Hotline Direct requests.
- [ ] Supports overscroll at the top for pull-to-refresh.
- [ ] Maintains a stable layout while switching between loading, list, and empty states.

### 6.5 Loading Lock (`AbsorbPointer`)

**Component:** Input blocking while data is loading.

**What it does:**
- [ ] While the controller’s loading flag is active, taps and long-presses on the list are ignored.
- [ ] Prevents users from triggering actions while data is refreshing.
- [ ] After loading finishes, interactions resume normally.

---

## 7. Role-Dependent Behavior (Black-Box)

The app uses role information from the logged-in user’s profile and an internal priority mapping to select the best-suited handler for each request.

7.1 **Recommended test accounts**
- [ ] Request-only user
- [ ] Release user
- [ ] Courier user
- [ ] Viewer-only user
- [ ] Multi-role users (e.g., Release + Courier)

7.2 **Expectations by role**
- [ ] **Viewer-only:** tapping any card shows view-only details; no editing or workflow progression actions.
- [ ] **Request-only:** tapping early-stage requests allows only limited request-level actions; no release or courier options.
- [ ] **Courier:** tapping delivery-stage requests prioritizes courier-relevant actions; preparation-stage actions are hidden or secondary.
- [ ] **Release:** tapping preparation-stage requests shows preparation/release actions; may also have visibility into delivery actions when Courier is not available.
- [ ] **Multi-role:** when a user has more than one role, the app applies the described priority and the behavior matches the highest-priority role suitable for the current status.

7.3 **Final-status behavior**
- [ ] For all roles, tapping a Hotline Direct request with status `Done Delivery` or `Cancelled` always results in the same, read-only handling (no further steps or state changes allowed).

---

## 8. Error Handling & Edge Cases

8.1 **Network/data load errors**
- [ ] If fetching Hotline Direct data fails due to network issues, the app does not crash.
- [ ] After restoring connectivity, pull-to-refresh successfully reloads and displays Hotline Direct requests.

8.2 **Rapid user actions**
- [ ] Quickly tapping multiple Hotline Direct cards does not cause overlapping dialogs or crashes.
- [ ] Quickly long-pressing multiple cards does not show incorrect remarks or multiple stacked dialogs.

8.3 **Background/foreground transitions**
- [ ] While viewing the Hotline Direct list, sending the app to background and then returning leaves the UI in a usable state.
- [ ] If the data reloads on resume, transitions between loading and content remain visually clean.

---

This checklist is intended for QA testers validating the Hotline Direct list screen and its interaction behaviors (tap, long-press, scroll, refresh, role-based actions) based solely on what they see and can do in the app, without needing to inspect Dart code or GetX controllers.

