-- =============================================================================
-- FILE: schema/create_tables.sql
-- PROJECT: Hospital Management Database System
-- DATABASE: PostgreSQL 15+
-- DESCRIPTION: Core DDL — creates all 25+ tables in dependency order.
--              Run this FIRST before any other script.
-- =============================================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- DROP EXISTING TABLES (safe re-run)
-- =============================================================================
DROP TABLE IF EXISTS inventory_logs       CASCADE;
DROP TABLE IF EXISTS audit_logs           CASCADE;
DROP TABLE IF EXISTS payments             CASCADE;
DROP TABLE IF EXISTS billing              CASCADE;
DROP TABLE IF EXISTS insurance            CASCADE;
DROP TABLE IF EXISTS lab_reports          CASCADE;
DROP TABLE IF EXISTS lab_tests            CASCADE;
DROP TABLE IF EXISTS prescriptions        CASCADE;
DROP TABLE IF EXISTS treatments           CASCADE;
DROP TABLE IF EXISTS discharges           CASCADE;
DROP TABLE IF EXISTS admissions           CASCADE;
DROP TABLE IF EXISTS bed_allocations      CASCADE;
DROP TABLE IF EXISTS appointments         CASCADE;
DROP TABLE IF EXISTS medical_records      CASCADE;
DROP TABLE IF EXISTS emergency_contacts   CASCADE;
DROP TABLE IF EXISTS patients             CASCADE;
DROP TABLE IF EXISTS leaves               CASCADE;
DROP TABLE IF EXISTS doctor_schedules     CASCADE;
DROP TABLE IF EXISTS doctor_specializations CASCADE;
DROP TABLE IF EXISTS nurses               CASCADE;
DROP TABLE IF EXISTS staff                CASCADE;
DROP TABLE IF EXISTS doctors              CASCADE;
DROP TABLE IF EXISTS specializations      CASCADE;
DROP TABLE IF EXISTS medicine_inventory   CASCADE;
DROP TABLE IF EXISTS medicines            CASCADE;
DROP TABLE IF EXISTS suppliers            CASCADE;
DROP TABLE IF EXISTS beds                 CASCADE;
DROP TABLE IF EXISTS rooms                CASCADE;
DROP TABLE IF EXISTS departments          CASCADE;
DROP TABLE IF EXISTS hospital_branches    CASCADE;

-- =============================================================================
-- 1. HOSPITAL BRANCHES
-- =============================================================================
CREATE TABLE hospital_branches (
    branch_id       SERIAL PRIMARY KEY,
    branch_name     VARCHAR(150) NOT NULL,
    address         TEXT        NOT NULL,
    city            VARCHAR(80) NOT NULL,
    state           VARCHAR(80) NOT NULL,
    pincode         VARCHAR(10) NOT NULL,
    phone           VARCHAR(15) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    established_on  DATE        NOT NULL DEFAULT CURRENT_DATE,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hospital_branches IS 'Top-level entity: physical hospital branches/campuses.';

-- =============================================================================
-- 2. DEPARTMENTS
-- =============================================================================
CREATE TABLE departments (
    dept_id         SERIAL PRIMARY KEY,
    branch_id       INT         NOT NULL,
    dept_name       VARCHAR(120) NOT NULL,
    dept_code       VARCHAR(10)  NOT NULL,
    floor_no        SMALLINT    NOT NULL DEFAULT 1,
    head_doctor_id  INT,                          -- FK added after doctors table
    phone_ext       VARCHAR(6),
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (branch_id, dept_code)
);

COMMENT ON TABLE departments IS 'Hospital departments per branch (Cardiology, Ortho, ICU, etc.).';

-- =============================================================================
-- 3. SPECIALIZATIONS
-- =============================================================================
CREATE TABLE specializations (
    spec_id     SERIAL PRIMARY KEY,
    spec_name   VARCHAR(120) NOT NULL UNIQUE,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE specializations IS 'Medical specializations (Cardiology, Neurology, etc.).';

-- =============================================================================
-- 4. SUPPLIERS
-- =============================================================================
CREATE TABLE suppliers (
    supplier_id     SERIAL PRIMARY KEY,
    supplier_name   VARCHAR(150) NOT NULL,
    contact_person  VARCHAR(100),
    phone           VARCHAR(15)  NOT NULL,
    email           VARCHAR(100),
    address         TEXT,
    city            VARCHAR(80),
    gstin           VARCHAR(15),
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE suppliers IS 'Pharmaceutical and medical supply vendors.';

-- =============================================================================
-- 5. MEDICINES
-- =============================================================================
CREATE TABLE medicines (
    medicine_id     SERIAL PRIMARY KEY,
    medicine_name   VARCHAR(150) NOT NULL,
    generic_name    VARCHAR(150),
    category        VARCHAR(60)  NOT NULL,  -- Antibiotic, Analgesic, etc.
    unit            VARCHAR(20)  NOT NULL DEFAULT 'tablet',
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    requires_prescription BOOLEAN NOT NULL DEFAULT TRUE,
    manufacturer    VARCHAR(150),
    hsn_code        VARCHAR(10),
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE medicines IS 'Master catalogue of all medicines stocked in the hospital.';

-- =============================================================================
-- 6. MEDICINE INVENTORY
-- =============================================================================
CREATE TABLE medicine_inventory (
    inventory_id    SERIAL PRIMARY KEY,
    medicine_id     INT          NOT NULL,
    branch_id       INT          NOT NULL,
    supplier_id     INT,
    batch_number    VARCHAR(40)  NOT NULL,
    quantity        INT          NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reorder_level   INT          NOT NULL DEFAULT 50,
    expiry_date     DATE         NOT NULL,
    purchase_price  NUMERIC(10,2) NOT NULL CHECK (purchase_price >= 0),
    received_on     DATE         NOT NULL DEFAULT CURRENT_DATE,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (medicine_id, branch_id, batch_number)
);

COMMENT ON TABLE medicine_inventory IS 'Stock per medicine per branch with batch tracking.';

-- =============================================================================
-- 7. ROOMS
-- =============================================================================
CREATE TABLE rooms (
    room_id         SERIAL PRIMARY KEY,
    branch_id       INT          NOT NULL,
    dept_id         INT          NOT NULL,
    room_number     VARCHAR(10)  NOT NULL,
    room_type       VARCHAR(30)  NOT NULL CHECK (room_type IN
                        ('General','Semi-Private','Private','ICU','NICU',
                         'OT','Emergency','Isolation','Labour')),
    floor_no        SMALLINT     NOT NULL DEFAULT 1,
    total_beds      SMALLINT     NOT NULL DEFAULT 1 CHECK (total_beds > 0),
    daily_charge    NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (daily_charge >= 0),
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (branch_id, room_number)
);

COMMENT ON TABLE rooms IS 'Physical rooms across all branches and departments.';

-- =============================================================================
-- 8. BEDS
-- =============================================================================
CREATE TABLE beds (
    bed_id          SERIAL PRIMARY KEY,
    room_id         INT          NOT NULL,
    bed_number      VARCHAR(10)  NOT NULL,
    bed_type        VARCHAR(30)  NOT NULL DEFAULT 'Standard'
                        CHECK (bed_type IN ('Standard','ICU','Ventilator',
                                            'Bariatric','Pediatric','Electric')),
    status          VARCHAR(20)  NOT NULL DEFAULT 'Available'
                        CHECK (status IN ('Available','Occupied','Maintenance','Reserved')),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (room_id, bed_number)
);

COMMENT ON TABLE beds IS 'Individual beds within rooms; status tracks real-time availability.';

-- =============================================================================
-- 9. DOCTORS
-- =============================================================================
CREATE TABLE doctors (
    doctor_id           SERIAL PRIMARY KEY,
    branch_id           INT          NOT NULL,
    dept_id             INT          NOT NULL,
    first_name          VARCHAR(60)  NOT NULL,
    last_name           VARCHAR(60)  NOT NULL,
    gender              CHAR(1)      NOT NULL CHECK (gender IN ('M','F','O')),
    date_of_birth       DATE         NOT NULL,
    phone               VARCHAR(15)  NOT NULL UNIQUE,
    email               VARCHAR(100) NOT NULL UNIQUE,
    registration_number VARCHAR(30)  NOT NULL UNIQUE,
    qualification       VARCHAR(150),
    experience_years    SMALLINT     NOT NULL DEFAULT 0 CHECK (experience_years >= 0),
    consultation_fee    NUMERIC(10,2) NOT NULL DEFAULT 500 CHECK (consultation_fee >= 0),
    joining_date        DATE         NOT NULL DEFAULT CURRENT_DATE,
    employment_type     VARCHAR(20)  NOT NULL DEFAULT 'Full-Time'
                            CHECK (employment_type IN ('Full-Time','Part-Time','Visiting','Consultant')),
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    -- Generated column: full name
    full_name           VARCHAR(121) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);

COMMENT ON TABLE doctors IS 'Registered doctors; registration_number is the medical council number.';

-- =============================================================================
-- 10. DOCTOR SPECIALIZATIONS (junction — many-to-many)
-- =============================================================================
CREATE TABLE doctor_specializations (
    doctor_id   INT NOT NULL,
    spec_id     INT NOT NULL,
    is_primary  BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (doctor_id, spec_id)
);

-- =============================================================================
-- 11. DOCTOR SCHEDULES
-- =============================================================================
CREATE TABLE doctor_schedules (
    schedule_id     SERIAL PRIMARY KEY,
    doctor_id       INT         NOT NULL,
    day_of_week     SMALLINT    NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun
    start_time      TIME        NOT NULL,
    end_time        TIME        NOT NULL,
    max_appointments SMALLINT   NOT NULL DEFAULT 20 CHECK (max_appointments > 0),
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    CHECK (end_time > start_time)
);

COMMENT ON TABLE doctor_schedules IS 'Weekly recurring availability slots per doctor.';

-- =============================================================================
-- 12. LEAVES
-- =============================================================================
CREATE TABLE leaves (
    leave_id        SERIAL PRIMARY KEY,
    doctor_id       INT         NOT NULL,
    leave_from      DATE        NOT NULL,
    leave_to        DATE        NOT NULL,
    leave_type      VARCHAR(30) NOT NULL DEFAULT 'Casual'
                        CHECK (leave_type IN ('Casual','Medical','Annual','Maternity','Paternity','Emergency')),
    reason          TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'Pending'
                        CHECK (status IN ('Pending','Approved','Rejected','Cancelled')),
    approved_by     INT,                    -- FK to staff
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (leave_to >= leave_from)
);

-- =============================================================================
-- 13. STAFF
-- =============================================================================
CREATE TABLE staff (
    staff_id        SERIAL PRIMARY KEY,
    branch_id       INT          NOT NULL,
    dept_id         INT,
    first_name      VARCHAR(60)  NOT NULL,
    last_name       VARCHAR(60)  NOT NULL,
    gender          CHAR(1)      NOT NULL CHECK (gender IN ('M','F','O')),
    date_of_birth   DATE         NOT NULL,
    role            VARCHAR(50)  NOT NULL,  -- Admin, Receptionist, Accountant, etc.
    phone           VARCHAR(15)  NOT NULL UNIQUE,
    email           VARCHAR(100) NOT NULL UNIQUE,
    joining_date    DATE         NOT NULL DEFAULT CURRENT_DATE,
    salary          NUMERIC(12,2) NOT NULL CHECK (salary >= 0),
    employment_type VARCHAR(20)  NOT NULL DEFAULT 'Full-Time'
                        CHECK (employment_type IN ('Full-Time','Part-Time','Contract')),
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    full_name       VARCHAR(121) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);

-- =============================================================================
-- 14. NURSES
-- =============================================================================
CREATE TABLE nurses (
    nurse_id        SERIAL PRIMARY KEY,
    branch_id       INT          NOT NULL,
    dept_id         INT          NOT NULL,
    first_name      VARCHAR(60)  NOT NULL,
    last_name       VARCHAR(60)  NOT NULL,
    gender          CHAR(1)      NOT NULL CHECK (gender IN ('M','F','O')),
    date_of_birth   DATE         NOT NULL,
    phone           VARCHAR(15)  NOT NULL UNIQUE,
    email           VARCHAR(100) NOT NULL UNIQUE,
    registration_number VARCHAR(30) NOT NULL UNIQUE,
    shift           VARCHAR(20)  NOT NULL DEFAULT 'Morning'
                        CHECK (shift IN ('Morning','Evening','Night','Rotating')),
    joining_date    DATE         NOT NULL DEFAULT CURRENT_DATE,
    salary          NUMERIC(12,2) NOT NULL CHECK (salary >= 0),
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    full_name       VARCHAR(121) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);

-- =============================================================================
-- 15. PATIENTS
-- =============================================================================
CREATE TABLE patients (
    patient_id      SERIAL PRIMARY KEY,
    branch_id       INT          NOT NULL,
    first_name      VARCHAR(60)  NOT NULL,
    last_name       VARCHAR(60)  NOT NULL,
    gender          CHAR(1)      NOT NULL CHECK (gender IN ('M','F','O')),
    date_of_birth   DATE         NOT NULL,
    blood_group     VARCHAR(5)   CHECK (blood_group IN
                        ('A+','A-','B+','B-','O+','O-','AB+','AB-')),
    phone           VARCHAR(15)  NOT NULL,
    email           VARCHAR(100),
    address         TEXT,
    city            VARCHAR(80),
    state           VARCHAR(80),
    pincode         VARCHAR(10),
    aadhar_number   VARCHAR(12)  UNIQUE,
    insurance_id    INT,                        -- FK to insurance
    registration_date DATE       NOT NULL DEFAULT CURRENT_DATE,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    -- NOTE: age is a regular column updated via trigger (AGE() is not immutable in PG)
    full_name       VARCHAR(121) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    age             INT
);

COMMENT ON TABLE patients IS 'All registered patients; age is maintained by trg_patients_set_age trigger.';

-- =============================================================================
-- 16. EMERGENCY CONTACTS
-- =============================================================================
CREATE TABLE emergency_contacts (
    contact_id      SERIAL PRIMARY KEY,
    patient_id      INT          NOT NULL,
    contact_name    VARCHAR(120) NOT NULL,
    relationship    VARCHAR(40)  NOT NULL,
    phone           VARCHAR(15)  NOT NULL,
    alt_phone       VARCHAR(15),
    address         TEXT,
    is_primary      BOOLEAN      NOT NULL DEFAULT FALSE
);

-- =============================================================================
-- 17. INSURANCE
-- =============================================================================
CREATE TABLE insurance (
    insurance_id        SERIAL PRIMARY KEY,
    patient_id          INT           NOT NULL,
    provider_name       VARCHAR(150)  NOT NULL,
    policy_number       VARCHAR(50)   NOT NULL UNIQUE,
    policy_type         VARCHAR(50)   NOT NULL DEFAULT 'Individual'
                            CHECK (policy_type IN ('Individual','Family','Group','Senior')),
    coverage_amount     NUMERIC(12,2) NOT NULL CHECK (coverage_amount > 0),
    premium_amount      NUMERIC(10,2) NOT NULL CHECK (premium_amount > 0),
    deductible          NUMERIC(10,2) NOT NULL DEFAULT 0,
    valid_from          DATE          NOT NULL,
    valid_to            DATE          NOT NULL,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CHECK (valid_to > valid_from)
);

-- =============================================================================
-- 18. MEDICAL RECORDS
-- =============================================================================
CREATE TABLE medical_records (
    record_id       SERIAL PRIMARY KEY,
    patient_id      INT          NOT NULL,
    doctor_id       INT          NOT NULL,
    visit_date      DATE         NOT NULL DEFAULT CURRENT_DATE,
    chief_complaint TEXT         NOT NULL,
    diagnosis       TEXT,
    notes           TEXT,
    follow_up_date  DATE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 19. APPOINTMENTS
-- =============================================================================
CREATE TABLE appointments (
    appointment_id      SERIAL PRIMARY KEY,
    branch_id           INT          NOT NULL,
    patient_id          INT          NOT NULL,
    doctor_id           INT          NOT NULL,
    dept_id             INT          NOT NULL,
    appointment_date    DATE         NOT NULL,
    appointment_time    TIME         NOT NULL,
    appointment_type    VARCHAR(30)  NOT NULL DEFAULT 'OPD'
                            CHECK (appointment_type IN ('OPD','Follow-Up','Emergency','Teleconsult')),
    status              VARCHAR(20)  NOT NULL DEFAULT 'Scheduled'
                            CHECK (status IN ('Scheduled','Confirmed','Completed',
                                              'Cancelled','No-Show')),
    reason              TEXT,
    notes               TEXT,
    booked_on           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE appointments IS 'OPD/emergency appointments; triggers prevent double-booking.';

-- =============================================================================
-- 20. ADMISSIONS
-- =============================================================================
CREATE TABLE admissions (
    admission_id        SERIAL PRIMARY KEY,
    patient_id          INT          NOT NULL,
    doctor_id           INT          NOT NULL,
    branch_id           INT          NOT NULL,
    bed_id              INT          NOT NULL,
    admission_date      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    admission_type      VARCHAR(30)  NOT NULL DEFAULT 'Regular'
                            CHECK (admission_type IN ('Regular','Emergency','Transfer','Surgery')),
    diagnosis           TEXT,
    status              VARCHAR(20)  NOT NULL DEFAULT 'Active'
                            CHECK (status IN ('Active','Discharged','Transferred','Deceased')),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 21. DISCHARGES
-- =============================================================================
CREATE TABLE discharges (
    discharge_id        SERIAL PRIMARY KEY,
    admission_id        INT          NOT NULL UNIQUE,
    patient_id          INT          NOT NULL,
    doctor_id           INT          NOT NULL,
    discharge_date      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    discharge_type      VARCHAR(30)  NOT NULL DEFAULT 'Normal'
                            CHECK (discharge_type IN
                                ('Normal','AMA','Transfer','Deceased','Referral')),
    discharge_notes     TEXT,
    follow_up_date      DATE,
    -- Generated: length of stay (days)
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 22. BED ALLOCATIONS (history)
-- =============================================================================
CREATE TABLE bed_allocations (
    allocation_id   SERIAL PRIMARY KEY,
    bed_id          INT          NOT NULL,
    patient_id      INT          NOT NULL,
    admission_id    INT          NOT NULL,
    allocated_on    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    released_on     TIMESTAMPTZ,
    notes           TEXT
);

-- =============================================================================
-- 23. TREATMENTS
-- =============================================================================
CREATE TABLE treatments (
    treatment_id        SERIAL PRIMARY KEY,
    admission_id        INT          NOT NULL,
    patient_id          INT          NOT NULL,
    doctor_id           INT          NOT NULL,
    treatment_name      VARCHAR(150) NOT NULL,
    treatment_type      VARCHAR(50)  NOT NULL DEFAULT 'Medication'
                            CHECK (treatment_type IN
                                ('Medication','Surgery','Therapy','Procedure',
                                 'Diagnostic','Physiotherapy')),
    treatment_date      DATE         NOT NULL DEFAULT CURRENT_DATE,
    cost                NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (cost >= 0),
    notes               TEXT,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 24. LAB TESTS
-- =============================================================================
CREATE TABLE lab_tests (
    test_id         SERIAL PRIMARY KEY,
    test_name       VARCHAR(120) NOT NULL UNIQUE,
    category        VARCHAR(60)  NOT NULL,  -- Hematology, Biochemistry, Radiology…
    normal_range    VARCHAR(100),
    unit_of_measure VARCHAR(30),
    cost            NUMERIC(10,2) NOT NULL CHECK (cost >= 0),
    turnaround_hrs  SMALLINT     NOT NULL DEFAULT 24,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 25. LAB REPORTS
-- =============================================================================
CREATE TABLE lab_reports (
    report_id       SERIAL PRIMARY KEY,
    patient_id      INT          NOT NULL,
    doctor_id       INT          NOT NULL,
    test_id         INT          NOT NULL,
    admission_id    INT,                        -- NULL for OPD lab tests
    test_date       DATE         NOT NULL DEFAULT CURRENT_DATE,
    result_value    VARCHAR(200),
    result_status   VARCHAR(20)  DEFAULT 'Pending'
                        CHECK (result_status IN ('Pending','Normal','Abnormal','Critical')),
    remarks         TEXT,
    technician_name VARCHAR(120),
    reported_on     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 26. PRESCRIPTIONS
-- =============================================================================
CREATE TABLE prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    patient_id      INT          NOT NULL,
    doctor_id       INT          NOT NULL,
    appointment_id  INT,
    admission_id    INT,
    medicine_id     INT          NOT NULL,
    dosage          VARCHAR(60)  NOT NULL,      -- e.g. "500mg twice daily"
    frequency       VARCHAR(40)  NOT NULL,      -- e.g. "BD", "TDS"
    duration_days   SMALLINT     NOT NULL CHECK (duration_days > 0),
    quantity        INT          NOT NULL CHECK (quantity > 0),
    instructions    TEXT,
    prescribed_on   DATE         NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 27. BILLING
-- =============================================================================
CREATE TABLE billing (
    bill_id             SERIAL PRIMARY KEY,
    patient_id          INT           NOT NULL,
    admission_id        INT,
    appointment_id      INT,
    branch_id           INT           NOT NULL,
    bill_date           DATE          NOT NULL DEFAULT CURRENT_DATE,
    consultation_charge NUMERIC(10,2) NOT NULL DEFAULT 0,
    room_charge         NUMERIC(10,2) NOT NULL DEFAULT 0,
    medicine_charge     NUMERIC(10,2) NOT NULL DEFAULT 0,
    lab_charge          NUMERIC(10,2) NOT NULL DEFAULT 0,
    treatment_charge    NUMERIC(10,2) NOT NULL DEFAULT 0,
    other_charge        NUMERIC(10,2) NOT NULL DEFAULT 0,
    discount_pct        NUMERIC(5,2)  NOT NULL DEFAULT 0
                            CHECK (discount_pct BETWEEN 0 AND 100),
    tax_pct             NUMERIC(5,2)  NOT NULL DEFAULT 18
                            CHECK (tax_pct BETWEEN 0 AND 30),
    -- Generated columns
    subtotal            NUMERIC(12,2) GENERATED ALWAYS AS (
                            consultation_charge + room_charge + medicine_charge +
                            lab_charge + treatment_charge + other_charge
                        ) STORED,
    discount_amount     NUMERIC(12,2) GENERATED ALWAYS AS (
                            ROUND((consultation_charge + room_charge + medicine_charge +
                                   lab_charge + treatment_charge + other_charge)
                                  * discount_pct / 100, 2)
                        ) STORED,
    tax_amount          NUMERIC(12,2) GENERATED ALWAYS AS (
                            ROUND((consultation_charge + room_charge + medicine_charge +
                                   lab_charge + treatment_charge + other_charge)
                                  * (1 - discount_pct/100)
                                  * tax_pct / 100, 2)
                        ) STORED,
    total_amount        NUMERIC(12,2) GENERATED ALWAYS AS (
                            ROUND((consultation_charge + room_charge + medicine_charge +
                                   lab_charge + treatment_charge + other_charge)
                                  * (1 - discount_pct/100)
                                  * (1 + tax_pct/100), 2)
                        ) STORED,
    insurance_id        INT,
    insurance_covered   NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_status      VARCHAR(20)   NOT NULL DEFAULT 'Pending'
                            CHECK (payment_status IN
                                ('Pending','Partial','Paid','Waived','Insurance')),
    notes               TEXT,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE billing IS 'Bill per visit/admission; totals are generated columns (auto-computed).';

-- =============================================================================
-- 28. PAYMENTS
-- =============================================================================
CREATE TABLE payments (
    payment_id      SERIAL PRIMARY KEY,
    bill_id         INT           NOT NULL,
    patient_id      INT           NOT NULL,
    payment_date    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    amount_paid     NUMERIC(12,2) NOT NULL CHECK (amount_paid > 0),
    payment_mode    VARCHAR(30)   NOT NULL
                        CHECK (payment_mode IN
                            ('Cash','UPI','Card','NetBanking',
                             'Cheque','Insurance','Wallet')),
    transaction_ref VARCHAR(100),
    received_by     INT,                        -- FK to staff
    notes           TEXT,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 29. AUDIT LOGS
-- =============================================================================
CREATE TABLE audit_logs (
    log_id          BIGSERIAL PRIMARY KEY,
    table_name      VARCHAR(60)  NOT NULL,
    operation       VARCHAR(10)  NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
    record_id       INT,
    old_data        JSONB,
    new_data        JSONB,
    changed_by      VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    changed_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE audit_logs IS 'Row-level change tracking for sensitive tables.';

-- =============================================================================
-- 30. INVENTORY LOGS
-- =============================================================================
CREATE TABLE inventory_logs (
    log_id          BIGSERIAL PRIMARY KEY,
    inventory_id    INT          NOT NULL,
    medicine_id     INT          NOT NULL,
    action_type     VARCHAR(20)  NOT NULL CHECK (action_type IN ('Stock-In','Stock-Out','Expired','Adjustment')),
    quantity_change INT          NOT NULL,
    quantity_before INT          NOT NULL,
    quantity_after  INT          NOT NULL,
    reference_id    INT,                        -- prescription_id or receipt id
    reference_type  VARCHAR(30),
    performed_by    VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    performed_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    notes           TEXT
);

COMMENT ON TABLE inventory_logs IS 'Full audit trail for medicine inventory movements.';

-- =============================================================================
-- AGE TRIGGER: keep patients.age current on INSERT and UPDATE of date_of_birth
-- (AGE() is not immutable so cannot be used in a GENERATED ALWAYS column)
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_patients_set_age()
RETURNS TRIGGER AS $$
BEGIN
    NEW.age := DATE_PART('year', AGE(NEW.date_of_birth))::INT;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patients_set_age
    BEFORE INSERT OR UPDATE OF date_of_birth ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_patients_set_age();

-- =============================================================================
-- Add self-referential FK: departments.head_doctor_id -> doctors.doctor_id
-- (done after both tables exist)
-- =============================================================================
ALTER TABLE departments
    ADD CONSTRAINT fk_dept_head_doctor
    FOREIGN KEY (head_doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE SET NULL;

-- =============================================================================
SELECT 'create_tables.sql completed successfully.' AS status;