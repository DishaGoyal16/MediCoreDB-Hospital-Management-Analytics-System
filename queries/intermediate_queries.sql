-- =============================================================================
-- FILE: queries/intermediate_queries.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: 20 intermediate SQL queries using JOINs, GROUP BY,
--              subqueries, HAVING, and multi-table operations.
-- =============================================================================

-- I1. Appointment completion rate per doctor (current year)
SELECT
    d.full_name                                                AS doctor_name,
    dep.dept_name,
    COUNT(a.appointment_id)                                    AS total_booked,
    COUNT(a.appointment_id) FILTER (WHERE a.status = 'Completed')  AS completed,
    COUNT(a.appointment_id) FILTER (WHERE a.status = 'Cancelled')  AS cancelled,
    COUNT(a.appointment_id) FILTER (WHERE a.status = 'No-Show')    AS no_show,
    ROUND(
        COUNT(a.appointment_id) FILTER (WHERE a.status = 'Completed')
        ::NUMERIC / NULLIF(COUNT(a.appointment_id), 0) * 100, 1
    )                                                          AS completion_rate_pct
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
LEFT JOIN appointments a ON a.doctor_id = d.doctor_id
    AND EXTRACT(YEAR FROM a.appointment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE d.is_active = TRUE
GROUP BY d.doctor_id, d.full_name, dep.dept_name
HAVING COUNT(a.appointment_id) > 0
ORDER BY completion_rate_pct DESC;

-- I2. Department-wise monthly revenue for current year
SELECT
    dep.dept_name,
    TO_CHAR(b.bill_date, 'Mon YYYY')                           AS month,
    COUNT(b.bill_id)                                           AS bills,
    ROUND(SUM(b.total_amount), 2)                              AS revenue
FROM billing b
JOIN appointments a ON a.appointment_id = b.appointment_id
JOIN departments dep ON dep.dept_id    = a.dept_id
WHERE EXTRACT(YEAR FROM b.bill_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY dep.dept_name, TO_CHAR(b.bill_date, 'Mon YYYY'), EXTRACT(MONTH FROM b.bill_date)
ORDER BY dep.dept_name, EXTRACT(MONTH FROM b.bill_date);

-- I3. Most prescribed medicines with prescription count
SELECT
    m.medicine_name,
    m.generic_name,
    m.category,
    COUNT(px.prescription_id)                                  AS total_prescriptions,
    SUM(px.quantity)                                           AS total_qty,
    ROUND(AVG(px.duration_days), 1)                            AS avg_duration_days,
    ROUND(SUM(px.quantity * m.unit_price), 2)                  AS total_medicine_revenue
FROM prescriptions px
JOIN medicines m ON m.medicine_id = px.medicine_id
GROUP BY m.medicine_id, m.medicine_name, m.generic_name, m.category
ORDER BY total_prescriptions DESC
LIMIT 20;

-- I4. Patients with pending bills over ₹10,000
SELECT
    p.full_name,
    p.phone,
    hb.branch_name,
    COUNT(b.bill_id)                                           AS pending_bills,
    ROUND(SUM(b.total_amount), 2)                              AS total_pending_amount,
    MIN(b.bill_date)                                           AS oldest_bill_date
FROM billing b
JOIN patients p ON p.patient_id = b.patient_id
JOIN hospital_branches hb ON hb.branch_id = b.branch_id
WHERE b.payment_status IN ('Pending','Partial')
GROUP BY p.patient_id, p.full_name, p.phone, hb.branch_name
HAVING SUM(b.total_amount) > 10000
ORDER BY total_pending_amount DESC;

-- I5. Lab tests ordered most frequently, with avg turnaround
SELECT
    lt.test_name,
    lt.category,
    lt.cost,
    COUNT(lr.report_id)                                        AS times_ordered,
    COUNT(lr.report_id) FILTER (WHERE lr.result_status = 'Abnormal') AS abnormal_count,
    COUNT(lr.report_id) FILTER (WHERE lr.result_status = 'Critical') AS critical_count,
    ROUND(
        COUNT(lr.report_id) FILTER (WHERE lr.result_status IN ('Abnormal','Critical'))
        ::NUMERIC / NULLIF(COUNT(lr.report_id), 0) * 100, 1
    )                                                          AS abnormal_rate_pct
FROM lab_tests lt
LEFT JOIN lab_reports lr ON lr.test_id = lt.test_id
WHERE lt.is_active = TRUE
GROUP BY lt.test_id, lt.test_name, lt.category, lt.cost
ORDER BY times_ordered DESC;

-- I6. Average waiting time (appointment_time vs next slot gap)
SELECT
    d.full_name                                                AS doctor_name,
    a.appointment_date,
    COUNT(a.appointment_id)                                    AS appointments_that_day,
    MIN(a.appointment_time)                                    AS first_slot,
    MAX(a.appointment_time)                                    AS last_slot,
    EXTRACT(EPOCH FROM (MAX(a.appointment_time) - MIN(a.appointment_time))) / 60::NUMERIC AS session_duration_mins
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status IN ('Completed','Confirmed')
GROUP BY d.doctor_id, d.full_name, a.appointment_date
HAVING COUNT(a.appointment_id) > 5
ORDER BY session_duration_mins DESC
LIMIT 20;

-- I7. Rooms with highest occupancy in last 90 days
SELECT
    hb.branch_name,
    r.room_number,
    r.room_type,
    dep.dept_name,
    COUNT(DISTINCT adm.admission_id)                           AS admissions_handled,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (d.discharge_date - adm.admission_date)) / 86400
    ), 1)                                                      AS avg_stay_days,
    r.daily_charge
FROM rooms r
JOIN beds b               ON b.room_id      = r.room_id
JOIN admissions adm       ON adm.bed_id     = b.bed_id
JOIN discharges d         ON d.admission_id = adm.admission_id
JOIN departments dep      ON dep.dept_id    = r.dept_id
JOIN hospital_branches hb ON hb.branch_id  = r.branch_id
WHERE adm.admission_date >= CURRENT_DATE - 90
GROUP BY r.room_id, r.room_number, r.room_type, dep.dept_name,
         hb.branch_name, r.daily_charge
ORDER BY admissions_handled DESC
LIMIT 20;

-- I8. Stock valuation per branch
SELECT
    hb.branch_name,
    m.category,
    COUNT(DISTINCT m.medicine_id)                              AS distinct_medicines,
    SUM(mi.quantity)                                           AS total_units,
    ROUND(SUM(mi.quantity * mi.purchase_price), 2)             AS stock_cost_value,
    ROUND(SUM(mi.quantity * m.unit_price), 2)                  AS stock_retail_value,
    ROUND(SUM(mi.quantity * m.unit_price) -
          SUM(mi.quantity * mi.purchase_price), 2)             AS potential_margin
FROM medicine_inventory mi
JOIN medicines m          ON m.medicine_id = mi.medicine_id
JOIN hospital_branches hb ON hb.branch_id  = mi.branch_id
WHERE mi.is_active = TRUE AND mi.expiry_date > CURRENT_DATE
GROUP BY hb.branch_name, m.category
ORDER BY hb.branch_name, stock_retail_value DESC;

-- I9. Insurance claim analysis
SELECT
    i.provider_name,
    COUNT(DISTINCT i.insurance_id)                             AS policy_count,
    COUNT(b.bill_id)                                           AS claims_filed,
    ROUND(SUM(b.insurance_covered), 2)                         AS total_covered,
    ROUND(AVG(b.insurance_covered), 2)                         AS avg_claim,
    ROUND(SUM(b.total_amount), 2)                              AS total_billed,
    ROUND(SUM(b.insurance_covered) / NULLIF(SUM(b.total_amount), 0) * 100, 1) AS coverage_pct
FROM insurance i
JOIN billing b ON b.insurance_id = i.insurance_id
WHERE b.insurance_covered > 0
GROUP BY i.provider_name
ORDER BY total_covered DESC;

-- I10. Doctors on leave this week
SELECT
    d.full_name                                                AS doctor_name,
    dep.dept_name,
    hb.branch_name,
    l.leave_from,
    l.leave_to,
    l.leave_type,
    (l.leave_to - l.leave_from + 1)                           AS leave_days,
    s.full_name                                                AS approved_by
FROM leaves l
JOIN doctors d            ON d.doctor_id   = l.doctor_id
JOIN departments dep      ON dep.dept_id   = d.dept_id
JOIN hospital_branches hb ON hb.branch_id  = d.branch_id
LEFT JOIN staff s         ON s.staff_id    = l.approved_by
WHERE l.status = 'Approved'
  AND l.leave_from <= CURRENT_DATE + 7
  AND l.leave_to   >= CURRENT_DATE
ORDER BY l.leave_from;

-- I11. Revenue breakdown by payment mode
SELECT
    payment_mode,
    COUNT(payment_id)                                          AS transaction_count,
    ROUND(SUM(amount_paid), 2)                                 AS total_collected,
    ROUND(AVG(amount_paid), 2)                                 AS avg_transaction,
    ROUND(SUM(amount_paid) / (SELECT SUM(amount_paid) FROM payments) * 100, 1) AS share_pct
FROM payments
GROUP BY payment_mode
ORDER BY total_collected DESC;

-- I12. Patient demographics by city
SELECT
    city,
    COUNT(*)                                                   AS patient_count,
    COUNT(*) FILTER (WHERE gender = 'M')                       AS male,
    COUNT(*) FILTER (WHERE gender = 'F')                       AS female,
    ROUND(AVG(age), 1)                                         AS avg_age,
    COUNT(*) FILTER (WHERE age < 18)                           AS pediatric,
    COUNT(*) FILTER (WHERE age >= 60)                          AS senior
FROM patients
WHERE is_active = TRUE AND city IS NOT NULL
GROUP BY city
HAVING COUNT(*) >= 5
ORDER BY patient_count DESC;

-- I13. Nurse workload by department and shift
SELECT
    dep.dept_name,
    hb.branch_name,
    n.shift,
    COUNT(n.nurse_id)                                          AS nurses_on_shift,
    -- Ratio: patients per nurse (active admissions)
    COUNT(DISTINCT adm.patient_id)                             AS active_patients_in_dept
FROM nurses n
JOIN departments dep       ON dep.dept_id   = n.dept_id
JOIN hospital_branches hb  ON hb.branch_id  = n.branch_id
LEFT JOIN admissions adm   ON adm.branch_id = n.branch_id
    AND adm.status = 'Active'
LEFT JOIN beds b    ON b.bed_id  = adm.bed_id
LEFT JOIN rooms r   ON r.room_id = b.room_id AND r.dept_id = n.dept_id
WHERE n.is_active = TRUE
GROUP BY dep.dept_name, hb.branch_name, n.shift
ORDER BY dep.dept_name, n.shift;

-- I14. Medicines below reorder level (low stock alert)
SELECT
    m.medicine_name,
    m.category,
    hb.branch_name,
    mi.quantity                                                AS current_stock,
    mi.reorder_level,
    mi.reorder_level - mi.quantity                             AS units_needed,
    fn_medicine_stock_status(m.medicine_id, hb.branch_id)     AS stock_status,
    s.supplier_name,
    s.phone                                                    AS supplier_phone
FROM medicine_inventory mi
JOIN medicines m          ON m.medicine_id  = mi.medicine_id
JOIN hospital_branches hb ON hb.branch_id   = mi.branch_id
LEFT JOIN suppliers s     ON s.supplier_id  = mi.supplier_id
WHERE mi.quantity <= mi.reorder_level
  AND mi.is_active = TRUE
  AND mi.expiry_date > CURRENT_DATE
ORDER BY (mi.reorder_level - mi.quantity) DESC;

-- I15. Discharge summary statistics
SELECT
    discharge_type,
    COUNT(*)                                                   AS count,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (d.discharge_date - a.admission_date)) / 86400
    ), 1)                                                      AS avg_los_days,
    COUNT(*) FILTER (WHERE d.follow_up_date IS NOT NULL)       AS with_follow_up
FROM discharges d
JOIN admissions a ON a.admission_id = d.admission_id
GROUP BY discharge_type
ORDER BY count DESC;

-- I16. Doctors seeing the most unique patients
SELECT
    d.full_name,
    dep.dept_name,
    COUNT(DISTINCT a.patient_id) AS unique_patients,
    COUNT(a.appointment_id)      AS total_appointments,
    ROUND(COUNT(a.appointment_id)::NUMERIC / NULLIF(COUNT(DISTINCT a.patient_id),0), 1) AS appts_per_patient
FROM appointments a
JOIN doctors d     ON d.doctor_id  = a.doctor_id
JOIN departments dep ON dep.dept_id = d.dept_id
GROUP BY d.doctor_id, d.full_name, dep.dept_name
ORDER BY unique_patients DESC
LIMIT 15;

-- I17. Patients with critical lab results (last 30 days)
SELECT
    p.full_name,
    p.phone,
    lt.test_name,
    lr.result_value,
    lr.result_status,
    lr.test_date,
    d.full_name AS ordered_by,
    lr.remarks
FROM lab_reports lr
JOIN patients  p  ON p.patient_id  = lr.patient_id
JOIN lab_tests lt ON lt.test_id    = lr.test_id
JOIN doctors   d  ON d.doctor_id   = lr.doctor_id
WHERE lr.result_status = 'Critical'
  AND lr.test_date >= CURRENT_DATE - 30
ORDER BY lr.test_date DESC;

-- I18. Appointment no-show rate by day of week
SELECT
    TO_CHAR(appointment_date, 'Day')                           AS day_of_week,
    EXTRACT(DOW FROM appointment_date)::INT                    AS day_num,
    COUNT(*)                                                   AS total_appointments,
    COUNT(*) FILTER (WHERE status = 'No-Show')                 AS no_shows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'No-Show')::NUMERIC
        / NULLIF(COUNT(*), 0) * 100, 1
    )                                                          AS no_show_pct
FROM appointments
GROUP BY TO_CHAR(appointment_date, 'Day'), EXTRACT(DOW FROM appointment_date)
ORDER BY day_num;

-- I19. Revenue vs target by branch (using estimated targets)
WITH targets AS (
    SELECT
        branch_id,
        CASE branch_id
            WHEN 1 THEN 5000000
            WHEN 2 THEN 4500000
            WHEN 3 THEN 4000000
            WHEN 4 THEN 3500000
            WHEN 5 THEN 3000000
        END AS annual_target
    FROM hospital_branches
)
SELECT
    hb.branch_name,
    t.annual_target,
    ROUND(SUM(b.total_amount), 2)                              AS actual_revenue,
    ROUND(SUM(b.total_amount) / t.annual_target * 100, 1)     AS target_achievement_pct
FROM billing b
JOIN hospital_branches hb ON hb.branch_id = b.branch_id
JOIN targets t ON t.branch_id = hb.branch_id
WHERE EXTRACT(YEAR FROM b.bill_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY hb.branch_name, t.annual_target
ORDER BY target_achievement_pct DESC;

-- I20. Doctor specialization coverage matrix
SELECT
    s.spec_name,
    COUNT(ds.doctor_id)                                        AS total_doctors,
    COUNT(ds.doctor_id) FILTER (WHERE ds.is_primary = TRUE)   AS primary_specialists,
    COUNT(ds.doctor_id) FILTER (WHERE ds.is_primary = FALSE)  AS secondary_specialists,
    ARRAY_AGG(d.full_name ORDER BY d.full_name)               AS doctor_list
FROM specializations s
LEFT JOIN doctor_specializations ds ON ds.spec_id = s.spec_id
LEFT JOIN doctors d ON d.doctor_id = ds.doctor_id AND d.is_active = TRUE
GROUP BY s.spec_id, s.spec_name
ORDER BY total_doctors DESC;
