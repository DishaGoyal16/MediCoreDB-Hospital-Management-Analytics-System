-- =============================================================================
-- FILE: schema/procedures.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: Stored procedures for core hospital workflows.
--              Run AFTER triggers.sql.
-- =============================================================================

-- =============================================================================
-- 1. BOOK APPOINTMENT
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_book_appointment(
    OUT p_appointment_id INT,
    p_branch_id          INT,
    p_patient_id         INT,
    p_doctor_id          INT,
    p_dept_id            INT,
    p_appt_date          DATE,
    p_appt_time          TIME,
    p_appt_type          VARCHAR DEFAULT 'OPD',
    p_reason             TEXT    DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_patient_exists  BOOLEAN;
    v_doctor_active   BOOLEAN;
    v_max_slots       INT;
    v_booked_slots    INT;
BEGIN
    -- Validate patient
    SELECT EXISTS(SELECT 1 FROM patients WHERE patient_id = p_patient_id AND is_active = TRUE)
    INTO v_patient_exists;
    IF NOT v_patient_exists THEN
        RAISE EXCEPTION 'Patient ID % not found or inactive.', p_patient_id;
    END IF;

    -- Validate doctor
    SELECT is_active INTO v_doctor_active FROM doctors WHERE doctor_id = p_doctor_id;
    IF NOT FOUND OR NOT v_doctor_active THEN
        RAISE EXCEPTION 'Doctor ID % not found or inactive.', p_doctor_id;
    END IF;

    -- Check doctor slot capacity for the day
    SELECT COALESCE(MAX(ds.max_appointments), 20)
    INTO v_max_slots
    FROM doctor_schedules ds
    WHERE ds.doctor_id   = p_doctor_id
      AND ds.day_of_week = EXTRACT(DOW FROM p_appt_date)::INT
      AND ds.is_active   = TRUE;

    SELECT COUNT(*) INTO v_booked_slots
    FROM appointments
    WHERE doctor_id        = p_doctor_id
      AND appointment_date = p_appt_date
      AND status IN ('Scheduled', 'Confirmed');

    IF v_booked_slots >= v_max_slots THEN
        RAISE EXCEPTION 'Doctor % is fully booked on %. Max slots: %.',
            p_doctor_id, p_appt_date, v_max_slots;
    END IF;

    -- Insert appointment (double-booking check handled by trigger)
    INSERT INTO appointments(
        branch_id, patient_id, doctor_id, dept_id,
        appointment_date, appointment_time, appointment_type,
        status, reason
    )
    VALUES (
        p_branch_id, p_patient_id, p_doctor_id, p_dept_id,
        p_appt_date, p_appt_time, p_appt_type,
        'Scheduled', p_reason
    )
    RETURNING appointment_id INTO p_appointment_id;

    RAISE NOTICE 'Appointment % booked successfully for Patient % with Doctor % on % at %.',
        p_appointment_id, p_patient_id, p_doctor_id, p_appt_date, p_appt_time;
END;
$$;

COMMENT ON PROCEDURE sp_book_appointment IS
    'Books an OPD/Emergency appointment; validates capacity and triggers double-booking check.';

-- =============================================================================
-- 2. CANCEL APPOINTMENT
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_cancel_appointment(
    p_appointment_id INT,
    p_reason         TEXT DEFAULT 'Cancelled by request'
)
LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR;
BEGIN
    SELECT status INTO v_status
    FROM appointments
    WHERE appointment_id = p_appointment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment ID % not found.', p_appointment_id;
    END IF;

    IF v_status IN ('Completed', 'Cancelled') THEN
        RAISE EXCEPTION 'Cannot cancel appointment % (current status: %).', p_appointment_id, v_status;
    END IF;

    UPDATE appointments
    SET status = 'Cancelled', notes = p_reason, updated_at = NOW()
    WHERE appointment_id = p_appointment_id;

    RAISE NOTICE 'Appointment % cancelled.', p_appointment_id;
END;
$$;

-- =============================================================================
-- 3. ADMIT PATIENT
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_admit_patient(
    OUT p_admission_id   INT,
    p_patient_id         INT,
    p_doctor_id          INT,
    p_branch_id          INT,
    p_bed_id             INT,
    p_admission_type     VARCHAR DEFAULT 'Regular',
    p_diagnosis          TEXT    DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Bed availability check is handled by trigger trg_check_bed_availability

    INSERT INTO admissions(
        patient_id, doctor_id, branch_id, bed_id,
        admission_date, admission_type, diagnosis, status
    )
    VALUES (
        p_patient_id, p_doctor_id, p_branch_id, p_bed_id,
        NOW(), p_admission_type, p_diagnosis, 'Active'
    )
    RETURNING admission_id INTO p_admission_id;

    RAISE NOTICE 'Patient % admitted. Admission ID: %, Bed: %.',
        p_patient_id, p_admission_id, p_bed_id;
END;
$$;

-- =============================================================================
-- 4. DISCHARGE PATIENT
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_discharge_patient(
    OUT p_discharge_id   INT,
    OUT p_bill_id        INT,
    p_admission_id       INT,
    p_discharge_type     VARCHAR DEFAULT 'Normal',
    p_notes              TEXT    DEFAULT NULL,
    p_follow_up_date     DATE    DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_patient_id INT;
    v_doctor_id  INT;
    v_status     VARCHAR;
BEGIN
    SELECT patient_id, doctor_id, status
    INTO v_patient_id, v_doctor_id, v_status
    FROM admissions
    WHERE admission_id = p_admission_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Admission ID % not found.', p_admission_id;
    END IF;
    IF v_status != 'Active' THEN
        RAISE EXCEPTION 'Admission % is not active (status: %).', p_admission_id, v_status;
    END IF;

    BEGIN
        -- Insert discharge record (triggers bed release + bill generation)
        INSERT INTO discharges(
            admission_id, patient_id, doctor_id,
            discharge_date, discharge_type, discharge_notes, follow_up_date
        )
        VALUES (
            p_admission_id, v_patient_id, v_doctor_id,
            NOW(), p_discharge_type, p_notes, p_follow_up_date
        )
        RETURNING discharge_id INTO p_discharge_id;

        -- Update admission status (triggers bed release)
        UPDATE admissions
        SET status = 'Discharged', updated_at = NOW()
        WHERE admission_id = p_admission_id;

        -- Get the auto-generated bill_id
        SELECT bill_id INTO p_bill_id
        FROM billing
        WHERE admission_id = p_admission_id
        ORDER BY created_at DESC LIMIT 1;

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Discharge failed: %', SQLERRM;
    END;

    RAISE NOTICE 'Patient % discharged. Discharge ID: %, Bill ID: %.',
        v_patient_id, p_discharge_id, p_bill_id;
END;
$$;

-- =============================================================================
-- 5. ALLOCATE BED (transfer patient to a different bed)
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_transfer_bed(
    p_admission_id  INT,
    p_new_bed_id    INT,
    p_notes         TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_old_bed_id INT;
    v_new_status VARCHAR;
BEGIN
    SELECT bed_id INTO v_old_bed_id
    FROM admissions WHERE admission_id = p_admission_id AND status = 'Active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active admission % not found.', p_admission_id;
    END IF;

    SELECT status INTO v_new_status FROM beds WHERE bed_id = p_new_bed_id;

    IF v_new_status != 'Available' THEN
        RAISE EXCEPTION 'Target bed % is not available (status: %).', p_new_bed_id, v_new_status;
    END IF;

    -- Release old bed
    UPDATE beds SET status = 'Available', updated_at = NOW()
    WHERE bed_id = v_old_bed_id;

    UPDATE bed_allocations SET released_on = NOW()
    WHERE admission_id = p_admission_id AND released_on IS NULL;

    -- Assign new bed
    UPDATE beds SET status = 'Occupied', updated_at = NOW()
    WHERE bed_id = p_new_bed_id;

    UPDATE admissions SET bed_id = p_new_bed_id, updated_at = NOW()
    WHERE admission_id = p_admission_id;

    INSERT INTO bed_allocations(bed_id, patient_id, admission_id, allocated_on, notes)
    SELECT p_new_bed_id, patient_id, p_admission_id, NOW(), p_notes
    FROM admissions WHERE admission_id = p_admission_id;

    RAISE NOTICE 'Admission % transferred from bed % to bed %.', p_admission_id, v_old_bed_id, p_new_bed_id;
END;
$$;

-- =============================================================================
-- 6. PAY BILL
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_pay_bill(
    OUT p_payment_id  INT,
    p_bill_id         INT,
    p_amount          NUMERIC,
    p_mode            VARCHAR DEFAULT 'Cash',
    p_received_by     INT     DEFAULT NULL,
    p_txn_ref         VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total     NUMERIC;
    v_paid_so_far NUMERIC;
    v_remaining NUMERIC;
BEGIN
    SELECT total_amount INTO v_total FROM billing WHERE bill_id = p_bill_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Bill % not found.', p_bill_id; END IF;

    SELECT COALESCE(SUM(amount_paid), 0) INTO v_paid_so_far
    FROM payments WHERE bill_id = p_bill_id;

    v_remaining := v_total - v_paid_so_far;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be positive.';
    END IF;
    IF p_amount > v_remaining + 0.01 THEN
        RAISE EXCEPTION 'Payment % exceeds remaining balance % for bill %.', p_amount, v_remaining, p_bill_id;
    END IF;

    INSERT INTO payments(bill_id, patient_id, amount_paid, payment_mode, transaction_ref, received_by)
    SELECT p_bill_id, patient_id, p_amount, p_mode, p_txn_ref, p_received_by
    FROM billing WHERE bill_id = p_bill_id
    RETURNING payment_id INTO p_payment_id;

    RAISE NOTICE 'Payment % recorded for bill %. Amount: %. Remaining: %.',
        p_payment_id, p_bill_id, p_amount, v_remaining - p_amount;
END;
$$;

-- =============================================================================
-- 7. ADD MEDICINE TO CATALOGUE
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_add_medicine(
    OUT p_medicine_id  INT,
    p_name             VARCHAR,
    p_generic          VARCHAR,
    p_category         VARCHAR,
    p_unit             VARCHAR DEFAULT 'tablet',
    p_price            NUMERIC DEFAULT 0,
    p_req_rx           BOOLEAN DEFAULT TRUE,
    p_manufacturer     VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO medicines(medicine_name, generic_name, category, unit,
                          unit_price, requires_prescription, manufacturer)
    VALUES (p_name, p_generic, p_category, p_unit, p_price, p_req_rx, p_manufacturer)
    RETURNING medicine_id INTO p_medicine_id;

    RAISE NOTICE 'Medicine % added with ID %.', p_name, p_medicine_id;
END;
$$;

-- =============================================================================
-- 8. REFILL INVENTORY
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_refill_inventory(
    OUT p_inventory_id   INT,
    p_medicine_id        INT,
    p_branch_id          INT,
    p_supplier_id        INT,
    p_batch              VARCHAR,
    p_qty                INT,
    p_purchase_price     NUMERIC,
    p_expiry_date        DATE,
    p_reorder_lvl        INT DEFAULT 50
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_qty <= 0 THEN
        RAISE EXCEPTION 'Quantity must be positive.';
    END IF;
    IF p_expiry_date <= CURRENT_DATE THEN
        RAISE EXCEPTION 'Expiry date must be in the future.';
    END IF;

    -- Upsert: if same batch exists, add qty; else insert new row
    INSERT INTO medicine_inventory(
        medicine_id, branch_id, supplier_id, batch_number,
        quantity, reorder_level, expiry_date, purchase_price, received_on
    )
    VALUES (
        p_medicine_id, p_branch_id, p_supplier_id, p_batch,
        p_qty, p_reorder_lvl, p_expiry_date, p_purchase_price, CURRENT_DATE
    )
    ON CONFLICT (medicine_id, branch_id, batch_number)
    DO UPDATE SET
        quantity      = medicine_inventory.quantity + EXCLUDED.quantity,
        updated_at    = NOW()
    RETURNING inventory_id INTO p_inventory_id;

    RAISE NOTICE 'Inventory updated. ID: %, Qty added: %.', p_inventory_id, p_qty;
END;
$$;

-- =============================================================================
-- 9. GENERATE DAILY REPORT (summary, returns as table)
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_daily_report(p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    metric      TEXT,
    count_value BIGINT,
    amount_value NUMERIC
) AS $$
BEGIN
    RETURN QUERY

    SELECT 'Total Appointments'::TEXT,
           COUNT(*)::BIGINT, NULL::NUMERIC
    FROM appointments WHERE appointment_date = p_date

    UNION ALL
    SELECT 'Completed Appointments',
           COUNT(*)::BIGINT, NULL
    FROM appointments WHERE appointment_date = p_date AND status = 'Completed'

    UNION ALL
    SELECT 'New Admissions',
           COUNT(*)::BIGINT, NULL
    FROM admissions WHERE admission_date::DATE = p_date

    UNION ALL
    SELECT 'Discharges',
           COUNT(*)::BIGINT, NULL
    FROM discharges WHERE discharge_date::DATE = p_date

    UNION ALL
    SELECT 'Bills Generated',
           COUNT(*)::BIGINT, SUM(total_amount)
    FROM billing WHERE bill_date = p_date

    UNION ALL
    SELECT 'Payments Received',
           COUNT(*)::BIGINT, SUM(amount_paid)
    FROM payments WHERE payment_date::DATE = p_date

    UNION ALL
    SELECT 'Available Beds',
           COUNT(*)::BIGINT, NULL
    FROM beds WHERE status = 'Available'

    UNION ALL
    SELECT 'Occupied Beds',
           COUNT(*)::BIGINT, NULL
    FROM beds WHERE status = 'Occupied';
END;
$$ LANGUAGE plpgsql STABLE;

SELECT 'procedures.sql completed successfully.' AS status;
