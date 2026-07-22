-- =============================================================================
-- FILE: data/insert_treatments.sql
-- NOTE: Bulk treatment data is generated in generate_large_dataset.sql.
--       This file adds specific treatment records for the demo admissions.
-- =============================================================================
-- Sample treatments for the first few admissions created during bulk generation
INSERT INTO treatments
    (admission_id, patient_id, doctor_id, treatment_name, treatment_type,
     treatment_date, cost, notes)
SELECT
    a.admission_id,
    a.patient_id,
    a.doctor_id,
    'Initial Assessment & Monitoring',
    'Procedure',
    a.admission_date::DATE,
    500,
    'Patient assessed on admission. Vital signs stable. Plan of care initiated.'
FROM admissions a
WHERE a.admission_id <= 10
ON CONFLICT DO NOTHING;

SELECT 'insert_treatments.sql completed.' AS status;
