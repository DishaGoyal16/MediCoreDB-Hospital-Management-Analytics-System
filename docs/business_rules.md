# Business Rules

## Hospital Management System — Enforced Constraints

---

### Patient Rules
1. A patient must belong to exactly one branch (registration branch).
2. A patient may have at most one active insurance policy linked.
3. Each patient must have at least one emergency contact.
4. Patients are never hard-deleted — only marked `is_active = FALSE`.
5. Aadhaar number (if provided) must be unique across the system.

### Doctor Rules
6. A doctor belongs to exactly one department and one branch.
7. A doctor may have multiple specializations; exactly one must be primary.
8. A doctor on approved leave cannot be booked for appointments (enforced by trigger).
9. A doctor cannot be double-booked at the same date and time (enforced by trigger).
10. Department head must be an active, full-time doctor in that department.

### Appointment Rules
11. An appointment must have a valid patient, doctor, department, and branch.
12. Appointment time must fall within the doctor's scheduled hours for that day.
13. A cancelled or completed appointment cannot be cancelled again.
14. Maximum daily appointments per doctor is set in `doctor_schedules.max_appointments`.

### Admission Rules
15. A patient can only be admitted to an 'Available' bed (trigger enforced).
16. One patient = one active admission at a time per branch.
17. The admitting doctor must be active and in-house.
18. Bed status transitions: Available → Occupied (on admission), Occupied → Available (on discharge).

### Discharge Rules
19. A discharge record can only be created for an 'Active' admission.
20. Discharge triggers automatic bill generation.
21. Discharge date must be ≥ admission date (enforced in procedure).
22. Discharge type 'AMA' (Against Medical Advice) still generates a bill.

### Billing Rules
23. Bills are auto-generated on discharge (via trigger) for inpatients.
24. OPD bills are created manually or via appointment completion.
25. `total_amount` is a generated column — never manually updated.
26. Insurance coverage cannot exceed `insurance.coverage_amount`.
27. Payment amount cannot exceed the remaining balance on a bill.

### Medicine / Inventory Rules
28. Stock is deducted automatically when a prescription is inserted (trigger).
29. If stock is insufficient, the prescription INSERT fails (exception raised).
30. FIFO stock deduction: oldest non-expired batch is consumed first.
31. Expired medicine inventory is flagged but not auto-deleted.
32. Reorder level breach triggers an alert (visible via `vw_medicine_inventory`).

### Financial Rules
33. Payment_status transitions: Pending → Partial → Paid (one-way).
34. A bill marked 'Waived' cannot accept further payments.
35. Insurance-covered bills are split: insurance pays first, patient covers remainder.

### Audit Rules
36. All INSERT/UPDATE/DELETE on `billing` and `patients` are logged to `audit_logs`.
37. Inventory movements are fully tracked in `inventory_logs` with before/after quantities.
38. User who made the change is captured via `CURRENT_USER`.
