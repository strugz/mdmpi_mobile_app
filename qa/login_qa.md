# QA Overview – Login Screen

## Scope / Overview

Screen name: Login Screen

Purpose: Verify that the Login screen looks correct, is consistent with the app’s design, and allows users to log in without visual or interaction issues, based only on what is visible in the app (no knowledge of the internal code is required).

---

## 1. Entry to the Login Screen

1.1 **Navigation into the screen**
- [ ] From the app’s starting point (e.g., splash, welcome, or previous screen), there is a clear, discoverable way to open the Login screen (e.g., a “Login” / “Sign In” button or direct landing).
- [ ] Tapping the entry point opens the Login screen without:
  - [ ] Crashes
  - [ ] Long blank screens
  - [ ] Flickering or obvious visual glitches

1.2 **Back navigation**
- [ ] A back or close control is visible if the Login screen is not the first screen (e.g., back arrow in the top bar or system back behavior).
- [ ] Using back navigation returns to the previous screen correctly.
- [ ] No duplicate screens appear in the back stack (you don’t have to press back multiple times unexpectedly after one visit).

---

## 2. Overall Layout & Visual Design

2.1 **Top area / header**
- [ ] The top area of the screen (header, logo, or title) is visible and matches the design (e.g., app logo, welcome text).
- [ ] The style (colors, fonts, iconography) is consistent with the rest of the app.

2.2 **Page padding and alignment**
- [ ] Content does not touch the extreme left or right edges; there is comfortable horizontal padding.
- [ ] Main elements (header area, form fields, buttons, social login section) are aligned consistently, typically left-aligned for text.
- [ ] The screen appears balanced on different device sizes (no overly cramped or overly empty regions).

2.3 **Typography and colors**
- [ ] Key texts (e.g., screen title, section headings) are visually distinct from body text.
- [ ] All texts are readable with sufficient contrast against the background.
- [ ] Colors and fonts match the app’s established style, especially compared to the Sign Up screen.

---

## 3. Header & Intro Content

3.1 **Header presence**
- [ ] A login-related header is visible near the top (e.g., a title like “Login” / “Sign In” or intro text like “Welcome back”).
- [ ] If a logo or illustration is part of the design, it appears correctly sized and positioned.

3.2 **Copy and localization**
- [ ] All header text is free from typos and uses the approved wording.
- [ ] If the app supports multiple languages, switching the device language updates any header/intro text to the correct translation.

---

## 4. Login Form Content & Layout (What QA Sees)

4.1 **Visible fields**
- [ ] All required login fields are present (commonly username/email and password).
- [ ] Labels and/or placeholders clearly describe what should be entered.
- [ ] Helper text (if present, e.g., password rules) is understandable and correctly placed.

4.2 **Field layout and spacing**
- [ ] Fields are stacked vertically in a logical order (e.g., Email → Password).
- [ ] There is consistent vertical spacing between fields so nothing appears cramped.
- [ ] Labels, helper texts, and input boxes are aligned and do not overlap.

4.3 **Password field behavior**
- [ ] Password input is masked (characters not visible) by default, if that is the expected behavior.
- [ ] If a “show/hide password” toggle is provided, it works correctly and clearly indicates its state.

4.4 **Primary and secondary actions**
- [ ] A primary login button is clearly visible (e.g., “Login” / “Sign In”).
- [ ] Any secondary actions (e.g., “Forgot Password?”, “Create Account”) are visible, readable, and look tappable.
- [ ] Primary and secondary actions are spaced so they can be tapped without accidental presses.

4.5 **Button feedback**
- [ ] Buttons show a visual feedback on tap (e.g., ripple, highlight, or opacity change).
- [ ] If disabled states are used (e.g., before fields are filled), disabled vs enabled states are visually distinct.

---

## 5. Scrolling & Small-Screen / Keyboard Behavior

5.1 **Vertical scrolling**
- [ ] On smaller devices, you can scroll to see the entire content, including the login form, any dividers, social login buttons, and links.
- [ ] The bottom-most content (e.g., social login buttons, footer text) is fully visible after scrolling.

5.2 **On-screen keyboard**
- [ ] When tapping into a text field, the keyboard appears without breaking the layout.
- [ ] While the keyboard is open, you can still reach the main login button (via scrolling if necessary).
- [ ] Closing the keyboard returns the layout to normal with no persistent gaps or misaligned content.

5.3 **Device rotation**
- [ ] Rotating between portrait and landscape does not cause controls to overlap or disappear.
- [ ] All essential elements remain reachable through scrolling in both orientations.

---

## 6. Divider & Social Login Section (If Present)

6.1 **Form divider**
- [ ] A visual separator between the classic login form and any social login options is present (e.g., a horizontal line with text like “OR” / “or continue with”).
- [ ] The divider text is centered and readable.
- [ ] Divider visuals (line, spacing) align with overall app style.

6.2 **Social login buttons**
- [ ] Social login buttons for the configured providers (e.g., Google, Facebook, Apple) are visible where expected.
- [ ] Icons, labels, and button colors for each provider look correct and are recognizable.
- [ ] Each social login button is clearly tappable and spaced appropriately.

6.3 **Social login interaction (black-box)**
- [ ] Tapping a social login button gives appropriate visual feedback.
- [ ] If sign-in fails or is canceled, a clear, user-friendly message or behavior is shown (no silent failures or stuck states).

---

## 7. Interaction, Validation & Flows (Black-Box)

7.1 **Typing into fields**
- [ ] You can type into all login fields without unexpected truncation.
- [ ] Input type is appropriate (e.g., email keyboard for email field where applicable).

7.2 **Validation feedback**
- [ ] Attempt to submit with empty fields:
  - [ ] Clear error messages or indicators appear for each required field.
- [ ] Attempt to submit with obviously incorrect input (e.g., bad email format):
  - [ ] A clear, non-technical error message is shown.
- [ ] Error messages appear in a consistent, predictable place and do not overlap other content.

7.3 **Successful login**
- [ ] With valid credentials, tapping the login button:
  - [ ] Shows a loading indication if there is a noticeable delay.
  - [ ] Navigates to the expected next screen (e.g., dashboard, home) without freezing.
  - [ ] Does not leave you on the login screen without feedback.

7.4 **Authentication error scenarios**
- [ ] With invalid credentials (wrong password, unknown account), the screen shows a clear error message.
- [ ] The user can correct the input and retry without needing to restart the app.
- [ ] No infinite spinners or blank error states occur.

7.5 **Forgot password / alternative flows**
- [ ] If a “Forgot Password?” link is present, tapping it opens the correct recovery flow/screen.
- [ ] Returning from the recovery flow brings you back to the Login screen in a consistent state (no half-filled broken UI).

---

## 8. Visual & Behavioral Consistency

8.1 **Consistency with Sign Up screen and other auth screens**
- [ ] Fonts, colors, and button styles are consistent with the Sign Up screen.
- [ ] Spacing between header, fields, and actions follows the same design language.
- [ ] Copy tone and capitalization style are consistent (e.g., both use "Login" vs "Log In" consistently where intended).

8.2 **Theme and contrast (if multiple themes supported)**
- [ ] In light mode, all text and controls are clearly visible with good contrast.
- [ ] In dark mode or other themes, text remains legible (no dark-on-dark or light-on-light issues).
- [ ] Primary buttons stand out clearly in all themes.

8.3 **Accessibility basics**
- [ ] Tap targets (buttons, social icons, links) are large enough for comfortable tapping.
- [ ] Contrast ratios are sufficient for text and primary visual elements.
- [ ] Navigating fields via the keyboard "Next" button (if applicable) follows a logical top-to-bottom order.

---

## 9. Regression & Edge Cases

9.1 **Repeated navigation**
- [ ] Navigate to the Login screen and back multiple times:
  - [ ] No abnormal lag or graphical glitches appear.
  - [ ] Back navigation always returns to the expected previous screen.

9.2 **Form state on revisit**
- [ ] Leave the Login screen and return:
  - [ ] Confirm whether fields are expected to reset or retain values based on requirements, and check that actual behavior matches.
  - [ ] Previous error messages do not remain unexpectedly if the form is supposed to start clean.

9.3 **Network and server delays (if testable)**
- [ ] Under slow or unstable network conditions:
  - [ ] Loading indicators behave reasonably (not stuck forever without any message).
  - [ ] Clear, user-friendly error messages appear if login fails due to connectivity issues.

---

This checklist is intended for QA testers validating the Login screen based solely on visible behavior and UX, without any need to inspect the underlying code or widget implementation.

