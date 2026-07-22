# ER Diagram — Schema Description

## Hospital Management Database System

---

## Entity Groups and Relationships

### Group 1: Organization Hierarchy
```
hospital_branches (1) ──────────────────< departments (M)
hospital_branches (1) ──────────────────< doctors (M)
hospital_branches (1) ──────────────────< staff (M)
hospital_branches (1) ──────────────────< nurses (M)
hospital_branches (1) ──────────────────< patients (M)
hospital_branches (1) ──────────────────< rooms (M)
departments (1) ─────────────────────── head_doctor_id ──> doctors (self-ref FK)
```

### Group 2: Clinical Staff
```
doctors (M) ─────────< doctor_specializations >───── specializations (M)
doctors (1) ──────────────────────────────────────< doctor_schedules (M)
doctors (1) ──────────────────────────────────────< leaves (M)
departments (1) ────────────────────────────────── doctors (M)
departments (1) ────────────────────────────────── nurses (M)
```

### Group 3: Patient Management
```
patients (1) ────────────────────────< emergency_contacts (M)
patients (1) ─────────────────────── insurance (1) [optional]
patients (1) ────────────────────────< medical_records (M)
patients (1) ────────────────────────< appointments (M)
patients (1) ────────────────────────< admissions (M)
patients (1) ────────────────────────< billing (M)
patients (1) ────────────────────────< prescriptions (M)
patients (1) ────────────────────────< lab_reports (M)
```

### Group 4: Appointment Flow
```
appointments ─── patient_id ──> patients
appointments ─── doctor_id  ──> doctors
appointments ─── dept_id    ──> departments
appointments ─── branch_id  ──> hospital_branches
appointments (1) ─────────────────────────────────< billing (1:0..1)
appointments (1) ─────────────────────────────────< prescriptions (M)
appointments (1) ─────────────────────────────────< lab_reports (M)
```

### Group 5: Inpatient Flow
```
admissions ──── patient_id  ──> patients
admissions ──── doctor_id   ──> doctors
admissions ──── branch_id   ──> hospital_branches
admissions ──── bed_id      ──> beds
admissions (1) ─────────────────────────────────< discharges (1)
admissions (1) ─────────────────────────────────< bed_allocations (M)
admissions (1) ─────────────────────────────────< treatments (M)
admissions (1) ─────────────────────────────────< lab_reports (M)
admissions (1) ─────────────────────────────────< prescriptions (M)
admissions (1) ─────────────────────────────────< billing (1)
discharges ──── (triggers) ──────────────────── billing (auto-generated)
```

### Group 6: Facility
```
rooms ──── room_id  ──> beds (M)
rooms ──── dept_id  ──> departments
rooms ──── branch_id ──> hospital_branches
beds  ──── bed_id   ──> admissions (currently occupied by)
beds  ──── bed_id   ──> bed_allocations (history)
```

### Group 7: Pharmacy
```
medicines (M) ─────< medicine_inventory (branch/batch) >── hospital_branches (M)
medicine_inventory ─── supplier_id ──> suppliers
prescriptions ──── medicine_id ──> medicines
prescriptions ──── triggers deduct medicine_inventory
inventory_logs ─── tracks all medicine_inventory changes
```

### Group 8: Finance
```
billing (1) ────< payments (M)
billing ────── insurance_id ──> insurance [optional]
payments ────── received_by ──> staff [optional]
```

### Group 9: Audit
```
audit_logs ─── triggered by INSERT/UPDATE/DELETE on billing, patients
inventory_logs ─── triggered by INSERT/UPDATE on medicine_inventory,
                    and AFTER INSERT on prescriptions
```

---

## Cardinality Summary

| Relationship | Type | Notes |
|---|---|---|
| branch → departments | 1:M | Each branch has 4+ departments |
| branch → doctors | 1:M | Doctors belong to one branch |
| dept → doctors | 1:M | Multiple doctors per dept |
| doctor → specializations | M:N | Via doctor_specializations junction |
| doctor → schedules | 1:M | Multiple day/time slots |
| patient → appointments | 1:M | Patient can book many appointments |
| patient → admissions | 1:M | Patient can be admitted multiple times |
| patient → insurance | 1:0..1 | Optional single insurance |
| admission → discharge | 1:0..1 | One discharge per admission |
| admission → bed | M:1 | One bed per active admission |
| bed → allocations | 1:M | Full history of occupants |
| billing → payments | 1:M | Bill can be paid in installments |
| medicine → inventory | 1:M | Multiple batches per medicine |

---

## Key Attributes per Entity

### patients
`patient_id PK`, `branch_id FK`, `first_name`, `last_name`, `gender`, `date_of_birth`, `blood_group`, `phone UNIQUE`, `email`, `aadhar_number UNIQUE`, `insurance_id FK`, `registration_date`, `is_active`
**Generated:** `full_name`, `age`

### doctors
`doctor_id PK`, `branch_id FK`, `dept_id FK`, `first_name`, `last_name`, `gender`, `date_of_birth`, `phone UNIQUE`, `email UNIQUE`, `registration_number UNIQUE`, `qualification`, `experience_years`, `consultation_fee`, `employment_type`, `is_active`
**Generated:** `full_name`

### appointments
`appointment_id PK`, `branch_id FK`, `patient_id FK`, `doctor_id FK`, `dept_id FK`, `appointment_date`, `appointment_time`, `appointment_type`, `status`

### billing
`bill_id PK`, `patient_id FK`, `admission_id FK`, `appointment_id FK`, `branch_id FK`, `bill_date`, `consultation_charge`, `room_charge`, `medicine_charge`, `lab_charge`, `treatment_charge`, `other_charge`, `discount_pct`, `tax_pct`, `insurance_id FK`, `insurance_covered`, `payment_status`
**Generated:** `subtotal`, `discount_amount`, `tax_amount`, `total_amount`

### medicine_inventory
`inventory_id PK`, `medicine_id FK`, `branch_id FK`, `supplier_id FK`, `batch_number`, `quantity`, `reorder_level`, `expiry_date`, `purchase_price`
**Unique:** `(medicine_id, branch_id, batch_number)`
