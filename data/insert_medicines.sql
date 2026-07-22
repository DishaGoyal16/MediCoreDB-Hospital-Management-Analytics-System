-- =============================================================================
-- FILE: data/insert_medicines.sql
-- DESCRIPTION: Seed data — suppliers + 500 medicines.
-- =============================================================================

-- =============================================================================
-- SUPPLIERS
-- =============================================================================
INSERT INTO suppliers
    (supplier_name, contact_person, phone, email, address, city, gstin)
VALUES
('Sun Pharma Distributors',   'Ashok Mehta',    '9400100001','sunpharma@dist.com',     'Plot 12, MIDC, Phase I',     'Mumbai',    '27AABCS1429B1ZB'),
('Cipla Healthcare Ltd',      'Ramesh Patil',   '9400100002','cipla@dist.com',          '45 Peenya Industrial Area',  'Bangalore', '29AABCC1234A1ZA'),
('Abbott Medical Supplies',   'Jennifer D''Souza','9400100003','abbott@dist.com',        '78 Sipcot Estate',           'Chennai',   '33AABCA5678B1ZC'),
('Dr. Reddy''s Distribution', 'Srinivas Reddy', '9400100004','drreddy@dist.com',        '23 IDA Uppal',               'Hyderabad', '36AABCD7890C1ZD'),
('Lupin Pharma Dealers',      'Kamlesh Shah',   '9400100005','lupin@dist.com',          'C-34 Naroda Industrial',     'Ahmedabad', '24AABCL2468D1ZE'),
('Alkem Lab Distributors',    'Suresh Gupta',   '9400100006','alkem@dist.com',          'L-12 Vasai Industrial',      'Mumbai',    '27AABCA3579E1ZF'),
('Torrent Pharma Supplies',   'Bhavesh Patel',  '9400100007','torrent@dist.com',        'Phase II, GIDC, Gandhinagar','Gandhinagar','24AABCT4691F1ZG'),
('Glenmark Healthcare',       'Vivek Salve',    '9400100008','glenmark@dist.com',       '89 TTC Industrial Area',     'Navi Mumbai','27AABCG5802G1ZH'),
('Mankind Pharma Ltd',        'Rajesh Verma',   '9400100009','mankind@dist.com',        'A-34 Industrial Estate',     'Delhi',     '07AABCM6913H1ZI'),
('Zydus Cadila Supplies',     'Nilesh Desai',   '9400100010','zydus@dist.com',          '14 S.G. Highway',            'Ahmedabad', '24AABCZ7024I1ZJ');

-- =============================================================================
-- MEDICINES (500 medicines across categories)
-- Using generate_series + arrays for realistic data
-- =============================================================================

-- Antibiotics (50)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Amoxicillin','Azithromycin','Ciprofloxacin','Doxycycline','Ceftriaxone',
            'Metronidazole','Clindamycin','Levofloxacin','Meropenem','Vancomycin',
            'Ampicillin','Cefixime','Clarithromycin','Erythromycin','Gentamicin',
            'Linezolid','Nitrofurantoin','Piperacillin','Tetracycline','Tinidazole']
    )[(i % 20) + 1] || ' ' || (ARRAY['250mg','500mg','750mg','1g','200mg'])[(i % 5) + 1] AS medicine_name,
    (ARRAY['Amoxicillin','Azithromycin','Ciprofloxacin','Doxycycline','Ceftriaxone',
            'Metronidazole','Clindamycin','Levofloxacin','Meropenem','Vancomycin',
            'Ampicillin','Cefixime','Clarithromycin','Erythromycin','Gentamicin',
            'Linezolid','Nitrofurantoin','Piperacillin','Tetracycline','Tinidazole']
    )[(i % 20) + 1] AS generic_name,
    'Antibiotic' AS category,
    (ARRAY['tablet','capsule','injection','syrup'])[(i % 4) + 1] AS unit,
    ROUND((5 + i * 2.3)::NUMERIC, 2) AS unit_price,
    TRUE, 'Sun Pharma'
FROM GENERATE_SERIES(1, 50) AS i;

-- Analgesics / Pain Killers (40)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Paracetamol','Ibuprofen','Diclofenac','Tramadol','Ketorolac',
            'Naproxen','Aspirin','Aceclofenac','Celecoxib','Etoricoxib',
            'Morphine','Fentanyl','Codeine','Pentazocine','Buprenorphine']
    )[(i % 15) + 1] || ' ' || (ARRAY['100mg','200mg','500mg','50mg','400mg'])[(i % 5) + 1],
    (ARRAY['Paracetamol','Ibuprofen','Diclofenac','Tramadol','Ketorolac',
            'Naproxen','Aspirin','Aceclofenac','Celecoxib','Etoricoxib',
            'Morphine','Fentanyl','Codeine','Pentazocine','Buprenorphine']
    )[(i % 15) + 1],
    'Analgesic', (ARRAY['tablet','injection','patch'])[(i % 3) + 1],
    ROUND((3 + i * 1.8)::NUMERIC, 2),
    CASE WHEN i % 3 = 0 THEN TRUE ELSE FALSE END,
    'Cipla'
FROM GENERATE_SERIES(1, 40) AS i;

-- Cardiovascular (60)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Atorvastatin','Amlodipine','Metoprolol','Ramipril','Losartan',
            'Aspirin','Clopidogrel','Digoxin','Furosemide','Spironolactone',
            'Bisoprolol','Carvedilol','Enalapril','Nitroglycerin','Warfarin',
            'Atenolol','Nifedipine','Verapamil','Lisinopril','Valsartan']
    )[(i % 20) + 1] || ' ' || (ARRAY['5mg','10mg','20mg','40mg','25mg','50mg'])[(i % 6) + 1],
    (ARRAY['Atorvastatin','Amlodipine','Metoprolol','Ramipril','Losartan',
            'Aspirin','Clopidogrel','Digoxin','Furosemide','Spironolactone',
            'Bisoprolol','Carvedilol','Enalapril','Nitroglycerin','Warfarin',
            'Atenolol','Nifedipine','Verapamil','Lisinopril','Valsartan']
    )[(i % 20) + 1],
    'Cardiovascular', 'tablet',
    ROUND((8 + i * 3.2)::NUMERIC, 2),
    TRUE, 'Dr. Reddy''s'
FROM GENERATE_SERIES(1, 60) AS i;

-- Antidiabetics (30)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Metformin','Glibenclamide','Insulin Glargine','Sitagliptin','Empagliflozin',
            'Dapagliflozin','Glimepiride','Pioglitazone','Vildagliptin','Liraglutide']
    )[(i % 10) + 1] || ' ' || (ARRAY['500mg','1g','100mg','25mg','2mg','4mg'])[(i % 6) + 1],
    (ARRAY['Metformin','Glibenclamide','Insulin Glargine','Sitagliptin','Empagliflozin',
            'Dapagliflozin','Glimepiride','Pioglitazone','Vildagliptin','Liraglutide']
    )[(i % 10) + 1],
    'Antidiabetic', (ARRAY['tablet','injection'])[(i % 2) + 1],
    ROUND((10 + i * 4.1)::NUMERIC, 2),
    TRUE, 'Lupin'
FROM GENERATE_SERIES(1, 30) AS i;

-- Antihypertensives (25)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Telmisartan','Olmesartan','Candesartan','Irbesartan','Hydralazine',
            'Clonidine','Methyldopa','Prazosin','Doxazosin','Minoxidil']
    )[(i % 10) + 1] || ' ' || (ARRAY['20mg','40mg','80mg','8mg','16mg'])[(i % 5) + 1],
    (ARRAY['Telmisartan','Olmesartan','Candesartan','Irbesartan','Hydralazine',
            'Clonidine','Methyldopa','Prazosin','Doxazosin','Minoxidil']
    )[(i % 10) + 1],
    'Antihypertensive', 'tablet',
    ROUND((6 + i * 2.5)::NUMERIC, 2),
    TRUE, 'Torrent'
FROM GENERATE_SERIES(1, 25) AS i;

-- Respiratory (30)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Salbutamol','Budesonide','Formoterol','Ipratropium','Theophylline',
            'Montelukast','Tiotropium','Salmeterol','Beclomethasone','Fluticasone']
    )[(i % 10) + 1] || ' ' || (ARRAY['100mcg','200mcg','400mcg','2mg','4mg','5mg'])[(i % 6) + 1],
    (ARRAY['Salbutamol','Budesonide','Formoterol','Ipratropium','Theophylline',
            'Montelukast','Tiotropium','Salmeterol','Beclomethasone','Fluticasone']
    )[(i % 10) + 1],
    'Respiratory', (ARRAY['inhaler','tablet','syrup','nebulizer solution'])[(i % 4) + 1],
    ROUND((15 + i * 5.5)::NUMERIC, 2),
    TRUE, 'Cipla'
FROM GENERATE_SERIES(1, 30) AS i;

-- GI / Gastro (30)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Omeprazole','Pantoprazole','Ranitidine','Domperidone','Ondansetron',
            'Metoclopramide','Lactulose','Sucralfate','Mesalazine','Esomeprazole']
    )[(i % 10) + 1] || ' ' || (ARRAY['20mg','40mg','10mg','4mg','150mg'])[(i % 5) + 1],
    (ARRAY['Omeprazole','Pantoprazole','Ranitidine','Domperidone','Ondansetron',
            'Metoclopramide','Lactulose','Sucralfate','Mesalazine','Esomeprazole']
    )[(i % 10) + 1],
    'Gastrointestinal', (ARRAY['tablet','capsule','syrup','injection'])[(i % 4) + 1],
    ROUND((4 + i * 1.5)::NUMERIC, 2),
    CASE WHEN i % 4 = 0 THEN FALSE ELSE TRUE END,
    'Alkem'
FROM GENERATE_SERIES(1, 30) AS i;

-- Psychotropics / Neuro (30)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Alprazolam','Lorazepam','Clonazepam','Sertraline','Fluoxetine',
            'Escitalopram','Olanzapine','Risperidone','Quetiapine','Lithium',
            'Valproate','Phenytoin','Carbamazepine','Levetiracetam','Zolpidem']
    )[(i % 15) + 1] || ' ' || (ARRAY['0.5mg','1mg','2mg','10mg','25mg','50mg'])[(i % 6) + 1],
    (ARRAY['Alprazolam','Lorazepam','Clonazepam','Sertraline','Fluoxetine',
            'Escitalopram','Olanzapine','Risperidone','Quetiapine','Lithium',
            'Valproate','Phenytoin','Carbamazepine','Levetiracetam','Zolpidem']
    )[(i % 15) + 1],
    'Psychotropic/Neurological', 'tablet',
    ROUND((7 + i * 2.7)::NUMERIC, 2),
    TRUE, 'Glenmark'
FROM GENERATE_SERIES(1, 30) AS i;

-- Vitamins & Supplements (50)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Vitamin C','Vitamin D3','Vitamin B12','Calcium Carbonate','Iron Folic Acid',
            'Zinc Sulphate','Vitamin E','Multivitamin','Omega-3','Folic Acid',
            'Vitamin A','Magnesium','Potassium Chloride','Biotin','Vitamin B Complex']
    )[(i % 15) + 1] || ' ' || (ARRAY['500mg','1000IU','2000IU','250mg','60mg'])[(i % 5) + 1],
    (ARRAY['Ascorbic Acid','Cholecalciferol','Cyanocobalamin','Calcium Carbonate',
            'Ferrous Sulphate','Zinc Sulphate','Tocopherol','Multivitamin',
            'Omega-3 Fatty Acids','Folic Acid','Retinol','Magnesium Hydroxide',
            'Potassium Chloride','D-Biotin','Vitamin B Complex']
    )[(i % 15) + 1],
    'Vitamin/Supplement', (ARRAY['tablet','capsule','syrup'])[(i % 3) + 1],
    ROUND((2 + i * 0.8)::NUMERIC, 2),
    FALSE, 'Mankind'
FROM GENERATE_SERIES(1, 50) AS i;

-- Oncology drugs (25)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Paclitaxel','Docetaxel','Cisplatin','Carboplatin','Doxorubicin',
            'Cyclophosphamide','Vincristine','Methotrexate','5-Fluorouracil','Imatinib',
            'Erlotinib','Sorafenib','Bevacizumab','Rituximab','Trastuzumab']
    )[(i % 15) + 1] || ' Injection',
    (ARRAY['Paclitaxel','Docetaxel','Cisplatin','Carboplatin','Doxorubicin',
            'Cyclophosphamide','Vincristine','Methotrexate','5-Fluorouracil','Imatinib',
            'Erlotinib','Sorafenib','Bevacizumab','Rituximab','Trastuzumab']
    )[(i % 15) + 1],
    'Oncology', 'injection',
    ROUND((500 + i * 150)::NUMERIC, 2),
    TRUE, 'Dr. Reddy''s'
FROM GENERATE_SERIES(1, 25) AS i;

-- OTC / General (80 remaining)
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
SELECT
    (ARRAY['Cetirizine','Loratadine','Diphenhydramine','Phenylephrine','Oxymetazoline',
            'Dextromethorphan','Guaifenesin','Pseudoephedrine','Chlorpheniramine','Bromhexine',
            'Ambroxol','Pholcodine','Noscapine','Benzydamine','Povidone Iodine',
            'Silver Sulfadiazine','Mupirocin','Clotrimazole','Ketoconazole','Fluconazole']
    )[(i % 20) + 1] || ' ' || (ARRAY['5mg','10mg','25mg','0.1%','2%','1%','100mg'])[(i % 7) + 1],
    (ARRAY['Cetirizine','Loratadine','Diphenhydramine','Phenylephrine','Oxymetazoline',
            'Dextromethorphan','Guaifenesin','Pseudoephedrine','Chlorpheniramine','Bromhexine',
            'Ambroxol','Pholcodine','Noscapine','Benzydamine','Povidone Iodine',
            'Silver Sulfadiazine','Mupirocin','Clotrimazole','Ketoconazole','Fluconazole']
    )[(i % 20) + 1],
    (ARRAY['Antiallergic','OTC Cough/Cold','Antifungal','Antiseptic','Decongestant']
    )[(i % 5) + 1],
    (ARRAY['tablet','syrup','cream','drops','lotion'])[(i % 5) + 1],
    ROUND((2 + i * 0.6)::NUMERIC, 2),
    CASE WHEN i % 3 = 0 THEN FALSE ELSE TRUE END,
    (ARRAY['Mankind','Zydus','Abbott','Sun Pharma','Cipla'])[(i % 5) + 1]
FROM GENERATE_SERIES(1, 80) AS i;

-- Add lab reagents / IV fluids
INSERT INTO medicines (medicine_name, generic_name, category, unit, unit_price, requires_prescription, manufacturer)
VALUES
('Normal Saline 500ml',       'Sodium Chloride 0.9%',     'IV Fluid',   'bag',    45.00, TRUE,  'Abbott'),
('Dextrose 5% 500ml',         'Dextrose 5%',              'IV Fluid',   'bag',    55.00, TRUE,  'Abbott'),
('Ringer Lactate 500ml',      'Ringer Lactate Solution',  'IV Fluid',   'bag',    60.00, TRUE,  'Cipla'),
('DNS 500ml',                 'Dextrose Normal Saline',   'IV Fluid',   'bag',    65.00, TRUE,  'Cipla'),
('Mannitol 20% 100ml',        'Mannitol',                 'IV Fluid',   'bottle', 120.00,TRUE,  'Sun Pharma'),
('Heparin 5000IU',            'Heparin Sodium',           'Anticoagulant','injection',85.00,TRUE,'Dr. Reddy''s'),
('Potassium Chloride 15%',    'Potassium Chloride',       'Electrolyte','ampoule',35.00, TRUE,  'Lupin'),
('Adrenaline 1mg/ml',         'Epinephrine',              'Emergency',  'injection',65.00,TRUE, 'Torrent'),
('Atropine 0.6mg/ml',         'Atropine Sulphate',        'Emergency',  'injection',45.00,TRUE, 'Glenmark'),
('Hydrocortisone 100mg',      'Hydrocortisone Sodium',    'Corticosteroid','injection',120.00,TRUE,'Alkem');

SELECT 'insert_medicines.sql completed. Medicines: '
    || (SELECT COUNT(*) FROM medicines)::TEXT
    || ', Suppliers: '
    || (SELECT COUNT(*) FROM suppliers)::TEXT AS status;
