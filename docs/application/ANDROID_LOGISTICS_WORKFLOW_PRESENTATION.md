# Android Logistics Workflow and User-Role Presentation

This document is the presentation and training workflow for Logistics users of
the MDMPI Android app. It follows the current implemented modal, controller,
and role-handler behavior when older module documentation differs.

## Presentation Goal

Prepare each Logistics user to:

- identify the current request status;
- understand which role owns the next action;
- complete only the action allowed for that role;
- verify required transport, location, receiver, signature, and proof data; and
- confirm that the new status is visible after submission.

Use demo accounts and non-production sample transactions during training.

## Presentation Structure

1. Android Logistics training title
2. Session objectives and workflow overview
3. Role guide: Request, Release, Courier, Provincial, Viewer, and Admin
4. Standard Delivery process
5. Standard Delivery responsibilities by role
6. Standard Delivery role-based demonstration
7. Pull Out / Return process
8. Pull Out / Return responsibilities by role
9. Pick Up process
10. Pick Up responsibilities by role
11. Air / Sea / Land preparation and dispatch process
12. Air / Sea / Land provincial delivery extension
13. Air / Sea / Land responsibilities by role
14. Hotline Direct process
15. Hotline Direct responsibilities by role
16. Proof, synchronization, and exception responsibilities
17. Role-based hands-on exercises
18. Readiness check, questions, and feedback

## User Roles

| Role | Primary responsibility |
|---|---|
| Request | Create new Logistics requests and monitor existing requests. |
| Release | Prepare, pack, release, or receive items where the workflow allows. |
| Courier | Dispatch, transport, track, pull out, and complete assigned delivery actions. |
| Provincial | Continue eligible Air / Sea / Land requests through the provincial delivery stages. |
| Viewer | Review requests without changing their status. |
| Admin | Support operations; normal request status actions remain view-only unless another lifecycle role is assigned. |

When a user has multiple roles, the current request status determines which
permitted role action appears.

## Standard Delivery Workflow

~~~mermaid
flowchart LR
    A["New Request"] -->|Release| B["Getting Supplies Ready"]
    B -->|Same Release user| C["Item Prepared"]
    C -->|Assigned Courier or helper| D["For Delivery"]
    D -->|Assigned Courier or helper| E["Delivered"]
~~~

### Responsibilities by Role

| Role | Responsibility |
|---|---|
| Request | Create the request and view existing transaction details. |
| Release | Move New Request to Getting Supplies Ready. The same preparer moves it to Item Prepared after entering the trip ticket, driver, and vehicle. |
| Courier | If assigned as driver or helper, dispatch the request, start tracking, capture the receiver, signature, and up to three proof photos, and complete drop-off. |
| Provincial | No Standard Delivery status action. |
| Viewer | View-only. |
| Admin | View-only for normal modal transitions. |

The current transport workflow moves directly from **Item Prepared** to
**For Delivery** and then **Delivered**. It does not expose a separate
**In Transit** action.

### Demonstration

1. Release opens a New Request and marks it Getting Supplies Ready.
2. The same Release user enters the trip ticket, driver, and vehicle.
3. Release marks the request Item Prepared.
4. The assigned Courier or helper verifies the route and dispatches it.
5. Tracking begins when the request becomes For Delivery.
6. Courier enters the receiver, captures the signature and up to three proof photos,
   unticks any items the client will not receive (with a reason each), and
   confirms Delivered.

## Pull Out / Return Workflow

~~~mermaid
flowchart LR
    A["New Request"] -->|Release enters transport details| B["For Pull Out"]
    B -->|Courier departs| C["In Transit"]
    C -->|Courier| D["Taken Out"]
    C -->|Courier pauses| B
~~~

### Responsibilities by Role

| Role | Responsibility |
|---|---|
| Request | Create the Pull Out / Return request and monitor its progress. |
| Release | Set the request For Pull Out, entering the trip ticket, driver, helper, and vehicle. |
| Courier | Depart (For Pull Out to In Transit), record any items that could not be pulled out, then mark Taken Out. May pause back to For Pull Out. |
| Provincial | No Pull Out / Return action. |
| Viewer | View-only. |
| Admin | View-only for normal modal transitions. |

Release captures the transport information at the **For Pull Out** step — the Courier
cannot depart until that is done. A courier who is interrupted mid-trip can pause the
request back to For Pull Out; the start time is cleared and re-recorded on the next
departure.

## Pick Up Workflow

~~~mermaid
flowchart LR
    A["New Request"] -->|Release| B["Getting Supplies Ready"]
    B -->|Release| C["Item Packed"]
    C -->|Release with receiver and proof| D["Received"]
~~~

### Responsibilities by Role

| Role | Responsibility |
|---|---|
| Request | Create the Pick Up request and monitor its progress. |
| Release | Perform every implemented transition from New Request through Received, including receiver and proof requirements. |
| Courier | View-only in the current Pick Up role handler. |
| Provincial | No Pick Up action. |
| Viewer | View-only. |
| Admin | View-only for normal modal transitions. |

Release must verify that **Received** is visible before leaving the transaction.

## Air / Sea / Land Workflow

The Release role first prepares and packs the shipment.

~~~mermaid
flowchart LR
    A["New Request"] -->|Release| B["Getting Supplies Ready"]
    B -->|Release| C["Item Packed"]
    C -->|Release: guard branch| D["Endorsed to Guard"]
    D -->|Release| E["Received"]
    C -->|Release: direct receipt| E
    C -->|Release: dispatch branch| F["For Dispatch"]
    F -->|Courier| G["Dispatch"]
    G -->|Courier| H["Drop Off"]
~~~

### Branch Requirements

| Branch after Item Packed | Required information |
|---|---|
| Endorsed to Guard | Guard name and guard signature. |
| Directly Received | Receiver name, waybill number, and receiver signature. |
| For Dispatch | Trip ticket, driver, helper, and vehicle. |

### Provincial Delivery Extension

An eligible request may continue from **Received** or **Drop Off**.

~~~mermaid
flowchart LR
    A["Received or Drop Off"] -->|Provincial + pickup image| B["Provincial Pick Up"]
    B -->|Provincial + latest location| C["Provincial In Transit"]
    C -->|Provincial + recipient, signature, and proof| D["Provincial Delivered"]
~~~

### Responsibilities by Role

| Role | Responsibility |
|---|---|
| Request | Create the Air / Sea / Land request and view its progress. |
| Release | Prepare and pack the shipment, then select Endorsed to Guard, Received, or For Dispatch. Release also completes guard receipt when applicable. |
| Courier | Move For Dispatch to Dispatch and then Drop Off. |
| Provincial | Move Received or Drop Off through Provincial Pick Up, Provincial In Transit, and Provincial Delivered. |
| Viewer | View-only. |
| Admin | View-only for normal modal transitions. |

## Hotline Direct Workflow

Hotline Direct uses the Standard Delivery model and transport pattern but
appears as a separate request category.

~~~mermaid
flowchart LR
    A["New Request"] -->|Release| B["Getting Supplies Ready"]
    B -->|Same Release user| C["Item Prepared"]
    C -->|Assigned Courier or helper| D["For Delivery"]
    D -->|Assigned Courier or helper| E["Delivered"]
~~~

### Responsibilities by Role

| Role | Responsibility |
|---|---|
| Request | Create Hotline Direct requests and view existing details. |
| Release | Move New Request through Item Prepared after entering the trip ticket, driver, and vehicle. |
| Courier | If assigned as driver or helper, dispatch, track, capture receiver/signature/proof, and complete drop-off. |
| Provincial | No Hotline Direct status action. |
| Viewer | View-only. |
| Admin | View-only for normal modal transitions. |

Verify the request category before acting because Standard Delivery and
Hotline Direct appear in separate lists.

## Proof, Synchronization, and Exceptions

### Proof

- Use the correct transaction.
- Complete every required receiver, signature, image, location, waybill, or
  transport field.
- Review the proof before saving.
- Never reuse proof from another transaction.

### Synchronization

- Wait for the save result.
- Confirm that the new status is visible.
- Keep the app open when the connection is unstable.
- Do not create duplicate updates while waiting.
- Record and report the exact error if submission fails.

### Exceptions

- Use only approved Cancel or Back Load reasons.
- Do not change a status merely to clear a task.
- Protect credentials and customer information.
- Report issues through the approved support process without including
  passwords or unnecessary customer data.

## Role-Based Hands-On Exercises

| Role | Demo exercise |
|---|---|
| Request | Create one sample request and verify it appears in the correct category. |
| Release | Prepare or pack the assigned demo transaction. |
| Courier | Perform one assigned dispatch, delivery, or Pull Out action. |
| Provincial | Validate one Air / Sea / Land provincial extension step. |
| Viewer | Explain the current status and identify the next responsible role. |
| Admin | Confirm that normal modal actions are view-only without an additional lifecycle role. |

## Readiness Checklist

A user is ready when they can:

- identify the correct request category;
- read the current transaction status;
- explain which role owns the next action;
- complete only their assigned status transition;
- enter all required transport or proof information;
- verify the visible result after saving;
- avoid duplicate actions during synchronization; and
- report a failed action safely and clearly.

## Scope

This training workflow is:

- for Logistics users only;
- for the Android app;
- based on safe demo data;
- aligned with the current implemented workflow; and
- separate from Collection, Service, InHouse, and Windows training.

## Related Documentation

- [Logistics Role-Based User Manual](LOGISTICS_ROLE_USER_MANUAL.md)
- [Logistics User Guide](USER_GUIDE.md)
- [Standard Delivery Module](../modules/standard-delivery/README.md)
- [Pull Out / Return Module](../modules/pull-out/README.md)
- [Pick Up Module](../modules/pick-up/README.md)
- [Air / Sea / Land Module](../modules/air-sea/README.md)
- [Hotline Direct Module](../modules/hotline-direct/README.md)
