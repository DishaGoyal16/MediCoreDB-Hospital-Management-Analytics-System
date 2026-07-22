-- =============================================================================
-- FILE: queries/interview_queries.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: 45 interview-style SQL questions with solutions.
--              Organized by difficulty: Easy → Medium → Hard.
-- =============================================================================

-- ╔══════════════════════════════════════════════╗
-- ║              EASY  (Q1–Q15)                 ║
-- ╚══════════════════════════════════════════════╝

-- ─────────────────────────────────────────────────────────────
-- Q1. Find the second highest consultation fee among doctors.
-- ─────────────────────────────────────────────────────────────
-- Method 1: OFFSET
SELECT consultation_fee
FROM (
    SELECT DISTINCT consultation_fee
    FROM doctors
    ORDER BY consultation_fee DESC
    LIMIT 2
) t
ORDER BY consultation_fee ASC
LIMIT 1;

-- Method 2: Subquery
SELECT MAX(consultation_fee) AS second_highest
FROM doctors
WHERE consultation_fee < (SELECT MAX(consultation_fee) FROM doctors);

-- ─────────────────────────────────────────────────────────────
-- Q2. List patients who have never had an appointment.
-- ─────────────────────────────────────────────────────────────
SELECT p.patient_id, p.full_name, p.registration_date
FROM patients p
LEFT JOIN appointments a ON a.patient_id = p.patient_id
WHERE a.appointment_id IS NULL
ORDER BY p.registration_date;

-- ─────────────────────────────────────────────────────────────
-- Q3. Count total appointments grouped by status.
-- ─────────────────────────────────────────────────────────────
SELECT
    status,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM appointments
GROUP BY status
ORDER BY total DESC;

-- ─────────────────────────────────────────────────────────────
-- Q4. Find departments that have MORE than 5 doctors.
-- ─────────────────────────────────────────────────────────────
SELECT
    dep.dept_name,
    COUNT(d.doctor_id) AS doctor_count
FROM departments dep
JOIN doctors d ON d.dept_id = dep.dept_id AND d.is_active = TRUE
GROUP BY dep.dept_name
HAVING COUNT(d.doctor_id) > 5
ORDER BY doctor_count DESC;

-- ─────────────────────────────────────────────────────────────
-- Q5. Find the most common blood group among admitted patients.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.blood_group,
    COUNT(*) AS admitted_count
FROM admissions a
JOIN patients p ON p.patient_id = a.patient_id
WHERE p.blood_group IS NOT NULL
GROUP BY p.blood_group
ORDER BY admitted_count DESC
LIMIT 1;

-- ─────────────────────────────────────────────────────────────
-- Q6. Show all doctors hired in the last 2 years.
-- ─────────────────────────────────────────────────────────────
SELECT full_name, dept_id, joining_date, qualification
FROM doctors
WHERE joining_date >= CURRENT_DATE - INTERVAL '2 years'
  AND is_active = TRUE
ORDER BY joining_date DESC;

-- ─────────────────────────────────────────────────────────────
-- Q7. What is the total bill amount for patient_id = 10?
-- ─────────────────────────────────────────────────────────────
SELECT
    p.full_name,
    COUNT(b.bill_id)               AS bills,
    ROUND(SUM(b.total_amount), 2)  AS total_billed,
    ROUND(SUM(py.amount_paid), 2)  AS total_paid,
    ROUND(SUM(b.total_amount) - COALESCE(SUM(py.amount_paid), 0), 2) AS balance
FROM patients p
JOIN billing  b  ON b.patient_id = p.patient_id
LEFT JOIN payments py ON py.bill_id = b.bill_id
WHERE p.patient_id = 10
GROUP BY p.full_name;

-- ─────────────────────────────────────────────────────────────
-- Q8. Find medicines that require NO prescription.
-- ─────────────────────────────────────────────────────────────
SELECT medicine_name, generic_name, category, unit, unit_price
FROM medicines
WHERE requires_prescription = FALSE
  AND is_active = TRUE
ORDER BY category, medicine_name;

-- ─────────────────────────────────────────────────────────────
-- Q9. List all rooms with no available beds.
-- ─────────────────────────────────────────────────────────────
SELECT
    r.room_id,
    r.room_number,
    r.room_type,
    r.total_beds,
    COUNT(b.bed_id) FILTER (WHERE b.status = 'Available') AS available_beds
FROM rooms r
JOIN beds b ON b.room_id = r.room_id
GROUP BY r.room_id, r.room_number, r.room_type, r.total_beds
HAVING COUNT(b.bed_id) FILTER (WHERE b.status = 'Available') = 0;

-- ─────────────────────────────────────────────────────────────
-- Q10. Which payment mode is used most frequently?
-- ─────────────────────────────────────────────────────────────
SELECT payment_mode, COUNT(*) AS frequency
FROM payments
GROUP BY payment_mode
ORDER BY frequency DESC
LIMIT 1;

-- ─────────────────────────────────────────────────────────────
-- Q11. List doctors who share the same last name (SELF JOIN).
-- ─────────────────────────────────────────────────────────────
SELECT
    d1.full_name AS doctor_1,
    d2.full_name AS doctor_2,
    d1.last_name AS shared_surname
FROM doctors d1
JOIN doctors d2
    ON d1.last_name = d2.last_name
   AND d1.doctor_id < d2.doctor_id
ORDER BY d1.last_name;

-- ─────────────────────────────────────────────────────────────
-- Q12. Find all patients whose name starts with 'A'.
-- ─────────────────────────────────────────────────────────────
SELECT patient_id, full_name, gender, age, phone
FROM patients
WHERE first_name LIKE 'A%' AND is_active = TRUE
ORDER BY full_name;

-- ─────────────────────────────────────────────────────────────
-- Q13. How many medicines are in each category?
-- ─────────────────────────────────────────────────────────────
SELECT
    category,
    COUNT(*) AS medicine_count,
    ROUND(AVG(unit_price), 2) AS avg_price,
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price
FROM medicines
WHERE is_active = TRUE
GROUP BY category
ORDER BY medicine_count DESC;

-- ─────────────────────────────────────────────────────────────
-- Q14. Find the oldest patient currently admitted.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.full_name,
    p.age,
    p.blood_group,
    adm.admission_date,
    adm.diagnosis,
    d.full_name AS attending_doctor
FROM admissions adm
JOIN patients p ON p.patient_id = adm.patient_id
JOIN doctors  d ON d.doctor_id  = adm.doctor_id
WHERE adm.status = 'Active'
ORDER BY p.age DESC
LIMIT 1;

-- ─────────────────────────────────────────────────────────────
-- Q15. What is the average experience of doctors per branch?
-- ─────────────────────────────────────────────────────────────
SELECT
    hb.branch_name,
    ROUND(AVG(d.experience_years), 1) AS avg_experience,
    MIN(d.experience_years)           AS min_experience,
    MAX(d.experience_years)           AS max_experience
FROM doctors d
JOIN hospital_branches hb ON hb.branch_id = d.branch_id
WHERE d.is_active = TRUE
GROUP BY hb.branch_name
ORDER BY avg_experience DESC;


-- ╔══════════════════════════════════════════════╗
-- ║             MEDIUM  (Q16–Q32)               ║
-- ╚══════════════════════════════════════════════╝

-- ─────────────────────────────────────────────────────────────
-- Q16. Find patients who have appointments with more than 3
--      different doctors.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.full_name,
    COUNT(DISTINCT a.doctor_id) AS distinct_doctors_seen
FROM patients p
JOIN appointments a ON a.patient_id = p.patient_id
GROUP BY p.patient_id, p.full_name
HAVING COUNT(DISTINCT a.doctor_id) > 3
ORDER BY distinct_doctors_seen DESC;

-- ─────────────────────────────────────────────────────────────
-- Q17. Rank doctors by revenue generated using RANK().
-- ─────────────────────────────────────────────────────────────
SELECT
    d.full_name,
    dep.dept_name,
    ROUND(SUM(b.total_amount), 2)                           AS revenue,
    RANK()       OVER (ORDER BY SUM(b.total_amount) DESC)   AS rank_all,
    RANK()       OVER (PARTITION BY dep.dept_name
                       ORDER BY SUM(b.total_amount) DESC)   AS rank_in_dept
FROM appointments a
JOIN doctors     d   ON d.doctor_id  = a.doctor_id
JOIN departments dep ON dep.dept_id  = d.dept_id
JOIN billing     b   ON b.appointment_id = a.appointment_id
GROUP BY d.doctor_id, d.full_name, dep.dept_name
ORDER BY revenue DESC;

-- ─────────────────────────────────────────────────────────────
-- Q18. Find the department with the highest average bill.
-- ─────────────────────────────────────────────────────────────
SELECT
    dep.dept_name,
    ROUND(AVG(b.total_amount), 2) AS avg_bill,
    COUNT(b.bill_id)              AS bill_count
FROM billing b
JOIN appointments a  ON a.appointment_id = b.appointment_id
JOIN departments dep ON dep.dept_id      = a.dept_id
GROUP BY dep.dept_name
ORDER BY avg_bill DESC
LIMIT 1;

-- ─────────────────────────────────────────────────────────────
-- Q19. Write a query to get the Nth highest bill amount
--      (parameterized example for N = 3).
-- ─────────────────────────────────────────────────────────────
SELECT total_amount AS nth_highest_bill
FROM (
    SELECT DISTINCT total_amount,
           DENSE_RANK() OVER (ORDER BY total_amount DESC) AS rnk
    FROM billing
) ranked
WHERE rnk = 3;

-- ─────────────────────────────────────────────────────────────
-- Q20. Find doctors who have given more prescriptions than
--      the average number of prescriptions per doctor.
-- ─────────────────────────────────────────────────────────────
WITH doc_rx AS (
    SELECT doctor_id, COUNT(*) AS rx_count
    FROM prescriptions
    GROUP BY doctor_id
)
SELECT
    d.full_name,
    dr.rx_count,
    ROUND((SELECT AVG(rx_count) FROM doc_rx), 1) AS overall_avg
FROM doc_rx dr
JOIN doctors d ON d.doctor_id = dr.doctor_id
WHERE dr.rx_count > (SELECT AVG(rx_count) FROM doc_rx)
ORDER BY dr.rx_count DESC;

-- ─────────────────────────────────────────────────────────────
-- Q21. Using a CTE, find the top 3 revenue-generating months.
-- ─────────────────────────────────────────────────────────────
WITH monthly_revenue AS (
    SELECT
        TO_CHAR(bill_date, 'YYYY-MM')         AS month,
        ROUND(SUM(total_amount), 2)            AS revenue
    FROM billing
    GROUP BY TO_CHAR(bill_date, 'YYYY-MM')
)
SELECT month, revenue,
       RANK() OVER (ORDER BY revenue DESC) AS rank
FROM monthly_revenue
ORDER BY revenue DESC
LIMIT 3;

-- ─────────────────────────────────────────────────────────────
-- Q22. Delete duplicate prescriptions keeping the most recent.
--      (Show the DELETE CTE approach — safe to run as SELECT)
-- ─────────────────────────────────────────────────────────────
WITH duplicates AS (
    SELECT
        prescription_id,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id, medicine_id, prescribed_on
            ORDER BY prescription_id DESC
        ) AS rn
    FROM prescriptions
)
-- SELECT the ones that WOULD be deleted:
SELECT prescription_id
FROM duplicates
WHERE rn > 1;

-- Actual delete (commented for safety):
-- WITH duplicates AS (
--     SELECT prescription_id,
--            ROW_NUMBER() OVER (
--                PARTITION BY patient_id, medicine_id, prescribed_on
--                ORDER BY prescription_id DESC
--            ) AS rn
--     FROM prescriptions
-- )
-- DELETE FROM prescriptions WHERE prescription_id IN (
--     SELECT prescription_id FROM duplicates WHERE rn > 1
-- );

-- ─────────────────────────────────────────────────────────────
-- Q23. Find patients who visited in both January and July
--      (INTERSECT approach).
-- ─────────────────────────────────────────────────────────────
SELECT patient_id FROM appointments
WHERE EXTRACT(MONTH FROM appointment_date) = 1
  AND status = 'Completed'
INTERSECT
SELECT patient_id FROM appointments
WHERE EXTRACT(MONTH FROM appointment_date) = 7
  AND status = 'Completed';

-- ─────────────────────────────────────────────────────────────
-- Q24. Find patients who visited in January but NOT in July
--      (EXCEPT approach).
-- ─────────────────────────────────────────────────────────────
SELECT patient_id FROM appointments
WHERE EXTRACT(MONTH FROM appointment_date) = 1
  AND status = 'Completed'
EXCEPT
SELECT patient_id FROM appointments
WHERE EXTRACT(MONTH FROM appointment_date) = 7
  AND status = 'Completed';

-- ─────────────────────────────────────────────────────────────
-- Q25. Find medicines never prescribed.
-- ─────────────────────────────────────────────────────────────
SELECT m.medicine_id, m.medicine_name, m.category, m.unit_price
FROM medicines m
WHERE NOT EXISTS (
    SELECT 1 FROM prescriptions px
    WHERE px.medicine_id = m.medicine_id
)
AND m.is_active = TRUE
ORDER BY m.category, m.medicine_name;

-- ─────────────────────────────────────────────────────────────
-- Q26. Calculate month-over-month growth rate of new patients.
-- ─────────────────────────────────────────────────────────────
WITH monthly_reg AS (
    SELECT
        DATE_TRUNC('month', registration_date)::DATE AS month,
        COUNT(*) AS new_patients
    FROM patients
    GROUP BY DATE_TRUNC('month', registration_date)
)
SELECT
    month,
    new_patients,
    LAG(new_patients) OVER (ORDER BY month) AS prev_month,
    ROUND(
        (new_patients - LAG(new_patients) OVER (ORDER BY month))::NUMERIC
        / NULLIF(LAG(new_patients) OVER (ORDER BY month), 0) * 100, 1
    ) AS mom_growth_pct
FROM monthly_reg
ORDER BY month;

-- ─────────────────────────────────────────────────────────────
-- Q27. Using window functions, show each payment and its
--      running total per patient.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.full_name,
    py.payment_date::DATE,
    py.amount_paid,
    py.payment_mode,
    SUM(py.amount_paid) OVER (
        PARTITION BY py.patient_id
        ORDER BY py.payment_date
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_paid
FROM payments py
JOIN patients p ON p.patient_id = py.patient_id
ORDER BY py.patient_id, py.payment_date;

-- ─────────────────────────────────────────────────────────────
-- Q28. Find all doctors who have NOT taken any leave.
-- ─────────────────────────────────────────────────────────────
SELECT d.doctor_id, d.full_name, d.joining_date, dep.dept_name
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
WHERE d.doctor_id NOT IN (SELECT DISTINCT doctor_id FROM leaves)
  AND d.is_active = TRUE
ORDER BY d.joining_date;

-- ─────────────────────────────────────────────────────────────
-- Q29. What percentage of bills resulted in full payment?
-- ─────────────────────────────────────────────────────────────
SELECT
    COUNT(*) FILTER (WHERE payment_status = 'Paid')      AS fully_paid,
    COUNT(*)                                              AS total_bills,
    ROUND(
        COUNT(*) FILTER (WHERE payment_status = 'Paid')::NUMERIC
        / COUNT(*) * 100, 1
    )                                                     AS fully_paid_pct,
    ROUND(SUM(total_amount) FILTER (WHERE payment_status = 'Paid'), 2) AS revenue_collected
FROM billing;

-- ─────────────────────────────────────────────────────────────
-- Q30. Find patients with the same name (potential duplicates).
-- ─────────────────────────────────────────────────────────────
SELECT
    full_name,
    COUNT(*) AS count,
    STRING_AGG(patient_id::TEXT, ', ') AS patient_ids,
    STRING_AGG(phone, ', ')            AS phones
FROM patients
GROUP BY full_name
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- ─────────────────────────────────────────────────────────────
-- Q31. Get the 3 most recent appointments for each doctor
--      (using ROW_NUMBER partitioned by doctor).
-- ─────────────────────────────────────────────────────────────
WITH ranked AS (
    SELECT
        a.*,
        d.full_name AS doctor_name,
        p.full_name AS patient_name,
        ROW_NUMBER() OVER (
            PARTITION BY a.doctor_id
            ORDER BY a.appointment_date DESC, a.appointment_time DESC
        ) AS rn
    FROM appointments a
    JOIN doctors  d ON d.doctor_id  = a.doctor_id
    JOIN patients p ON p.patient_id = a.patient_id
)
SELECT
    doctor_name,
    patient_name,
    appointment_date,
    appointment_time,
    status
FROM ranked
WHERE rn <= 3
ORDER BY doctor_name, rn;

-- ─────────────────────────────────────────────────────────────
-- Q32. Find the average number of days between a patient's
--      appointments (engagement frequency).
-- ─────────────────────────────────────────────────────────────
WITH ordered_appts AS (
    SELECT
        patient_id,
        appointment_date,
        LAG(appointment_date) OVER (
            PARTITION BY patient_id
            ORDER BY appointment_date
        ) AS prev_appt_date
    FROM appointments
    WHERE status = 'Completed'
)
SELECT
    p.full_name,
    COUNT(oa.prev_appt_date)                             AS gaps_measured,
    ROUND(AVG(oa.appointment_date - oa.prev_appt_date), 0) AS avg_days_between_visits
FROM ordered_appts oa
JOIN patients p ON p.patient_id = oa.patient_id
WHERE oa.prev_appt_date IS NOT NULL
GROUP BY p.patient_id, p.full_name
HAVING COUNT(oa.prev_appt_date) >= 2
ORDER BY avg_days_between_visits;


-- ╔══════════════════════════════════════════════╗
-- ║              HARD   (Q33–Q45)               ║
-- ╚══════════════════════════════════════════════╝

-- ─────────────────────────────────────────────────────────────
-- Q33. Recursive CTE: Generate a date range and fill
--      missing appointment dates with 0 count.
-- ─────────────────────────────────────────────────────────────
WITH RECURSIVE date_range AS (
    SELECT CURRENT_DATE - 30 AS dt
    UNION ALL
    SELECT dt + 1 FROM date_range WHERE dt < CURRENT_DATE
),
daily_appts AS (
    SELECT appointment_date, COUNT(*) AS cnt
    FROM appointments
    WHERE appointment_date >= CURRENT_DATE - 30
    GROUP BY appointment_date
)
SELECT
    dr.dt                              AS date,
    TO_CHAR(dr.dt, 'Dy')              AS day,
    COALESCE(da.cnt, 0)               AS appointments,
    REPEAT('▓', COALESCE(da.cnt, 0) / 5) AS bar
FROM date_range dr
LEFT JOIN daily_appts da ON da.appointment_date = dr.dt
ORDER BY dr.dt;

-- ─────────────────────────────────────────────────────────────
-- Q34. Find the first and last appointment date for each
--      patient and calculate total active months.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.full_name,
    MIN(a.appointment_date)                              AS first_visit,
    MAX(a.appointment_date)                              AS last_visit,
    COUNT(DISTINCT a.appointment_id)                     AS total_visits,
    DATE_PART('month', AGE(MAX(a.appointment_date),
                            MIN(a.appointment_date)))::INT
        + DATE_PART('year', AGE(MAX(a.appointment_date),
                                  MIN(a.appointment_date)))::INT * 12 AS active_months,
    ROUND(COUNT(DISTINCT a.appointment_id)::NUMERIC /
        NULLIF(DATE_PART('month', AGE(MAX(a.appointment_date),
                                       MIN(a.appointment_date)))::INT
               + DATE_PART('year', AGE(MAX(a.appointment_date),
                                        MIN(a.appointment_date)))::INT * 12, 0), 2)
                                                         AS visits_per_month
FROM patients p
JOIN appointments a ON a.patient_id = p.patient_id
GROUP BY p.patient_id, p.full_name
HAVING COUNT(DISTINCT a.appointment_id) >= 3
ORDER BY active_months DESC;

-- ─────────────────────────────────────────────────────────────
-- Q35. Using a recursive CTE, calculate cumulative revenue
--      for each branch month by month (recursive accumulation).
-- ─────────────────────────────────────────────────────────────
WITH monthly_by_branch AS (
    SELECT
        branch_id,
        DATE_TRUNC('month', bill_date)::DATE AS month,
        SUM(total_amount)                    AS monthly_rev
    FROM billing
    GROUP BY branch_id, DATE_TRUNC('month', bill_date)
)
SELECT
    hb.branch_name,
    m.month,
    ROUND(m.monthly_rev, 2) AS monthly_revenue,
    ROUND(SUM(m.monthly_rev) OVER (
        PARTITION BY m.branch_id
        ORDER BY m.month
        ROWS UNBOUNDED PRECEDING
    ), 2)                                                AS cumulative_revenue
FROM monthly_by_branch m
JOIN hospital_branches hb ON hb.branch_id = m.branch_id
ORDER BY hb.branch_name, m.month;

-- ─────────────────────────────────────────────────────────────
-- Q36. Advanced: Find "champion" doctors — top performer per
--      department on 3 different metrics simultaneously.
-- ─────────────────────────────────────────────────────────────
WITH ranked_doctors AS (
    SELECT
        d.doctor_id,
        d.full_name,
        dep.dept_name,
        COUNT(a.appointment_id)           AS appts,
        COALESCE(SUM(b.total_amount), 0)  AS revenue,
        d.experience_years                AS experience,
        RANK() OVER (PARTITION BY dep.dept_name ORDER BY COUNT(a.appointment_id) DESC) AS appt_rank,
        RANK() OVER (PARTITION BY dep.dept_name ORDER BY COALESCE(SUM(b.total_amount), 0) DESC) AS rev_rank,
        RANK() OVER (PARTITION BY dep.dept_name ORDER BY d.experience_years DESC) AS exp_rank
    FROM doctors d
    JOIN departments dep ON dep.dept_id = d.dept_id
    LEFT JOIN appointments a ON a.doctor_id = d.doctor_id
    LEFT JOIN billing      b ON b.appointment_id = a.appointment_id
    WHERE d.is_active = TRUE
    GROUP BY d.doctor_id, d.full_name, dep.dept_name, d.experience_years
)
SELECT
    dept_name,
    full_name,
    appts,
    ROUND(revenue, 2) AS revenue,
    experience        AS experience_yrs,
    appt_rank, rev_rank, exp_rank,
    (appt_rank + rev_rank + exp_rank)::NUMERIC AS composite_score
FROM ranked_doctors
WHERE appt_rank <= 3 OR rev_rank <= 3
ORDER BY dept_name, composite_score;

-- ─────────────────────────────────────────────────────────────
-- Q37. Detect anomalies: bills with total_amount > 3× the
--      standard deviation above the mean (outlier detection).
-- ─────────────────────────────────────────────────────────────
WITH stats AS (
    SELECT
        AVG(total_amount)    AS mean,
        STDDEV(total_amount) AS std
    FROM billing
)
SELECT
    b.bill_id,
    p.full_name      AS patient,
    b.total_amount,
    ROUND(s.mean, 2) AS overall_mean,
    ROUND(s.std, 2)  AS std_dev,
    ROUND((b.total_amount - s.mean) / s.std, 2) AS z_score,
    b.payment_status,
    b.bill_date
FROM billing b
CROSS JOIN stats s
JOIN patients p ON p.patient_id = b.patient_id
WHERE b.total_amount > s.mean + 3 * s.std
ORDER BY b.total_amount DESC;

-- ─────────────────────────────────────────────────────────────
-- Q38. Write a query to UPDATE billing status using a CTE
--      (mark overdue bills — 90+ days pending).
-- ─────────────────────────────────────────────────────────────
-- Preview (SELECT) of what would be updated:
WITH overdue AS (
    SELECT bill_id
    FROM billing
    WHERE payment_status = 'Pending'
      AND bill_date < CURRENT_DATE - 90
)
SELECT b.bill_id, p.full_name, b.bill_date, b.total_amount
FROM billing b
JOIN patients p ON p.patient_id = b.patient_id
WHERE b.bill_id IN (SELECT bill_id FROM overdue);

-- Actual update (commented for safety):
-- WITH overdue AS (
--     SELECT bill_id FROM billing
--     WHERE payment_status = 'Pending' AND bill_date < CURRENT_DATE - 90
-- )
-- UPDATE billing SET payment_status = 'Overdue'
-- WHERE bill_id IN (SELECT bill_id FROM overdue);

-- ─────────────────────────────────────────────────────────────
-- Q39. Find doctors whose appointment cancellation rate is
--      above 20% — using HAVING with computed aggregates.
-- ─────────────────────────────────────────────────────────────
SELECT
    d.full_name,
    dep.dept_name,
    COUNT(a.appointment_id)                              AS total,
    COUNT(*) FILTER (WHERE a.status = 'Cancelled')       AS cancelled,
    ROUND(
        COUNT(*) FILTER (WHERE a.status = 'Cancelled')::NUMERIC
        / NULLIF(COUNT(*), 0) * 100, 1
    )                                                    AS cancel_rate_pct
FROM appointments a
JOIN doctors d     ON d.doctor_id  = a.doctor_id
JOIN departments dep ON dep.dept_id = d.dept_id
GROUP BY d.doctor_id, d.full_name, dep.dept_name
HAVING COUNT(*) >= 10
   AND (COUNT(*) FILTER (WHERE a.status = 'Cancelled'))::NUMERIC
       / NULLIF(COUNT(*), 0) > 0.20
ORDER BY cancel_rate_pct DESC;

-- ─────────────────────────────────────────────────────────────
-- Q40. Gap analysis: Find time gaps > 60 days between a
--      patient's consecutive appointments.
-- ─────────────────────────────────────────────────────────────
WITH gaps AS (
    SELECT
        patient_id,
        appointment_date,
        LAG(appointment_date) OVER (
            PARTITION BY patient_id ORDER BY appointment_date
        ) AS prev_date,
        appointment_date - LAG(appointment_date) OVER (
            PARTITION BY patient_id ORDER BY appointment_date
        ) AS gap_days
    FROM appointments
    WHERE status = 'Completed'
)
SELECT
    p.full_name,
    g.prev_date   AS last_visit,
    g.appointment_date AS return_date,
    g.gap_days
FROM gaps g
JOIN patients p ON p.patient_id = g.patient_id
WHERE g.gap_days > 60
ORDER BY g.gap_days DESC
LIMIT 20;

-- ─────────────────────────────────────────────────────────────
-- Q41. Pivot: Show medicine category totals across branches
--      using conditional aggregation.
-- ─────────────────────────────────────────────────────────────
SELECT
    m.category,
    SUM(mi.quantity) FILTER (WHERE mi.branch_id = 1) AS branch_1_stock,
    SUM(mi.quantity) FILTER (WHERE mi.branch_id = 2) AS branch_2_stock,
    SUM(mi.quantity) FILTER (WHERE mi.branch_id = 3) AS branch_3_stock,
    SUM(mi.quantity) FILTER (WHERE mi.branch_id = 4) AS branch_4_stock,
    SUM(mi.quantity) FILTER (WHERE mi.branch_id = 5) AS branch_5_stock,
    SUM(mi.quantity)                                  AS total_stock
FROM medicine_inventory mi
JOIN medicines m ON m.medicine_id = mi.medicine_id
WHERE mi.is_active = TRUE
GROUP BY m.category
ORDER BY total_stock DESC;

-- ─────────────────────────────────────────────────────────────
-- Q42. Complex multi-join: Show complete patient journey
--      (appointment → admission → discharge → bill → payment).
-- ─────────────────────────────────────────────────────────────
SELECT
    p.full_name                                AS patient,
    p.age,
    doc.full_name                              AS doctor,
    dep.dept_name,
    a.appointment_date,
    adm.admission_date::DATE,
    dis.discharge_date::DATE,
    (dis.discharge_date - adm.admission_date)::TEXT AS los,
    ROUND(b.total_amount, 2)                   AS bill_amount,
    ROUND(COALESCE(SUM(py.amount_paid), 0), 2) AS amount_paid,
    b.payment_status
FROM patients    p
JOIN appointments a   ON a.patient_id   = p.patient_id
JOIN doctors     doc  ON doc.doctor_id  = a.doctor_id
JOIN departments dep  ON dep.dept_id    = a.dept_id
JOIN admissions  adm  ON adm.patient_id = p.patient_id
    AND adm.doctor_id = a.doctor_id
JOIN discharges  dis  ON dis.admission_id = adm.admission_id
JOIN billing     b    ON b.admission_id   = adm.admission_id
LEFT JOIN payments py ON py.bill_id       = b.bill_id
GROUP BY p.patient_id, p.full_name, p.age, doc.full_name, dep.dept_name,
         a.appointment_date, adm.admission_date, dis.discharge_date,
         b.total_amount, b.payment_status
ORDER BY adm.admission_date DESC
LIMIT 20;

-- ─────────────────────────────────────────────────────────────
-- Q43. Using LATERAL, for each department get the top doctor
--      by revenue AND by appointments in one query.
-- ─────────────────────────────────────────────────────────────
SELECT
    dep.dept_name,
    top_rev.doctor_name  AS top_by_revenue,
    ROUND(top_rev.revenue, 2),
    top_appt.doctor_name AS top_by_appointments,
    top_appt.appts
FROM departments dep
CROSS JOIN LATERAL (
    SELECT d.full_name AS doctor_name, COALESCE(SUM(b.total_amount), 0) AS revenue
    FROM doctors d
    LEFT JOIN appointments a ON a.doctor_id = d.doctor_id
    LEFT JOIN billing b ON b.appointment_id = a.appointment_id
    WHERE d.dept_id = dep.dept_id AND d.is_active = TRUE
    GROUP BY d.doctor_id, d.full_name
    ORDER BY revenue DESC LIMIT 1
) top_rev
CROSS JOIN LATERAL (
    SELECT d.full_name AS doctor_name, COUNT(a.appointment_id) AS appts
    FROM doctors d
    LEFT JOIN appointments a ON a.doctor_id = d.doctor_id
    WHERE d.dept_id = dep.dept_id AND d.is_active = TRUE
    GROUP BY d.doctor_id, d.full_name
    ORDER BY appts DESC LIMIT 1
) top_appt
ORDER BY dep.dept_name;

-- ─────────────────────────────────────────────────────────────
-- Q44. Hospital-wide KPI summary (single query dashboard).
-- ─────────────────────────────────────────────────────────────
SELECT
    (SELECT COUNT(*) FROM patients WHERE is_active = TRUE)           AS active_patients,
    (SELECT COUNT(*) FROM doctors  WHERE is_active = TRUE)           AS active_doctors,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date = CURRENT_DATE) AS todays_appointments,
    (SELECT COUNT(*) FROM admissions WHERE status = 'Active')        AS current_inpatients,
    (SELECT COUNT(*) FROM beds WHERE status = 'Available')           AS available_beds,
    (SELECT ROUND(COUNT(*) FILTER (WHERE status='Available')::NUMERIC
                  / NULLIF(COUNT(*),0) * 100, 1) FROM beds)         AS bed_availability_pct,
    (SELECT ROUND(SUM(total_amount), 2) FROM billing
     WHERE bill_date = CURRENT_DATE)                                  AS todays_billing,
    (SELECT ROUND(SUM(amount_paid), 2) FROM payments
     WHERE payment_date::DATE = CURRENT_DATE)                        AS todays_collections,
    (SELECT COUNT(*) FROM medicine_inventory
     WHERE quantity <= reorder_level AND is_active = TRUE
       AND expiry_date > CURRENT_DATE)                               AS low_stock_alerts,
    (SELECT COUNT(*) FROM medicine_inventory
     WHERE expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
       AND is_active = TRUE)                                          AS expiring_soon;

-- ─────────────────────────────────────────────────────────────
-- Q45. Write a query to implement a sliding window
--      (7-day moving average) for daily appointment counts.
-- ─────────────────────────────────────────────────────────────
WITH daily AS (
    SELECT
        appointment_date,
        COUNT(*) AS daily_count
    FROM appointments
    WHERE appointment_date >= CURRENT_DATE - 90
    GROUP BY appointment_date
),
filled AS (
    SELECT
        gs::DATE AS dt,
        COALESCE(d.daily_count, 0) AS cnt
    FROM GENERATE_SERIES(CURRENT_DATE - 90, CURRENT_DATE, INTERVAL '1 day') gs
    LEFT JOIN daily d ON d.appointment_date = gs::DATE
)
SELECT
    dt,
    cnt AS daily_appointments,
    ROUND(AVG(cnt) OVER (
        ORDER BY dt
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 1) AS moving_avg_7d,
    SUM(cnt) OVER (ORDER BY dt ROWS UNBOUNDED PRECEDING) AS cumulative_total
FROM filled
ORDER BY dt;
