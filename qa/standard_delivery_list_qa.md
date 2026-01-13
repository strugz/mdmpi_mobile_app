# QA Overview – Standard Delivery List

## Scope / Overview

Screen name: Standard Delivery List (BList)

Purpose: Verify that the **Standard Delivery list** screen correctly displays, refreshes, and reacts to user interactions with delivery requests, based only on what is visible in the app (no knowledge of internal code is required), while the behavior of taps and long-presses is described at a high level.

This QA focuses on:
- How the list behaves with data, while loading, and when empty
- Pull-to-refresh and loading indicator behavior
- Tapping and long-pressing on Standard Delivery requests
- Role-dependent behavior when a request is tapped (from a black-box POV)

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
  - [ ] Tapping shows a default view of request details with no further workflow steps.
- **Preparation-stage statuses (e.g., "New Request", "Getting Supplies Ready")**
  - [ ] Users with "Release" permission should see actions relevant to preparing and releasing items.
  - [ ] Users with only "Request"/viewer rights see limited or view-only interactions.
- **Delivery-stage statuses (e.g., "Item Prepared", "For Delivery")**
  - [ ] Users with "Courier" permission should see delivery-related actions.
  - [ ] If no Courier role exists for the user, but Release role does, Release-level actions may still be surfaced.

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

### 5.4 Scroll Interactions

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

