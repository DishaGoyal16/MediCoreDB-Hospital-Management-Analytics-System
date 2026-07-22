-- =============================================================================
-- FILE: data/insert_patients.sql
-- DESCRIPTION: Seed data — 1000 patients + emergency contacts + insurance.
--              Uses generate_series for bulk realistic data.
-- =============================================================================

-- =============================================================================
-- INSERT 1000 PATIENTS via generate_series
-- =============================================================================
INSERT INTO patients
    (branch_id, first_name, last_name, gender, date_of_birth,
     blood_group, phone, email, address, city, state, pincode,
     registration_date, is_active)
SELECT
    -- Spread across 5 branches
    (((i - 1) % 5) + 1)                                        AS branch_id,
    -- First names cycling through realistic Indian names
    (ARRAY['Aarav','Aditi','Akash','Alok','Amita','Ananya','Anil','Anjali',
            'Ankur','Anoop','Anshul','Anu','Arjun','Aryan','Asha','Ashish',
            'Ashok','Avinash','Ayush','Bharat','Chandra','Deepak','Deepti',
            'Dev','Divya','Geeta','Gaurav','Girish','Harish','Heena','Indira',
            'Isha','Jaya','Jayesh','Kapil','Kavita','Kiran','Komal','Kumar',
            'Lalit','Lata','Mahesh','Mamta','Manish','Meena','Meera','Mihir',
            'Mohan','Monica','Mukesh','Nandita','Naresh','Neha','Nikhil',
            'Nilesh','Nisha','Pallavi','Pankaj','Payal','Pooja','Pradeep',
            'Prakash','Priya','Rahul','Raj','Rajesh','Rakesh','Ravi','Rekha',
            'Ritika','Rohit','Ruchi','Sachin','Sanjay','Sangeeta','Sarika',
            'Seema','Shilpa','Shruti','Smita','Sonal','Sudhir','Sunil',
            'Sunita','Suresh','Swati','Tarun','Usha','Vandana','Varun',
            'Vikas','Vikram','Vinay','Vinod','Vishal','Vivek','Yash','Zoya']
    )[(i % 97) + 1]                                            AS first_name,
    -- Last names cycling
    (ARRAY['Agarwal','Ahuja','Bajaj','Banerjee','Bose','Chandra','Chopra',
            'Das','Desai','Doshi','Dubey','Ghosh','Goyal','Gupta','Iyer',
            'Jain','Joshi','Kapur','Kapoor','Khanna','Kulkarni','Kumar',
            'Lal','Malhotra','Mathur','Mehta','Menon','Mishra','Nair',
            'Pandey','Patel','Patil','Pillai','Rao','Reddy','Roy','Saxena',
            'Shah','Sharma','Shukla','Singh','Sinha','Soni','Srivastava',
            'Tiwari','Tripathi','Varma','Verma','Yadav','Jha']
    )[(i % 50) + 1]                                            AS last_name,
    -- Gender alternating
    CASE WHEN i % 3 = 0 THEN 'F' ELSE 'M' END                  AS gender,
    -- DOB: patients aged 1–85
    (CURRENT_DATE - (INTERVAL '1 year' * ((i % 85) + 1))
                  - (INTERVAL '1 day'  * (i % 365)))::DATE      AS date_of_birth,
    -- Blood groups cycling
    (ARRAY['A+','A-','B+','B-','O+','O-','AB+','AB-'])[(i % 8) + 1] AS blood_group,
    -- Unique phone numbers
    '98' || LPAD((10000000 + i)::TEXT, 8, '0')                 AS phone,
    -- Email (some NULL to be realistic)
    CASE WHEN i % 7 = 0 THEN NULL
         ELSE LOWER(
            (ARRAY['aarav','aditi','akash','alok','amita','ananya','anil','anjali',
                   'ankur','anoop','arjun','aryan','asha','ashish','ashok',
                   'ayush','bharat','chandra','deepak','deepti','dev','divya',
                   'geeta','gaurav','girish','harish','heena','indira','isha',
                   'jaya','jayesh','kapil','kavita','kiran','komal','lalit',
                   'lata','mahesh','mamta','manish','meena','meera','mohan',
                   'monica','mukesh','nandita','naresh','neha','nikhil','nilesh']
            )[(i % 50) + 1]
            || i::TEXT || '@email.com')
    END                                                          AS email,
    -- Address
    (i % 99 + 1)::TEXT || ' Sector ' || (i % 30 + 1)::TEXT
        || ', Block ' || CHR(65 + (i % 26))                    AS address,
    -- City cycling
    (ARRAY['Mumbai','Delhi','Chennai','Kolkata','Pune','Bangalore','Hyderabad',
            'Ahmedabad','Jaipur','Lucknow'])[(i % 10) + 1]      AS city,
    -- State
    (ARRAY['Maharashtra','Delhi','Tamil Nadu','West Bengal','Maharashtra',
            'Karnataka','Telangana','Gujarat','Rajasthan','Uttar Pradesh']
    )[(i % 10) + 1]                                             AS state,
    -- Pincode
    LPAD((400001 + (i % 999))::TEXT, 6, '4')                   AS pincode,
    -- Registration date spread over last 5 years
    (CURRENT_DATE - (INTERVAL '1 day' * (i % 1825)))::DATE      AS registration_date,
    TRUE                                                         AS is_active
FROM GENERATE_SERIES(1, 1000) AS i;

-- Mark ~50 patients as inactive (transferred/moved)
UPDATE patients SET is_active = FALSE
WHERE patient_id IN (
    SELECT patient_id FROM patients
    WHERE patient_id % 20 = 0
    LIMIT 50
);

-- =============================================================================
-- EMERGENCY CONTACTS (1 per patient, primary contact)
-- =============================================================================
INSERT INTO emergency_contacts
    (patient_id, contact_name, relationship, phone, alt_phone, is_primary)
SELECT
    p.patient_id,
    -- Spouse/Parent names
    (ARRAY['Ramesh','Kavita','Suresh','Anita','Mahesh','Sunita','Prakash',
            'Meena','Vijay','Priya','Rajesh','Seema','Anil','Rekha','Mohan',
            'Pooja','Vinod','Geeta','Ashok','Lata'])
        [(p.patient_id % 20) + 1]
    || ' '
    || (ARRAY['Sharma','Patel','Singh','Kumar','Mehta','Gupta','Verma',
               'Joshi','Nair','Rao'])[(p.patient_id % 10) + 1]       AS contact_name,
    (ARRAY['Spouse','Parent','Sibling','Child','Friend','Guardian'])
        [(p.patient_id % 6) + 1]                                      AS relationship,
    '97' || LPAD((20000000 + p.patient_id)::TEXT, 8, '0')            AS phone,
    CASE WHEN p.patient_id % 3 = 0
         THEN '96' || LPAD((30000000 + p.patient_id)::TEXT, 8, '0')
         ELSE NULL
    END                                                               AS alt_phone,
    TRUE                                                              AS is_primary
FROM patients p;

-- =============================================================================
-- INSURANCE (for ~600 patients)
-- =============================================================================
INSERT INTO insurance
    (patient_id, provider_name, policy_number, policy_type,
     coverage_amount, premium_amount, deductible, valid_from, valid_to)
SELECT
    p.patient_id,
    (ARRAY['Star Health Insurance','HDFC Ergo Health','ICICI Lombard Health',
            'Bajaj Allianz Health','Max Bupa Health','New India Assurance',
            'United India Insurance','Oriental Insurance','National Insurance',
            'Reliance Health Insurance'])[(p.patient_id % 10) + 1]   AS provider_name,
    'POL' || LPAD(p.patient_id::TEXT, 8, '0')                        AS policy_number,
    (ARRAY['Individual','Family','Group','Senior'])[(p.patient_id % 4) + 1] AS policy_type,
    -- Coverage amount based on policy type
    CASE (p.patient_id % 4) + 1
        WHEN 1 THEN 300000  -- Individual
        WHEN 2 THEN 500000  -- Family
        WHEN 3 THEN 400000  -- Group
        WHEN 4 THEN 200000  -- Senior
    END                                                               AS coverage_amount,
    CASE (p.patient_id % 4) + 1
        WHEN 1 THEN 8000
        WHEN 2 THEN 15000
        WHEN 3 THEN 6000
        WHEN 4 THEN 12000
    END                                                               AS premium_amount,
    5000                                                              AS deductible,
    -- Policy valid from 1-3 years ago
    (CURRENT_DATE - INTERVAL '1 year' * ((p.patient_id % 3) + 1))::DATE AS valid_from,
    -- Valid for 2 more years
    (CURRENT_DATE + INTERVAL '1 year' * 2)::DATE                     AS valid_to
FROM patients p
WHERE p.patient_id % 5 != 0;   -- ~80% have insurance (skip every 5th)

-- Link insurance to patient
UPDATE patients p
SET insurance_id = (
    SELECT insurance_id FROM insurance i
    WHERE i.patient_id = p.patient_id LIMIT 1
);

SELECT 'insert_patients.sql completed. Patients: '
    || (SELECT COUNT(*) FROM patients)::TEXT
    || ', Insurance: '
    || (SELECT COUNT(*) FROM insurance)::TEXT AS status;
