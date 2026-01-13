# QA Overview – Stock Receive Form

## Scope / Overview

Screen name: Stock Receive Form

Purpose: Verify that the **Stock Receive Form** screen opens correctly, shows the right title and navigation behavior, and is visually consistent with other request forms, based only on what is visible in the app (no knowledge of the internal code is required).

> Note: As of now, this screen only shows a basic app bar and has no visible fields or actions. This checklist focuses on navigation, header, and layout behavior so QA can still validate this screen.

---

## 1. Entry to the Stock Receive Form

1.1 **Navigation from Request screen**
- [ ] From the Request screen, select the category that corresponds to **Stock Receive** (per product design).
- [ ] Tap the **Add/New Request** button (floating action button or similar entry point).
- [ ] Confirm that the **Stock Receive Form** screen opens.

1.2 **Back navigation**
- [ ] A back arrow is visible in the top app bar.
- [ ] Tapping the back arrow returns to the previous screen (usually the Request screen) without crashing.
- [ ] Only one Stock Receive Form screen is created per entry (a single back press exits this screen; no duplicate pages in the stack).

---

## 2. App Bar & Visual Design

2.1 **App bar title**
- [ ] The app bar displays the text **"Stock Receive Form"**.
- [ ] The title is spelled correctly and uses the correct casing.

2.2 **App bar style**
- [ ] The app bar’s color, height, and typography are consistent with other request forms (e.g., Standard Delivery, Pull Out, Pick-Up, Air/Sea, Hotline Direct).
- [ ] The back arrow style and behavior match those other forms.

2.3 **Status bar and safe area**
- [ ] The app bar does not overlap with the device status bar; content is correctly aligned within the safe area.

---

## 3. Body Layout & Background

3.1 **Body content**
- [ ] The main body area below the app bar is currently empty or shows the default background.
- [ ] There are no stray widgets, debug text, or placeholder artifacts visible.

3.2 **Background color and theme**
- [ ] The background color is consistent with other logistics request forms.
- [ ] In light/dark mode (if supported), the screen respects the theme and remains readable.

---

## 4. Orientation & Responsiveness

4.1 **Orientation changes**
- [ ] Rotate the device between portrait and landscape:
  - [ ] The app bar remains at the top, with the title **"Stock Receive Form"** still visible.
  - [ ] There are no layout glitches, overlaps, or clipped regions.

4.2 **Different device sizes**
- [ ] On small and large devices, the app bar and body area render correctly without clipping or excessive empty margins.

---

## 5. Regression & Navigation Edge Cases

5.1 **Repeated navigation**
- [ ] Open the Stock Receive Form multiple times from the Request screen and go back each time:
  - [ ] No crashes, slow-downs, or visual glitches accumulate.
  - [ ] Back navigation consistently returns to the Request screen.

5.2 **Background/foreground transitions**
- [ ] While on the Stock Receive Form, send the app to the background and bring it back:
  - [ ] The app bar and screen restore correctly.
  - [ ] No blank or half-rendered UI appears.

---

## 6. Future Fields & Form Behavior (Placeholder for Later)

> This section is reserved for future expansion when input fields and actions are added to the Stock Receive Form.

When the form is expanded in future versions, QA should add checks for:
- Client selection and validation
- Document reference fields
- Item/category fields
- Date/time fields for stock receipt
- Responsible user (Received By) and any other logistics details
- Create/Save actions, loading states, and error handling

---

This checklist is intended for QA testers validating the current Stock Receive Form behavior based solely on visible UI and navigation, without any need to inspect the underlying Dart code or widgets.

