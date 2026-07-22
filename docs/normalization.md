# Normalization Documentation

## Hospital Management Database — 1NF → 3NF Walkthrough

---

## First Normal Form (1NF)

**Rules:** Atomic values, no repeating groups, each row uniquely identifiable.

### Problem (Pre-1NF design):
```
patient_table:
patient_id | name         | phones              | diagnoses
1          | Rahul Sharma | 9000100001,98001... | Diabetes, HTN, Migraine
```

### 1NF Fix:
- Split `phones` → one phone per row (or separate `emergency_contacts` table)
- Split `diagnoses` → separate `medical_records` table with one diagnosis per record
- Added `patient_id` as PK

---

## Second Normal Form (2NF)

**Rules:** Must be in 1NF + No partial dependencies (every non-key column fully depends on the whole PK).

### Problem: Composite key with partial dependency
```
appointment_treatments:
(appointment_id, treatment_id) → PRIMARY KEY
appointment_date               → depends only on appointment_id ← PARTIAL DEPENDENCY
treatment_name                 → depends only on treatment_id   ← PARTIAL DEPENDENCY
```

### 2NF Fix:
- Moved `appointment_date` → `appointments` table
- Moved `treatment_name`, `treatment_type`, `cost` → `treatments` table
- Junction only holds: `(admission_id, treatment_id)` relationship

---

## Third Normal Form (3NF)

**Rules:** Must be in 2NF + No transitive dependencies (non-key column depending on another non-key column).

### Problem: Transitive dependency in doctors
```
doctors_raw:
doctor_id | dept_id | dept_name | dept_phone | branch_id | branch_city
```
Here: `dept_name` depends on `dept_id` (not on `doctor_id`) — transitive via `dept_id`.
And: `branch_city` depends on `branch_id` — transitive via `branch_id`.

### 3NF Fix:
- `departments` table: `(dept_id PK, branch_id FK, dept_name, dept_code, floor_no)`
- `hospital_branches` table: `(branch_id PK, branch_name, city, state, ...)`
- `doctors` table: `(doctor_id PK, dept_id FK, branch_id FK, first_name, last_name, ...)`

---

## Boyce-Codd Normal Form (BCNF) — Achieved Where Applicable

### Doctor Specializations (many-to-many):
Without the junction table:
```
doctors: doctor_id → spec_id, spec_name  ← spec_name depends on spec_id, not doctor_id
```

Fix: `doctor_specializations(doctor_id FK, spec_id FK, is_primary)` + `specializations(spec_id PK, spec_name)`

---

## Normalization Decisions Table

| Table | Normal Form | Key Design Decision |
|-------|-------------|---------------------|
| `hospital_branches` | 3NF | Top-level entity, no transitive deps |
| `departments` | 3NF | Branch FK removes city/state transitive dep |
| `doctors` | 3NF | Dept FK + branch FK, generated `full_name` |
| `specializations` | 3NF | Separated from doctors (many-to-many) |
| `doctor_specializations` | BCNF | Pure junction table |
| `patients` | 3NF | Branch FK; insurance as separate table |
| `insurance` | 3NF | Provider details not duplicated per patient |
| `appointments` | 3NF | No treatment/billing data here |
| `billing` | 3NF | Generated columns for computed totals |
| `medicine_inventory` | 3NF | Batch-level tracking separates stock from medicine master |
| `bed_allocations` | 3NF | History table separates current status (beds) from history |
| `audit_logs` | 3NF | JSONB stores old/new data without schema coupling |

---

## Denormalization Exceptions (Intentional)

| Decision | Reason |
|----------|--------|
| `doctors.full_name` (generated column) | Avoids concatenation in every query; auto-synced |
| `patients.age` (generated from DOB) | Avoids date arithmetic in reporting queries |
| `billing.subtotal`, `total_amount` (generated) | Eliminates recomputation; enables direct indexing |
| `mvw_monthly_revenue` (materialized view) | Intentional read-model denormalization for analytics |
