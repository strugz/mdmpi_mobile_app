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

### 6.1 Request Card (Tap)

**Component:** Each row is a tappable card representing a Pull Out / Return / Pick-Up request (`InkWell` around a `PullOutRequestCard`).

**What QA sees & should verify:**
- [ ] Cards show visual feedback when tapped (e.g., ripple or highlight within the card’s rounded corners).
- [ ] Tapping a card selects that request and opens the appropriate **action handler** flow for that request.

**Behavior summary from a black-box perspective:**
- When a card is tapped, the app:
  - [ ] Treats that request as the current selection.
  - [ ] Looks at the request’s status (e.g., `New`, `In-progress`, `Picked-up`, `Cancelled`).
  - [ ] Looks at the logged-in user’s roles (e.g., Request, Release, Courier, Viewer).
  - [ ] Chooses the **most powerful role** the user has (Release > Courier > Request > Viewer).
  - [ ] Opens the corresponding dialog/screen for that combination of role and request:
    - **If request status is `Cancelled` or `Picked-up`:**
      - [ ] A default, **read-only** style handler is opened (view details only, no further actions).
    - **If request status is NOT Cancelled/Picked-up:**
      - [ ] For a **Release**-capable user, tapping shows actions around preparing, releasing, or handling pull-out/return.
      - [ ] For a **Courier**-capable user, tapping shows delivery/pick-up related actions.
      - [ ] For a **Request**-only user, tapping shows actions limited to their permitted workflow steps (e.g., advancing new requests).
      - [ ] For a **Viewer**-only user, tapping shows a view-only detail without mutating actions.

> QA does not need to know class names like `PullOutReleaseRoleHandler`; instead, test with different user accounts/roles and confirm that tapping a request opens only the appropriate actions for that role and status.

### 6.2 Request Card (Long Press – Remarks)

**Component:** Long-press gesture (`onLongPress`) on each request card.

**What it does:**
- [ ] Long-pressing a card for a request that is **not in final status** (status is **not** `Picked-up` and not `Cancelled`) opens a **Remarks** dialog.
- [ ] The Remarks dialog allows the user to:
  - [ ] View existing remarks associated with that request.
  - [ ] Add or edit remarks according to design.
  - [ ] Save/apply changes or cancel.
- [ ] Long-pressing a card where status is `Picked-up` or `Cancelled` does **not** open the Remarks dialog (no effect or minimal feedback only).

### 6.3 Pull-to-Refresh (List & Empty)

**Component:** `RefreshIndicator` around the list and the empty state scroll view.

**What it does:**
- [ ] Pulling down from the top triggers a refresh of Pull Out / Return / Pick-Up requests.
- [ ] A spinner appears at the top until the refresh completes.
- [ ] After refresh, the list or empty state is updated.

### 6.4 Scroll Interactions

**Component:** Vertical scroll on `ListView` / `SingleChildScrollView`.

**What it does:**
- [ ] Lets users browse all requests.
- [ ] Works smoothly with pull-to-refresh.
- [ ] Maintains visual stability when the list switches between loading, has data, or is empty.

### 6.5 Loading Lock (`AbsorbPointer`)

**Component:** Touch-input lock while loading.

**What it does:**
- [ ] While the screen is loading data (e.g., after a refresh or initial load), taps and long-presses on the list or empty state are ignored.
- [ ] This prevents accidental actions from occurring while data is mid-update.
- [ ] Once loading completes, items become interactive again.

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

