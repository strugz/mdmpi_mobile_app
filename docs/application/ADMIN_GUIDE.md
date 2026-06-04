# Logistics Operations Admin Guide

This guide is for operations admins who support Logistics users, request sync, local data, contact records, proof uploads, and troubleshooting. It does not cover backend infrastructure administration.

## Admin Responsibilities

Logistics operations admins help keep field workflows usable by:

- Confirming users can access the Logistics department flow.
- Helping users sync locally modified Logistics request data.
- Refreshing stale Logistics request and reference data.
- Reviewing pending proof uploads in Signature Outbox and Image Outbox.
- Supporting Contact Directory data used by Logistics forms.
- Coordinating with developers when local database inspection is required.

## Accessing Logistics Support Tools

Open:

```text
Settings
```

Important sections:

- Data Settings
- Hard Reset Refresh
- Realtime Location Saver
- Contact Directory
- Developer Tools

Developer Tools currently include Local Storage Viewer, Signature Outbox, and Image Outbox. These are support/debug tools. They must remain hidden from production users unless a release intentionally exposes them to authorized support staff.

## Data Upload and Sync

Use Upload Data when a Logistics user has local changes that need to be sent to the cloud server.

Procedure:

1. Open Settings.
2. Tap Upload Data.
3. Confirm the upload dialog.
4. Wait for the upload operation to finish.
5. Ask the user to refresh the affected Logistics request list.

Use this after offline/local work or when modified requests need to be pushed manually.

## Local vs Server Request Data

Logistics request controllers can switch between local storage and server data.

Use server data when:

- The user has stable network access.
- You need the latest server state.
- You are validating whether a local issue is stale cache.

Use local data when:

- The user is offline or in a poor-signal area.
- You need to inspect locally saved Logistics requests.
- You are preserving unsynced work before upload.

Before clearing local data, confirm that required local updates have been uploaded or are no longer needed.

## Hard Reset Refresh

Hard Reset Refresh clears cached local data for the selected Logistics area and reloads from the server.

Request data refresh options:

- Standard Delivery
- Hotline Direct
- Air / Sea
- Pick Up
- Pull Out / Return
- Stock Receive

Reference data refresh options used by Logistics:

- Client List
- Users List and MDMPI requester cache
- Vehicle List

Recommended workflow:

1. Ask which Logistics category or reference list looks stale.
2. Confirm network connectivity.
3. Use the smallest reset option that matches the issue.
4. Confirm the reset dialog.
5. Reopen or refresh the affected Logistics screen.
6. If data is still incorrect, compare server state and local database state with developer support.

Do not use hard reset as the first response to failed proof uploads. Review Signature Outbox or Image Outbox first.

## Logistics Request Support Matrix

| Area | Primary admin support actions |
|---|---|
| Standard Delivery | Refresh request cache, verify status progress, check signature/image outboxes, support BackLoad routing. |
| Pull Out / Return | Refresh pull-out cache, verify filters/status, confirm cancellation remarks. |
| Pick Up | Refresh pickup cache, verify status/filter data, confirm cancellation remarks. |
| Air / Sea | Refresh air/sea cache, verify request data and filters. |
| Hotline Direct | Refresh Hotline Direct cache, remember it reuses Standard Delivery form/data patterns. |
| Stock Receive | Refresh Stock Receive cache, remember it reuses Pull Out / Return form/data patterns. |
| BackLoad | Confirm it is opened from a Standard Delivery request context. |

## Realtime Location Saver

The Realtime Location Saver setting stores the latest location locally. Delivery tracking handles live sharing separately.

Use this toggle when:

- A Logistics support workflow requires latest-location persistence.
- A user needs local location state retained for troubleshooting.

If location features fail, verify:

- Device location services are enabled.
- The app has location permission.
- Maps and location services are configured.
- The request is in a status that supports active tracking.

## Contact Directory

Contact Directory is available from Settings and supports local contact workflows.

If contact suggestions or contact-person lookup behaves incorrectly:

1. Open Contact Directory and confirm the contact exists locally.
2. Refresh related reference data if stale.
3. Check local storage only if the issue cannot be resolved from the normal UI.

## Signature Outbox

Signature Outbox is a developer-facing support page for pending or failed receiver signature uploads.

Use it when:

- A completed Standard Delivery or related delivery request is missing a receiver signature on the server.
- A Logistics user reports that signature upload failed.
- Local proof data exists but has not synced.

Procedure:

1. Open Settings.
2. Open Signature Outbox.
3. Tap refresh.
4. Review pending or failed items by request ID.
5. Preview the signature if needed.
6. Retry upload when available.
7. Clear outbox entries only after confirming they are no longer needed or have uploaded successfully.

## Image Outbox

Image Outbox is a developer-facing support page for pending or failed proof image uploads.

Use it when:

- Proof images are missing on the server.
- A Logistics request has a local image but upload failed.
- A user completed image capture while offline.

Procedure:

1. Open Settings.
2. Open Image Outbox.
3. Refresh the list.
4. Review pending items by request ID and image metadata.
5. Retry upload when available.
6. Clear entries only when they are confirmed safe to remove.

## Local Storage Viewer

Local Storage Viewer is a debug/testing tool for inspecting SQLite tables. It can display, delete, refresh, and clear local table data.

Use it only for support/debug workflows. Deleting or clearing table data can permanently remove local records from the device.

Logistics-relevant tables include:

- `a_tblRequest`
- `a_tblRequestDocumentReference`
- `a_tblRequestReceiverSignature`
- `a_tblRequestImage`
- `a_tblRequestImageOutbox`
- `a_tblRequestRemarks`
- `a_tblRequestPickUp`
- `a_tblRequestAirSea`
- `a_tblRequestPullOutReturnPickUp`
- `a_tblRequestBackload`
- `ACCMST_`
- `a_tblMobile`
- `Users`
- `CNTMST`
- `contacts`
- `a_tblItemCategory`
- `a_tblFormCategory`

Before deleting data:

1. Confirm the affected Logistics request/user/table.
2. Confirm whether unsynced data exists.
3. Prefer a normal hard reset refresh when possible.
4. Escalate to developers if table relationships or foreign-key effects are unclear.

## Troubleshooting Playbooks

### User Cannot Access Logistics

1. Confirm the user's account department is Logistics.
2. Ask the user to logout and sign in again.
3. Confirm Logistics onboarding completion.
4. If the user lands in another department, escalate with account details and cached department state.

### Logistics Request Category Missing

1. Confirm Form Category data is available.
2. Refresh related request/reference data.
3. Check whether the category is one of the supported Logistics categories.
4. If local data is stale, run the smallest matching hard reset.

### Upload Failed or Proof Missing

1. Confirm network connection.
2. Check Signature Outbox or Image Outbox.
3. Retry upload if the item is present.
4. Use Upload Data for modified request data.
5. Escalate with request ID, category, status, and outbox state if retry fails.

### Logistics Request Data Looks Wrong

1. Confirm whether the user is viewing local or server data.
2. Switch to server data to compare latest state.
3. Upload any required local changes.
4. Run hard reset for the affected request or reference data.
5. Use Local Storage Viewer only when normal refresh does not explain the issue.

## Escalation Checklist

Send developers:

- Platform: Android or Windows.
- User role and confirmation that department is Logistics.
- Request category and request ID.
- Current request status.
- Whether local or server data was selected.
- Error message or screenshot, if available.
- Signature/Image Outbox state for proof issues.
- Whether hard reset or Upload Data was already attempted.
