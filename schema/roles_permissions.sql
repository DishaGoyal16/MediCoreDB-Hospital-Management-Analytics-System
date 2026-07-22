-- =============================================================================
-- FILE: schema/roles_permissions.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: Role-Based Access Control (RBAC) — roles, grants, revokes.
--              Run LAST among schema files.
-- =============================================================================

-- =============================================================================
-- CREATE ROLES (idempotent)
-- =============================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_admin') THEN
        CREATE ROLE hospital_admin;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_doctor') THEN
        CREATE ROLE hospital_doctor;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_nurse') THEN
        CREATE ROLE hospital_nurse;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_receptionist') THEN
        CREATE ROLE hospital_receptionist;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_billing') THEN
        CREATE ROLE hospital_billing;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_pharmacist') THEN
        CREATE ROLE hospital_pharmacist;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_readonly') THEN
        CREATE ROLE hospital_readonly;
    END IF;
END
$$;

-- =============================================================================
-- ROLE: hospital_admin
--    Full read/write access across all tables and views.
-- =============================================================================
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO hospital_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hospital_admin;
GRANT EXECUTE ON ALL FUNCTIONS        IN SCHEMA public TO hospital_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hospital_admin;

-- =============================================================================
-- ROLE: hospital_doctor
--    Read patients and their own appointments/records.
--    Write prescriptions, treatments, lab_reports, medical_records.
--    Cannot see billing or other doctors' data.
-- =============================================================================
-- Read access
GRANT SELECT ON patients, emergency_contacts, insurance        TO hospital_doctor;
GRANT SELECT ON appointments, admissions, discharges           TO hospital_doctor;
GRANT SELECT ON medical_records, lab_tests, lab_reports        TO hospital_doctor;
GRANT SELECT ON treatments, prescriptions                      TO hospital_doctor;
GRANT SELECT ON medicines, medicine_inventory                  TO hospital_doctor;
GRANT SELECT ON doctor_schedules, leaves, specializations      TO hospital_doctor;
GRANT SELECT ON departments, hospital_branches                 TO hospital_doctor;

-- Write access (doctor's own clinical activities)
GRANT INSERT, UPDATE ON prescriptions     TO hospital_doctor;
GRANT INSERT, UPDATE ON treatments        TO hospital_doctor;
GRANT INSERT, UPDATE ON lab_reports       TO hospital_doctor;
GRANT INSERT, UPDATE ON medical_records   TO hospital_doctor;
GRANT UPDATE          ON appointments     TO hospital_doctor;
GRANT INSERT          ON leaves           TO hospital_doctor;

-- Sequence access
GRANT USAGE ON SEQUENCE prescriptions_prescription_id_seq   TO hospital_doctor;
GRANT USAGE ON SEQUENCE treatments_treatment_id_seq         TO hospital_doctor;
GRANT USAGE ON SEQUENCE lab_reports_report_id_seq           TO hospital_doctor;
GRANT USAGE ON SEQUENCE medical_records_record_id_seq       TO hospital_doctor;
GRANT USAGE ON SEQUENCE leaves_leave_id_seq                 TO hospital_doctor;

-- Views
GRANT SELECT ON vw_doctor_dashboard, vw_todays_appointments  TO hospital_doctor;
GRANT SELECT ON vw_patient_summary, vw_active_admissions     TO hospital_doctor;
GRANT SELECT ON vw_medicine_inventory                        TO hospital_doctor;

-- =============================================================================
-- ROLE: hospital_nurse
--    Read patient info, bed assignments, admissions.
--    Update bed status, log vitals (via medical_records).
-- =============================================================================
GRANT SELECT ON patients, emergency_contacts              TO hospital_nurse;
GRANT SELECT ON admissions, discharges, bed_allocations   TO hospital_nurse;
GRANT SELECT ON beds, rooms, departments                  TO hospital_nurse;
GRANT SELECT ON prescriptions, treatments, medicines      TO hospital_nurse;
GRANT SELECT ON appointments                              TO hospital_nurse;

GRANT UPDATE ON beds             TO hospital_nurse;
GRANT INSERT ON medical_records  TO hospital_nurse;
GRANT USAGE  ON SEQUENCE medical_records_record_id_seq  TO hospital_nurse;

GRANT SELECT ON vw_bed_availability, vw_active_admissions TO hospital_nurse;
GRANT SELECT ON vw_todays_appointments                    TO hospital_nurse;

-- =============================================================================
-- ROLE: hospital_receptionist
--    Book/cancel appointments, register patients.
--    Cannot see billing detail or clinical notes.
-- =============================================================================
GRANT SELECT ON doctors, doctor_schedules, specializations    TO hospital_receptionist;
GRANT SELECT ON departments, hospital_branches                TO hospital_receptionist;
GRANT SELECT, INSERT, UPDATE ON patients                      TO hospital_receptionist;
GRANT SELECT, INSERT, UPDATE ON appointments                  TO hospital_receptionist;
GRANT SELECT, INSERT ON emergency_contacts                    TO hospital_receptionist;
GRANT SELECT ON beds, rooms                                   TO hospital_receptionist;

GRANT USAGE ON SEQUENCE patients_patient_id_seq          TO hospital_receptionist;
GRANT USAGE ON SEQUENCE appointments_appointment_id_seq  TO hospital_receptionist;
GRANT USAGE ON SEQUENCE emergency_contacts_contact_id_seq TO hospital_receptionist;

GRANT SELECT ON vw_todays_appointments, vw_bed_availability  TO hospital_receptionist;
GRANT SELECT ON vw_department_stats                          TO hospital_receptionist;

-- =============================================================================
-- ROLE: hospital_billing
--    Full access to billing, payments, insurance.
--    Read-only on clinical tables.
-- =============================================================================
GRANT SELECT ON patients, admissions, discharges, appointments TO hospital_billing;
GRANT SELECT ON treatments, lab_reports, prescriptions         TO hospital_billing;
GRANT SELECT, INSERT, UPDATE ON billing                        TO hospital_billing;
GRANT SELECT, INSERT ON payments                               TO hospital_billing;
GRANT SELECT, INSERT, UPDATE ON insurance                      TO hospital_billing;

GRANT USAGE ON SEQUENCE billing_bill_id_seq    TO hospital_billing;
GRANT USAGE ON SEQUENCE payments_payment_id_seq TO hospital_billing;
GRANT USAGE ON SEQUENCE insurance_insurance_id_seq TO hospital_billing;

GRANT SELECT ON vw_revenue_dashboard, mvw_monthly_revenue     TO hospital_billing;
GRANT SELECT ON vw_patient_summary                            TO hospital_billing;

-- =============================================================================
-- ROLE: hospital_pharmacist
--    Full access to medicine inventory and prescriptions.
--    Read-only on patient and doctor info.
-- =============================================================================
GRANT SELECT ON patients, doctors                               TO hospital_pharmacist;
GRANT SELECT, INSERT, UPDATE ON medicines                       TO hospital_pharmacist;
GRANT SELECT, INSERT, UPDATE ON medicine_inventory              TO hospital_pharmacist;
GRANT SELECT, INSERT ON inventory_logs                          TO hospital_pharmacist;
GRANT SELECT ON prescriptions                                   TO hospital_pharmacist;
GRANT SELECT ON suppliers                                       TO hospital_pharmacist;

GRANT USAGE ON SEQUENCE medicines_medicine_id_seq               TO hospital_pharmacist;
GRANT USAGE ON SEQUENCE medicine_inventory_inventory_id_seq     TO hospital_pharmacist;
GRANT USAGE ON SEQUENCE inventory_logs_log_id_seq               TO hospital_pharmacist;

GRANT SELECT ON vw_medicine_inventory, vw_top_medicines         TO hospital_pharmacist;

-- =============================================================================
-- ROLE: hospital_readonly
--    Analytics / reporting role — SELECT only on views.
-- =============================================================================
GRANT SELECT ON vw_doctor_dashboard        TO hospital_readonly;
GRANT SELECT ON vw_patient_summary         TO hospital_readonly;
GRANT SELECT ON vw_bed_availability        TO hospital_readonly;
GRANT SELECT ON vw_todays_appointments     TO hospital_readonly;
GRANT SELECT ON vw_revenue_dashboard       TO hospital_readonly;
GRANT SELECT ON vw_medicine_inventory      TO hospital_readonly;
GRANT SELECT ON vw_department_stats        TO hospital_readonly;
GRANT SELECT ON vw_top_doctors             TO hospital_readonly;
GRANT SELECT ON vw_top_medicines           TO hospital_readonly;
GRANT SELECT ON vw_active_admissions       TO hospital_readonly;
GRANT SELECT ON mvw_monthly_revenue        TO hospital_readonly;
GRANT SELECT ON mvw_doctor_performance     TO hospital_readonly;

-- =============================================================================
-- REVOKE sensitive table access from PUBLIC (security hardening)
-- =============================================================================
REVOKE ALL ON audit_logs       FROM PUBLIC;
REVOKE ALL ON billing          FROM PUBLIC;
REVOKE ALL ON payments         FROM PUBLIC;
REVOKE ALL ON insurance        FROM PUBLIC;
REVOKE ALL ON medical_records  FROM PUBLIC;

-- Grant audit_logs read to admin only
GRANT SELECT ON audit_logs TO hospital_admin;

-- =============================================================================
-- EXAMPLE: Create application users and assign roles
-- (Commented out — run manually with real passwords)
-- =============================================================================
/*
CREATE USER app_doctor      WITH PASSWORD 'SecurePass123!' LOGIN;
CREATE USER app_nurse       WITH PASSWORD 'SecurePass456!' LOGIN;
CREATE USER app_receptionist WITH PASSWORD 'SecurePass789!' LOGIN;
CREATE USER app_billing     WITH PASSWORD 'SecurePass321!' LOGIN;
CREATE USER app_pharmacist  WITH PASSWORD 'SecurePass654!' LOGIN;
CREATE USER app_readonly    WITH PASSWORD 'SecurePass987!' LOGIN;
CREATE USER app_admin       WITH PASSWORD 'AdminPass@999!' LOGIN;

GRANT hospital_doctor       TO app_doctor;
GRANT hospital_nurse        TO app_nurse;
GRANT hospital_receptionist TO app_receptionist;
GRANT hospital_billing      TO app_billing;
GRANT hospital_pharmacist   TO app_pharmacist;
GRANT hospital_readonly     TO app_readonly;
GRANT hospital_admin        TO app_admin;
*/

SELECT 'roles_permissions.sql completed successfully.' AS status;
