# Logistics User Guide

This guide explains how Logistics users work with the MDMPI Mobile App on Android and Windows. Some permission prompts may differ by platform, but the Logistics workflow is intended to stay consistent across both targets.

## Getting Started

### Sign In

1. Open the app.
2. Enter your email and password.
3. Submit the sign-in form.
4. If your email is verified and your department is Logistics, the app checks Logistics onboarding.
5. Complete Logistics onboarding if prompted.
6. After onboarding, the app opens the main navigation.

### Sign Up

1. Open the sign-up screen.
2. Complete the required account, role, and department fields.
3. Select or confirm the Logistics department when applicable.
4. Submit the form.
5. Verify your email when prompted.
6. Return to sign in after verification.

### Reset a Forgotten Password

1. From sign in, open the forgot-password flow.
2. Enter your account email.
3. Follow the reset instructions sent through the configured authentication provider.

## Logistics Onboarding

After sign in, the app checks the `LogisticsOnboardingComplete` flag. If onboarding has not been completed, the Logistics onboarding screen appears before the main navigation.

Other departments exist in shared routing, but this guide focuses only on Logistics. If you are routed to a non-Logistics screen, ask support to verify your account department.

## Logistics Main Navigation

The bottom navigation has four areas:

- Home: Logistics home/dashboard.
- Request: Logistics request categories, request lists, filters, and forms.
- Location: delivery or rider location map view.
- Settings: account, sync, contact, and support tools.

## Request Categories

Open the Request tab to work with Logistics request categories. The app loads categories from local/server data and displays them in this order:

1. Standard Delivery
2. Pull Out / Return
3. Pick Up
4. Air / Sea
5. Hotline Direct
6. Stock Receive

BackLoad is opened from a Standard Delivery request when a backload transaction is needed.

## View and Filter Requests

1. Open Request.
2. Select or swipe to the request category.
3. Review the request cards/list.
4. Use the visible filters for common filtering.
5. Open the custom filter panel for more specific filtering.

Common filters include:

- Date range
- Status
- Item category
- Client name
- Document reference

Available filters depend on the selected category.

## Create a Request

1. Open Request.
2. Select the request category.
3. Tap the add/create action.
4. Complete required client, requester, item, delivery, date, and document-reference fields.
5. Save the request.
6. Confirm that the request appears in the appropriate list.

Category notes:

- Hotline Direct uses the Standard Delivery form structure.
- Stock Receive uses the Pull Out / Return form structure.
- BackLoad expects an existing Standard Delivery request context.

## Standard Delivery Workflow

Standard Delivery manages standard logistics deliveries from request creation through delivery confirmation.

Typical status flow:

```text
New Request
Getting Supplies Ready
Item Prepared
For Delivery
In Transit
Done Delivery
```

Requests can also be cancelled when cancellation is allowed. Cancellation requires remarks.

Common user actions:

- Create a request.
- Prepare items.
- Assign or confirm delivery details.
- Move a request through delivery statuses.
- Capture receiver signature and proof image.
- Check live/location-related delivery information.

## Pull Out / Return Workflow

Pull Out / Return handles return or pull-out request data. Use the Pull Out / Return tab to:

- View pull-out/return requests.
- Filter by date, status, client, item category, or document reference.
- Create or update a request.
- Cancel a request with remarks when allowed.

## Pick Up Workflow

Pick Up handles pickup-specific request tracking. Use the Pick Up tab to:

- View pickup requests.
- Filter pickup data.
- Create or update pickup requests.
- Track status and cancellation remarks.

## Air / Sea Workflow

Air / Sea handles air and sea logistics requests. Use the Air / Sea tab to:

- View air/sea requests.
- Filter by date, status, client, item category, or document reference.
- Create or update air/sea request details.
- Refresh or report stale data to operations admins.

## Hotline Direct Workflow

Hotline Direct is a Logistics request type that reuses Standard Delivery data structures and form behavior.

Use the Hotline Direct tab to:

- View Hotline Direct requests.
- Apply Hotline Direct filters.
- Create requests using the Standard Delivery form base.
- Update status and cancellation remarks where allowed.

## Stock Receive Workflow

Stock Receive is a Logistics request type that reuses Pull Out / Return form behavior.

Use the Stock Receive tab to:

- View Stock Receive requests.
- Apply Stock Receive filters.
- Create requests using the Pull Out / Return form base.
- Update status and cancellation remarks where allowed.

## BackLoad Workflow

BackLoad is tied to a Standard Delivery request. Open BackLoad only from a request context where the app passes the selected Standard Delivery request into the BackLoad page.

Use BackLoad when a delivery requires backload transaction details connected to the original request.

## Proof Capture

Some Logistics delivery flows support:

- Receiver signature
- Proof image
- Receiver details

If proof capture succeeds locally but does not appear on the server, ask an operations admin to check Signature Outbox or Image Outbox.

## Location

Open Location to view delivery location information. Location features depend on permission approval and configured maps/location services.

On Android, the app may request location, camera, storage, and SMS permissions. On Windows, the app requests supported desktop permissions such as location and camera.

## Settings

Open Settings from the bottom navigation.

Common Logistics user actions:

- View account/profile information.
- Upload locally modified request data.
- Toggle Realtime Location Saver.
- Open Contact Directory.
- Logout.

Support/debug tools may also be visible in Settings. Use them only when directed by an operations admin or developer.

## Offline and Local Data

Several Logistics request screens can use local storage. Local mode reads SQLite data on the device and can support field workflows with poor connectivity.

Recommended behavior:

- Use server data when network access is stable.
- Use local data only when instructed or when field conditions require it.
- Upload modified data after reconnecting.
- Do not run reset/debug tools unless support asks you to.

## Troubleshooting

| Problem | What to try |
|---|---|
| Cannot sign in | Check email/password, network connection, and email verification. |
| App does not show Logistics workflow | Logout and sign in again; ask support to verify the account department. |
| Logistics onboarding repeats | Ask support to verify local onboarding storage and account state. |
| Request category is missing | Ask an operations admin to refresh Form Category data or check local/server data. |
| Request list looks stale | Switch to server data or ask an admin to run the smallest matching hard reset. |
| Location is unavailable | Confirm location permission and device location services. |
| Camera or signature capture fails | Confirm camera permission and retry the request. |
| Upload appears stuck | Use Upload Data after reconnecting, then ask an operations admin to check outboxes. |

## Current Logistics Limitations

- Developer tools are visible in Settings in the current implementation, but they are intended for debugging/support.
- Collection, Service, and InHouse workflows are outside this Logistics guide.
- Service and InHouse onboarding screens are not yet implemented in shared routing.
