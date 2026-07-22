-- =============================================================================
-- FILE: schema/indexes.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: Performance indexes — B-Tree, Composite, Partial, Expression.
--              Run AFTER constraints.sql.
-- =============================================================================

-- =============================================================================
-- APPOINTMENTS — most queried table
-- =============================================================================

-- Most common query: find appointments for a doctor on a date
CREATE INDEX idx_appt_doctor_date
    ON appointments(doctor_id, appointment_date);

-- Appointment status filter (Scheduled/Confirmed)
CREATE INDEX idx_appt_status
    ON appointments(status)
    WHERE status IN ('Scheduled', 'Confirmed');

-- Partial index: active (non-terminal) appointments only
-- Note: CURRENT_DATE is not immutable so cannot be used in index predicates.
-- This partial index covers the non-cancelled/no-show rows, which is the
-- high-value subset for operational queries.
CREATE INDEX idx_appt_upcoming
    ON appointments(appointment_date, doctor_id)
    WHERE status NOT IN ('Cancelled', 'No-Show');

-- Patient appointment history
CREATE INDEX idx_appt_patient
    ON appointments(patient_id, appointment_date DESC);

-- Branch + date composite for branch-level dashboards
CREATE INDEX idx_appt_branch_date
    ON appointments(branch_id, appointment_date);

-- =============================================================================
-- PATIENTS
-- =============================================================================
CREATE INDEX idx_patient_name
    ON patients(last_name, first_name);

CREATE INDEX idx_patient_phone
    ON patients(phone);

-- Partial: active patients only
CREATE INDEX idx_patient_active
    ON patients(branch_id, registration_date DESC)
    WHERE is_active = TRUE;

-- Note: expression index on LOWER(email) requires the column to exist.
-- Created after patients table is confirmed present.

-- Expression index: case-insensitive email lookup
CREATE INDEX idx_patient_email_lower
    ON patients(LOWER(email));

-- =============================================================================
-- DOCTORS
-- =============================================================================
CREATE INDEX idx_doctor_dept
    ON doctors(dept_id, is_active);

CREATE INDEX idx_doctor_name
    ON doctors(last_name, first_name);

-- Active doctors by branch
CREATE INDEX idx_doctor_branch_active
    ON doctors(branch_id, dept_id)
    WHERE is_active = TRUE;

-- =============================================================================
-- BILLING
-- =============================================================================
-- Revenue reports by date range
CREATE INDEX idx_bill_date
    ON billing(bill_date DESC);

CREATE INDEX idx_bill_patient
    ON billing(patient_id, bill_date DESC);

-- Unpaid bills (partial index — avoids scanning paid records)
CREATE INDEX idx_bill_unpaid
    ON billing(patient_id, bill_date)
    WHERE payment_status IN ('Pending', 'Partial');

CREATE INDEX idx_bill_branch_date
    ON billing(branch_id, bill_date DESC);

-- =============================================================================
-- PAYMENTS
-- =============================================================================
CREATE INDEX idx_pay_bill
    ON payments(bill_id);

CREATE INDEX idx_pay_date
    ON payments(payment_date DESC);

-- =============================================================================
-- ADMISSIONS
-- =============================================================================
CREATE INDEX idx_adm_patient
    ON admissions(patient_id, admission_date DESC);

CREATE INDEX idx_adm_doctor
    ON admissions(doctor_id);

-- Active admissions only (partial)
CREATE INDEX idx_adm_active
    ON admissions(branch_id, admission_date DESC)
    WHERE status = 'Active';

CREATE INDEX idx_adm_bed
    ON admissions(bed_id);

-- =============================================================================
-- PRESCRIPTIONS
-- =============================================================================
CREATE INDEX idx_prx_patient
    ON prescriptions(patient_id, prescribed_on DESC);

CREATE INDEX idx_prx_medicine
    ON prescriptions(medicine_id);

CREATE INDEX idx_prx_doctor
    ON prescriptions(doctor_id);

-- =============================================================================
-- MEDICINE INVENTORY
-- =============================================================================
-- Stock check by branch
CREATE INDEX idx_inv_branch_medicine
    ON medicine_inventory(branch_id, medicine_id);

-- Low-stock alert (partial)
CREATE INDEX idx_inv_low_stock
    ON medicine_inventory(branch_id, medicine_id, quantity)
    WHERE quantity <= reorder_level AND is_active = TRUE;

-- Expiring soon (expression index)
CREATE INDEX idx_inv_expiry
    ON medicine_inventory(expiry_date)
    WHERE is_active = TRUE;

-- =============================================================================
-- LAB REPORTS
-- =============================================================================
CREATE INDEX idx_lr_patient_date
    ON lab_reports(patient_id, test_date DESC);

CREATE INDEX idx_lr_status
    ON lab_reports(result_status)
    WHERE result_status IN ('Pending', 'Critical');

-- =============================================================================
-- BEDS
-- =============================================================================
-- Available bed lookup (most critical for admissions)
CREATE INDEX idx_bed_status
    ON beds(status, room_id)
    WHERE status = 'Available';

-- =============================================================================
-- MEDICAL RECORDS
-- =============================================================================
CREATE INDEX idx_mr_patient_date
    ON medical_records(patient_id, visit_date DESC);

-- =============================================================================
-- AUDIT LOGS
-- =============================================================================
CREATE INDEX idx_audit_table_time
    ON audit_logs(table_name, changed_at DESC);

CREATE INDEX idx_audit_time
    ON audit_logs(changed_at DESC);

-- =============================================================================
-- DOCTOR SCHEDULES
-- =============================================================================
CREATE INDEX idx_sched_doctor_day
    ON doctor_schedules(doctor_id, day_of_week)
    WHERE is_active = TRUE;

-- =============================================================================
-- INVENTORY LOGS
-- =============================================================================
CREATE INDEX idx_invlog_medicine_time
    ON inventory_logs(medicine_id, performed_at DESC);

-- =============================================================================
SELECT 'indexes.sql completed successfully.' AS status;