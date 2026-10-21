# Department-aware "Create your account"

Status: **Implemented** (2026-10-14)

Department is the first choice on the sign-up screen, and the rest of the form follows
it. The change only adds: every earlier field is still there with the same validation and
is saved to the Firestore `Users` doc under the same key.

## Form order

1. **Department** (moved to the top)
2. First name / Last name
3. Username
4. Email
5. Initial
6. Role: only the selected department's roles. Until a department is picked it shows
   "Select a department first", and tapping it shows a warning.
7. *Collection only:* **My Head (optional)**
8. Mobile Number
9. Password
10. Privacy Policy + Create Account

## Per department

| Department | Extra fields | Roles offered (untagged defaults) |
|---|---|---|
| Logistics | none | every role except the `Collection*` ones |
| Collection | My Head → `HeadKey` / `HeadName` | every role, including `CollectionPoster`, `CollectionHead` |
| Service | none | every role except the `Collection*` ones |
| InHouse | none | every role except the `Collection*` ones |

Collection users get the Logistics roles as well, because real Collection accounts hold
them too (e.g. `Request, Release, Courier, HD, CollectionPoster, CollectionHead`).

A Collection sign-up writes the same fields Settings → My Head writes:

```
Department: "Collection"
HeadKey:    "GSC"
HeadName:   "Gemalee S Chua"
Role:       "Request, Release, Courier, HD, CollectionPoster, CollectionHead"
```

Other departments save `HeadKey` / `HeadName` as `''`.

## Role → department mapping

`RoleModel.appliesTo(department)` (`lib/data/models/role_model.dart`):

- If the `Roles` doc has a `Departments` field (an array, or a comma-separated string),
  the role is offered only to those departments. The match ignores case and spaces.
- With no `Departments` field: a role whose name starts with `Collection` is offered to
  Collection only. Every other role is offered to every department.
- With no department picked, no roles are offered.

To change the mapping without an app release, add `Departments` to a `Roles` doc in the
Firestore console. For example, `Departments: ["Logistics"]` on `Courier` hides it from
Collection.

## Behaviour

- Changing the department clears the chosen roles, so a role from another department
  can't be submitted. Leaving Collection also clears the Head. Picking the same
  department again keeps the choices.
- The Head picker reads `UserDirectoryRepository` (CNTMST + Firestore `Users`). Before
  the first login the directory is often empty, because masters aren't downloaded yet.
  In that case the sheet tells the user to set the Head later in Settings > My Head. The
  Head never blocks sign-up.

## Code

- `lib/data/models/role_model.dart`: `departments`, `appliesTo`, `parseDepartments`
- `lib/features/authentication/presentation/controllers/signup_controller.dart`:
  `selectedDepartment`, `filteredRoles`, `onDepartmentChanged`, the Head state and
  directory, and `HeadKey` / `HeadName` in `signup()`
- `lib/features/authentication/presentation/pages/signup/widgets/signup_form.dart`:
  the order and the `_departmentFields` switch
- `.../signup/widgets/department_fields/collection_signup_fields.dart`: the Head picker
- `lib/common/widgets/dropdown/dropdown.dart`: optional `onChanged` (other callers are
  unchanged)
- `lib/base/utils/popups/full_screen_loader.dart`: the role checklist lists
  `filteredRoles`

To add fields for another department, add a widget under `department_fields/` and a
case in `SignUpForm._departmentFields`.

## Tests

- `test/data/models/role_model_test.dart`
- `test/features/authentication/signup_controller_test.dart`
- `test/features/authentication/signup_form_test.dart`: every original field is still
  shown for each department, and only Collection shows the Head
