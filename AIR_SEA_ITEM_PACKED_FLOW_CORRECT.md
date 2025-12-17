# Air/Sea Item Packed Flow - CORRECTED

## Correct Flow Understanding

### **Air/Sea Request Status Flow:**

1. **New Request** → (User creates request)
2. **Getting Supplies Ready** → (Preparing items)
3. **Item Packed** → **DECISION POINT:**
   - **Option A: "Endorsed to Guard"** (Courier is late, guard holds item)
   - **Option B: "Received"** (Courier arrives on time, picks up directly)
4. **Endorsed to Guard** → (Later) **Received** (When courier finally arrives, guard gives item with waybill number)

---

## Implementation

### **Widget** (`air_sea_item_packed_section.dart`)

**Dropdown Options:**
- ✅ "Endorsed to Guard"
- ✅ "Received"

**Conditional Fields:**

#### When "Endorsed to Guard" is selected:
- **Guard Name** field (using `waybillNumberController`)
- **Guard Signature** capture (using `receiverSignatureBytes`)
- Status updates to: `BTexts.statusEndorsedToGuard`
- Saves: `endorsedBy` = guard name

#### When "Received" is selected:
- **Receiver Name** field (using `waybillNumberController`)
- **Receiver Signature** capture (using `receiverSignatureBytes`)
- Status updates to: `BTexts.statusReceived`
- Saves: `receivedBy` = receiver name

---

### **Role Handler** (`air_sea_role_handler.dart`)

```dart
} else if (request.status == BTexts.statusItemPacked) {
  // Show modal with dropdown: Endorsed to Guard OR Received
  BFullScreenLoader.showAirSeaDialog(context, request, () async {
    final selectedStatus = controller.formState.endorsedToController.text;
    
    if (selectedStatus == 'Endorsed to Guard') {
      await controller.updateStatusWithInputs(request, BTexts.statusEndorsedToGuard);
    } else if (selectedStatus == 'Received') {
      await controller.updateStatusWithInputs(request, BTexts.statusReceived);
    }
  }, true);
```

---

### **Data Manager** (`air_sea_data_manager.dart`)

**Field Population:**
```dart
endorsedBy: newStatus == BTexts.statusEndorsedToGuard &&
        formState.waybillNumberController.text.isNotEmpty
    ? formState.waybillNumberController.text
    : request.endorsedBy,
    
receivedBy: newStatus == BTexts.statusReceived &&
        formState.waybillNumberController.text.isNotEmpty
    ? formState.waybillNumberController.text
    : (request.receivedBy.isEmpty ? userInitial : request.receivedBy),
```

**Signature Upload:**
```dart
final bool signatureWasAdded = 
    (newStatus == BTexts.statusEndorsedToGuard || newStatus == BTexts.statusReceived) &&
    formState.receiverSignatureBase64.value.isNotEmpty;
```

Both statuses upload signature with type = 'Signature'.

---

## Real-World Scenarios

### **Scenario A: Courier Arrives On Time**
1. Items are packed (status: "Item Packed")
2. Courier arrives immediately
3. Staff selects: **"Received"**
4. Enters courier name + captures signature
5. Status → **"Received"** ✅ (COMPLETE)

### **Scenario B: Courier is Late**
1. Items are packed (status: "Item Packed")
2. Courier doesn't arrive, end of day approaching
3. Staff selects: **"Endorsed to Guard"**
4. Enters guard name + captures guard signature
5. Status → **"Endorsed to Guard"** ✅
6. **Next day:** Courier arrives with waybill
7. Guard gives item to courier (guard doesn't have app)
8. **Later:** Staff manually updates in app:
   - Opens request (status: "Endorsed to Guard")
   - Updates to "Received" with waybill number
   - Status → **"Received"** ✅ (COMPLETE)

---

## Why Both Options Are Needed

### **"Endorsed to Guard"**
- Courier schedule is uncertain
- Need to secure items at end of business day
- Guard takes responsibility for holding items
- Creates audit trail with guard signature

### **"Received"**
- Courier arrives as scheduled
- Direct handoff possible
- Skip intermediate guard step
- Faster process completion

---

## Key Fields

| Field | Used For | Controller | Populated When |
|-------|----------|------------|----------------|
| `endorsedBy` | Guard name | `waybillNumberController` | Status = "Endorsed to Guard" |
| `receivedBy` | Receiver name | `waybillNumberController` | Status = "Received" |
| `receiverSignatureBytes` | Signature (both) | `formState` | Both statuses |
| `waybillNumber` | Tracking number | `waybillNumberController` | (Future: when transitioning from Endorsed → Received) |

**Note:** `waybillNumberController` is repurposed:
- For "Item Packed" → "Endorsed to Guard": Stores **guard name**
- For "Item Packed" → "Received": Stores **receiver name**
- For "Endorsed to Guard" → "Received": Can store **waybill number** (future enhancement)

---

## Status

✅ **COMPLETE** - Flow correctly implements the two-path decision from "Item Packed":
- Direct to "Received" (courier on time)
- Via "Endorsed to Guard" then "Received" (courier late)

