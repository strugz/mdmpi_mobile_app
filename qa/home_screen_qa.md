# QA Overview – Home Screen

## Scope / Overview

Screen name: Home Screen

Purpose: Verify that the Home screen looks correct, is consistent with the app's design, and displays request form shortcuts and activity dashboard statistics without visual or interaction issues, based only on what is visible in the app (no knowledge of the internal code is required).

---

## 1. Entry to the Home Screen

1.1 **Navigation into the screen**
- [ ] After logging in successfully as a returning user, the Home screen is displayed as the default landing screen.
- [ ] For first-time users, the Home screen appears after completing or skipping the Onboarding screens.
- [ ] From any other main section (Request, Location, Settings), tapping the Home icon in the bottom navigation bar switches to the Home screen without:
  - [ ] Crashes
  - [ ] Long blank screens
  - [ ] Flickering or obvious visual glitches

1.2 **Bottom navigation behavior**
- [ ] When the Home screen is active, the Home icon in the bottom navigation bar is visually highlighted/selected.
- [ ] The bottom navigation bar remains visible and fixed at the bottom of the screen.
- [ ] No system back button is needed on the Home screen (it is a top-level destination).

---

## 2. Overall Layout & Visual Design

2.1 **Header area**
- [ ] The top area of the screen has a colored primary header container that matches the app's design.
- [ ] The header includes an app bar with the app logo, title, or user greeting (as per design).
- [ ] The header style (colors, shape) is consistent with other main screens in the app.

2.2 **Page padding and alignment**
- [ ] Content below the header does not touch the extreme left or right edges; there is comfortable horizontal padding.
- [ ] Main sections (Request Form Shortcuts, Activity Dashboard) are aligned consistently.
- [ ] The screen appears balanced on different device sizes (no overly cramped or overly empty regions).

2.3 **Typography and colors**
- [ ] Section headings (e.g., "Request Form Shortcuts", "Activity Dashboard") are visually distinct from body text.
- [ ] All texts are readable with sufficient contrast against the background.
- [ ] Colors and fonts match the app's established style, especially compared to other main screens.

---

## 3. Header & App Bar Content

3.1 **App bar presence**
- [ ] The app bar is visible at the top within the primary header container.
- [ ] The app bar includes the app logo and/or a welcome message (e.g., "Welcome" or user's name if personalized).
- [ ] If there are action buttons (e.g., notifications, profile), they are clearly visible and tappable.

3.2 **Header consistency**
- [ ] The header area background color and shape (curved bottom) match the design system used across the app.
- [ ] The header does not overlap with the status bar or system UI elements.

---

## 4. Request Form Shortcuts Section

4.1 **Section heading**
- [ ] A section heading is visible below the header (e.g., "Request Form" or similar text from the design).
- [ ] The heading text is free from typos and uses the approved wording.
- [ ] The heading is aligned consistently with the content below it.

4.2 **Request form shortcuts grid/list**
- [ ] Multiple request form shortcuts are visible (e.g., Standard Delivery, Air & Sea, Pick-up, etc.).
- [ ] Each shortcut displays:
  - [ ] An icon or image representing the request type
  - [ ] A label clearly describing the request type (e.g., "Standard Delivery", "Air & Sea")
- [ ] All icons are rendered clearly without pixelation or distortion.
- [ ] Shortcut items are evenly spaced and aligned in a grid or list format.

4.3 **Shortcut interaction**
- [ ] Tapping any request shortcut (e.g., "Standard Delivery") navigates to the corresponding request form screen without:
  - [ ] Crashes
  - [ ] Long loading times
  - [ ] Blank screens
- [ ] After navigating to a request form and returning (via back button), the Home screen displays correctly without duplication or layout issues.

4.4 **Shortcut availability**
- [ ] All expected request types (per product requirements) are present and accessible.
- [ ] No duplicate shortcuts appear.
- [ ] Shortcuts remain tappable and do not overlap with other UI elements.

---

## 5. Divider Between Sections

5.1 **Visual separator**
- [ ] A divider or visual separator is present between the Request Form Shortcuts section and the Activity Dashboard section.
- [ ] The divider is subtle and does not distract from the content.
- [ ] The divider spans the appropriate width (typically full width with padding).

---

## 6. Activity Dashboard Section

6.1 **Section heading**
- [ ] A section heading is visible for the dashboard (e.g., "Activity Dashboard" or similar text from the design).
- [ ] The heading text is free from typos and uses the approved wording.
- [ ] A year label is displayed below or near the dashboard heading (e.g., "2026" or the current year).
- [ ] The year value updates correctly to reflect the current year.

6.2 **Dashboard statistics display**
- [ ] Multiple dashboard items are visible, each displaying:
  - [ ] A descriptive label (e.g., "Total Requests", "Getting Supplies Ready", "Items Prepared", "For Delivery", "Delivered")
  - [ ] A numerical value corresponding to the label
- [ ] All dashboard items are aligned consistently in a vertical list.
- [ ] Labels are clear, readable, and free from typos.
- [ ] Numerical values are displayed clearly and formatted appropriately (e.g., whole numbers, no unnecessary decimals).

6.3 **Dashboard data accuracy (visual verification)**
- [ ] Dashboard statistics appear to update when new requests are created or request statuses change:
  - [ ] After creating a new request, refresh or revisit the Home screen to verify the "Total Requests" count increases.
  - [ ] After changing a request's status (if possible in the app), verify the corresponding dashboard count updates (e.g., "For Delivery" increases).
- [ ] If no data is available (e.g., new user with no requests), dashboard items should display "0" or an appropriate empty state without crashing.

6.4 **Dashboard loading behavior**
- [ ] When the Home screen first loads, dashboard statistics appear without excessive delay.
- [ ] If there is a loading state (e.g., spinner, skeleton), it should be brief and not block the entire screen.
- [ ] If data fails to load (e.g., no network), an appropriate error message or retry option should appear (if per design).

---

## 7. Scrolling & Small-Screen / Keyboard Behavior

7.1 **Vertical scrolling**
- [ ] On smaller devices, you can scroll to see the entire Home screen content, including:
  - [ ] The header and app bar
  - [ ] All request form shortcuts
  - [ ] The divider
  - [ ] The activity dashboard section header and year
  - [ ] All dashboard statistics
- [ ] The bottom-most dashboard item is fully visible after scrolling.
- [ ] Scrolling is smooth without lag or stuttering.

7.2 **Screen orientation**
- [ ] Rotating between portrait and landscape does not cause:
  - [ ] Overlapping content
  - [ ] Disappearing UI elements
  - [ ] Layout breaks
- [ ] All essential elements remain reachable through scrolling in both orientations.

7.3 **Bottom navigation overlap**
- [ ] The bottom navigation bar does not cover or overlap the last dashboard item.
- [ ] There is sufficient bottom padding to ensure all content is visible above the navigation bar.

---

## 8. Data Refresh & Real-Time Updates

8.1 **Manual refresh**
- [ ] Navigating away from the Home screen (to another tab) and returning refreshes the dashboard data.
- [ ] Pulling down to refresh (if the design includes pull-to-refresh) updates the dashboard statistics.

8.2 **Automatic updates**
- [ ] After performing actions elsewhere in the app (e.g., creating a new request, changing a request status), returning to the Home screen shows updated dashboard counts.
- [ ] Dashboard updates do not cause the screen to jump or reset scroll position unexpectedly.

---

## 9. Theme & Dark Mode Support

9.1 **Light mode**
- [ ] In light mode, the Home screen uses light background colors with appropriate contrast.
- [ ] Text is readable (dark text on light backgrounds).
- [ ] Icons and images are clearly visible.

9.2 **Dark mode**
- [ ] In dark mode, the Home screen uses dark background colors with appropriate contrast.
- [ ] Text is readable (light text on dark backgrounds).
- [ ] Icons and images adapt to dark mode (if applicable) or remain clearly visible.
- [ ] The primary header container adapts its color scheme for dark mode.

9.3 **Theme consistency**
- [ ] Switching between light and dark mode (via system settings or app settings) updates the Home screen immediately without requiring a restart.
- [ ] No elements remain stuck in the wrong theme (e.g., light text on light background in light mode).

---

## 10. Accessibility

10.1 **Text scaling**
- [ ] Increasing the system font size (via device accessibility settings) does not cause:
  - [ ] Text to be cut off or overlap
  - [ ] UI elements to become unusable
- [ ] All labels and values remain readable at larger font sizes.

10.2 **Screen reader support (if applicable)**
- [ ] With a screen reader enabled (e.g., TalkBack on Android, VoiceOver on iOS), all interactive elements (shortcuts, navigation buttons) are announced clearly.
- [ ] Dashboard labels and values are read aloud in a meaningful order.

---

## 11. Performance & Stability

11.1 **Screen loading time**
- [ ] The Home screen loads quickly after login or navigation from another tab (within 1-2 seconds under normal conditions).
- [ ] If loading takes longer (e.g., due to network), a loading indicator appears and the screen does not freeze.

11.2 **Stability**
- [ ] The Home screen does not crash when:
  - [ ] Loading initially
  - [ ] Refreshing data
  - [ ] Navigating to and from request forms
  - [ ] Switching themes
  - [ ] Rotating the device
- [ ] No memory leaks or performance degradation occur after repeatedly navigating to and from the Home screen.

---

## 12. Edge Cases & Error Handling

12.1 **No network / offline state**
- [ ] If the device is offline when the Home screen loads:
  - [ ] Dashboard statistics show previously cached data (if available), OR
  - [ ] An appropriate message indicates the data may be out of date, OR
  - [ ] An error message with retry option appears (per design).
- [ ] The screen does not crash or show blank content.

12.2 **No data / new user**
- [ ] For a new user with no requests, dashboard statistics display "0" for all counts.
- [ ] The screen layout remains intact (no missing sections or broken UI).

12.3 **Large numbers**
- [ ] If dashboard statistics grow to large numbers (e.g., 1000+ requests), values display correctly without:
  - [ ] Text overflow
  - [ ] UI element misalignment
  - [ ] Truncation without indication (e.g., "1000+" or proper formatting)

---

## 13. Summary Checklist

- [ ] **Entry & Navigation**: Home screen accessible from login, onboarding, and bottom navigation without issues.
- [ ] **Header & App Bar**: Clearly visible, styled consistently, no overlaps.
- [ ] **Request Form Shortcuts**: All shortcuts present, tappable, navigate correctly.
- [ ] **Divider**: Present and visually appropriate.
- [ ] **Activity Dashboard**: Heading, year, and all statistics display correctly.
- [ ] **Data Accuracy**: Dashboard counts reflect actual request data.
- [ ] **Scrolling**: Smooth, all content reachable, no overlap with bottom navigation.
- [ ] **Theme Support**: Light and dark modes work correctly.
- [ ] **Accessibility**: Text scaling and screen reader support functional.
- [ ] **Performance**: Fast loading, stable under all tested conditions.
- [ ] **Error Handling**: Offline, no data, and edge cases handled gracefully.

---

## Notes / Additional Context

- This QA document is based on the Home screen's current design and functionality as of the review date.
- Any deviations from expected behavior should be documented and reported to the development team.
- Future updates to the Home screen (e.g., new dashboard metrics, additional shortcuts) will require updating this QA document accordingly.

---

**QA Document Version:** 1.0  
**Last Updated:** February 18, 2026  
**Prepared By:** QA Team

