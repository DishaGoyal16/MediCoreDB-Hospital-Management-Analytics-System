-- =============================================================================
-- FILE: data/insert_billing.sql
-- NOTE: Bulk billing is generated in generate_large_dataset.sql.
--       This file verifies and patches billing edge cases.
-- =============================================================================

-- Ensure all discharged patients have a bill
INSERT INTO billing
    (patient_id, admission_id, branch_id, bill_date,
     consultation_charge, room_charge, other_charge,
     discount_pct, tax_pct, payment_status)
SELECT
    d.patient_id,
    d.admission_id,
    a.branch_id,
    d.discharge_date::DATE,
    500,    -- default consultation
    2000,   -- default room charge
    200,    -- misc
    0,
    18,
    'Pending'
FROM discharges d
JOIN admissions a ON a.admission_id = d.admission_id
WHERE NOT EXISTS (
    SELECT 1 FROM billing b WHERE b.admission_id = d.admission_id
)
LIMIT 100;

-- Summary
SELECT
    payment_status,
    COUNT(*)              AS bill_count,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM billing
GROUP BY payment_status
ORDER BY total_revenue DESC;
