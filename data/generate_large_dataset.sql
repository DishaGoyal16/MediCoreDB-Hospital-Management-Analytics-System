-- =============================================================================
-- FILE: data/generate_large_dataset.sql
-- DESCRIPTION: Generates 5000+ appointments, admissions, treatments, lab
--              reports, prescriptions, and 3000+ bills using PL/pgSQL loops.
--              Run LAST among data scripts.
-- =============================================================================

-- Disable triggers temporarily for bulk load performance
ALTER TABLE appointments   DISABLE TRIGGER trg_prevent_double_booking;
ALTER TABLE appointments   DISABLE TRIGGER trg_check_doctor_leave;
ALTER TABLE admissions     DISABLE TRIGGER trg_check_bed_availability;
ALTER TABLE admissions     DISABLE TRIGGER trg_mark_bed_occupied;
ALTER TABLE prescriptions  DISABLE TRIGGER trg_deduct_medicine_stock;

-- =============================================================================
-- 1. LAB TESTS
-- =============================================================================
INSERT INTO lab_tests (test_name, category, normal_range, unit_of_measure, cost, turnaround_hrs)
VALUES
('Complete Blood Count (CBC)',         'Hematology',    'RBC 4.5-5.5, WBC 4-11',  'cells/µL',  350,  6),
('Blood Glucose Fasting',              'Biochemistry',  '70-100',                  'mg/dL',     120,  4),
('Blood Glucose Post Prandial',        'Biochemistry',  '<140',                    'mg/dL',     120,  4),
('HbA1c',                             'Biochemistry',  '<5.7%',                   '%',         450,  8),
('Lipid Profile',                      'Biochemistry',  'TC<200, LDL<100',         'mg/dL',     600, 12),
('Liver Function Test (LFT)',          'Biochemistry',  'ALT<56, AST<40',          'U/L',       700, 12),
('Kidney Function Test (KFT)',         'Biochemistry',  'Creatinine 0.6-1.2',      'mg/dL',     600, 12),
('Thyroid Function Test (TFT)',        'Biochemistry',  'TSH 0.4-4.0',             'mIU/L',     900, 24),
('Urine Routine Examination',          'Microbiology',  'Normal',                  'N/A',       150,  4),
('Urine Culture & Sensitivity',        'Microbiology',  'No growth',               'N/A',       600, 48),
('Blood Culture',                      'Microbiology',  'No growth',               'N/A',       800, 72),
('ECG (12-lead)',                      'Cardiology',    'Normal sinus rhythm',     'N/A',       400,  1),
('2D Echocardiography',               'Cardiology',    'EF>55%',                  '%',        2500,  2),
('Chest X-Ray',                        'Radiology',     'Clear lung fields',       'N/A',       500,  2),
('Ultrasound Abdomen',                 'Radiology',     'Normal',                  'N/A',      1500,  2),
('CT Scan Brain',                      'Radiology',     'No lesion',               'N/A',      6000,  4),
('MRI Brain',                          'Radiology',     'No abnormality',          'N/A', 12000,  6),
('CT Scan Chest',                      'Radiology',     'No lesion',               'N/A',      8000,  4),
('Bone Density (DEXA)',                'Radiology',     'T-score > -1.0',          'g/cm²',    3000, 24),
('Mammography',                        'Radiology',     'BIRADS 1',                'N/A',      2000, 24),
('Pap Smear',                          'Pathology',     'Negative',                'N/A',       800, 48),
('Sputum AFB Culture',                 'Microbiology',  'No AFB',                  'N/A',       900, 72),
('HIV ELISA',                          'Serology',      'Non-reactive',            'N/A',       400, 12),
('HBsAg',                             'Serology',      'Negative',                'N/A',       300,  8),
('Dengue NS1 Antigen',                 'Serology',      'Negative',                'N/A',       900,  8),
('Malaria Antigen',                    'Serology',      'Negative',                'N/A',       400,  4),
('Prothrombin Time (PT/INR)',          'Hematology',    'INR 0.8-1.2',             'ratio',     350,  4),
('Serum Electrolytes',                 'Biochemistry',  'Na 136-145, K 3.5-5',     'mEq/L',     500,  6),
('Arterial Blood Gas (ABG)',           'Biochemistry',  'pH 7.35-7.45',            'N/A',       800,  2),
('PSA (Prostate Specific Antigen)',    'Biochemistry',  '<4.0',                    'ng/mL',    1200, 12),
('CA-125',                            'Oncology Marker','<35',                    'U/mL',     1800, 24),
('CEA',                               'Oncology Marker','<2.5',                   'ng/mL',    1500, 24),
('AFP',                               'Oncology Marker','<10',                    'ng/mL',    1500, 24),
('Troponin I',                         'Cardiology',    '<0.04',                   'ng/mL',    1800,  2),
('D-Dimer',                           'Hematology',    '<0.5',                    'mg/L FEU',  1200,  4);

-- =============================================================================
-- 2. APPOINTMENTS (5000+) — bulk generation
-- =============================================================================
DO $$
DECLARE
    v_appt_date DATE;
    v_doctor_id INT;
    v_patient_id INT;
    v_dept_id   INT;
    v_branch_id INT;
    v_time      TIME;
    v_status    VARCHAR(20);
    v_type      VARCHAR(30);
    i           INT;
BEGIN
    FOR i IN 1..5500 LOOP
        -- Pick a patient and doctor
        v_patient_id := (i % 1000) + 1;
        v_doctor_id  := (i % 150) + 1;

        SELECT dept_id, branch_id INTO v_dept_id, v_branch_id
        FROM doctors WHERE doctor_id = v_doctor_id;

        -- Appointment date: last 18 months
        v_appt_date := CURRENT_DATE - (i % 548);

        -- Time slots every 20 minutes starting 09:00
        v_time := ('09:00'::TIME + (INTERVAL '20 minutes' * (i % 24)));

        -- Status distribution
        v_status := CASE
            WHEN v_appt_date < CURRENT_DATE - 2 THEN
                (ARRAY['Completed','Completed','Completed','Cancelled','No-Show'])[i % 5 + 1]
            WHEN v_appt_date = CURRENT_DATE THEN
                (ARRAY['Confirmed','Scheduled','Completed'])[i % 3 + 1]
            ELSE 'Scheduled'
        END;

        v_type := (ARRAY['OPD','OPD','OPD','Follow-Up','Emergency'])[i % 5 + 1];

        INSERT INTO appointments
            (branch_id, patient_id, doctor_id, dept_id,
             appointment_date, appointment_time, appointment_type, status,
             reason, booked_on)
        VALUES (
            v_branch_id, v_patient_id, v_doctor_id, v_dept_id,
            v_appt_date, v_time, v_type, v_status,
            (ARRAY['Chest pain','Fever and cough','Joint pain','Headache',
                   'Back pain','Diabetes follow-up','Hypertension review',
                   'Routine check-up','Skin rash','Eye checkup',
                   'Stomach ache','Breathlessness','Swelling in legs',
                   'General weakness','Post-surgery follow-up'])[i % 15 + 1],
            CURRENT_TIMESTAMP - (INTERVAL '1 day' * (i % 548 + 1))
        )
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$;

-- =============================================================================
-- 3. MEDICAL RECORDS (linked to completed appointments)
-- =============================================================================
INSERT INTO medical_records (patient_id, doctor_id, visit_date, chief_complaint, diagnosis, notes)
SELECT
    a.patient_id,
    a.doctor_id,
    a.appointment_date,
    a.reason,
    (ARRAY['Hypertension Stage 1','Type 2 Diabetes Mellitus','Acute Bronchitis',
            'Lumbar Spondylosis','Migraine','GERD','Iron Deficiency Anaemia',
            'Hypothyroidism','Osteoarthritis Knee','Anxiety Disorder',
            'Urinary Tract Infection','Community Acquired Pneumonia',
            'Coronary Artery Disease','Chronic Kidney Disease Stage 3',
            'Major Depressive Disorder']
    )[(a.appointment_id % 15) + 1],
    'Patient reviewed. Medications adjusted. Follow-up in 4 weeks.'
FROM appointments a
WHERE a.status = 'Completed'
LIMIT 2000;

-- =============================================================================
-- 4. ADMISSIONS (1200 patients admitted)
-- =============================================================================
DO $$
DECLARE
    v_patient_id INT;
    v_doctor_id  INT;
    v_branch_id  INT;
    v_bed_id     INT;
    v_adm_type   VARCHAR(30);
    v_adm_date   TIMESTAMPTZ;
    v_adm_id     INT;
    i            INT;
    bed_cursor   CURSOR FOR
        SELECT b.bed_id, r.branch_id
        FROM beds b
        JOIN rooms r ON r.room_id = b.room_id
        WHERE b.status = 'Available'
        AND   r.room_type NOT IN ('OT')
        ORDER BY RANDOM()
        LIMIT 1200;
    bed_rec      RECORD;
    counter      INT := 0;
BEGIN
    FOR bed_rec IN bed_cursor LOOP
        counter      := counter + 1;
        v_patient_id := (counter % 800) + 1;
        v_doctor_id  := (counter % 100) + 1;
        v_branch_id  := bed_rec.branch_id;
        v_bed_id     := bed_rec.bed_id;
        v_adm_type   := (ARRAY['Regular','Regular','Emergency','Surgery','Transfer'])[counter % 5 + 1];
        v_adm_date   := NOW() - (INTERVAL '1 day' * (counter % 365));

        INSERT INTO admissions
            (patient_id, doctor_id, branch_id, bed_id,
             admission_date, admission_type, diagnosis, status)
        VALUES (
            v_patient_id, v_doctor_id, v_branch_id, v_bed_id,
            v_adm_date, v_adm_type,
            (ARRAY['Acute MI','Cerebrovascular Accident','Hip Fracture',
                   'Appendicitis','Pneumonia','Diabetic Ketoacidosis',
                   'Renal Failure','Sepsis','Post-op care','Cholecystitis']
            )[counter % 10 + 1],
            CASE
                WHEN counter % 4 = 0 THEN 'Active'
                ELSE 'Discharged'
            END
        )
        RETURNING admission_id INTO v_adm_id;

        -- Mark beds occupied for active admissions
        IF counter % 4 = 0 THEN
            UPDATE beds SET status = 'Occupied', updated_at = NOW()
            WHERE bed_id = v_bed_id;

            INSERT INTO bed_allocations(bed_id, patient_id, admission_id, allocated_on)
            VALUES (v_bed_id, v_patient_id, v_adm_id, v_adm_date);
        END IF;
    END LOOP;
END;
$$;

-- =============================================================================
-- 5. DISCHARGES (for all non-active admissions)
-- =============================================================================
INSERT INTO discharges
    (admission_id, patient_id, doctor_id, discharge_date, discharge_type, discharge_notes)
SELECT
    a.admission_id,
    a.patient_id,
    a.doctor_id,
    a.admission_date + (INTERVAL '1 day' * (a.admission_id % 14 + 1)),
    (ARRAY['Normal','Normal','Normal','AMA','Referral'])[a.admission_id % 5 + 1],
    'Patient stable at discharge. ' ||
    (ARRAY['Advised rest for 2 weeks.','Follow-up in 1 week.',
            'Continue medications.','Diet modification advised.',
            'Physiotherapy recommended.'])[a.admission_id % 5 + 1]
FROM admissions a
WHERE a.status = 'Discharged'
ON CONFLICT (admission_id) DO NOTHING;

-- =============================================================================
-- 6. TREATMENTS (multiple per admission)
-- =============================================================================
INSERT INTO treatments
    (admission_id, patient_id, doctor_id, treatment_name, treatment_type,
     treatment_date, cost, notes)
SELECT
    a.admission_id,
    a.patient_id,
    a.doctor_id,
    (ARRAY['IV Fluid Therapy','Wound Dressing','Physiotherapy Session',
            'Nebulization','Catheterization','Nasogastric Tube Placement',
            'Blood Transfusion','Central Line Insertion','Chest Physiotherapy',
            'Occupational Therapy','Cardiac Monitoring','Oxygen Therapy',
            'Dialysis Session','Colostomy Care','Pressure Ulcer Care']
    )[(a.admission_id * gs.n) % 15 + 1],
    (ARRAY['Therapy','Procedure','Therapy','Procedure','Procedure',
            'Procedure','Procedure','Procedure','Therapy','Therapy',
            'Medication','Therapy','Procedure','Procedure','Therapy']
    )[(a.admission_id * gs.n) % 15 + 1],
    a.admission_date::DATE + (gs.n - 1),
    ROUND((200 + (a.admission_id % 8) * 150)::NUMERIC, 2),
    'Treatment administered as per protocol.'
FROM admissions a
CROSS JOIN GENERATE_SERIES(1, 3) AS gs(n)
WHERE a.admission_id <= 900;

-- =============================================================================
-- 7. LAB REPORTS
-- =============================================================================
INSERT INTO lab_reports
    (patient_id, doctor_id, test_id, admission_id,
     test_date, result_value, result_status, remarks, technician_name, reported_on)
SELECT
    a.patient_id,
    a.doctor_id,
    (a.admission_id % 35) + 1,
    a.admission_id,
    a.admission_date::DATE + 1,
    -- Realistic result values
    CASE (a.admission_id % 35) + 1
        WHEN 1 THEN 'WBC: 11.2, RBC: 4.2, Hb: 11.8, Plt: 180'
        WHEN 2 THEN (90 + (a.admission_id % 60))::TEXT
        WHEN 5 THEN 'TC: 210, LDL: 130, HDL: 42, TG: 185'
        WHEN 6 THEN 'ALT: 68, AST: 52, ALP: 95, Bilirubin: 1.2'
        WHEN 7 THEN 'Creatinine: 1.8, Urea: 52, Na: 138, K: 4.2'
        ELSE 'Result within acceptable range'
    END,
    (ARRAY['Normal','Normal','Normal','Abnormal','Critical'])[a.admission_id % 5 + 1],
    'Results reviewed by attending physician.',
    (ARRAY['Suresh Lab','Priya Lab','Ravi Tech','Anita Tech','Deepak Lab'])[a.admission_id % 5 + 1],
    a.admission_date + INTERVAL '26 hours'
FROM admissions a
WHERE a.admission_id % 2 = 0;

-- OPD lab reports
INSERT INTO lab_reports
    (patient_id, doctor_id, test_id, test_date,
     result_value, result_status, technician_name, reported_on)
SELECT
    ap.patient_id,
    ap.doctor_id,
    (ap.appointment_id % 35) + 1,
    ap.appointment_date,
    'See attached report.',
    (ARRAY['Normal','Normal','Abnormal','Pending'])[ap.appointment_id % 4 + 1],
    'Lab Technician',
    ap.appointment_date + INTERVAL '6 hours'
FROM appointments ap
WHERE ap.status = 'Completed'
  AND ap.appointment_id % 3 = 0
LIMIT 1500;

-- =============================================================================
-- 8. PRESCRIPTIONS (2+ per admission/appointment)
-- =============================================================================
-- Prescriptions via admissions (disable stock trigger first — already done above)
INSERT INTO prescriptions
    (patient_id, doctor_id, admission_id, medicine_id,
     dosage, frequency, duration_days, quantity, instructions, prescribed_on)
SELECT
    a.patient_id,
    a.doctor_id,
    a.admission_id,
    (a.admission_id * gs.n % 400) + 1,
    (ARRAY['5mg once daily','10mg twice daily','500mg thrice daily',
            '1g IV 8-hourly','250mg at bedtime','2 tablets BD',
            '1 tablet TDS','1 puff BD','5ml TDS','200mg OD']
    )[(a.admission_id + gs.n) % 10 + 1],
    (ARRAY['OD','BD','TDS','QID','SOS','STAT','BD','TDS','OD','BD'])[gs.n % 10 + 1],
    GREATEST(3, (a.admission_id % 14 + 1)),
    GREATEST(5, (a.admission_id % 14 + 1) * 2),
    'Take with food. Avoid alcohol.',
    a.admission_date::DATE
FROM admissions a
CROSS JOIN GENERATE_SERIES(1, 2) AS gs(n)
WHERE a.admission_id <= 800;

-- OPD prescriptions
INSERT INTO prescriptions
    (patient_id, doctor_id, appointment_id, medicine_id,
     dosage, frequency, duration_days, quantity, instructions, prescribed_on)
SELECT
    ap.patient_id,
    ap.doctor_id,
    ap.appointment_id,
    (ap.appointment_id % 400) + 1,
    (ARRAY['5mg once daily','10mg twice daily','500mg TDS','1 tablet BD',
            '2 tablets OD','5ml BD','1 capsule TDS','250mg at night']
    )[ap.appointment_id % 8 + 1],
    (ARRAY['OD','BD','TDS','OD','BD','BD','TDS','OD'])[ap.appointment_id % 8 + 1],
    7,
    14,
    'Complete the full course.',
    ap.appointment_date
FROM appointments ap
WHERE ap.status = 'Completed'
  AND ap.appointment_id % 2 = 0
LIMIT 2000;

-- =============================================================================
-- 9. BILLING (auto-generated for discharges; add OPD bills)
-- =============================================================================
-- OPD bills for completed appointments
INSERT INTO billing
    (patient_id, appointment_id, branch_id, bill_date,
     consultation_charge, medicine_charge, lab_charge,
     other_charge, discount_pct, tax_pct, payment_status)
SELECT
    a.patient_id,
    a.appointment_id,
    a.branch_id,
    a.appointment_date,
    d.consultation_fee,
    ROUND((50 + (a.appointment_id % 500))::NUMERIC, 2),
    CASE WHEN a.appointment_id % 3 = 0 THEN lt.cost ELSE 0 END,
    50,
    CASE WHEN a.patient_id % 10 = 0 THEN 10 ELSE 0 END,
    18,
    (ARRAY['Paid','Paid','Paid','Partial','Pending'])[a.appointment_id % 5 + 1]
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
LEFT JOIN lab_tests lt ON lt.test_id = (a.appointment_id % 35) + 1
WHERE a.status = 'Completed'
ON CONFLICT DO NOTHING;

-- Generate bills for discharged admissions that don't have one yet
INSERT INTO billing
    (patient_id, admission_id, branch_id, bill_date,
     consultation_charge, room_charge, medicine_charge,
     lab_charge, treatment_charge, other_charge,
     discount_pct, tax_pct, payment_status)
SELECT
    dis.patient_id,
    dis.admission_id,
    adm.branch_id,
    dis.discharge_date::DATE,
    d.consultation_fee,
    -- Room × days
    ROUND(r.daily_charge *
          GREATEST(1, EXTRACT(EPOCH FROM (dis.discharge_date - adm.admission_date))::INT / 86400), 2),
    -- Medicines: sum prescriptions
    COALESCE((SELECT SUM(p.quantity * m.unit_price)
              FROM prescriptions p
              JOIN medicines m ON m.medicine_id = p.medicine_id
              WHERE p.admission_id = dis.admission_id), 0),
    -- Lab
    COALESCE((SELECT SUM(lt.cost)
              FROM lab_reports lr
              JOIN lab_tests lt ON lt.test_id = lr.test_id
              WHERE lr.admission_id = dis.admission_id), 0),
    -- Treatments
    COALESCE((SELECT SUM(t.cost)
              FROM treatments t
              WHERE t.admission_id = dis.admission_id), 0),
    200,  -- misc charge
    CASE WHEN dis.patient_id % 10 = 0 THEN 10 ELSE 0 END,
    18,
    (ARRAY['Paid','Paid','Partial','Pending','Insurance'])[dis.admission_id % 5 + 1]
FROM discharges dis
JOIN admissions adm ON adm.admission_id = dis.admission_id
JOIN doctors d      ON d.doctor_id      = dis.doctor_id
JOIN beds b         ON b.bed_id         = adm.bed_id
JOIN rooms r        ON r.room_id        = b.room_id
WHERE NOT EXISTS (
    SELECT 1 FROM billing WHERE admission_id = dis.admission_id
);

-- =============================================================================
-- 10. PAYMENTS (for paid and partial bills)
-- =============================================================================
-- Full payments for 'Paid' bills
INSERT INTO payments
    (bill_id, patient_id, payment_date, amount_paid, payment_mode,
     transaction_ref, received_by)
SELECT
    b.bill_id,
    b.patient_id,
    b.bill_date + INTERVAL '1 day',
    b.total_amount,
    (ARRAY['Cash','UPI','Card','NetBanking','UPI','Card'])[b.bill_id % 6 + 1],
    'TXN' || LPAD(b.bill_id::TEXT, 10, '0'),
    (SELECT staff_id FROM staff
     WHERE role IN ('Billing Executive','Senior Accountant')
     AND branch_id = b.branch_id
     ORDER BY staff_id LIMIT 1)
FROM billing b
WHERE b.payment_status = 'Paid';

-- Partial payments for 'Partial' bills (~50% of total)
INSERT INTO payments
    (bill_id, patient_id, payment_date, amount_paid, payment_mode, transaction_ref)
SELECT
    b.bill_id,
    b.patient_id,
    b.bill_date + INTERVAL '2 days',
    ROUND(b.total_amount * 0.5, 2),
    'Cash',
    'PART-TXN' || LPAD(b.bill_id::TEXT, 8, '0')
FROM billing b
WHERE b.payment_status = 'Partial';

-- Insurance payments for 'Insurance' bills
UPDATE billing b
SET insurance_id = (
    SELECT i.insurance_id FROM insurance i
    WHERE i.patient_id = b.patient_id AND i.is_active = TRUE LIMIT 1
),
insurance_covered = LEAST(total_amount * 0.8, 400000)
WHERE b.payment_status = 'Insurance'
  AND EXISTS (SELECT 1 FROM insurance i WHERE i.patient_id = b.patient_id);

-- =============================================================================
-- Re-enable triggers
-- =============================================================================
ALTER TABLE appointments   ENABLE TRIGGER trg_prevent_double_booking;
ALTER TABLE appointments   ENABLE TRIGGER trg_check_doctor_leave;
ALTER TABLE admissions     ENABLE TRIGGER trg_check_bed_availability;
ALTER TABLE admissions     ENABLE TRIGGER trg_mark_bed_occupied;
ALTER TABLE prescriptions  ENABLE TRIGGER trg_deduct_medicine_stock;

-- =============================================================================
-- REFRESH MATERIALIZED VIEWS
-- =============================================================================
REFRESH MATERIALIZED VIEW mvw_monthly_revenue;
REFRESH MATERIALIZED VIEW mvw_doctor_performance;

-- =============================================================================
SELECT
    'Dataset generation complete.' AS status,
    (SELECT COUNT(*) FROM appointments)  AS appointments,
    (SELECT COUNT(*) FROM admissions)    AS admissions,
    (SELECT COUNT(*) FROM discharges)    AS discharges,
    (SELECT COUNT(*) FROM billing)       AS bills,
    (SELECT COUNT(*) FROM payments)      AS payments,
    (SELECT COUNT(*) FROM treatments)    AS treatments,
    (SELECT COUNT(*) FROM lab_reports)   AS lab_reports,
    (SELECT COUNT(*) FROM prescriptions) AS prescriptions;
