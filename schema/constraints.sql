-- =============================================================================
-- FILE: schema/constraints.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: All foreign key, unique, and check constraints.
--              Run AFTER create_tables.sql.
-- =============================================================================

-- =============================================================================
-- FOREIGN KEYS: hospital_branches
-- =============================================================================
ALTER TABLE departments
    ADD CONSTRAINT fk_dept_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id)
    ON DELETE RESTRICT;

-- =============================================================================
-- FOREIGN KEYS: departments
-- =============================================================================
ALTER TABLE medicine_inventory
    ADD CONSTRAINT fk_inv_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE medicine_inventory
    ADD CONSTRAINT fk_inv_medicine
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
    ON DELETE RESTRICT;

ALTER TABLE medicine_inventory
    ADD CONSTRAINT fk_inv_supplier
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
    ON DELETE SET NULL;

-- =============================================================================
-- FOREIGN KEYS: rooms & beds
-- =============================================================================
ALTER TABLE rooms
    ADD CONSTRAINT fk_room_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE rooms
    ADD CONSTRAINT fk_room_dept
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id);

ALTER TABLE beds
    ADD CONSTRAINT fk_bed_room
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
    ON DELETE CASCADE;

-- =============================================================================
-- FOREIGN KEYS: doctors
-- =============================================================================
ALTER TABLE doctors
    ADD CONSTRAINT fk_doctor_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE doctors
    ADD CONSTRAINT fk_doctor_dept
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id);

ALTER TABLE doctor_specializations
    ADD CONSTRAINT fk_ds_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE;

ALTER TABLE doctor_specializations
    ADD CONSTRAINT fk_ds_spec
    FOREIGN KEY (spec_id) REFERENCES specializations(spec_id)
    ON DELETE CASCADE;

ALTER TABLE doctor_schedules
    ADD CONSTRAINT fk_sched_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE;

ALTER TABLE leaves
    ADD CONSTRAINT fk_leave_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE;

ALTER TABLE leaves
    ADD CONSTRAINT fk_leave_approver
    FOREIGN KEY (approved_by) REFERENCES staff(staff_id)
    ON DELETE SET NULL;

-- =============================================================================
-- FOREIGN KEYS: staff & nurses
-- =============================================================================
ALTER TABLE staff
    ADD CONSTRAINT fk_staff_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE staff
    ADD CONSTRAINT fk_staff_dept
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
    ON DELETE SET NULL;

ALTER TABLE nurses
    ADD CONSTRAINT fk_nurse_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE nurses
    ADD CONSTRAINT fk_nurse_dept
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id);

-- =============================================================================
-- FOREIGN KEYS: patients
-- =============================================================================
ALTER TABLE patients
    ADD CONSTRAINT fk_patient_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

-- Note: insurance FK added after insurance table; insurance references patients
ALTER TABLE insurance
    ADD CONSTRAINT fk_ins_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE;

ALTER TABLE patients
    ADD CONSTRAINT fk_patient_insurance
    FOREIGN KEY (insurance_id) REFERENCES insurance(insurance_id)
    ON DELETE SET NULL;

ALTER TABLE emergency_contacts
    ADD CONSTRAINT fk_ec_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE;

ALTER TABLE medical_records
    ADD CONSTRAINT fk_mr_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE medical_records
    ADD CONSTRAINT fk_mr_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id);

-- =============================================================================
-- FOREIGN KEYS: appointments
-- =============================================================================
ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id);

ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_dept
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id);

-- =============================================================================
-- FOREIGN KEYS: admissions & discharges
-- =============================================================================
ALTER TABLE admissions
    ADD CONSTRAINT fk_adm_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE admissions
    ADD CONSTRAINT fk_adm_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id);

ALTER TABLE admissions
    ADD CONSTRAINT fk_adm_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE admissions
    ADD CONSTRAINT fk_adm_bed
    FOREIGN KEY (bed_id) REFERENCES beds(bed_id);

ALTER TABLE discharges
    ADD CONSTRAINT fk_dis_admission
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id);

ALTER TABLE discharges
    ADD CONSTRAINT fk_dis_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE discharges
    ADD CONSTRAINT fk_dis_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id);

-- =============================================================================
-- FOREIGN KEYS: bed_allocations
-- =============================================================================
ALTER TABLE bed_allocations
    ADD CONSTRAINT fk_ba_bed
    FOREIGN KEY (bed_id) REFERENCES beds(bed_id);

ALTER TABLE bed_allocations
    ADD CONSTRAINT fk_ba_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE bed_allocations
    ADD CONSTRAINT fk_ba_admission
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id);

-- =============================================================================
-- FOREIGN KEYS: treatments, lab_reports, prescriptions
-- =============================================================================
ALTER TABLE treatments
    ADD CONSTRAINT fk_tr_admission
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id);

ALTER TABLE treatments
    ADD CONSTRAINT fk_tr_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE treatments
    ADD CONSTRAINT fk_tr_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id);

ALTER TABLE lab_reports
    ADD CONSTRAINT fk_lr_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE lab_reports
    ADD CONSTRAINT fk_lr_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id);

ALTER TABLE lab_reports
    ADD CONSTRAINT fk_lr_test
    FOREIGN KEY (test_id) REFERENCES lab_tests(test_id);

ALTER TABLE lab_reports
    ADD CONSTRAINT fk_lr_admission
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
    ON DELETE SET NULL;

ALTER TABLE prescriptions
    ADD CONSTRAINT fk_prx_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE prescriptions
    ADD CONSTRAINT fk_prx_doctor
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id);

ALTER TABLE prescriptions
    ADD CONSTRAINT fk_prx_medicine
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id);

ALTER TABLE prescriptions
    ADD CONSTRAINT fk_prx_appointment
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE SET NULL;

ALTER TABLE prescriptions
    ADD CONSTRAINT fk_prx_admission
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
    ON DELETE SET NULL;

-- =============================================================================
-- FOREIGN KEYS: billing & payments
-- =============================================================================
ALTER TABLE billing
    ADD CONSTRAINT fk_bill_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE billing
    ADD CONSTRAINT fk_bill_admission
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
    ON DELETE SET NULL;

ALTER TABLE billing
    ADD CONSTRAINT fk_bill_appointment
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE SET NULL;

ALTER TABLE billing
    ADD CONSTRAINT fk_bill_branch
    FOREIGN KEY (branch_id) REFERENCES hospital_branches(branch_id);

ALTER TABLE billing
    ADD CONSTRAINT fk_bill_insurance
    FOREIGN KEY (insurance_id) REFERENCES insurance(insurance_id)
    ON DELETE SET NULL;

ALTER TABLE payments
    ADD CONSTRAINT fk_pay_bill
    FOREIGN KEY (bill_id) REFERENCES billing(bill_id);

ALTER TABLE payments
    ADD CONSTRAINT fk_pay_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

ALTER TABLE payments
    ADD CONSTRAINT fk_pay_staff
    FOREIGN KEY (received_by) REFERENCES staff(staff_id)
    ON DELETE SET NULL;

-- =============================================================================
-- FOREIGN KEYS: inventory_logs
-- =============================================================================
ALTER TABLE inventory_logs
    ADD CONSTRAINT fk_invlog_inventory
    FOREIGN KEY (inventory_id) REFERENCES medicine_inventory(inventory_id);

ALTER TABLE inventory_logs
    ADD CONSTRAINT fk_invlog_medicine
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id);

-- =============================================================================
-- ADDITIONAL BUSINESS RULE CONSTRAINTS
-- =============================================================================

-- Appointments cannot be for past dates (allow today or future)
-- Note: we leave this as an application-layer rule to allow historical data inserts

-- Bed cannot be double-allocated at the same time (enforced via trigger)
-- Insurance coverage must be non-negative
ALTER TABLE insurance
    ADD CONSTRAINT chk_coverage_positive
    CHECK (coverage_amount > 0 AND premium_amount > 0);

-- A doctor cannot be the head of a department in a different branch
-- (enforced via trigger — see triggers.sql)

-- Discharge date must be after admission date (enforced in procedure)
-- Patient age must be non-negative (guaranteed by computed column on DOB)

SELECT 'constraints.sql completed successfully.' AS status;
