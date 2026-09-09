# Logistics Role-Based User Manual

MDMPI Mobile App | Logistics Department | User Manual by Role

**Purpose:** Use this guide to identify what each Logistics role can create, view, update, deliver, or support across request categories.

This manual explains what Logistics users can do in the MDMPI Mobile App based on their assigned role. It is for the Logistics Department only.

## Manual map

| Section | Use it for |
|---|---|
| Role Basics | Understand role selection, multi-role behavior, and common navigation. |
| Request / Release / Courier / Provincial | Follow role-specific tasks and status actions. |
| Viewer / Admin | Confirm read-only and support-tool expectations. |
| Quick Reference Matrix | Compare categories and role capabilities at a glance. |
| Troubleshooting by Role | Resolve common missing-action and proof issues. |

## Role Basics

Logistics users may have one role or multiple comma-separated roles. When a user has multiple roles, the app chooses the role with the action capability for the selected request status. If no assigned role can act on that status, the request opens as view-only.

Core Logistics roles:

| Role | Primary purpose |
|---|---|
| Request | Create Logistics requests and monitor submitted requests. |
| Release | Prepare, pack, receive, and hand off requests depending on category. |
| Courier | Handle dispatch, transport, delivery, pull-out, and proof workflows. |
| Provincial | Handle the provincial leg of Air / Sea / Land requests. |
| HD | Create requests on the Air / Sea / Land HD tab. |
| Viewer | View requests without status-changing actions. |
| Admin | Support operations through Settings/admin tools; not a universal status-action override. |

## Common Navigation

1. Sign in with a Logistics account.
2. Complete Logistics onboarding if prompted.
3. Open the Request tab.
4. Select a request category.
5. Tap a request card to view details or perform available role actions.
6. Use filters to narrow the list by date, status, client, item category, or document reference.

The add button appears for users whose role includes `Request`. Two exceptions: Couriers also get it on the **Hotline Direct** tab, and creating on the **Air / Sea / Land HD** tab requires the `HD` role.

## Role Summary

| Role | Can create requests | Can update request statuses | Can use delivery/proof screens | Typical access |
|---|---:|---:|---:|---|
| Request | Yes | Limited by category | No | Create and monitor |
| Release | No | Yes, preparation/receiving stages | Some proof fields by category | Internal processing |
| Courier | No | Yes, delivery/transport stages | Yes | Dispatch, transit, delivery, pull-out |
| Provincial | No | Air / Sea / Land provincial stages | Yes | Provincial pickup/transit/delivery |
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
| Pull Out / Return | Create requests; view existing request details. Status actions are handled by Release, then Courier. |
| Pick Up | Create requests; view existing request details. Status actions are handled by Release. |
| Air / Sea / Land | Create requests; view existing request details. Status actions are handled by Release, Courier, or Provincial. |
| Air / Sea / Land HD | Same workflow and roles as Air / Sea / Land. Creating on this tab requires the `HD` role. |
| Stock Receive | Create requests; view existing request details. Status actions are handled by Release, then Courier. |

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

### Air / Sea / Land

| Current status | Release action |
|---|---|
| New Request | Mark as Getting supplies ready. |
| Getting supplies ready | Mark Item Packed. |
| Item Packed | Proceed to the selected next status. |
| Endorsed to Guard | Mark Received. |
| Provincial or delivery-complete statuses | View-only unless the user also has the matching role. |

When Item Packed is processed, the next step is selected inside the Air / Sea / Land screen:

- Endorsed to Guard: requires guard name and guard signature.
- Received: requires receiver name, waybill number, and receiver signature.
- For Dispatch: requires trip ticket, driver, helper, and vehicle.

### Stock Receive

| Current status | Release action |
|---|---|
| New Request | Move to In Transit. |
| In Transit | View-only — Courier marks Taken Out. |
| Taken Out or Cancelled | View-only. |

### Pull Out / Return

| Current status | Release action |
|---|---|
| New Request | Set For Pull Out. |
| For Pull Out, In Transit, Taken Out | View-only — Courier handles these. |

Setting a Pull Out / Return request to For Pull Out is where the transport details are
entered: trip ticket, driver, helper and vehicle. This step belongs to Release, not
Courier.

## Courier Role

The Courier role is for transport, dispatch, delivery, pull-out, and proof workflows.

### Standard Delivery

| Current status | Courier action |
|---|---|
| New Request or Getting supplies ready | View-only. |
| Item Prepared | Open the Request Transport workflow. |
| For Delivery | Open the Request Transport workflow. |
| Delivered or Cancelled | View-only. |

The Request Transport workflow is where delivery-stage details, location-related actions, receiver information, signature, and proof photo workflows are handled (up to three proof-of-delivery photos). Depending on the request, the user may need to be assigned as driver or helper.

### Hotline Direct

Hotline Direct follows the same Courier behavior as Standard Delivery:

- Item Prepared opens Request Transport.
- For Delivery opens Request Transport.
- A Courier who **created** the Hotline Direct request can also act on it at New Request.
  Otherwise earlier preparation stages are view-only for Courier.

### Pull Out / Return

| Current status | Courier action |
|---|---|
| New Request | View-only — Release sets For Pull Out first. |
| For Pull Out | Set In Transit (depart). |
| In Transit | Mark Taken Out, or **Pause (Back to For Pull Out)**. |
| Taken Out or Cancelled | View-only. |

Transport details (trip ticket, driver, helper, vehicle) are entered by **Release** at the
For Pull Out step, not by Courier.

Pausing returns the request to For Pull Out and clears the start time; departing again
records a fresh one.

While In Transit the courier can also record **lost items** — items that were not pulled
out — with a required reason for each. These are saved before the Taken Out transition; if
that save fails, the transition is cancelled and the entries are kept.

### Air / Sea / Land

| Current status | Courier action |
|---|---|
| For Dispatch | Dispatch. |
| Dispatch | Mark Drop Off. |
| Other statuses | View-only unless another assigned role applies. |

### Pick Up and Stock Receive

Pick Up and Stock Receive are view-only for Courier in the current workflow.

## Provincial Role

The Provincial role applies to Air / Sea / Land provincial-leg processing.

| Current Air / Sea / Land status | Provincial action |
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
- Air / Sea / Land provincial statuses prefer Provincial.
- If no assigned role can act, the request opens as view-only.

If the expected action does not appear:

1. Confirm the request category.
2. Confirm the current request status.
3. Confirm the user's role string.
4. Refresh the list.
5. Ask an operations admin to verify account role setup.

## What changed in v1.1.102

Behavior that is live in the app but was not covered by earlier versions of this manual.

**Text message on For Delivery.** When a Standard Delivery or Hotline Direct request moves
to For Delivery, the app sends an SMS to the request contacts, including all document
references. While it sends you see per-recipient progress; when every recipient has been
reached a full-screen "Message Sent!" confirmation appears and dismisses itself. Nothing is
required from the user — this replaces the old per-recipient popup on the request card.

**Backloading individual items at For Delivery.** On the Request Transport screen there is
now an "Items to Deliver" checklist above Proof of Delivery. Untick any item the client will
not receive and give a reason for each; Drop Off stays blocked until every unticked item has
one. Completed requests show a read-only "Backloaded Items" list. This is separate from the
whole-request BackLoad flow (long-press → BackLoad → Reprocess), which is unchanged and is
still the right tool when the entire request comes back.

**Document references open in their own screen.** Forms now show an "Add Document Reference
(n)" button instead of inline fields. The same validation applies when you save the form.
Document references are **optional for Stock Receive** and remain mandatory for Pull Out and
Return.

**Up to three proof-of-delivery photos** can be captured instead of one.

**Pick Up requests accept multiple item categories** — the item category field is now a
multi-select.

**Recipient name and contact details are optional** on the Standard Delivery form.

**Pausing a pull-out.** A courier who is In Transit on a Pull Out / Return can pause back to
For Pull Out; see the Courier role section.

## Quick Reference Matrix

| Category | Request | Release | Courier | Provincial | Viewer/Admin |
|---|---|---|---|---|---|
| Standard Delivery | Create, view | Prepare and mark item prepared | Transport/delivery workflow | Not used | View/support |
| Hotline Direct | Create, view (Courier may also create) | Prepare and mark item prepared | Transport/delivery workflow | Not used | View/support |
| Pull Out / Return | Create, view | Set For Pull Out (enters transport details) | Set In Transit, Pause, Mark Taken Out, record lost items | Not used | View/support |
| Pick Up | Create, view | Getting supplies ready, Item Packed, Received | View | Not used | View/support |
| Air / Sea / Land | Create, view | Getting supplies ready, item packed, guard/received/dispatch handoff | Dispatch, Drop Off | Provincial pickup/transit/delivery | View/support |
| Air / Sea / Land HD | Create (needs `HD` role), view | Same as Air / Sea / Land | Same as Air / Sea / Land | Same as Air / Sea / Land | View/support |
| Stock Receive | Create, view | New Request to In Transit | In Transit to Taken Out | Not used | View/support |
| BackLoad | Context-based | Context-based | Context-based | Not used | Support/review |

## Troubleshooting by Role

| Problem | Likely cause | What to do |
|---|---|---|
| Add button is missing | User does not have Request role. | Ask support to verify the role assignment. |
| Request opens but no action button appears | Current role cannot act on that status. | Check the category/status matrix. |
| Courier cannot continue delivery | User may not be assigned as driver/helper or required delivery details are missing. | Verify assignment and required fields. |
| Release cannot mark item prepared | Another user may be the preparer or required delivery prep fields are missing. | Confirm preparer, trip ticket, driver, and vehicle. |
| Air / Sea / Land cannot proceed from Item Packed | Required next-status fields are missing. | Complete guard, receiver, waybill, dispatch, driver, helper, or vehicle fields as prompted. |
| Provincial cannot start transit | No realtime location sample is saved. | Enable Realtime Location Saver and wait for location update. |
| Proof is missing after completion | Upload may be pending or failed. | Ask operations admin to check Signature Outbox or Image Outbox. |
