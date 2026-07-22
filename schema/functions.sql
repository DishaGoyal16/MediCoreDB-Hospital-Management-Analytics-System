-- =============================================================================
-- FILE: schema/functions.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: PL/pgSQL scalar and table-valued functions.
--              Run AFTER indexes.sql and BEFORE triggers.sql.
-- =============================================================================

-- =============================================================================
-- 1. DOCTOR UTILIZATION RATE
--    Returns percentage of available slots that were booked for a doctor
--    in a given month.
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_doctor_utilization(
    p_doctor_id   INT,
    p_year        INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    p_month       INT DEFAULT EXTRACT(MONTH FROM CURRENT_DATE)::INT
)
RETURNS NUMERIC AS $$
DECLARE
    v_booked    INT;
    v_available INT;
    v_util      NUMERIC;
BEGIN
    -- Count completed/confirmed appointments
    SELECT COUNT(*)
    INTO v_booked
    FROM public.appointments
    WHERE doctor_id = p_doctor_id
      AND EXTRACT(YEAR  FROM appointment_date) = p_year
      AND EXTRACT(MONTH FROM appointment_date) = p_month
      AND status IN ('Completed', 'Confirmed');

    -- Estimated available slots (schedule × working days in month)
    SELECT COALESCE(SUM(ds.max_appointments), 1) * 4   -- ~4 weeks
    INTO v_available
    FROM public.doctor_schedules ds
    WHERE ds.doctor_id = p_doctor_id
      AND ds.is_active = TRUE;

    IF v_available = 0 THEN RETURN 0; END IF;

    v_util := ROUND((v_booked::NUMERIC / v_available) * 100, 2);
    RETURN LEAST(v_util, 100);  -- cap at 100%
END;
$$ LANGUAGE plpgsql STABLE
   SET search_path = public;

COMMENT ON FUNCTION fn_doctor_utilization IS
    'Returns doctor booking utilization % for a given year-month (0–100).';

-- =============================================================================
-- 2. MONTHLY REVENUE
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_monthly_revenue(
    p_branch_id INT DEFAULT NULL,
    p_year      INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    p_month     INT DEFAULT EXTRACT(MONTH FROM CURRENT_DATE)::INT
)
RETURNS NUMERIC AS $$
DECLARE
    v_revenue NUMERIC;
BEGIN
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_revenue
    FROM billing
    WHERE EXTRACT(YEAR  FROM bill_date) = p_year
      AND EXTRACT(MONTH FROM bill_date) = p_month
      AND (p_branch_id IS NULL OR branch_id = p_branch_id)
      AND payment_status IN ('Paid', 'Partial', 'Insurance');
    RETURN v_revenue;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 3. PATIENT COUNT
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_patient_count(
    p_branch_id INT DEFAULT NULL,
    p_active    BOOLEAN DEFAULT TRUE
)
RETURNS BIGINT AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM patients
        WHERE (p_branch_id IS NULL OR branch_id = p_branch_id)
          AND is_active = p_active
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 4. MEDICINE STOCK STATUS
--    Returns 'OK', 'Low', 'Critical', or 'Out of Stock'
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_medicine_stock_status(
    p_medicine_id INT,
    p_branch_id   INT
)
RETURNS VARCHAR AS $$
DECLARE
    v_qty   INT;
    v_reorder INT;
BEGIN
    SELECT COALESCE(SUM(quantity), 0),
           COALESCE(MAX(reorder_level), 50)
    INTO v_qty, v_reorder
    FROM medicine_inventory
    WHERE medicine_id = p_medicine_id
      AND branch_id   = p_branch_id
      AND is_active   = TRUE
      AND expiry_date > CURRENT_DATE;

    IF    v_qty = 0                        THEN RETURN 'Out of Stock';
    ELSIF v_qty <= (v_reorder * 0.5)::INT  THEN RETURN 'Critical';
    ELSIF v_qty <= v_reorder               THEN RETURN 'Low';
    ELSE                                        RETURN 'OK';
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 5. AVERAGE LENGTH OF STAY (days) for a department or hospital
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_avg_length_of_stay(
    p_dept_id   INT DEFAULT NULL,
    p_year      INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT
)
RETURNS NUMERIC AS $$
DECLARE
    v_avg NUMERIC;
BEGIN
    SELECT ROUND(AVG(
               EXTRACT(EPOCH FROM (d.discharge_date - a.admission_date)) / 86400.0
           ), 2)
    INTO v_avg
    FROM discharges d
    JOIN admissions a ON a.admission_id = d.admission_id
    JOIN beds b       ON b.bed_id       = a.bed_id
    JOIN rooms r      ON r.room_id      = b.room_id
    WHERE EXTRACT(YEAR FROM d.discharge_date) = p_year
      AND (p_dept_id IS NULL OR r.dept_id = p_dept_id);
    RETURN COALESCE(v_avg, 0);
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 6. BED OCCUPANCY RATE (%) for a branch
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_bed_occupancy_rate(p_branch_id INT DEFAULT NULL)
RETURNS NUMERIC AS $$
DECLARE
    v_total    INT;
    v_occupied INT;
BEGIN
    SELECT COUNT(*),
           COUNT(*) FILTER (WHERE status = 'Occupied')
    INTO v_total, v_occupied
    FROM beds b
    JOIN rooms r ON r.room_id = b.room_id
    WHERE (p_branch_id IS NULL OR r.branch_id = p_branch_id);

    IF v_total = 0 THEN RETURN 0; END IF;
    RETURN ROUND((v_occupied::NUMERIC / v_total) * 100, 2);
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 7. DEPARTMENT PERFORMANCE SCORE
--    Composite score: appointments + revenue + patient count (normalized)
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_dept_performance(
    p_dept_id INT,
    p_year    INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT
)
RETURNS TABLE(
    metric          TEXT,
    value           NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Appointments'::TEXT,
           COUNT(a.appointment_id)::NUMERIC
    FROM appointments a
    WHERE a.dept_id = p_dept_id
      AND EXTRACT(YEAR FROM a.appointment_date) = p_year

    UNION ALL

    SELECT 'Completed Appointments',
           COUNT(*)::NUMERIC
    FROM appointments
    WHERE dept_id = p_dept_id
      AND EXTRACT(YEAR FROM appointment_date) = p_year
      AND status = 'Completed'

    UNION ALL

    SELECT 'Revenue Generated',
           COALESCE(SUM(b.total_amount), 0)
    FROM billing b
    JOIN appointments ap ON ap.appointment_id = b.appointment_id
    WHERE ap.dept_id = p_dept_id
      AND EXTRACT(YEAR FROM b.bill_date) = p_year

    UNION ALL

    SELECT 'Unique Patients',
           COUNT(DISTINCT a.patient_id)::NUMERIC
    FROM appointments a
    WHERE a.dept_id = p_dept_id
      AND EXTRACT(YEAR FROM a.appointment_date) = p_year;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 8. INSURANCE CLAIM AMOUNT for a patient on a bill
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_insurance_claim(
    p_patient_id INT,
    p_bill_id    INT
)
RETURNS NUMERIC AS $$
DECLARE
    v_total     NUMERIC;
    v_coverage  NUMERIC;
    v_deduct    NUMERIC;
    v_claim     NUMERIC;
BEGIN
    SELECT b.total_amount
    INTO v_total
    FROM billing b
    WHERE b.bill_id = p_bill_id AND b.patient_id = p_patient_id;

    SELECT COALESCE(i.coverage_amount, 0),
           COALESCE(i.deductible, 0)
    INTO v_coverage, v_deduct
    FROM insurance i
    JOIN patients p ON p.insurance_id = i.insurance_id
    WHERE p.patient_id = p_patient_id
      AND i.is_active = TRUE
      AND i.valid_to >= CURRENT_DATE
    LIMIT 1;

    v_claim := LEAST(v_total - v_deduct, v_coverage);
    RETURN GREATEST(v_claim, 0);
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 9. REVENUE BY MONTH — returns table (used in views)
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_revenue_by_month(
    p_branch_id INT DEFAULT NULL,
    p_year      INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT
)
RETURNS TABLE(
    month_num    INT,
    month_name   TEXT,
    revenue      NUMERIC,
    bill_count   BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        EXTRACT(MONTH FROM bill_date)::INT                         AS month_num,
        TO_CHAR(bill_date, 'Mon YYYY')                            AS month_name,
        ROUND(SUM(total_amount), 2)                               AS revenue,
        COUNT(*)                                                   AS bill_count
    FROM billing
    WHERE EXTRACT(YEAR FROM bill_date) = p_year
      AND (p_branch_id IS NULL OR branch_id = p_branch_id)
      AND payment_status IN ('Paid', 'Partial', 'Insurance')
    GROUP BY EXTRACT(MONTH FROM bill_date), TO_CHAR(bill_date, 'Mon YYYY')
    ORDER BY month_num;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 10. TRIGGER HELPER: updated_at auto-update
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fn_set_updated_at IS
    'Generic trigger function to auto-update updated_at timestamp.';

-- =============================================================================
-- 11. TRIGGER HELPER: audit log writer
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_write_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs(table_name, operation, record_id, old_data, changed_by)
        VALUES (TG_TABLE_NAME, 'DELETE',
                (row_to_json(OLD) ->> 'id')::INT,
                row_to_json(OLD)::JSONB,
                CURRENT_USER);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs(table_name, operation, record_id, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, 'UPDATE',
                (row_to_json(NEW) ->> 'id')::INT,
                row_to_json(OLD)::JSONB,
                row_to_json(NEW)::JSONB,
                CURRENT_USER);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs(table_name, operation, record_id, new_data, changed_by)
        VALUES (TG_TABLE_NAME, 'INSERT',
                (row_to_json(NEW) ->> 'id')::INT,
                row_to_json(NEW)::JSONB,
                CURRENT_USER);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT 'functions.sql completed successfully.' AS status;
