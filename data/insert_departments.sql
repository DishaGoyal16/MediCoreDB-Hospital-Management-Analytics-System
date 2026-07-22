-- =============================================================================
-- FILE: data/insert_departments.sql
-- DESCRIPTION: Seed data — hospital branches and departments.
-- =============================================================================

-- =============================================================================
-- HOSPITAL BRANCHES
-- =============================================================================
INSERT INTO hospital_branches
    (branch_name, address, city, state, pincode, phone, email, established_on)
VALUES
    ('City Central Hospital',     '12 MG Road, Sector 5',       'Mumbai',    'Maharashtra', '400001', '022-40001111', 'central@cityhosp.com',  '2005-03-15'),
    ('North Wing Medical Center', '45 NH-8 Highway, Phase II',  'Delhi',     'Delhi',       '110001', '011-40002222', 'northwing@cityhosp.com','2008-07-20'),
    ('Southside Health Campus',   '88 Anna Salai, OMR',         'Chennai',   'Tamil Nadu',  '600002', '044-40003333', 'southside@cityhosp.com','2010-01-10'),
    ('Eastern Care Hospital',     '23 Park Street, Alipore',    'Kolkata',   'West Bengal', '700016', '033-40004444', 'eastern@cityhosp.com',  '2012-09-05'),
    ('West End Specialty Clinic', '56 FC Road, Shivajinagar',   'Pune',      'Maharashtra', '411004', '020-40005555', 'westend@cityhosp.com',  '2015-11-22');

-- =============================================================================
-- DEPARTMENTS (20 departments, spread across 5 branches)
-- =============================================================================
INSERT INTO departments
    (branch_id, dept_name, dept_code, floor_no, phone_ext)
VALUES
    -- Branch 1: City Central Hospital
    (1, 'Cardiology',               'CARD', 3, '3001'),
    (1, 'Orthopedics',              'ORTH', 2, '3002'),
    (1, 'Neurology',                'NEUR', 4, '3003'),
    (1, 'General Surgery',          'GSUR', 2, '3004'),
    (1, 'Emergency & Trauma',       'EMER', 1, '3005'),

    -- Branch 2: North Wing Medical Center
    (2, 'Pediatrics',               'PEDI', 2, '2001'),
    (2, 'Gynecology & Obstetrics',  'GYNO', 3, '2002'),
    (2, 'Oncology',                 'ONCO', 5, '2003'),
    (2, 'Pulmonology',              'PULM', 2, '2004'),
    (2, 'Nephrology',               'NEPH', 3, '2005'),

    -- Branch 3: Southside Health Campus
    (3, 'Dermatology',              'DERM', 2, '1001'),
    (3, 'ENT',                      'ENTD', 2, '1002'),
    (3, 'Ophthalmology',            'OPHT', 3, '1003'),
    (3, 'Gastroenterology',         'GAST', 3, '1004'),
    (3, 'Endocrinology',            'ENDO', 4, '1005'),

    -- Branch 4: Eastern Care Hospital
    (4, 'Psychiatry',               'PSYC', 4, '4001'),
    (4, 'Rheumatology',             'RHEU', 3, '4002'),
    (4, 'Urology',                  'UROL', 3, '4003'),

    -- Branch 5: West End Specialty Clinic
    (5, 'Plastic & Cosmetic Surgery','PLAS', 2, '5001'),
    (5, 'Internal Medicine',         'INTM', 2, '5002');

SELECT 'insert_departments.sql completed. Branches: '
    || (SELECT COUNT(*) FROM hospital_branches)::TEXT
    || ', Departments: '
    || (SELECT COUNT(*) FROM departments)::TEXT
    AS status;
