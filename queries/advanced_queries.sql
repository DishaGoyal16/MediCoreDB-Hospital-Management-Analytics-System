-- =============================================================================
-- FILE: queries/advanced_queries.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: 25 advanced queries — CTEs, window functions, recursive,
--              subqueries, correlated queries, FULL/SELF JOINs.
-- =============================================================================

-- =============================================================================
-- A1. RUNNING TOTAL of revenue per month (window function)
-- =============================================================================
SELECT
    TO_CHAR(bill_date, 'YYYY-MM')                                   AS month,
    ROUND(SUM(total_amount), 2)                                     AS monthly_revenue,
    ROUND(SUM(SUM(total_amount)) OVER (ORDER BY MIN(bill_date)), 2) AS running_total
FROM billing
WHERE payment_status IN ('Paid','Partial','Insurance')
GROUP BY TO_CHAR(bill_date, 'YYYY-MM')
ORDER BY month;

-- =============================================================================
-- A2. RANK DOCTORS by appointment count using DENSE_RANK
-- =============================================================================
SELECT
    d.full_name                                              AS doctor_name,
    dep.dept_name,
    COUNT(a.appointment_id)                                  AS total_appointments,
    DENSE_RANK() OVER (ORDER BY COUNT(a.appointment_id) DESC) AS rank_overall,
    DENSE_RANK() OVER (
        PARTITION BY dep.dept_name
        ORDER BY COUNT(a.appointment_id) DESC
    )                                                        AS rank_in_dept
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
LEFT JOIN appointments a ON a.doctor_id = d.doctor_id
WHERE d.is_active = TRUE
GROUP BY d.doctor_id, d.full_name, dep.dept_name
ORDER BY total_appointments DESC;

-- =============================================================================
-- A3. PATIENT READMISSION RATE — patients admitted more than once
-- =============================================================================
WITH readmissions AS (
    SELECT
        patient_id,
        COUNT(admission_id)                                   AS admission_count,
        MIN(admission_date)                                   AS first_admission,
        MAX(admission_date)                                   AS last_admission
    FROM admissions
    GROUP BY patient_id
    HAVING COUNT(admission_id) > 1
)
SELECT
    p.full_name,
    p.age,
    r.admission_count,
    r.first_admission::DATE,
    r.last_admission::DATE,
    DATE_PART('day', r.last_admission - r.first_admission)::INT AS days_between
FROM readmissions r
JOIN patients p ON p.patient_id = r.patient_id
ORDER BY r.admission_count DESC, days_between;

-- =============================================================================
-- A4. LEAD/LAG: Compare each month's revenue to previous month
-- =============================================================================
WITH monthly AS (
    SELECT
        EXTRACT(YEAR  FROM bill_date)::INT                    AS yr,
        EXTRACT(MONTH FROM bill_date)::INT                    AS mo,
        TO_CHAR(bill_date, 'Mon YYYY')                        AS period,
        ROUND(SUM(total_amount), 2)                           AS revenue
    FROM billing
    GROUP BY yr, mo, TO_CHAR(bill_date, 'Mon YYYY')
)
SELECT
    period,
    revenue,
    LAG(revenue)  OVER (ORDER BY yr, mo)                     AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY yr, mo), 2)  AS month_over_month_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY yr, mo))
        / NULLIF(LAG(revenue) OVER (ORDER BY yr, mo), 0) * 100, 1
    )                                                         AS pct_change
FROM monthly
ORDER BY yr, mo;

-- =============================================================================
-- A5. RECURSIVE CTE: Hospital Org Chart (department → head → reporting chain)
-- =============================================================================
WITH RECURSIVE org_chart AS (
    -- Base: department heads
    SELECT
        d.doctor_id,
        d.full_name                                           AS name,
        d.dept_id,
        dep.dept_name,
        NULL::INT                                             AS reports_to,
        0                                                     AS level,
        d.full_name::TEXT                                     AS path
    FROM doctors d
    JOIN departments dep ON dep.dept_id = d.dept_id
    WHERE dep.head_doctor_id = d.doctor_id

    UNION ALL

    -- Recursive: other doctors in same dept
    SELECT
        doc.doctor_id,
        doc.full_name,
        doc.dept_id,
        oc.dept_name,
        oc.doctor_id                                          AS reports_to,
        oc.level + 1,
        oc.path || ' → ' || doc.full_name
    FROM doctors doc
    JOIN org_chart oc ON oc.dept_id = doc.dept_id
    WHERE doc.doctor_id != oc.doctor_id
      AND oc.level = 0   -- only one level deep to avoid cycles
)
SELECT
    REPEAT('  ', level) || name                              AS doctor_with_indent,
    dept_name,
    level                                                    AS hierarchy_level,
    path
FROM org_chart
ORDER BY dept_id, level, name
LIMIT 60;

-- =============================================================================
-- A6. CORRELATED SUBQUERY: Doctors with above-average consultation fee in dept
-- =============================================================================
SELECT
    d.full_name,
    dep.dept_name,
    d.consultation_fee,
    (SELECT ROUND(AVG(d2.consultation_fee), 2)
     FROM doctors d2
     WHERE d2.dept_id = d.dept_id)                          AS dept_avg_fee
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
WHERE d.consultation_fee > (
    SELECT AVG(d2.consultation_fee)
    FROM doctors d2
    WHERE d2.dept_id = d.dept_id
)
  AND d.is_active = TRUE
ORDER BY dep.dept_name, d.consultation_fee DESC;

-- =============================================================================
-- A7. FULL OUTER JOIN: All patients vs all doctors — find unmatched
-- =============================================================================
SELECT
    COALESCE(p.full_name, 'N/A')                             AS patient,
    COALESCE(d.full_name, 'N/A')                             AS doctor,
    a.appointment_date,
    a.status
FROM appointments a
FULL OUTER JOIN patients p ON p.patient_id = a.patient_id
FULL OUTER JOIN doctors  d ON d.doctor_id  = a.doctor_id
WHERE a.appointment_id IS NULL   -- unmatched (orphan rows if any)
   OR p.patient_id     IS NULL
   OR d.doctor_id      IS NULL
LIMIT 20;

-- =============================================================================
-- A8. SELF JOIN: Find patients who share the same doctor AND same diagnosis
-- =============================================================================
SELECT
    mr1.patient_id                                           AS patient_a,
    p1.full_name                                             AS patient_a_name,
    mr2.patient_id                                           AS patient_b,
    p2.full_name                                             AS patient_b_name,
    mr1.doctor_id,
    d.full_name                                              AS shared_doctor,
    mr1.diagnosis                                            AS shared_diagnosis
FROM medical_records mr1
JOIN medical_records mr2
    ON mr1.doctor_id = mr2.doctor_id
   AND mr1.diagnosis = mr2.diagnosis
   AND mr1.patient_id < mr2.patient_id   -- avoid duplicates
JOIN patients p1 ON p1.patient_id = mr1.patient_id
JOIN patients p2 ON p2.patient_id = mr2.patient_id
JOIN doctors  d  ON d.doctor_id   = mr1.doctor_id
ORDER BY mr1.diagnosis, mr1.doctor_id
LIMIT 30;

-- =============================================================================
-- A9. NTILE: Segment patients into quartiles by number of visits
-- =============================================================================
WITH visit_counts AS (
    SELECT
        patient_id,
        COUNT(appointment_id) AS visit_count
    FROM appointments
    WHERE status = 'Completed'
    GROUP BY patient_id
)
SELECT
    p.full_name,
    vc.visit_count,
    NTILE(4) OVER (ORDER BY vc.visit_count)                  AS quartile,
    CASE NTILE(4) OVER (ORDER BY vc.visit_count)
        WHEN 1 THEN 'Low frequency (bottom 25%)'
        WHEN 2 THEN 'Below average'
        WHEN 3 THEN 'Above average'
        WHEN 4 THEN 'High frequency (top 25%)'
    END                                                      AS segment
FROM visit_counts vc
JOIN patients p ON p.patient_id = vc.patient_id
ORDER BY vc.visit_count DESC;

-- =============================================================================
-- A10. CTE CHAIN: Revenue → cost → profit estimate per branch
-- =============================================================================
WITH revenue AS (
    SELECT
        branch_id,
        ROUND(SUM(total_amount), 2) AS total_revenue
    FROM billing
    WHERE payment_status IN ('Paid','Partial','Insurance')
    GROUP BY branch_id
),
costs AS (
    SELECT
        branch_id,
        ROUND(SUM(salary), 2) AS annual_staff_cost
    FROM staff
    GROUP BY branch_id
),
doctor_costs AS (
    SELECT
        branch_id,
        ROUND(SUM(consultation_fee * 200), 2) AS est_doctor_cost  -- 200 consults/yr estimate
    FROM doctors
    WHERE is_active = TRUE
    GROUP BY branch_id
)
SELECT
    hb.branch_name,
    r.total_revenue,
    c.annual_staff_cost,
    dc.est_doctor_cost,
    c.annual_staff_cost + dc.est_doctor_cost                AS est_total_cost,
    ROUND(r.total_revenue - c.annual_staff_cost - dc.est_doctor_cost, 2) AS est_profit
FROM revenue r
JOIN costs c         USING (branch_id)
JOIN doctor_costs dc USING (branch_id)
JOIN hospital_branches hb ON hb.branch_id = r.branch_id
ORDER BY est_profit DESC;

-- =============================================================================
-- A11. ROW_NUMBER: Find duplicate prescriptions for same patient+medicine
-- =============================================================================
WITH ranked_rx AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id, medicine_id, prescribed_on
            ORDER BY prescription_id
        ) AS rn
    FROM prescriptions
)
SELECT
    prescription_id, patient_id, doctor_id, medicine_id, prescribed_on
FROM ranked_rx
WHERE rn > 1;

-- =============================================================================
-- A12. CROSS JOIN: All doctors × departments for schedule gap analysis
-- =============================================================================
SELECT
    d.full_name       AS doctor_name,
    dep.dept_name,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM doctor_schedules ds
            WHERE ds.doctor_id = d.doctor_id AND ds.is_active = TRUE
        )
        THEN 'Has Schedule'
        ELSE '⚠ No Schedule Set'
    END               AS schedule_status
FROM doctors d
CROSS JOIN departments dep
WHERE d.dept_id = dep.dept_id   -- same dept
  AND d.is_active = TRUE
ORDER BY schedule_status DESC, d.full_name
LIMIT 30;

-- =============================================================================
-- A13. WINDOW FRAME: 3-month rolling average revenue
-- =============================================================================
WITH monthly_rev AS (
    SELECT
        DATE_TRUNC('month', bill_date)::DATE  AS month,
        ROUND(SUM(total_amount), 2)           AS revenue
    FROM billing
    GROUP BY DATE_TRUNC('month', bill_date)
)
SELECT
    month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                                    AS rolling_3m_avg
FROM monthly_rev
ORDER BY month;

-- =============================================================================
-- A14. EXISTS: Patients who have BOTH a bill AND an active insurance
-- =============================================================================
SELECT
    p.full_name,
    p.age,
    i.provider_name,
    i.coverage_amount,
    COUNT(b.bill_id)      AS bill_count,
    SUM(b.total_amount)   AS total_billed
FROM patients p
JOIN insurance i ON i.insurance_id = p.insurance_id
JOIN billing   b ON b.patient_id   = p.patient_id
WHERE EXISTS (
    SELECT 1 FROM billing b2 WHERE b2.patient_id = p.patient_id
)
  AND i.is_active = TRUE
  AND i.valid_to >= CURRENT_DATE
GROUP BY p.patient_id, p.full_name, p.age, i.provider_name, i.coverage_amount
ORDER BY total_billed DESC
LIMIT 20;

-- =============================================================================
-- A15. NOT EXISTS: Doctors who have NEVER had a completed appointment
-- =============================================================================
SELECT
    d.doctor_id,
    d.full_name,
    d.employment_type,
    dep.dept_name,
    d.joining_date
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
WHERE NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = d.doctor_id
      AND a.status    = 'Completed'
)
  AND d.is_active = TRUE
ORDER BY d.joining_date;

-- =============================================================================
-- A16. CASE + AGGREGATE: Bill distribution by size bucket
-- =============================================================================
SELECT
    CASE
        WHEN total_amount < 1000          THEN '< ₹1,000'
        WHEN total_amount BETWEEN 1000 AND 5000   THEN '₹1,000–5,000'
        WHEN total_amount BETWEEN 5001 AND 20000  THEN '₹5,001–20,000'
        WHEN total_amount BETWEEN 20001 AND 100000 THEN '₹20,001–1,00,000'
        ELSE '> ₹1,00,000'
    END                                                      AS bill_bucket,
    COUNT(*)                                                 AS bill_count,
    ROUND(SUM(total_amount), 2)                              AS total_value,
    ROUND(AVG(total_amount), 2)                              AS avg_value
FROM billing
GROUP BY bill_bucket
ORDER BY MIN(total_amount);

-- =============================================================================
-- A17. MULTI-LEVEL CTE: Top 5 patients by outstanding balance
-- =============================================================================
WITH billed AS (
    SELECT patient_id, SUM(total_amount) AS total_billed
    FROM billing
    GROUP BY patient_id
),
paid AS (
    SELECT patient_id, SUM(amount_paid) AS total_paid
    FROM payments
    GROUP BY patient_id
),
balance AS (
    SELECT
        b.patient_id,
        b.total_billed,
        COALESCE(p.total_paid, 0)                            AS total_paid,
        b.total_billed - COALESCE(p.total_paid, 0)          AS outstanding
    FROM billed b
    LEFT JOIN paid p USING (patient_id)
)
SELECT
    pat.full_name,
    pat.phone,
    ROUND(bal.total_billed, 2)                               AS total_billed,
    ROUND(bal.total_paid, 2)                                 AS total_paid,
    ROUND(bal.outstanding, 2)                                AS outstanding_balance
FROM balance bal
JOIN patients pat ON pat.patient_id = bal.patient_id
WHERE bal.outstanding > 0
ORDER BY bal.outstanding DESC
LIMIT 10;

-- =============================================================================
-- A18. STRING functions: Mask Aadhaar, format phone
-- =============================================================================
SELECT
    full_name,
    COALESCE(
        OVERLAY(aadhar_number PLACING '****' FROM 5 FOR 4),
        'Not Provided'
    )                                                        AS masked_aadhaar,
    '+91-' || SUBSTRING(phone, 1, 5) || '-' || SUBSTRING(phone, 6) AS formatted_phone,
    UPPER(LEFT(city, 1)) || LOWER(SUBSTRING(city, 2))        AS city_formatted
FROM patients
WHERE is_active = TRUE
LIMIT 20;

-- =============================================================================
-- A19. DATE functions: Length-of-stay stats per admission type
-- =============================================================================
SELECT
    a.admission_type,
    COUNT(*)                                                 AS admissions,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (d.discharge_date - a.admission_date)) / 86400
    ), 1)                                                    AS avg_los_days,
    MIN(DATE_PART('day', d.discharge_date - a.admission_date)::INT) AS min_los,
    MAX(DATE_PART('day', d.discharge_date - a.admission_date)::INT) AS max_los
FROM admissions a
JOIN discharges d ON d.admission_id = a.admission_id
GROUP BY a.admission_type
ORDER BY avg_los_days DESC;

-- =============================================================================
-- A20. ROLLUP: Revenue by branch → department hierarchy
-- =============================================================================
SELECT
    COALESCE(hb.branch_name, '** ALL BRANCHES **') AS branch,
    COALESCE(dep.dept_name, '* All Depts *')        AS department,
    COUNT(b.bill_id)                                AS bills,
    ROUND(SUM(b.total_amount), 2)                   AS revenue
FROM billing b
JOIN hospital_branches hb ON hb.branch_id = b.branch_id
LEFT JOIN appointments a   ON a.appointment_id = b.appointment_id
LEFT JOIN departments dep  ON dep.dept_id = a.dept_id
GROUP BY ROLLUP (hb.branch_name, dep.dept_name)
ORDER BY branch NULLS LAST, department NULLS LAST;

-- =============================================================================
-- A21. PIVOT-STYLE: Monthly appointments per department (using FILTER)
-- =============================================================================
SELECT
    dep.dept_name,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 1)  AS jan,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 2)  AS feb,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 3)  AS mar,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 4)  AS apr,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 5)  AS may,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 6)  AS jun,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 7)  AS jul,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 8)  AS aug,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 9)  AS sep,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 10) AS oct,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 11) AS nov,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM a.appointment_date) = 12) AS dec,
    COUNT(*)                                                             AS total
FROM appointments a
JOIN departments dep ON dep.dept_id = a.dept_id
WHERE EXTRACT(YEAR FROM a.appointment_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
GROUP BY dep.dept_name
ORDER BY total DESC;

-- =============================================================================
-- A22. LATERAL JOIN: Latest appointment per patient
-- =============================================================================
SELECT
    p.full_name,
    p.age,
    lat.last_appt_date,
    lat.last_doctor,
    lat.last_status
FROM patients p
CROSS JOIN LATERAL (
    SELECT
        a.appointment_date  AS last_appt_date,
        d.full_name         AS last_doctor,
        a.status            AS last_status
    FROM appointments a
    JOIN doctors d ON d.doctor_id = a.doctor_id
    WHERE a.patient_id = p.patient_id
    ORDER BY a.appointment_date DESC
    LIMIT 1
) lat
WHERE p.is_active = TRUE
ORDER BY lat.last_appt_date DESC
LIMIT 30;

-- =============================================================================
-- A23. PERCENTILE: Revenue distribution percentiles
-- =============================================================================
SELECT
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_amount), 2) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_amount), 2) AS median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_amount), 2) AS p75,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_amount), 2) AS p90,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_amount), 2) AS p95,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_amount), 2) AS p99,
    ROUND(AVG(total_amount), 2)                                           AS mean,
    ROUND(STDDEV(total_amount), 2)                                        AS std_dev
FROM billing;

-- =============================================================================
-- A24. JSONB audit log query: recent patient updates
-- =============================================================================
SELECT
    log_id,
    changed_at,
    changed_by,
    operation,
    (new_data ->> 'full_name')   AS patient_name,
    (old_data ->> 'phone')       AS old_phone,
    (new_data ->> 'phone')       AS new_phone
FROM audit_logs
WHERE table_name = 'patients'
  AND operation  = 'UPDATE'
ORDER BY changed_at DESC
LIMIT 10;

-- =============================================================================
-- A25. RECURSIVE date series: Appointment count per day last 30 days
-- =============================================================================
WITH RECURSIVE date_series AS (
    SELECT CURRENT_DATE - 29 AS dt
    UNION ALL
    SELECT dt + 1 FROM date_series WHERE dt < CURRENT_DATE
)
SELECT
    ds.dt                                                    AS appointment_date,
    TO_CHAR(ds.dt, 'Dy DD-Mon')                             AS day_label,
    COALESCE(COUNT(a.appointment_id), 0)                     AS appointment_count
FROM date_series ds
LEFT JOIN appointments a ON a.appointment_date = ds.dt
GROUP BY ds.dt
ORDER BY ds.dt;
