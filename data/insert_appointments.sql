-- =============================================================================
-- FILE: data/insert_appointments.sql
-- NOTE: Core appointment data is in generate_large_dataset.sql.
--       This file adds specific real-world named appointments for demo.
-- =============================================================================
-- Today's appointments for dashboard demo
INSERT INTO appointments
    (branch_id, patient_id, doctor_id, dept_id,
     appointment_date, appointment_time, appointment_type, status, reason)
VALUES
(1,  1,  1, 1, CURRENT_DATE, '09:00', 'OPD',       'Confirmed', 'Chest pain and palpitations'),
(1,  2,  2, 1, CURRENT_DATE, '09:20', 'OPD',       'Confirmed', 'Blood pressure review'),
(1,  3,  8, 2, CURRENT_DATE, '09:40', 'Follow-Up', 'Confirmed', 'Post knee replacement'),
(1,  4, 15, 3, CURRENT_DATE, '10:00', 'OPD',       'Confirmed', 'Severe migraine'),
(1,  5, 21, 4, CURRENT_DATE, '10:20', 'OPD',       'Scheduled', 'Abdominal pain'),
(2,  6, 30, 6, CURRENT_DATE, '09:00', 'OPD',       'Confirmed', 'Child fever 3 days'),
(2,  7, 37, 7, CURRENT_DATE, '09:30', 'OPD',       'Confirmed', 'Pregnancy 28 weeks'),
(2,  8, 43, 8, CURRENT_DATE, '10:00', 'OPD',       'Scheduled', 'Chemotherapy review'),
(3,  9, 56, 11, CURRENT_DATE, '09:00', 'OPD',      'Confirmed', 'Acne and skin rash'),
(3, 10, 65, 13, CURRENT_DATE, '09:30', 'OPD',      'Confirmed', 'Vision blurring')
ON CONFLICT DO NOTHING;

-- NOTE: To use stored procedures after data load, use OUT-first syntax:
-- CALL sp_book_appointment(NULL, 1, 1, 1, 1, CURRENT_DATE+1, '09:00');
SELECT 'insert_appointments.sql completed.' AS status;