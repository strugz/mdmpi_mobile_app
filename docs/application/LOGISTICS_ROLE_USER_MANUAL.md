# Logistics Role-Based User Manual

This manual explains what Logistics users can do in the MDMPI Mobile App based on their assigned role. It is for the Logistics Department only.

## Role Basics

Logistics users may have one role or multiple comma-separated roles. When a user has multiple roles, the app chooses the role with the action capability for the selected request status. If no assigned role can act on that status, the request opens as view-only.

Core Logistics roles:

| Role | Primary purpose |
|---|---|
| Request | Create Logistics requests and monitor submitted requests. |
| Release | Prepare, pack, receive, and hand off requests depending on category. |
| Courier | Handle dispatch, transport, delivery, pull-out, and proof workflows. |
| Provincial | Handle the provincial leg of Air / Sea requests. |
| Viewer | View requests without status-changing actions. |
| Admin | Support operations through Settings/admin tools; not a universal status-action override. |

## Common Navigation

1. Sign in with a Logistics account.
2. Complete Logistics onboarding if prompted.
3. Open the Request tab.
4. Select a request category.
5. Tap a request card to view details or perform available role actions.
6. Use filters to narrow the list by date, status, client, item category, or document reference.

The add button appears for users whose role includes `Request`.

## Role Summary

| Role | Can create requests | Can update request statuses | Can use delivery/proof screens | Typical access |
|---|---:|---:|---:|---|
| Request | Yes | Limited by category | No | Create and monitor |
| Release | No | Yes, preparation/receiving stages | Some proof fields by category | Internal processing |
| Courier | No | Yes, delivery/transport stages | Yes | Dispatch, transit, delivery, pull-out |
| Provincial | No | Air / Sea provincial stages | Yes | Provincial pickup/transit/delivery |
| Viewer | No | No | No | Read-only |
| Admin | Not role-based by default | Not automatic | Support only | Sync, reset, outbox, troubleshooting |

## Request Role

The Request role is for users who submit Logistics requests.

### Main Tasks

1. Open Request.
2. Select the request category.
3. Tap the add button.
4. Fill in the required form details.
5. Save the request.
6. Monitor the request from the category list.

### Category Behavior

| Category | Request role behavior |
|---|---|
| Standard Delivery | Create requests; view existing request details. Existing status changes are view-only. |
| Hotline Direct | Create requests using the Standard Delivery form base; view existing request details. |
| Pull Out / Return | Create requests; view existing request details. Status actions are handled by Courier. |
| Pick Up | Create requests; view existing request details. Status actions are handled by Release. |
| Air / Sea | Create requests; view existing request details. Status actions are handled by Release, Courier, or Provincial. |
| Stock Receive | Create requests; can move a New Request to In Transit when the Stock Receive action is available. |

### Notes

- If the add button is missing, confirm that the user role includes `Request`.
- If a request opens without action buttons, the current status is handled by another role.

## Release Role

The Release role is for users who prepare, pack, receive, or hand off requests.

### Standard Delivery

| Current status | Release action |
|---|---|
| New Request | Mark as Getting supplies ready. |
| Getting supplies ready | Mark as Item Prepared if the current user is the assigned preparer. |
| Item Prepared, For Delivery, Delivered | View-only unless the user also has Courier capability. |

Before marking Standard Delivery as Item Prepared, the app requires delivery preparation details such as trip ticket, driver, and vehicle.

### Hotline Direct

Hotline Direct follows the same Release behavior as Standard Delivery:

- New Request to Getting supplies ready.
- Getting supplies ready to Item Prepared if assigned as the preparer.
- Later delivery-stage statuses are handled by Courier.

### Pick Up

| Current status | Release action |
|---|---|
| New Request | Move to Getting supplies ready. |
| Getting supplies ready | Move to Item Packed. |
| Item Packed | Move to Received. |
| Received or Cancelled | View-only. |

Pick Up proof or receiver fields may appear during the final receiving step when required by the screen.

### Air / Sea

| Current status | Release action |
|---|---|
| New Request | Mark Preparing. |
| Getting supplies ready | Mark Item Packed. |
| Item Packed | Proceed to the selected next status. |
| Endorsed to Guard | Mark Received. |
| Provincial or delivery-complete statuses | View-only unless the user also has the matching role. |

When Item Packed is processed, the next step is selected inside the Air / Sea screen:

- Endorsed to Guard: requires guard name and guard signature.
- Received: requires receiver name, waybill number, and receiver signature.
- For Dispatch: requires trip ticket, driver, helper, and vehicle.

### Stock Receive

| Current status | Release action |
|---|---|
| New Request | Move to In Transit. |
| In Transit | Move to Taken Out. |
| Picked-up or Cancelled | View-only. |

### Pull Out / Return

Pull Out / Return is view-only for Release. Courier handles the action stages.

## Courier Role

The Courier role is for transport, dispatch, delivery, pull-out, and proof workflows.

### Standard Delivery

| Current status | Courier action |
|---|---|
| New Request or Getting supplies ready | View-only. |
| Item Prepared | Open the Request Transport workflow. |
| For Delivery | Open the Request Transport workflow. |
| Delivered or Cancelled | View-only. |

The Request Transport workflow is where delivery-stage details, location-related actions, receiver information, signature, and proof image workflows are handled. Depending on the request, the user may need to be assigned as driver or helper.

### Hotline Direct

Hotline Direct follows the same Courier behavior as Standard Delivery:

- Item Prepared opens Request Transport.
- For Delivery opens Request Transport.
- Earlier preparation stages are view-only for Courier.

### Pull Out / Return

| Current status | Courier action |
|---|---|
| New Request | Set In Transit. |
| In Transit | Mark Taken Out. |
| Taken Out, Picked-up, or Cancelled | View-only. |

Setting Pull Out / Return to In Transit requires trip ticket, driver, and vehicle information.

### Air / Sea

| Current status | Courier action |
|---|---|
| For Dispatch | Dispatch. |
| Dispatch | Mark Drop Off. |
| Other statuses | View-only unless another assigned role applies. |

### Pick Up and Stock Receive

Pick Up and Stock Receive are view-only for Courier in the current workflow.

## Provincial Role

The Provincial role applies to Air / Sea provincial-leg processing.

| Current Air / Sea status | Provincial action |
|---|---|
| Received or Drop Off | Confirm Pick Up. |
| Provincial Pick Up | Start Transit. |
| Provincial In Transit | Confirm Delivery. |
| Provincial Delivered or Cancelled | View-only. |

Required proof and validation:

- Confirm Pick Up requires a pickup proof image.
- Start Transit requires a latest realtime location sample.
- Confirm Delivery requires recipient/client contact person, recipient signature, and delivery proof image.

If Start Transit fails because no realtime location is available, enable Realtime Location Saver in Settings and wait for the app to capture a location update.

## Viewer Role

The Viewer role is read-only.

Viewer users can:

- Open Logistics request lists.
- View request cards and details.
- Use filters.
- Pull to refresh lists.
- Review status, client, document reference, delivery, and proof information where visible.

Viewer users cannot:

- Create new requests.
- Move requests to another status.
- Capture new proof as part of a status transition.
- Open action-only transport or receiving steps.

## Admin Role

The Admin role is for operations support, not a universal request-lifecycle actor in the current Logistics screens.

Admin/support users typically use Settings tools:

- Upload Data.
- Hard Reset Refresh.
- Realtime Location Saver.
- Contact Directory.
- Local Storage Viewer.
- Signature Outbox.
- Image Outbox.

If an Admin user must perform a request status action, confirm that the account also has the required lifecycle role, such as Request, Release, Courier, or Provincial.

## BackLoad Access

BackLoad is connected to Standard Delivery and Hotline Direct request contexts. It is not a separate role-owned request category.

Use BackLoad when:

- A Standard Delivery or Hotline Direct request requires backload handling.
- The request is not Delivered, Cancelled, or already in Back Load status.
- Operations has instructed the user to record or review backload details.

BackLoad reprocessing returns the request to New Request when the reprocess action succeeds.

## Cancellation Remarks

Several Logistics lists support long-press cancellation remarks when a request is not already terminal.

General rules:

- Do not cancel a request without a clear operational reason.
- Enter remarks that explain why the request is cancelled.
- Terminal statuses such as Delivered, Received, Picked-up, Provincial Delivered, Back Load, or Cancelled are typically view-only for cancellation.

## Multi-Role Users

Some users may have multiple roles, for example `Request, Release` or `Release, Courier`.

The app generally chooses the active role by request status:

- Preparation statuses prefer Release.
- Delivery/transport statuses prefer Courier.
- Air / Sea provincial statuses prefer Provincial.
- If no assigned role can act, the request opens as view-only.

If the expected action does not appear:

1. Confirm the request category.
2. Confirm the current request status.
3. Confirm the user's role string.
4. Refresh the list.
5. Ask an operations admin to verify account role setup.

## Quick Reference Matrix

| Category | Request | Release | Courier | Provincial | Viewer/Admin |
|---|---|---|---|---|---|
| Standard Delivery | Create, view | Prepare and mark item prepared | Transport/delivery workflow | Not used | View/support |
| Hotline Direct | Create, view | Prepare and mark item prepared | Transport/delivery workflow | Not used | View/support |
| Pull Out / Return | Create, view | View | Set In Transit, Mark Taken Out | Not used | View/support |
| Pick Up | Create, view | Getting supplies ready, Item Packed, Received | View | Not used | View/support |
| Air / Sea | Create, view | Preparing, item packed, guard/received/dispatch handoff | Dispatch, Drop Off | Provincial pickup/transit/delivery | View/support |
| Stock Receive | Create, New Request to In Transit | New Request/In Transit progression | View | Not used | View/support |
| BackLoad | Context-based | Context-based | Context-based | Not used | Support/review |

## Troubleshooting by Role

| Problem | Likely cause | What to do |
|---|---|---|
| Add button is missing | User does not have Request role. | Ask support to verify the role assignment. |
| Request opens but no action button appears | Current role cannot act on that status. | Check the category/status matrix. |
| Courier cannot continue delivery | User may not be assigned as driver/helper or required delivery details are missing. | Verify assignment and required fields. |
| Release cannot mark item prepared | Another user may be the preparer or required delivery prep fields are missing. | Confirm preparer, trip ticket, driver, and vehicle. |
| Air / Sea cannot proceed from Item Packed | Required next-status fields are missing. | Complete guard, receiver, waybill, dispatch, driver, helper, or vehicle fields as prompted. |
| Provincial cannot start transit | No realtime location sample is saved. | Enable Realtime Location Saver and wait for location update. |
| Proof is missing after completion | Upload may be pending or failed. | Ask operations admin to check Signature Outbox or Image Outbox. |
