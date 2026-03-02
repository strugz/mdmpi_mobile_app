# QA Overview – Sign Up Screen

## Scope / Overview

Screen name: Sign Up Screen

Purpose: Verify that the Sign Up screen looks correct, is consistent with the app’s design, and allows users to complete sign up without visual or interaction issues, based only on what is visible in the app (no knowledge of the internal code is required).

---

## 1. Entry to the Sign Up Screen

1.1 **Navigation into the screen**
- [ ] From the previous screen (e.g., Login, Welcome, or Landing), there is a clear way to open the Sign Up screen (e.g., a “Sign Up” or “Create Account” button/link).
- [ ] Tapping that entry point opens the Sign Up screen without:
  - [ ] Crashes
  - [ ] Long blank screens
  - [ ] Flickering or obvious visual glitches

1.2 **Back navigation**
- [ ] A back or close control is visible (e.g., back arrow in the top bar or system back behavior).
- [ ] Using back navigation returns to the previous screen correctly.
- [ ] No duplicate screens appear in the back stack (you don’t have to press back multiple times unexpectedly after one visit).

---

## 2. Overall Layout & Visual Design

2.1 **Top bar / header**
- [ ] A header/top bar is visible at the top of the screen (if required by design).
- [ ] The header color, icons, and style are consistent with the rest of the app.
- [ ] If a title is shown in the header, it uses the expected wording (e.g., “Sign Up”, “Create Account”).

2.2 **Page padding and alignment**
- [ ] Content does not touch the extreme left or right edges of the screen; there is comfortable horizontal padding.
- [ ] All main elements (title, fields, buttons, helper text) are aligned consistently (typically left-aligned unless design specifies otherwise).
- [ ] The screen appears balanced on different devices (no area is overly cramped or too empty).

2.3 **Typography and colors**
- [ ] The main title text is visually more prominent than normal text (larger size, heavier weight, or distinct style).
- [ ] All texts are readable with good contrast against their backgrounds.
- [ ] Colors and fonts match the app’s style when compared to other major screens (e.g., Login).

---

## 3. Title / Heading

3.1 **Content**
- [ ] A clear Sign Up–related title is visible near the top of the content area (e.g., “Sign Up”, “Create Account”).
- [ ] The wording matches UX copy requirements (no typos, correct capitalization and phrasing).

3.2 **Position and style**
- [ ] The title appears above the input fields.
- [ ] There is some vertical space between the title and the first field (it should not look cramped).
- [ ] The title is aligned according to design (typically left-aligned) and stands out from other text.

3.3 **Localization (if applicable)**
- [ ] When the device language is changed, the title text updates to the correct translation (if the app supports multiple languages).

---

## 4. Form Content & Layout (What QA Sees)

4.1 **Visible fields**
- [ ] All required sign up fields are present (e.g., name, email, password, confirm password, and any other required data per specification).
- [ ] Each field has a clear label and/or placeholder that explains what the user should enter.
- [ ] Helper or hint texts, if present, are understandable and free from spelling/grammar errors.

4.2 **Field layout and spacing**
- [ ] Fields are arranged vertically in a logical order (e.g., Name → Email → Password → Confirm Password).
- [ ] There is consistent vertical spacing between fields; nothing looks cramped or overlapping.
- [ ] Labels and input boxes are properly aligned (left edges line up where expected).

4.3 **Primary and secondary actions**
- [ ] A clear primary action button exists (e.g., “Sign Up”, “Create Account”).
- [ ] Any secondary actions (e.g., “Already have an account? Log In”) are visible, readable, and not confusing.
- [ ] Buttons are large enough and placed so they can be easily tapped without accidental presses on other elements.

4.4 **Button feedback**
- [ ] Buttons provide a visual response when tapped (e.g., ripple, highlight, or animation).
- [ ] Disabled vs enabled states, if present, are visually distinguishable.

---

## 5. Scrolling & Small-Screen / Keyboard Behavior

5.1 **Vertical scrolling**
- [ ] On smaller screens, you can scroll vertically to see the entire form, including all fields and the main button.
- [ ] When scrolled to the top, the title and first fields are fully visible.
- [ ] When scrolled to the bottom, the main submit button and any final information (e.g., disclaimers) are fully visible.

5.2 **Device rotation**
- [ ] Rotating the device between portrait and landscape does not break the layout.
- [ ] After rotation, all form elements remain reachable via scrolling.

5.3 **On-screen keyboard**
- [ ] Tapping into a text field opens the keyboard without causing layout breakage or overlapping widgets.
- [ ] While the keyboard is open, you can still scroll to see the active field and the submit button.
- [ ] Closing the keyboard returns the screen to a normal layout without leftover gaps or misalignment.

---

## 6. Interaction, Validation & Flows (Black-Box)

6.1 **Typing into fields**
- [ ] Each field accepts text input as expected (no unexpected truncation unless specifically required).
- [ ] For password-type fields:
  - [ ] Characters are hidden/masked by default (if that is the expected behavior).
  - [ ] Any "show/hide password" control (if present) works correctly and clearly indicates the state.

6.2 **Validation feedback**
- [ ] Attempt to submit with required fields empty:
  - [ ] Clear error messages or indicators appear for each missing or invalid field.
  - [ ] Errors are visually associated with the correct fields (or displayed in a clear, consistent area).
- [ ] Attempt to submit with invalid formats (e.g., incorrect email format, weak password if specified):
  - [ ] Appropriate error messages are displayed.
  - [ ] Error text is user-friendly (no technical jargon or internal error codes).

6.3 **Successful submission**
- [ ] With valid data in all fields, tapping the primary button:
  - [ ] Shows any expected loading indicator if there is a delay.
  - [ ] Navigates to the correct next step (e.g., home screen, verification screen, or success screen) according to requirements.
  - [ ] Does not freeze or remain stuck indefinitely on the Sign Up screen without explanation.

6.4 **Error scenarios (user-visible)**
- [ ] If the email/account is already registered (if you can reproduce this state), the screen shows a clear, understandable message.
- [ ] In all error cases, the user can still edit the fields and attempt to submit again.
- [ ] There are no infinite spinners, blank states, or unclear “something went wrong” messages without guidance.

---

## 7. Visual & Behavioral Consistency

7.1 **Consistency with other auth screens**
- [ ] Fonts, colors, and button styles are consistent with the Login screen and other authentication-related screens.
- [ ] Spacing patterns (between title, fields, and buttons) are similar to other screens in the same flow.
- [ ] Copy tone (e.g., formal vs casual, capitalization style) is consistent with the rest of the app.

7.2 **Theme and contrast (if multiple themes are supported)**
- [ ] In light mode, all text, icons, and input borders are clearly visible and legible.
- [ ] In dark mode (or any alternate theme), text and icons remain readable (no dark-on-dark or light-on-light issues).
- [ ] Main buttons and interactive elements remain visually distinct in all themes.

7.3 **Accessibility basics**
- [ ] Tap targets for buttons and interactive text are large enough for comfortable use.
- [ ] There is sufficient contrast between text and background colors to support readability.
- [ ] Moving between fields using the keyboard "Next" or similar controls follows a logical order (top-to-bottom).

---

## 8. Regression & Edge Cases

8.1 **Repeated navigation**
- [ ] Navigate to the Sign Up screen and back multiple times:
  - [ ] No abnormal lag increases or visual glitches accumulate.
  - [ ] Back navigation always returns to the expected previous screen.

8.2 **Form reset / revisit behavior**
- [ ] Leave the Sign Up screen and return to it:
  - [ ] Confirm whether fields are expected to reset or keep their values (compare with requirements) and verify actual behavior matches expectations.
  - [ ] Old error messages do not remain incorrectly if the form is supposed to start fresh.

8.3 **Network or server delays (if testable)**
- [ ] Under slow or unstable network conditions:
  - [ ] Any loading indicators appear and behave reasonably (no infinite invisible wait with no feedback).
  - [ ] Clear error messages are shown if sign up fails due to connectivity.

---

This checklist is intended for QA testers validating the Sign Up screen based solely on visible behavior and UX, without any need to inspect the underlying code or widget implementation.
