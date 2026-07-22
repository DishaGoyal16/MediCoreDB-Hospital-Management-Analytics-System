-- =============================================================================
-- FILE: queries/analytical_queries.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: 20 analytical SQL queries for business intelligence and
--              reporting. Covers KPIs, trends, cohort analysis, forecasting.
-- =============================================================================

-- =============================================================================
-- AN1. MONTHLY REVENUE TREND with YoY comparison
-- =============================================================================
WITH monthly AS (
    SELECT
        EXTRACT(YEAR  FROM bill_date)::INT  AS yr,
        EXTRACT(MONTH FROM bill_date)::INT  AS mo,
        TO_CHAR(bill_date, 'Mon')           AS mon_label,
        ROUND(SUM(total_amount), 2)         AS revenue
    FROM billing
    WHERE payment_status IN ('Paid','Partial','Insurance')
    GROUP BY yr, mo, TO_CHAR(bill_date, 'Mon')
)
SELECT
    mon_label,
    MAX(revenue) FILTER (WHERE yr = EXTRACT(YEAR FROM CURRENT_DATE)::INT - 1) AS prev_year,
    MAX(revenue) FILTER (WHERE yr = EXTRACT(YEAR FROM CURRENT_DATE)::INT)      AS curr_year,
    ROUND(
        (MAX(revenue) FILTER (WHERE yr = EXTRACT(YEAR FROM CURRENT_DATE)::INT) -
         MAX(revenue) FILTER (WHERE yr = EXTRACT(YEAR FROM CURRENT_DATE)::INT - 1))
        / NULLIF(MAX(revenue) FILTER
            (WHERE yr = EXTRACT(YEAR FROM CURRENT_DATE)::INT - 1), 0) * 100, 1
    )                                                                           AS yoy_growth_pct
FROM monthly
GROUP BY mon_label, mo
ORDER BY mo;

-- =============================================================================
-- AN2. PATIENT COHORT ANALYSIS: Retention by registration month
-- =============================================================================
WITH cohort AS (
    SELECT
        patient_id,
        DATE_TRUNC('month', registration_date)::DATE AS cohort_month
    FROM patients
    WHERE is_active = TRUE
),
activity AS (
    SELECT
        c.patient_id,
        c.cohort_month,
        DATE_TRUNC('month', a.appointment_date)::DATE AS activity_month,
        DATE_PART('month', AGE(
            DATE_TRUNC('month', a.appointment_date),
            c.cohort_month
        ))::INT AS months_since_registration
    FROM cohort c
    JOIN appointments a ON a.patient_id = c.patient_id
    WHERE a.status = 'Completed'
)
SELECT
    cohort_month,
    months_since_registration,
    COUNT(DISTINCT patient_id) AS active_patients
FROM activity
WHERE months_since_registration BETWEEN 0 AND 12
GROUP BY cohort_month, months_since_registration
ORDER BY cohort_month, months_since_registration;

-- =============================================================================
-- AN3. DOCTOR UTILIZATION HEATMAP (appointment density by day and hour)
-- =============================================================================
SELECT
    EXTRACT(DOW FROM appointment_date)::INT              AS day_num,
    TO_CHAR(appointment_date, 'Dy')                      AS day_name,
    EXTRACT(HOUR FROM appointment_time)::INT             AS hour_of_day,
    COUNT(appointment_id)                                AS appointment_count,
    ROUND(AVG(COUNT(appointment_id)) OVER (
        PARTITION BY EXTRACT(DOW FROM appointment_date)
    ), 1)                                                AS avg_for_that_day,
    -- Visual density bar
    REPEAT('█', (COUNT(appointment_id) / 10)::INT + 1)  AS density_bar
FROM appointments
WHERE status IN ('Completed','Confirmed')
GROUP BY
    EXTRACT(DOW FROM appointment_date),
    TO_CHAR(appointment_date, 'Dy'),
    EXTRACT(HOUR FROM appointment_time)
ORDER BY day_num, hour_of_day;

-- =============================================================================
-- AN4. MEDICINE CONSUMPTION TREND (top 10 medicines, last 6 months)
-- =============================================================================
WITH monthly_consumption AS (
    SELECT
        m.medicine_name,
        DATE_TRUNC('month', px.prescribed_on)::DATE AS month,
        SUM(px.quantity)                             AS qty_dispensed
    FROM prescriptions px
    JOIN medicines m ON m.medicine_id = px.medicine_id
    WHERE px.prescribed_on >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY m.medicine_name, DATE_TRUNC('month', px.prescribed_on)
),
ranked AS (
    SELECT
        medicine_name,
        SUM(qty_dispensed) AS total_6m
    FROM monthly_consumption
    GROUP BY medicine_name
    ORDER BY total_6m DESC
    LIMIT 10
)
SELECT
    mc.medicine_name,
    mc.month,
    mc.qty_dispensed,
    SUM(mc.qty_dispensed) OVER (
        PARTITION BY mc.medicine_name ORDER BY mc.month
    )                                                    AS cumulative_dispensed
FROM monthly_consumption mc
JOIN ranked r ON r.medicine_name = mc.medicine_name
ORDER BY mc.medicine_name, mc.month;

-- =============================================================================
-- AN5. BED OCCUPANCY RATE TREND (last 12 months)
-- =============================================================================
WITH months AS (
    SELECT DATE_TRUNC('month', CURRENT_DATE - (n || ' months')::INTERVAL)::DATE AS month
    FROM GENERATE_SERIES(0, 11) AS n
),
monthly_admits AS (
    SELECT
        DATE_TRUNC('month', admission_date)::DATE AS month,
        COUNT(DISTINCT bed_id)                    AS beds_used
    FROM admissions
    GROUP BY DATE_TRUNC('month', admission_date)
),
total_beds AS (
    SELECT COUNT(*) AS total FROM beds WHERE status != 'Maintenance'
)
SELECT
    m.month,
    TO_CHAR(m.month, 'Mon YYYY')               AS period,
    COALESCE(ma.beds_used, 0)                   AS beds_used,
    tb.total                                    AS total_beds,
    ROUND(COALESCE(ma.beds_used, 0)::NUMERIC / tb.total * 100, 1) AS occupancy_pct
FROM months m
LEFT JOIN monthly_admits ma ON ma.month = m.month
CROSS JOIN total_beds tb
ORDER BY m.month;

-- =============================================================================
-- AN6. PATIENT READMISSION ANALYSIS (within 30 days)
-- =============================================================================
WITH readmit AS (
    SELECT
        a1.patient_id,
        a1.admission_id                            AS first_admission,
        a1.admission_date                          AS first_date,
        a2.admission_id                            AS readmission_id,
        a2.admission_date                          AS readmit_date,
        EXTRACT(EPOCH FROM (a2.admission_date - d1.discharge_date))
            / 86400                                AS days_to_readmit
    FROM admissions a1
    JOIN discharges  d1 ON d1.admission_id = a1.admission_id
    JOIN admissions  a2 ON a2.patient_id   = a1.patient_id
                        AND a2.admission_id > a1.admission_id
                        AND a2.admission_date BETWEEN d1.discharge_date
                            AND d1.discharge_date + INTERVAL '30 days'
)
SELECT
    p.full_name,
    p.age,
    r.first_date::DATE,
    r.readmit_date::DATE,
    ROUND(r.days_to_readmit, 0)::INT AS days_to_readmit,
    a_first.diagnosis                AS original_diagnosis,
    a_re.diagnosis                   AS readmit_diagnosis
FROM readmit r
JOIN patients   p      ON p.patient_id      = r.patient_id
JOIN admissions a_first ON a_first.admission_id = r.first_admission
JOIN admissions a_re   ON a_re.admission_id    = r.readmission_id
ORDER BY r.days_to_readmit;

-- =============================================================================
-- AN7. DEPARTMENT PERFORMANCE SCORECARD
-- =============================================================================
WITH dept_metrics AS (
    SELECT
        dep.dept_id,
        dep.dept_name,
        hb.branch_name,
        COUNT(DISTINCT doc.doctor_id)              AS doctor_count,
        COUNT(DISTINCT a.appointment_id)           AS total_appointments,
        COUNT(DISTINCT a.appointment_id) FILTER (WHERE a.status = 'Completed') AS completed,
        COUNT(DISTINCT adm.admission_id)           AS total_admissions,
        ROUND(SUM(b.total_amount), 2)              AS revenue,
        ROUND(AVG(
            EXTRACT(EPOCH FROM (d.discharge_date - adm.admission_date)) / 86400
        ), 1)                                      AS avg_los
    FROM departments dep
    JOIN hospital_branches hb ON hb.branch_id = dep.branch_id
    LEFT JOIN doctors doc ON doc.dept_id = dep.dept_id AND doc.is_active = TRUE
    LEFT JOIN appointments a ON a.dept_id = dep.dept_id
    LEFT JOIN billing b ON b.appointment_id = a.appointment_id
    LEFT JOIN admissions adm ON adm.doctor_id = doc.doctor_id
    LEFT JOIN discharges d ON d.admission_id = adm.admission_id
    GROUP BY dep.dept_id, dep.dept_name, hb.branch_name
)
SELECT
    dept_name,
    branch_name,
    doctor_count,
    total_appointments,
    completed,
    ROUND(completed::NUMERIC / NULLIF(total_appointments, 0) * 100, 1) AS completion_pct,
    total_admissions,
    ROUND(revenue, 2)                              AS revenue,
    avg_los,
    DENSE_RANK() OVER (ORDER BY revenue DESC)      AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY total_appointments DESC) AS volume_rank
FROM dept_metrics
ORDER BY revenue DESC;

-- =============================================================================
-- AN8. REVENUE PER PATIENT (LTV — Lifetime Value estimate)
-- =============================================================================
SELECT
    p.patient_id,
    p.full_name,
    p.registration_date,
    DATE_PART('year', AGE(p.registration_date))::INT AS years_as_patient,
    COUNT(b.bill_id)                                 AS total_bills,
    ROUND(SUM(b.total_amount), 2)                    AS lifetime_spend,
    ROUND(AVG(b.total_amount), 2)                    AS avg_bill_value,
    ROUND(SUM(b.total_amount) /
        NULLIF(DATE_PART('year', AGE(p.registration_date)), 0), 2) AS annual_revenue,
    CASE
        WHEN SUM(b.total_amount) > 100000 THEN 'Platinum'
        WHEN SUM(b.total_amount) > 50000  THEN 'Gold'
        WHEN SUM(b.total_amount) > 20000  THEN 'Silver'
        ELSE 'Standard'
    END                                              AS patient_tier
FROM patients p
JOIN billing b ON b.patient_id = p.patient_id
WHERE p.is_active = TRUE
GROUP BY p.patient_id, p.full_name, p.registration_date
ORDER BY lifetime_spend DESC
LIMIT 20;

-- =============================================================================
-- AN9. HOSPITAL OCCUPANCY DASHBOARD (real-time snapshot)
-- =============================================================================
SELECT
    hb.branch_name,
    r.room_type,
    COUNT(b.bed_id)                                  AS total_beds,
    COUNT(b.bed_id) FILTER (WHERE b.status = 'Occupied')    AS occupied,
    COUNT(b.bed_id) FILTER (WHERE b.status = 'Available')   AS available,
    COUNT(b.bed_id) FILTER (WHERE b.status = 'Maintenance') AS maintenance,
    ROUND(
        COUNT(b.bed_id) FILTER (WHERE b.status = 'Occupied')::NUMERIC
        / NULLIF(COUNT(b.bed_id), 0) * 100, 1
    )                                                AS occupancy_pct,
    r.daily_charge
FROM beds b
JOIN rooms r              ON r.room_id    = b.room_id
JOIN hospital_branches hb ON hb.branch_id = r.branch_id
GROUP BY hb.branch_name, r.room_type, r.daily_charge
ORDER BY hb.branch_name, occupancy_pct DESC;

-- =============================================================================
-- AN10. TOP SUPPLIERS BY MEDICINE SUPPLY VALUE
-- =============================================================================
SELECT
    s.supplier_name,
    s.city,
    COUNT(DISTINCT mi.medicine_id)                   AS medicines_supplied,
    COUNT(DISTINCT mi.batch_number)                  AS batches_supplied,
    SUM(mi.quantity)                                 AS total_units_supplied,
    ROUND(SUM(mi.quantity * mi.purchase_price), 2)   AS total_supply_value,
    ROUND(AVG(mi.purchase_price), 2)                 AS avg_purchase_price,
    MIN(mi.received_on)                              AS first_supply_date,
    MAX(mi.received_on)                              AS latest_supply_date
FROM suppliers s
JOIN medicine_inventory mi ON mi.supplier_id = s.supplier_id
WHERE mi.is_active = TRUE
GROUP BY s.supplier_id, s.supplier_name, s.city
ORDER BY total_supply_value DESC;

-- =============================================================================
-- AN11. DOCTOR REVENUE ATTRIBUTION
--       (revenue from appointments + from admissions)
-- =============================================================================
WITH appt_rev AS (
    SELECT
        a.doctor_id,
        ROUND(SUM(b.total_amount), 2) AS appt_revenue,
        COUNT(b.bill_id)              AS appt_bills
    FROM appointments a
    JOIN billing b ON b.appointment_id = a.appointment_id
    GROUP BY a.doctor_id
),
adm_rev AS (
    SELECT
        adm.doctor_id,
        ROUND(SUM(b.total_amount), 2) AS adm_revenue,
        COUNT(b.bill_id)              AS adm_bills
    FROM admissions adm
    JOIN billing b ON b.admission_id = adm.admission_id
    GROUP BY adm.doctor_id
)
SELECT
    d.full_name,
    dep.dept_name,
    COALESCE(ar.appt_revenue, 0)                     AS opd_revenue,
    COALESCE(ar.appt_bills, 0)                       AS opd_bills,
    COALESCE(adr.adm_revenue, 0)                     AS inpatient_revenue,
    COALESCE(adr.adm_bills, 0)                       AS inpatient_bills,
    COALESCE(ar.appt_revenue, 0) +
        COALESCE(adr.adm_revenue, 0)                 AS total_revenue,
    RANK() OVER (ORDER BY
        COALESCE(ar.appt_revenue, 0) +
        COALESCE(adr.adm_revenue, 0) DESC
    )                                                AS revenue_rank
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
LEFT JOIN appt_rev  ar  ON ar.doctor_id  = d.doctor_id
LEFT JOIN adm_rev   adr ON adr.doctor_id = d.doctor_id
WHERE d.is_active = TRUE
ORDER BY total_revenue DESC
LIMIT 20;

-- =============================================================================
-- AN12. INSURANCE COVERAGE GAP ANALYSIS
-- =============================================================================
SELECT
    p.full_name,
    p.age,
    i.provider_name,
    i.coverage_amount,
    i.deductible,
    ROUND(SUM(b.total_amount), 2)                    AS total_billed,
    ROUND(SUM(b.insurance_covered), 2)               AS insurance_paid,
    ROUND(SUM(b.total_amount) - SUM(b.insurance_covered), 2) AS patient_pays,
    ROUND(SUM(b.insurance_covered) /
          NULLIF(SUM(b.total_amount), 0) * 100, 1)   AS coverage_utilization_pct,
    CASE
        WHEN SUM(b.total_amount) > i.coverage_amount
        THEN ROUND(SUM(b.total_amount) - i.coverage_amount, 2)
        ELSE 0
    END                                              AS exceeds_coverage_by
FROM patients p
JOIN insurance i ON i.insurance_id = p.insurance_id
JOIN billing   b ON b.patient_id   = p.patient_id
WHERE b.insurance_covered > 0
  AND i.is_active = TRUE
GROUP BY p.patient_id, p.full_name, p.age,
         i.provider_name, i.coverage_amount, i.deductible
ORDER BY exceeds_coverage_by DESC
LIMIT 20;

-- =============================================================================
-- AN13. DISCHARGE TYPE ANALYSIS with avg cost and LOS
-- =============================================================================
SELECT
    d.discharge_type,
    COUNT(d.discharge_id)                            AS discharges,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (d.discharge_date - a.admission_date)) / 86400
    ), 1)                                            AS avg_los_days,
    ROUND(AVG(b.total_amount), 2)                    AS avg_bill,
    ROUND(SUM(b.total_amount), 2)                    AS total_revenue,
    COUNT(*) FILTER (WHERE d.follow_up_date IS NOT NULL) AS with_follow_up,
    ROUND(COUNT(*) FILTER (WHERE d.follow_up_date IS NOT NULL)::NUMERIC
          / COUNT(*) * 100, 1)                       AS follow_up_rate_pct
FROM discharges d
JOIN admissions a ON a.admission_id = d.admission_id
LEFT JOIN billing b ON b.admission_id = d.admission_id
GROUP BY d.discharge_type
ORDER BY discharges DESC;

-- =============================================================================
-- AN14. MOST EXPENSIVE TREATMENT CATEGORIES
-- =============================================================================
SELECT
    treatment_type,
    COUNT(treatment_id)                              AS treatments_done,
    ROUND(AVG(cost), 2)                              AS avg_cost,
    ROUND(SUM(cost), 2)                              AS total_cost,
    ROUND(MIN(cost), 2)                              AS min_cost,
    ROUND(MAX(cost), 2)                              AS max_cost,
    ROUND(STDDEV(cost), 2)                           AS cost_std_dev
FROM treatments
WHERE cost > 0
GROUP BY treatment_type
ORDER BY total_cost DESC;

-- =============================================================================
-- AN15. BLOOD GROUP DISTRIBUTION AND COMPATIBILITY (donor matching)
-- =============================================================================
WITH blood_counts AS (
    SELECT
        blood_group,
        COUNT(*)                                     AS patient_count
    FROM patients
    WHERE blood_group IS NOT NULL AND is_active = TRUE
    GROUP BY blood_group
)
SELECT
    bc.blood_group,
    bc.patient_count,
    ROUND(bc.patient_count::NUMERIC /
          SUM(bc.patient_count) OVER () * 100, 1)   AS percentage,
    -- Can donate to
    CASE bc.blood_group
        WHEN 'O-'  THEN 'O-, O+, A-, A+, B-, B+, AB-, AB+'
        WHEN 'O+'  THEN 'O+, A+, B+, AB+'
        WHEN 'A-'  THEN 'A-, A+, AB-, AB+'
        WHEN 'A+'  THEN 'A+, AB+'
        WHEN 'B-'  THEN 'B-, B+, AB-, AB+'
        WHEN 'B+'  THEN 'B+, AB+'
        WHEN 'AB-' THEN 'AB-, AB+'
        WHEN 'AB+' THEN 'AB+'
    END                                              AS can_donate_to,
    -- Can receive from
    CASE bc.blood_group
        WHEN 'AB+' THEN 'O-, O+, A-, A+, B-, B+, AB-, AB+'
        WHEN 'AB-' THEN 'O-, A-, B-, AB-'
        WHEN 'A+'  THEN 'O-, O+, A-, A+'
        WHEN 'A-'  THEN 'O-, A-'
        WHEN 'B+'  THEN 'O-, O+, B-, B+'
        WHEN 'B-'  THEN 'O-, B-'
        WHEN 'O+'  THEN 'O-, O+'
        WHEN 'O-'  THEN 'O-'
    END                                              AS can_receive_from
FROM blood_counts bc
ORDER BY bc.patient_count DESC;

-- =============================================================================
-- AN16. APPOINTMENT FUNNEL ANALYSIS
-- =============================================================================
WITH funnel AS (
    SELECT
        COUNT(*) FILTER (WHERE TRUE)                 AS total_booked,
        COUNT(*) FILTER (WHERE status = 'Confirmed') AS confirmed,
        COUNT(*) FILTER (WHERE status = 'Completed') AS completed,
        COUNT(*) FILTER (WHERE status = 'Cancelled') AS cancelled,
        COUNT(*) FILTER (WHERE status = 'No-Show')   AS no_show
    FROM appointments
)
SELECT
    total_booked,
    confirmed,
    ROUND(confirmed::NUMERIC / total_booked * 100, 1) AS confirm_rate_pct,
    completed,
    ROUND(completed::NUMERIC / total_booked * 100, 1) AS completion_rate_pct,
    cancelled,
    ROUND(cancelled::NUMERIC / total_booked * 100, 1) AS cancel_rate_pct,
    no_show,
    ROUND(no_show::NUMERIC / total_booked * 100, 1)   AS no_show_rate_pct,
    total_booked - completed - cancelled - no_show     AS in_progress
FROM funnel;

-- =============================================================================
-- AN17. DOCTOR SCHEDULE EFFICIENCY (actual vs max capacity)
-- =============================================================================
WITH capacity AS (
    SELECT
        doctor_id,
        SUM(max_appointments) * 4 AS monthly_capacity -- 4 weeks
    FROM doctor_schedules
    WHERE is_active = TRUE
    GROUP BY doctor_id
),
actual AS (
    SELECT
        doctor_id,
        COUNT(*) AS monthly_actual
    FROM appointments
    WHERE EXTRACT(YEAR  FROM appointment_date) = EXTRACT(YEAR  FROM CURRENT_DATE)
      AND EXTRACT(MONTH FROM appointment_date) = EXTRACT(MONTH FROM CURRENT_DATE)
      AND status IN ('Completed','Confirmed','Scheduled')
    GROUP BY doctor_id
)
SELECT
    d.full_name,
    dep.dept_name,
    c.monthly_capacity,
    COALESCE(a.monthly_actual, 0) AS monthly_booked,
    ROUND(COALESCE(a.monthly_actual, 0)::NUMERIC /
          NULLIF(c.monthly_capacity, 0) * 100, 1) AS utilization_pct,
    c.monthly_capacity - COALESCE(a.monthly_actual, 0) AS open_slots
FROM capacity c
JOIN doctors d ON d.doctor_id = c.doctor_id
JOIN departments dep ON dep.dept_id = d.dept_id
LEFT JOIN actual a ON a.doctor_id = d.doctor_id
WHERE d.is_active = TRUE
ORDER BY utilization_pct DESC;

-- =============================================================================
-- AN18. REVENUE CONCENTRATION (Pareto analysis — 80/20 rule)
-- =============================================================================
WITH patient_revenue AS (
    SELECT
        patient_id,
        SUM(total_amount) AS revenue
    FROM billing
    GROUP BY patient_id
),
ranked AS (
    SELECT
        patient_id,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC)       AS cumulative_revenue,
        SUM(revenue) OVER ()                            AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC)       AS rank_num,
        COUNT(*) OVER ()                                AS total_patients
    FROM patient_revenue
)
SELECT
    rank_num,
    ROUND(revenue, 2)                                    AS patient_revenue,
    ROUND(cumulative_revenue, 2)                         AS cumulative_revenue,
    ROUND(cumulative_revenue / total_revenue * 100, 1)   AS cumulative_pct,
    ROUND(rank_num::NUMERIC / total_patients * 100, 1)   AS patient_pct,
    CASE
        WHEN cumulative_revenue / total_revenue <= 0.80
        THEN 'Top 80% Revenue Contributors'
        ELSE 'Bottom 20% Revenue'
    END                                                  AS pareto_group
FROM ranked
WHERE rank_num <= 50
ORDER BY rank_num;

-- =============================================================================
-- AN19. SEASONAL ILLNESS PATTERN (diagnosis frequency by quarter)
-- =============================================================================
SELECT
    EXTRACT(QUARTER FROM mr.visit_date)::INT            AS quarter,
    CASE EXTRACT(QUARTER FROM mr.visit_date)::INT
        WHEN 1 THEN 'Q1 (Jan-Mar)'
        WHEN 2 THEN 'Q2 (Apr-Jun)'
        WHEN 3 THEN 'Q3 (Jul-Sep)'
        WHEN 4 THEN 'Q4 (Oct-Dec)'
    END                                                  AS period,
    mr.diagnosis,
    COUNT(*)                                             AS case_count,
    ROUND(COUNT(*)::NUMERIC /
          SUM(COUNT(*)) OVER (PARTITION BY EXTRACT(QUARTER FROM mr.visit_date)) * 100, 1) AS pct_in_quarter
FROM medical_records mr
WHERE mr.diagnosis IS NOT NULL
  AND mr.visit_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY EXTRACT(QUARTER FROM mr.visit_date), mr.diagnosis
HAVING COUNT(*) >= 3
ORDER BY quarter, case_count DESC;

-- =============================================================================
-- AN20. FORECASTING: Next month revenue estimate (based on 3-month avg)
-- =============================================================================
WITH monthly_rev AS (
    SELECT
        DATE_TRUNC('month', bill_date)::DATE AS month,
        SUM(total_amount)                    AS revenue
    FROM billing
    WHERE payment_status IN ('Paid','Partial','Insurance')
    GROUP BY DATE_TRUNC('month', bill_date)
    ORDER BY month DESC
    LIMIT 3
),
stats AS (
    SELECT
        ROUND(AVG(revenue), 2)    AS avg_3m,
        ROUND(STDDEV(revenue), 2) AS std_3m
    FROM monthly_rev
)
SELECT
    TO_CHAR(DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month', 'Mon YYYY') AS forecast_month,
    s.avg_3m                                                AS base_forecast,
    ROUND(s.avg_3m * 1.05, 2)                               AS optimistic_5pct,
    ROUND(s.avg_3m * 0.95, 2)                               AS conservative_5pct,
    s.std_3m                                                AS std_deviation,
    ROUND(s.avg_3m - s.std_3m, 2)                           AS lower_bound,
    ROUND(s.avg_3m + s.std_3m, 2)                           AS upper_bound
FROM stats s;
