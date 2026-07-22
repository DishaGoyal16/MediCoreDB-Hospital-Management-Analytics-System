-- =============================================================================
-- FILE: schema/views.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: Business-friendly views and materialized views.
--              Run AFTER procedures.sql.
-- =============================================================================

-- =============================================================================
-- 1. DOCTOR DASHBOARD VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_doctor_dashboard AS
SELECT
    d.doctor_id,
    d.full_name                                                AS doctor_name,
    d.registration_number,
    dep.dept_name,
    hb.branch_name,
    d.employment_type,
    d.consultation_fee,
    d.experience_years,
    COUNT(DISTINCT a.appointment_id)                          AS total_appointments,
    COUNT(DISTINCT a.appointment_id) FILTER (
        WHERE a.appointment_date = CURRENT_DATE
    )                                                          AS today_appointments,
    COUNT(DISTINCT a.appointment_id) FILTER (
        WHERE a.status = 'Completed'
    )                                                          AS completed_appointments,
    COUNT(DISTINCT a.appointment_id) FILTER (
        WHERE a.status IN ('Scheduled','Confirmed')
        AND   a.appointment_date >= CURRENT_DATE
    )                                                          AS upcoming_appointments,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (dis.discharge_date - adm.admission_date)) / 86400.0
    ), 1)                                                      AS avg_patient_stay_days,
    fn_doctor_utilization(d.doctor_id)                        AS utilization_pct_this_month
FROM doctors d
JOIN departments    dep ON dep.dept_id   = d.dept_id
JOIN hospital_branches hb ON hb.branch_id = d.branch_id
LEFT JOIN appointments   a   ON a.doctor_id   = d.doctor_id
LEFT JOIN admissions     adm ON adm.doctor_id = d.doctor_id
LEFT JOIN discharges     dis ON dis.admission_id = adm.admission_id
WHERE d.is_active = TRUE
GROUP BY d.doctor_id, d.full_name, d.registration_number,
         dep.dept_name, hb.branch_name, d.employment_type,
         d.consultation_fee, d.experience_years;

COMMENT ON VIEW vw_doctor_dashboard IS 'Per-doctor KPI overview for administrative dashboards.';

-- =============================================================================
-- 2. PATIENT SUMMARY VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_patient_summary AS
SELECT
    p.patient_id,
    p.full_name                                               AS patient_name,
    p.gender,
    p.age,
    p.blood_group,
    p.phone,
    hb.branch_name,
    p.registration_date,
    COUNT(DISTINCT a.appointment_id)                         AS total_appointments,
    COUNT(DISTINCT adm.admission_id)                         AS total_admissions,
    MAX(a.appointment_date)                                  AS last_appointment_date,
    MAX(adm.admission_date)                                  AS last_admission_date,
    COUNT(DISTINCT b.bill_id)                                AS total_bills,
    COALESCE(SUM(b.total_amount), 0)                         AS total_billed,
    COALESCE(SUM(py.amount_paid), 0)                         AS total_paid,
    COALESCE(SUM(b.total_amount), 0) -
        COALESCE(SUM(py.amount_paid), 0)                     AS balance_due,
    ins.provider_name                                        AS insurance_provider,
    ins.policy_number
FROM patients p
JOIN hospital_branches hb ON hb.branch_id = p.branch_id
LEFT JOIN appointments a   ON a.patient_id = p.patient_id
LEFT JOIN admissions   adm ON adm.patient_id = p.patient_id
LEFT JOIN billing      b   ON b.patient_id = p.patient_id
LEFT JOIN payments     py  ON py.bill_id   = b.bill_id
LEFT JOIN insurance    ins ON ins.insurance_id = p.insurance_id
GROUP BY p.patient_id, p.full_name, p.gender, p.age, p.blood_group,
         p.phone, hb.branch_name, p.registration_date,
         ins.provider_name, ins.policy_number;

-- =============================================================================
-- 3. BED AVAILABILITY VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_bed_availability AS
SELECT
    hb.branch_name,
    r.room_number,
    r.room_type,
    r.floor_no,
    dep.dept_name,
    b.bed_id,
    b.bed_number,
    b.bed_type,
    b.status,
    r.daily_charge,
    CASE WHEN b.status = 'Occupied' THEN
        (SELECT p.full_name FROM admissions adm
         JOIN patients p ON p.patient_id = adm.patient_id
         WHERE adm.bed_id = b.bed_id AND adm.status = 'Active'
         LIMIT 1)
    ELSE NULL END                                             AS current_patient
FROM beds b
JOIN rooms r            ON r.room_id   = b.room_id
JOIN departments   dep  ON dep.dept_id = r.dept_id
JOIN hospital_branches hb ON hb.branch_id = r.branch_id
ORDER BY hb.branch_name, r.room_number, b.bed_number;

-- =============================================================================
-- 4. TODAY'S APPOINTMENTS VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_todays_appointments AS
SELECT
    a.appointment_id,
    a.appointment_time,
    p.full_name                                               AS patient_name,
    p.phone                                                   AS patient_phone,
    p.age,
    d.full_name                                               AS doctor_name,
    dep.dept_name,
    a.appointment_type,
    a.status,
    a.reason
FROM appointments a
JOIN patients        p   ON p.patient_id = a.patient_id
JOIN doctors         d   ON d.doctor_id  = a.doctor_id
JOIN departments     dep ON dep.dept_id  = a.dept_id
WHERE a.appointment_date = CURRENT_DATE
ORDER BY a.appointment_time;

-- =============================================================================
-- 5. REVENUE DASHBOARD VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_revenue_dashboard AS
SELECT
    hb.branch_name,
    EXTRACT(YEAR  FROM b.bill_date)::INT                     AS year,
    EXTRACT(MONTH FROM b.bill_date)::INT                     AS month,
    TO_CHAR(b.bill_date, 'Mon YYYY')                         AS month_label,
    COUNT(b.bill_id)                                         AS bill_count,
    ROUND(SUM(b.subtotal), 2)                                AS gross_revenue,
    ROUND(SUM(b.discount_amount), 2)                         AS total_discounts,
    ROUND(SUM(b.tax_amount), 2)                              AS total_tax,
    ROUND(SUM(b.total_amount), 2)                            AS net_revenue,
    ROUND(SUM(b.insurance_covered), 2)                       AS insurance_covered,
    ROUND(SUM(py.amount_paid), 2)                            AS collected,
    ROUND(SUM(b.total_amount) - COALESCE(SUM(py.amount_paid), 0), 2) AS outstanding,
    COUNT(DISTINCT b.patient_id)                             AS unique_patients
FROM billing b
JOIN hospital_branches hb ON hb.branch_id = b.branch_id
LEFT JOIN payments py ON py.bill_id = b.bill_id
GROUP BY hb.branch_name, EXTRACT(YEAR FROM b.bill_date),
         EXTRACT(MONTH FROM b.bill_date), TO_CHAR(b.bill_date, 'Mon YYYY')
ORDER BY year DESC, month DESC;

-- =============================================================================
-- 6. MEDICINE INVENTORY VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_medicine_inventory AS
SELECT
    m.medicine_id,
    m.medicine_name,
    m.generic_name,
    m.category,
    m.unit,
    m.unit_price,
    hb.branch_name,
    s.supplier_name,
    mi.batch_number,
    mi.quantity                                              AS qty_in_stock,
    mi.reorder_level,
    CASE
        WHEN mi.quantity = 0             THEN 'Out of Stock'
        WHEN mi.quantity <= mi.reorder_level * 0.5 THEN 'Critical'
        WHEN mi.quantity <= mi.reorder_level       THEN 'Low'
        ELSE                                          'OK'
    END                                                      AS stock_status,
    mi.expiry_date,
    CASE
        WHEN mi.expiry_date <= CURRENT_DATE           THEN 'Expired'
        WHEN mi.expiry_date <= CURRENT_DATE + 30      THEN 'Expiring Soon'
        ELSE                                            'Valid'
    END                                                      AS expiry_status,
    mi.purchase_price,
    mi.received_on
FROM medicine_inventory mi
JOIN medicines         m  ON m.medicine_id = mi.medicine_id
JOIN hospital_branches hb ON hb.branch_id = mi.branch_id
LEFT JOIN suppliers    s  ON s.supplier_id = mi.supplier_id
WHERE mi.is_active = TRUE
ORDER BY hb.branch_name, stock_status, m.medicine_name;

-- =============================================================================
-- 7. DEPARTMENT STATISTICS VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_department_stats AS
SELECT
    dep.dept_id,
    dep.dept_name,
    hb.branch_name,
    d_head.full_name                                         AS dept_head,
    COUNT(DISTINCT doc.doctor_id)                            AS doctor_count,
    COUNT(DISTINCT n.nurse_id)                               AS nurse_count,
    COUNT(DISTINCT r.room_id)                                AS room_count,
    COUNT(DISTINCT b.bed_id)                                 AS total_beds,
    COUNT(DISTINCT b.bed_id) FILTER (WHERE b.status = 'Available') AS available_beds,
    COUNT(DISTINCT a.appointment_id)                         AS total_appointments,
    COUNT(DISTINCT a.appointment_id) FILTER (
        WHERE a.appointment_date = CURRENT_DATE
    )                                                        AS today_appointments,
    fn_bed_occupancy_rate(hb.branch_id)                     AS branch_occupancy_rate_pct
FROM departments dep
JOIN hospital_branches hb ON hb.branch_id = dep.branch_id
LEFT JOIN doctors      doc    ON doc.dept_id  = dep.dept_id AND doc.is_active = TRUE
LEFT JOIN doctors      d_head ON d_head.doctor_id = dep.head_doctor_id
LEFT JOIN nurses       n      ON n.dept_id    = dep.dept_id AND n.is_active   = TRUE
LEFT JOIN rooms        r      ON r.dept_id    = dep.dept_id
LEFT JOIN beds         b      ON b.room_id    = r.room_id
LEFT JOIN appointments a      ON a.dept_id    = dep.dept_id
GROUP BY dep.dept_id, dep.dept_name, hb.branch_name, d_head.full_name, hb.branch_id;

-- =============================================================================
-- 8. TOP DOCTORS BY APPOINTMENTS (current year)
-- =============================================================================
CREATE OR REPLACE VIEW vw_top_doctors AS
SELECT
    d.doctor_id,
    d.full_name                                              AS doctor_name,
    dep.dept_name,
    hb.branch_name,
    COUNT(a.appointment_id)                                  AS total_appointments,
    COUNT(a.appointment_id) FILTER (WHERE a.status = 'Completed') AS completed,
    ROUND(COUNT(a.appointment_id) FILTER (WHERE a.status = 'Completed')
          ::NUMERIC / NULLIF(COUNT(a.appointment_id), 0) * 100, 1) AS completion_rate_pct,
    COALESCE(SUM(b.total_amount), 0)                         AS revenue_generated,
    RANK() OVER (ORDER BY COUNT(a.appointment_id) DESC)      AS rank_by_appointments,
    RANK() OVER (ORDER BY COALESCE(SUM(b.total_amount), 0) DESC) AS rank_by_revenue
FROM doctors d
JOIN departments       dep ON dep.dept_id   = d.dept_id
JOIN hospital_branches hb  ON hb.branch_id  = d.branch_id
LEFT JOIN appointments a   ON a.doctor_id   = d.doctor_id
    AND EXTRACT(YEAR FROM a.appointment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN billing b ON b.appointment_id = a.appointment_id
WHERE d.is_active = TRUE
GROUP BY d.doctor_id, d.full_name, dep.dept_name, hb.branch_name
ORDER BY total_appointments DESC;

-- =============================================================================
-- 9. TOP MEDICINES BY PRESCRIPTION COUNT
-- =============================================================================
CREATE OR REPLACE VIEW vw_top_medicines AS
SELECT
    m.medicine_id,
    m.medicine_name,
    m.generic_name,
    m.category,
    m.unit_price,
    COUNT(px.prescription_id)                                AS times_prescribed,
    SUM(px.quantity)                                         AS total_qty_dispensed,
    ROUND(SUM(px.quantity * m.unit_price), 2)                AS total_revenue,
    RANK() OVER (ORDER BY COUNT(px.prescription_id) DESC)   AS rank_by_prescriptions
FROM medicines m
LEFT JOIN prescriptions px ON px.medicine_id = m.medicine_id
GROUP BY m.medicine_id, m.medicine_name, m.generic_name, m.category, m.unit_price
ORDER BY times_prescribed DESC;

-- =============================================================================
-- 10. ACTIVE ADMISSIONS VIEW
-- =============================================================================
CREATE OR REPLACE VIEW vw_active_admissions AS
SELECT
    adm.admission_id,
    p.full_name                                              AS patient_name,
    p.age,
    p.blood_group,
    p.phone                                                  AS patient_phone,
    d.full_name                                              AS attending_doctor,
    dep.dept_name,
    hb.branch_name,
    r.room_number,
    r.room_type,
    b.bed_number,
    adm.admission_date,
    DATE_PART('day', NOW() - adm.admission_date)::INT       AS days_admitted,
    adm.admission_type,
    adm.diagnosis
FROM admissions adm
JOIN patients        p   ON p.patient_id   = adm.patient_id
JOIN doctors         d   ON d.doctor_id    = adm.doctor_id
JOIN departments     dep ON dep.dept_id    = d.dept_id
JOIN hospital_branches hb ON hb.branch_id = adm.branch_id
JOIN beds            b   ON b.bed_id       = adm.bed_id
JOIN rooms           r   ON r.room_id      = b.room_id
WHERE adm.status = 'Active'
ORDER BY adm.admission_date;

-- =============================================================================
-- 11. MATERIALIZED VIEW: Monthly Revenue Summary (refresh on demand)
-- =============================================================================
CREATE MATERIALIZED VIEW mvw_monthly_revenue AS
SELECT
    hb.branch_id,
    hb.branch_name,
    EXTRACT(YEAR  FROM b.bill_date)::INT                     AS revenue_year,
    EXTRACT(MONTH FROM b.bill_date)::INT                     AS revenue_month,
    TO_CHAR(b.bill_date, 'Month YYYY')                       AS period_label,
    COUNT(b.bill_id)                                         AS bill_count,
    ROUND(SUM(b.total_amount), 2)                            AS total_revenue,
    ROUND(AVG(b.total_amount), 2)                            AS avg_bill_amount,
    COUNT(DISTINCT b.patient_id)                             AS unique_patients,
    ROUND(SUM(b.insurance_covered), 2)                       AS insurance_total,
    ROUND(SUM(py.amount_paid), 2)                            AS amount_collected
FROM billing b
JOIN hospital_branches hb ON hb.branch_id = b.branch_id
LEFT JOIN payments py ON py.bill_id = b.bill_id
GROUP BY hb.branch_id, hb.branch_name,
         EXTRACT(YEAR FROM b.bill_date),
         EXTRACT(MONTH FROM b.bill_date),
         TO_CHAR(b.bill_date, 'Month YYYY')
ORDER BY hb.branch_id, revenue_year DESC, revenue_month DESC
WITH DATA;

CREATE UNIQUE INDEX idx_mvw_monthly_revenue
    ON mvw_monthly_revenue(branch_id, revenue_year, revenue_month);

COMMENT ON MATERIALIZED VIEW mvw_monthly_revenue IS
    'Pre-computed monthly revenue per branch. Refresh with: REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_monthly_revenue;';

-- =============================================================================
-- 12. MATERIALIZED VIEW: Doctor Performance (heavy join — cache it)
-- =============================================================================
CREATE MATERIALIZED VIEW mvw_doctor_performance AS
SELECT
    d.doctor_id,
    d.full_name                                              AS doctor_name,
    dep.dept_name,
    hb.branch_name,
    EXTRACT(YEAR FROM a.appointment_date)::INT               AS appt_year,
    COUNT(a.appointment_id)                                  AS total_appointments,
    COUNT(a.appointment_id) FILTER (WHERE a.status = 'Completed') AS completed,
    COUNT(DISTINCT adm.admission_id)                         AS admissions_handled,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (dis.discharge_date - adm.admission_date)) / 86400.0
    ), 1)                                                    AS avg_los_days,
    COALESCE(SUM(b.total_amount), 0)                         AS revenue_attributed,
    fn_doctor_utilization(d.doctor_id,
        EXTRACT(YEAR FROM CURRENT_DATE)::INT,
        EXTRACT(MONTH FROM CURRENT_DATE)::INT)               AS current_month_util_pct
FROM doctors d
JOIN departments       dep ON dep.dept_id   = d.dept_id
JOIN hospital_branches hb  ON hb.branch_id  = d.branch_id
LEFT JOIN appointments a   ON a.doctor_id   = d.doctor_id
LEFT JOIN admissions   adm ON adm.doctor_id = d.doctor_id
LEFT JOIN discharges   dis ON dis.admission_id = adm.admission_id
LEFT JOIN billing      b   ON b.appointment_id = a.appointment_id
WHERE d.is_active = TRUE
GROUP BY d.doctor_id, d.full_name, dep.dept_name, hb.branch_name,
         EXTRACT(YEAR FROM a.appointment_date)
ORDER BY total_appointments DESC
WITH DATA;

-- Refresh commands (run manually or via pg_cron):
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_monthly_revenue;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_doctor_performance;

SELECT 'views.sql completed successfully.' AS status;
