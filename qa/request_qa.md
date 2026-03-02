# QA Overview – Request Screen

## Scope / Overview

Screen name: Request Screen

Purpose: Verify that the Request screen correctly displays and manages different logistics request categories in a tabbed + carousel layout, behaves consistently across categories, and exposes the correct actions and filters, based only on what is visible in the app (no knowledge of the internal code is required).

This QA focuses on what testers can see and do:
- Category tabs along the top
- A horizontal page/carousel view for each category
- Filters/controls per category (including Local/Server switch)
- A floating action button to create a new request (for users with permission)

---

## 1. Entry to the Request Screen

1.1 **Navigation into the screen**
- [ ] From the main app (e.g., bottom navigation, drawer, shortcut), there is a clear way to open the Request screen.
- [ ] Tapping the Request entry point opens the Request screen without:
  - [ ] Crashes
  - [ ] Long blank screens
  - [ ] Flickering or obvious visual glitches

1.2 **Back navigation**
- [ ] A back or close control is visible (e.g., top app bar back arrow or system back gesture/button).
- [ ] Pressing back returns to the previous screen correctly.
- [ ] No duplicate Request screens appear in the back stack (you don’t need to press back multiple times to exit a single visit).

---

## 2. Overall Layout & Visual Design

2.1 **App bar / header**
- [ ] The top app bar shows a clear title such as "Request".
- [ ] App bar styling (colors, shadows, icons) is consistent with other main screens.

2.2 **Content structure**
- [ ] Below the app bar, there is a filter area (when categories are available), a row of tabs (category names), and a content area that changes per tab.
- [ ] The content area fills the rest of the screen and looks balanced (no excessive empty spaces or overlapping content).

2.3 **Typography and colors**
- [ ] Category names in the tab bar are readable, correctly spelled, and follow the app’s text style.
- [ ] Texts in the filter area, lists, and action buttons have adequate contrast and consistent styling.
- [ ] Overall look and feel match other logistics-related screens.

---

## 3. Loading & Empty States

3.1 **Initial loading state**
- [ ] When first opening the Request screen (and categories are still loading), a clear loading indicator is shown (e.g., spinner in the center of the screen).
- [ ] The title/app bar remains visible during loading.
- [ ] Once data is loaded, the loading indicator disappears and the main content is shown.

3.2 **Empty state (no categories)**
- [ ] If no form categories are available, a message or placeholder state is displayed instead of the tabbed interface.
- [ ] The placeholder includes:
  - [ ] An icon or illustration indicating no categories / data.
  - [ ] A clear message such as "No form categories available" or an error message.
- [ ] If an error occurred while loading, the message explains that there was a problem.
- [ ] A **Retry** button is visible if an error can be retried, and pressing it reattempts loading and updates the UI.

3.3 **Transition from loading to normal state**
- [ ] No visual glitches occur when switching from loading or empty states into the tabbed content.

---

## 4. Category Tabs & Carousel Behavior

4.1 **Tabs visibility**
- [ ] When categories are available, they appear as tabs along the top.
- [ ] Each tab shows the category name clearly.
- [ ] If there are few categories, tabs fit the width; if many, tabs are horizontally scrollable.

4.2 **Tab selection behavior**
- [ ] The currently selected tab is visually highlighted (e.g., bold text, indicator line).
- [ ] Tapping a tab changes the visible content area to that category’s list.
- [ ] The highlight moves correctly to the tapped tab.

4.3 **Horizontal swipe / carousel behavior**
- [ ] You can swipe left/right on the content area to move between categories.
- [ ] Swiping changes the visible category and also updates the selected tab to match.
- [ ] Swiping loops or stops exactly as design requires (e.g., infinite scroll or stops at ends).

4.4 **Tab & carousel sync**
- [ ] When you tap a tab, the content area moves to the matching category.
- [ ] When you swipe to another category, the correct tab becomes selected.
- [ ] There is no mismatch between selected tab and visible content.

---

## 5. Per-Category Filter / Controls Area

5.1 **Filter area visibility**
- [ ] When categories are available, a filter area appears below the app bar and above the tabs.
- [ ] The contents of this area change appropriately when a different category is selected.
- [ ] Filter controls are clearly labeled and do not overlap other UI elements.

5.2 **Filter interaction**
- [ ] Changing any filter control (e.g., dropdown, chips, date pickers) visibly updates the list below (where applicable).
- [ ] Filters reset or persist across category changes according to requirements (document/verify expected behavior).

5.3 **Filter behavior with swiping**
- [ ] Swiping between categories also updates the filter area to correspond to the new category.
- [ ] No stale filters remain visible from another category.

---

## 6. Local/Server Switch in App Bar

6.1 **Switch visibility and labeling**
- [ ] When categories are available, a small control appears in the top-right area showing a label and switch (e.g., "Server" / "Local").
- [ ] The label text updates based on the switch position:
  - [ ] When the switch is ON, label shows the correct mode (e.g., "Server").
  - [ ] When the switch is OFF, label shows the other mode (e.g., "Local").

6.2 **Per-category behavior**
- [ ] For each category, the switch reflects that category’s current storage mode when selected.
- [ ] Changing the switch while on a given category updates only that category’s storage mode, not all categories.
- [ ] When you switch categories and come back, the previous selection (Server/Local) for each category is remembered if that is the expected behavior.

6.3 **Visual feedback**
- [ ] The switch thumb and track visually reflect the ON/OFF states (e.g., different colors when active/inactive).
- [ ] Tapping the switch has a smooth animation with no visible lag or glitch.

6.4 **Impact on visible data (black-box)**
- [ ] When switching between Local and Server modes, the visible list content or behavior changes appropriately (e.g., different data, offline vs online), based on functional requirements.
- [ ] There are no crashes, freezes, or duplicate items after toggling.

---

## 7. Category Lists (Content Area)

7.1 **General list structure**
- [ ] Each category shows a meaningful list or content area (e.g., list of requests) when selected.
- [ ] List items are visually separated (dividers, cards, spacing) and readable.

7.2 **Data correctness (black-box)**
- [ ] Each item shows key information according to product requirements (e.g., type, status, customer/client, date).
- [ ] No obvious placeholder text or debug labels remain.

7.3 **Scrolling**
- [ ] If there are more items than fit on the screen, vertical scrolling is available.
- [ ] Scrolling behaves smoothly without stuttering.

7.4 **Item interaction**
- [ ] Tapping a list item opens the appropriate detail or edit screen for that request.
- [ ] Back navigation from the detail screen returns to the correct category and scroll position, when feasible.

7.5 **Empty list in a specific category**
- [ ] If a specific category has no items, a clear empty state or message is shown instead of a blank area.

---

## 8. Floating Action Button (Add Request)

8.1 **Visibility according to user role**
- [ ] When logged in as a user who *should* be allowed to create requests, a circular add button (typically with a plus icon) is visible.
- [ ] When logged in as a user who *should NOT* be allowed to create requests, the add button is **not** visible.

8.2 **Position and style**
- [ ] The add button appears in the bottom-right (or the designated FAB area) and does not cover important content.
- [ ] Button color and icon style match the app’s primary button style.

8.3 **Interaction**
- [ ] Tapping the add button on a given category opens the appropriate "new request" form for that category.
- [ ] The opened form correctly reflects the currently selected category (e.g., Standard Delivery vs Pull Out form).
- [ ] Canceling or completing the form returns you to the Request screen without layout issues.

8.4 **Post-creation behavior**
- [ ] After successfully creating a request, the new item appears in the correct category list (if that is the expected behavior).
- [ ] There are no duplicate entries or missing items.

---

## 9. Error Handling & Edge Cases

9.1 **Network errors (if testable)**
- [ ] When network is unavailable or unstable, attempts to load or refresh data show clear, user-friendly errors.
- [ ] The screen does not get stuck with an infinite loader with no message.

9.2 **Switching rapidly between categories**
- [ ] Quickly tapping/swiping between categories does not cause:
  - [ ] Crashes
  - [ ] Broken layouts
  - [ ] Stuck loading indicators

9.3 **App background/foreground transitions**
- [ ] Putting the app in the background while on the Request screen and returning does not break the tab/scroll state.
- [ ] Data remains in a reasonable state (no completely blank lists unless expected).

9.4 **Orientation changes**
- [ ] Rotating the device while on the Request screen preserves the current category and shows its content correctly.
- [ ] Tabs, filters, and lists reflow properly with no overlapping elements.

---

## 10. Visual & Behavioral Consistency

10.1 **Consistency across categories**
- [ ] All categories use a consistent list style, spacing, and typography where appropriate.
- [ ] Filters and storage mode switch behave similarly across categories, unless explicitly designed otherwise.

10.2 **Consistency with other logistics screens**
- [ ] The Request screen’s app bar, colors, and fonts are consistent with other logistics features.

10.3 **Accessibility basics**
- [ ] Tabs and list items are large enough to tap without difficulty.
- [ ] Text and icon contrast are sufficient for readability.

---

This checklist is intended for QA testers validating the Request screen based solely on visible behavior and UX, without needing to inspect the underlying Dart code, controllers, or services.

