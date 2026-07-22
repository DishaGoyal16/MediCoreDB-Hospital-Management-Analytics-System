-- =============================================================================
-- FILE: queries/beginner_queries.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: 20 beginner-level SQL queries demonstrating core concepts.
-- =============================================================================

-- Q1. List all active patients with their age
SELECT
    patient_id, full_name, gender, age, blood_group, phone
FROM patients
WHERE is_active = TRUE
ORDER BY last_name, first_name;

-- Q2. Count patients by gender
SELECT
    gender,
    COUNT(*) AS total_patients
FROM patients
GROUP BY gender;

-- Q3. List all doctors in the Cardiology department
SELECT
    d.full_name       AS doctor_name,
    d.qualification,
    d.experience_years,
    d.consultation_fee,
    d.employment_type
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
WHERE dep.dept_name = 'Cardiology'
  AND d.is_active = TRUE
ORDER BY d.experience_years DESC;

-- Q4. Today's appointment schedule
SELECT
    a.appointment_time,
    p.full_name         AS patient_name,
    p.age,
    d.full_name         AS doctor_name,
    a.appointment_type,
    a.status,
    a.reason
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
JOIN doctors  d ON d.doctor_id  = a.doctor_id
WHERE a.appointment_date = CURRENT_DATE
ORDER BY a.appointment_time;

-- Q5. Available beds by room type
SELECT
    r.room_type,
    COUNT(*) AS available_beds
FROM beds b
JOIN rooms r ON r.room_id = b.room_id
WHERE b.status = 'Available'
GROUP BY r.room_type
ORDER BY available_beds DESC;

-- Q6. Top 10 most expensive medicines
SELECT
    medicine_name, generic_name, category, unit, unit_price
FROM medicines
WHERE is_active = TRUE
ORDER BY unit_price DESC
LIMIT 10;

-- Q7. Count appointments by status
SELECT
    status,
    COUNT(*) AS count
FROM appointments
GROUP BY status
ORDER BY count DESC;

-- Q8. List all departments with their branch name
SELECT
    hb.branch_name,
    dep.dept_name,
    dep.dept_code,
    dep.floor_no,
    d.full_name AS dept_head
FROM departments dep
JOIN hospital_branches hb ON hb.branch_id = dep.branch_id
LEFT JOIN doctors d ON d.doctor_id = dep.head_doctor_id
ORDER BY hb.branch_name, dep.dept_name;

-- Q9. Patients registered in the last 30 days
SELECT
    full_name, gender, age, blood_group, phone, registration_date
FROM patients
WHERE registration_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY registration_date DESC;

-- Q10. Total revenue collected this month
SELECT
    ROUND(SUM(amount_paid), 2) AS revenue_collected_this_month
FROM payments
WHERE EXTRACT(YEAR  FROM payment_date) = EXTRACT(YEAR  FROM CURRENT_DATE)
  AND EXTRACT(MONTH FROM payment_date) = EXTRACT(MONTH FROM CURRENT_DATE);

-- Q11. List all medicines expiring in the next 90 days
SELECT
    m.medicine_name,
    m.category,
    mi.batch_number,
    mi.quantity,
    mi.expiry_date,
    hb.branch_name
FROM medicine_inventory mi
JOIN medicines m         ON m.medicine_id = mi.medicine_id
JOIN hospital_branches hb ON hb.branch_id = mi.branch_id
WHERE mi.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 90
  AND mi.is_active = TRUE
ORDER BY mi.expiry_date;

-- Q12. How many doctors per department?
SELECT
    dep.dept_name,
    COUNT(d.doctor_id) AS doctor_count
FROM departments dep
LEFT JOIN doctors d ON d.dept_id = dep.dept_id AND d.is_active = TRUE
GROUP BY dep.dept_name
ORDER BY doctor_count DESC;

-- Q13. List patients with insurance
SELECT
    p.full_name,
    i.provider_name,
    i.policy_number,
    i.policy_type,
    i.coverage_amount,
    i.valid_to
FROM patients p
JOIN insurance i ON i.insurance_id = p.insurance_id
WHERE i.valid_to >= CURRENT_DATE
ORDER BY i.coverage_amount DESC;

-- Q14. Current active admissions count by branch
SELECT
    hb.branch_name,
    COUNT(a.admission_id) AS active_admissions
FROM admissions a
JOIN hospital_branches hb ON hb.branch_id = a.branch_id
WHERE a.status = 'Active'
GROUP BY hb.branch_name
ORDER BY active_admissions DESC;

-- Q15. Medicines with out-of-stock status
SELECT
    m.medicine_name,
    m.category,
    hb.branch_name,
    mi.quantity
FROM medicine_inventory mi
JOIN medicines m          ON m.medicine_id = mi.medicine_id
JOIN hospital_branches hb ON hb.branch_id  = mi.branch_id
WHERE mi.quantity = 0 AND mi.is_active = TRUE
ORDER BY hb.branch_name, m.medicine_name;

-- Q16. List all payment transactions for a specific bill (example: bill_id 1)
SELECT
    py.payment_id,
    py.payment_date,
    py.amount_paid,
    py.payment_mode,
    py.transaction_ref,
    s.full_name AS received_by
FROM payments py
LEFT JOIN staff s ON s.staff_id = py.received_by
WHERE py.bill_id = 1;

-- Q17. Doctor with highest consultation fee per department
SELECT DISTINCT ON (dep.dept_name)
    dep.dept_name,
    d.full_name       AS doctor_name,
    d.consultation_fee
FROM doctors d
JOIN departments dep ON dep.dept_id = d.dept_id
WHERE d.is_active = TRUE
ORDER BY dep.dept_name, d.consultation_fee DESC;

-- Q18. Average patient age by blood group
SELECT
    blood_group,
    ROUND(AVG(age), 1) AS avg_age,
    COUNT(*)           AS patient_count
FROM patients
WHERE blood_group IS NOT NULL AND is_active = TRUE
GROUP BY blood_group
ORDER BY blood_group;

-- Q19. Number of beds per branch
SELECT
    hb.branch_name,
    COUNT(b.bed_id)                                             AS total_beds,
    COUNT(b.bed_id) FILTER (WHERE b.status = 'Available')      AS available,
    COUNT(b.bed_id) FILTER (WHERE b.status = 'Occupied')       AS occupied,
    COUNT(b.bed_id) FILTER (WHERE b.status = 'Maintenance')    AS maintenance
FROM beds b
JOIN rooms r              ON r.room_id   = b.room_id
JOIN hospital_branches hb ON hb.branch_id = r.branch_id
GROUP BY hb.branch_name
ORDER BY total_beds DESC;

-- Q20. List all staff sorted by salary descending
SELECT
    full_name,
    role,
    employment_type,
    salary,
    joining_date
FROM staff
WHERE is_active = TRUE
ORDER BY salary DESC
LIMIT 20;
