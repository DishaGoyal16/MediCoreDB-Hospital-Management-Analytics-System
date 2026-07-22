-- =============================================================================
-- FILE: data/insert_doctors.sql
-- DESCRIPTION: Seed data — 150 doctors + specializations + schedules.
-- =============================================================================

-- =============================================================================
-- SPECIALIZATIONS
-- =============================================================================
INSERT INTO specializations (spec_name, description) VALUES
    ('Cardiology',              'Heart and cardiovascular system disorders'),
    ('Interventional Cardiology','Catheter-based treatment of heart diseases'),
    ('Orthopedic Surgery',      'Bones, joints, muscles, and related structures'),
    ('Spine Surgery',           'Surgical treatment of spinal conditions'),
    ('Neurology',               'Disorders of the nervous system'),
    ('Neurosurgery',            'Surgical treatment of neurological conditions'),
    ('General Surgery',         'Broad surgical procedures for various conditions'),
    ('Laparoscopic Surgery',    'Minimally invasive surgical techniques'),
    ('Emergency Medicine',      'Immediate care for acute illness and trauma'),
    ('Pediatrics',              'Medical care for infants, children, and adolescents'),
    ('Neonatology',             'Care for newborns, especially premature infants'),
    ('Obstetrics',              'Pregnancy, childbirth, and postpartum care'),
    ('Gynecology',              'Female reproductive health'),
    ('Oncology',                'Diagnosis and treatment of cancer'),
    ('Radiation Oncology',      'Radiation therapy for cancer treatment'),
    ('Pulmonology',             'Lung and respiratory tract diseases'),
    ('Nephrology',              'Kidney diseases and renal replacement therapy'),
    ('Dermatology',             'Skin, hair, and nail conditions'),
    ('ENT',                     'Ear, nose, and throat conditions'),
    ('Ophthalmology',           'Eye disorders and vision care'),
    ('Gastroenterology',        'Digestive system disorders'),
    ('Endocrinology',           'Hormonal and metabolic disorders'),
    ('Psychiatry',              'Mental, behavioral, and emotional disorders'),
    ('Rheumatology',            'Autoimmune and musculoskeletal diseases'),
    ('Urology',                 'Urinary tract and male reproductive health'),
    ('Plastic Surgery',         'Reconstructive and cosmetic procedures'),
    ('Internal Medicine',       'Non-surgical management of adult diseases'),
    ('Anesthesiology',          'Anesthesia and pain management'),
    ('Radiology',               'Medical imaging for diagnosis'),
    ('Pathology',               'Laboratory analysis of disease');

-- =============================================================================
-- DOCTORS (150 doctors)
-- Dept mapping: 1=Card,2=Orth,3=Neur,4=GSur,5=Emer,6=Pedi,7=Gyno,8=Onco,
--               9=Pulm,10=Neph,11=Derm,12=ENT,13=Opht,14=Gast,15=Endo,
--               16=Psyc,17=Rheu,18=Urol,19=Plas,20=IntM
-- =============================================================================
INSERT INTO doctors
    (branch_id, dept_id, first_name, last_name, gender, date_of_birth,
     phone, email, registration_number, qualification, experience_years,
     consultation_fee, joining_date, employment_type)
VALUES
-- CARDIOLOGY (dept_id=1, branch_id=1)
(1,1,'Arjun','Sharma','M','1975-04-12','9000100001','arjun.sharma@cityhosp.com','MCI-CARD-001','MBBS MD DM (Cardiology)',22,1500,'2010-06-01','Full-Time'),
(1,1,'Priya','Mehta','F','1980-09-23','9000100002','priya.mehta@cityhosp.com','MCI-CARD-002','MBBS MD DM (Cardiology)',17,1200,'2013-03-15','Full-Time'),
(1,1,'Rahul','Verma','M','1978-07-05','9000100003','rahul.verma@cityhosp.com','MCI-CARD-003','MBBS MD DM Interventional',19,1800,'2012-01-10','Full-Time'),
(1,1,'Sunita','Patel','F','1982-11-30','9000100004','sunita.patel@cityhosp.com','MCI-CARD-004','MBBS MD (Cardiology)',15,1000,'2015-08-20','Full-Time'),
(1,1,'Vikram','Singh','M','1970-03-18','9000100005','vikram.singh@cityhosp.com','MCI-CARD-005','MBBS MD DM (Cardiology) FACC',27,2000,'2008-05-01','Full-Time'),
(1,1,'Anjali','Gupta','F','1985-06-22','9000100006','anjali.gupta@cityhosp.com','MCI-CARD-006','MBBS MD DM (Cardiology)',12,900,'2016-07-01','Full-Time'),
(1,1,'Deepak','Nair','M','1977-12-01','9000100007','deepak.nair@cityhosp.com','MCI-CARD-007','MBBS MD DM (Cardiology)',20,1600,'2011-02-14','Full-Time'),
-- ORTHOPEDICS (dept_id=2)
(1,2,'Sanjay','Kulkarni','M','1973-08-14','9000100008','sanjay.kulkarni@cityhosp.com','MCI-ORTH-001','MBBS MS (Ortho) MCh',24,1200,'2009-04-01','Full-Time'),
(1,2,'Meera','Joshi','F','1981-02-27','9000100009','meera.joshi@cityhosp.com','MCI-ORTH-002','MBBS MS (Ortho)',16,800,'2014-09-10','Full-Time'),
(1,2,'Anil','Desai','M','1976-10-09','9000100010','anil.desai@cityhosp.com','MCI-ORTH-003','MBBS MS DNB (Ortho)',21,1000,'2010-11-20','Full-Time'),
(1,2,'Kavita','Rao','F','1984-05-16','9000100011','kavita.rao@cityhosp.com','MCI-ORTH-004','MBBS MS (Ortho)',13,750,'2017-01-05','Full-Time'),
(1,2,'Ravi','Kumar','M','1979-01-25','9000100012','ravi.kumar@cityhosp.com','MCI-ORTH-005','MBBS MS MCh (Spine)',18,1400,'2012-06-01','Full-Time'),
(1,2,'Pooja','Iyer','F','1986-07-03','9000100013','pooja.iyer@cityhosp.com','MCI-ORTH-006','MBBS MS (Ortho)',11,700,'2018-03-15','Full-Time'),
(1,2,'Nikhil','Bose','M','1983-09-28','9000100014','nikhil.bose@cityhosp.com','MCI-ORTH-007','MBBS MS DNB',14,850,'2016-05-20','Full-Time'),
-- NEUROLOGY (dept_id=3)
(1,3,'Suresh','Pillai','M','1972-03-07','9000100015','suresh.pillai@cityhosp.com','MCI-NEUR-001','MBBS MD DM (Neurology)',25,1800,'2008-09-01','Full-Time'),
(1,3,'Rekha','Saxena','F','1978-11-19','9000100016','rekha.saxena@cityhosp.com','MCI-NEUR-002','MBBS MD DM (Neurology)',19,1500,'2012-02-28','Full-Time'),
(1,3,'Amit','Tiwari','M','1982-06-14','9000100017','amit.tiwari@cityhosp.com','MCI-NEUR-003','MBBS MD (Neurology)',15,1200,'2015-10-01','Full-Time'),
(1,3,'Nisha','Chandra','F','1980-04-08','9000100018','nisha.chandra@cityhosp.com','MCI-NEUR-004','MBBS MD DM (Neurology)',17,1300,'2013-07-15','Full-Time'),
(1,3,'Gaurav','Mishra','M','1975-08-22','9000100019','gaurav.mishra@cityhosp.com','MCI-NEUR-005','MBBS MD MCh (Neurosurgery)',22,2000,'2010-04-01','Full-Time'),
(1,3,'Shweta','Banerjee','F','1985-12-11','9000100020','shweta.banerjee@cityhosp.com','MCI-NEUR-006','MBBS MD (Neurology)',12,1000,'2017-06-20','Full-Time'),
-- GENERAL SURGERY (dept_id=4)
(1,4,'Manoj','Tripathi','M','1971-07-29','9000100021','manoj.tripathi@cityhosp.com','MCI-GSUR-001','MBBS MS (Gen Surg) MCh',26,1200,'2007-01-15','Full-Time'),
(1,4,'Lata','Reddy','F','1979-03-04','9000100022','lata.reddy@cityhosp.com','MCI-GSUR-002','MBBS MS (Gen Surg)',18,900,'2013-05-01','Full-Time'),
(1,4,'Prakash','Shah','M','1977-10-17','9000100023','prakash.shah@cityhosp.com','MCI-GSUR-003','MBBS MS DNB (Surg)',20,1000,'2011-08-10','Full-Time'),
(1,4,'Usha','Menon','F','1983-01-21','9000100024','usha.menon@cityhosp.com','MCI-GSUR-004','MBBS MS (Laparoscopy)',14,1100,'2016-11-01','Full-Time'),
(1,4,'Rajesh','Pandey','M','1980-06-13','9000100025','rajesh.pandey@cityhosp.com','MCI-GSUR-005','MBBS MS (Gen Surg)',17,950,'2014-03-20','Full-Time'),
-- EMERGENCY & TRAUMA (dept_id=5)
(1,5,'Kapil','Malhotra','M','1984-02-18','9000100026','kapil.malhotra@cityhosp.com','MCI-EMER-001','MBBS MD (Emergency Med)',13,600,'2016-07-01','Full-Time'),
(1,5,'Divya','Agarwal','F','1986-08-05','9000100027','divya.agarwal@cityhosp.com','MCI-EMER-002','MBBS MD (Emergency Med)',11,600,'2018-01-10','Full-Time'),
(1,5,'Rohit','Choudhary','M','1982-11-29','9000100028','rohit.choudhary@cityhosp.com','MCI-EMER-003','MBBS MRCEM',15,700,'2015-06-01','Full-Time'),
(1,5,'Suman','Sethi','F','1987-04-07','9000100029','suman.sethi@cityhosp.com','MCI-EMER-004','MBBS MD (Emergency Med)',10,600,'2019-03-01','Full-Time'),
-- PEDIATRICS (dept_id=6, branch_id=2)
(2,6,'Vinod','Kapoor','M','1974-09-10','9000100030','vinod.kapoor@cityhosp.com','MCI-PEDI-001','MBBS MD DCH (Pediatrics)',23,1000,'2009-02-15','Full-Time'),
(2,6,'Anita','Mathur','F','1980-12-03','9000100031','anita.mathur@cityhosp.com','MCI-PEDI-002','MBBS MD (Pediatrics)',17,900,'2013-09-01','Full-Time'),
(2,6,'Harish','Varma','M','1978-05-26','9000100032','harish.varma@cityhosp.com','MCI-PEDI-003','MBBS MD DM (Neonatology)',19,1200,'2012-04-01','Full-Time'),
(2,6,'Smita','Jain','F','1982-08-14','9000100033','smita.jain@cityhosp.com','MCI-PEDI-004','MBBS MD (Pediatrics)',15,800,'2015-11-20','Full-Time'),
(2,6,'Arun','Ghosh','M','1976-01-30','9000100034','arun.ghosh@cityhosp.com','MCI-PEDI-005','MBBS MD DCH',21,950,'2011-06-01','Full-Time'),
(2,6,'Pallavi','Srivastava','F','1984-03-18','9000100035','pallavi.srivastava@cityhosp.com','MCI-PEDI-006','MBBS MD (Pediatrics)',13,750,'2016-08-10','Full-Time'),
(2,6,'Mohan','Das','M','1979-07-22','9000100036','mohan.das@cityhosp.com','MCI-PEDI-007','MBBS MD (Pediatrics)',18,900,'2013-01-15','Full-Time'),
-- GYNECOLOGY (dept_id=7)
(2,7,'Sarla','Khanna','F','1973-05-15','9000100037','sarla.khanna@cityhosp.com','MCI-GYNO-001','MBBS MD MS (OBG)',24,1200,'2009-06-01','Full-Time'),
(2,7,'Ritu','Bhatia','F','1980-10-28','9000100038','ritu.bhatia@cityhosp.com','MCI-GYNO-002','MBBS MD (OBG)',17,1000,'2013-11-01','Full-Time'),
(2,7,'Neha','Sharma','F','1983-02-11','9000100039','neha.sharma@cityhosp.com','MCI-GYNO-003','MBBS MS (OBG)',14,900,'2016-04-15','Full-Time'),
(2,7,'Sunita','Dubey','F','1978-08-19','9000100040','sunita.dubey@cityhosp.com','MCI-GYNO-004','MBBS MD (OBG)',19,1100,'2012-09-01','Full-Time'),
(2,7,'Kavitha','Natarajan','F','1981-12-05','9000100041','kavitha.natarajan@cityhosp.com','MCI-GYNO-005','MBBS MS (OBG)',16,1000,'2014-07-20','Full-Time'),
(2,7,'Preeti','Walia','F','1986-06-24','9000100042','preeti.walia@cityhosp.com','MCI-GYNO-006','MBBS MS (OBG)',11,800,'2018-05-01','Full-Time'),
-- ONCOLOGY (dept_id=8)
(2,8,'Sunil','Khare','M','1972-11-08','9000100043','sunil.khare@cityhosp.com','MCI-ONCO-001','MBBS MD DM (Oncology)',25,2000,'2008-03-01','Full-Time'),
(2,8,'Mala','Krishnan','F','1977-04-14','9000100044','mala.krishnan@cityhosp.com','MCI-ONCO-002','MBBS MD (Radiation Onco)',20,1800,'2011-10-15','Full-Time'),
(2,8,'Vivek','Sinha','M','1980-09-27','9000100045','vivek.sinha@cityhosp.com','MCI-ONCO-003','MBBS MD DM (Oncology)',17,1500,'2014-02-01','Full-Time'),
(2,8,'Nandita','Roy','F','1978-06-03','9000100046','nandita.roy@cityhosp.com','MCI-ONCO-004','MBBS MD (Oncology)',19,1600,'2012-05-20','Full-Time'),
(2,8,'Ashok','Patel','M','1975-02-21','9000100047','ashok.patel@cityhosp.com','MCI-ONCO-005','MBBS MD DM (Oncology)',22,1800,'2010-08-01','Full-Time'),
-- PULMONOLOGY (dept_id=9)
(2,9,'Rajan','Nath','M','1976-07-17','9000100048','rajan.nath@cityhosp.com','MCI-PULM-001','MBBS MD DM (Pulmonology)',21,1200,'2011-01-10','Full-Time'),
(2,9,'Asha','Pillai','F','1981-03-09','9000100049','asha.pillai@cityhosp.com','MCI-PULM-002','MBBS MD (Pulmonology)',16,1000,'2015-05-01','Full-Time'),
(2,9,'Santosh','Kumar','M','1979-11-23','9000100050','santosh.kumar@cityhosp.com','MCI-PULM-003','MBBS MD (Pulmonology)',18,1100,'2013-08-15','Full-Time'),
(2,9,'Geeta','Mehta','F','1984-08-06','9000100051','geeta.mehta@cityhosp.com','MCI-PULM-004','MBBS MD (Chest)',13,900,'2017-03-01','Full-Time'),
-- NEPHROLOGY (dept_id=10)
(2,10,'Vinay','Shetty','M','1974-12-28','9000100052','vinay.shetty@cityhosp.com','MCI-NEPH-001','MBBS MD DM (Nephrology)',23,1500,'2009-09-01','Full-Time'),
(2,10,'Aruna','Garg','F','1979-05-11','9000100053','aruna.garg@cityhosp.com','MCI-NEPH-002','MBBS MD (Nephrology)',18,1200,'2013-12-15','Full-Time'),
(2,10,'Prasad','Iyer','M','1977-09-04','9000100054','prasad.iyer@cityhosp.com','MCI-NEPH-003','MBBS MD DM (Nephrology)',20,1300,'2011-04-01','Full-Time'),
(2,10,'Lalitha','Rao','F','1982-01-16','9000100055','lalitha.rao@cityhosp.com','MCI-NEPH-004','MBBS MD (Nephrology)',15,1000,'2016-02-20','Full-Time'),
-- DERMATOLOGY (dept_id=11, branch_id=3)
(3,11,'Shruti','Acharya','F','1981-06-30','9000100056','shruti.acharya@cityhosp.com','MCI-DERM-001','MBBS MD (Dermatology)',16,800,'2014-10-01','Full-Time'),
(3,11,'Kiran','Patil','M','1978-03-25','9000100057','kiran.patil@cityhosp.com','MCI-DERM-002','MBBS MD (Dermatology)',19,900,'2012-07-15','Full-Time'),
(3,11,'Mamta','Singh','F','1983-10-12','9000100058','mamta.singh@cityhosp.com','MCI-DERM-003','MBBS MD (Dermatology)',14,750,'2016-12-01','Full-Time'),
(3,11,'Tushar','Shah','M','1985-07-08','9000100059','tushar.shah@cityhosp.com','MCI-DERM-004','MBBS MD DVD',12,700,'2018-04-10','Full-Time'),
(3,11,'Bharti','Nair','F','1977-02-14','9000100060','bharti.nair@cityhosp.com','MCI-DERM-005','MBBS MD (Dermatology)',20,950,'2011-09-01','Full-Time'),
-- ENT (dept_id=12)
(3,12,'Gopal','Menon','M','1975-05-20','9000100061','gopal.menon@cityhosp.com','MCI-ENTD-001','MBBS MS (ENT)',22,900,'2010-02-01','Full-Time'),
(3,12,'Swapna','Krishnan','F','1981-09-14','9000100062','swapna.krishnan@cityhosp.com','MCI-ENTD-002','MBBS MS DNB (ENT)',16,750,'2015-06-15','Full-Time'),
(3,12,'Dilip','Joshi','M','1979-04-02','9000100063','dilip.joshi@cityhosp.com','MCI-ENTD-003','MBBS MS (ENT)',18,800,'2013-03-01','Full-Time'),
(3,12,'Preethi','Rajan','F','1984-11-26','9000100064','preethi.rajan@cityhosp.com','MCI-ENTD-004','MBBS MS (ENT)',13,700,'2017-08-20','Full-Time'),
-- OPHTHALMOLOGY (dept_id=13)
(3,13,'Naresh','Goenka','M','1973-08-31','9000100065','naresh.goenka@cityhosp.com','MCI-OPHT-001','MBBS MS (Ophthalmology)',24,1200,'2009-05-01','Full-Time'),
(3,13,'Shobha','Verma','F','1978-12-17','9000100066','shobha.verma@cityhosp.com','MCI-OPHT-002','MBBS MS (Ophthalmology)',19,1000,'2012-10-15','Full-Time'),
(3,13,'Ramesh','Babu','M','1981-07-09','9000100067','ramesh.babu@cityhosp.com','MCI-OPHT-003','MBBS MS DNB (Ophthalmology)',16,900,'2015-01-20','Full-Time'),
(3,13,'Ila','Desai','F','1986-03-23','9000100068','ila.desai@cityhosp.com','MCI-OPHT-004','MBBS MS (Ophthalmology)',11,800,'2018-07-01','Full-Time'),
-- GASTROENTEROLOGY (dept_id=14)
(3,14,'Subramaniam','Venkat','M','1974-10-05','9000100069','subramaniam.venkat@cityhosp.com','MCI-GAST-001','MBBS MD DM (Gastro)',23,1500,'2009-11-01','Full-Time'),
(3,14,'Padma','Ravi','F','1979-06-18','9000100070','padma.ravi@cityhosp.com','MCI-GAST-002','MBBS MD (Gastro)',18,1200,'2013-04-15','Full-Time'),
(3,14,'Ashwin','Menon','M','1982-02-28','9000100071','ashwin.menon@cityhosp.com','MCI-GAST-003','MBBS MD DM (Gastro)',15,1300,'2016-09-01','Full-Time'),
(3,14,'Vasudha','Sharma','F','1977-11-10','9000100072','vasudha.sharma@cityhosp.com','MCI-GAST-004','MBBS MD (Gastro)',20,1100,'2011-07-20','Full-Time'),
-- ENDOCRINOLOGY (dept_id=15)
(3,15,'Kishore','Naidu','M','1976-04-27','9000100073','kishore.naidu@cityhosp.com','MCI-ENDO-001','MBBS MD DM (Endocrinology)',21,1400,'2011-03-01','Full-Time'),
(3,15,'Ananya','Bhatt','F','1981-10-19','9000100074','ananya.bhatt@cityhosp.com','MCI-ENDO-002','MBBS MD (Endocrinology)',16,1100,'2015-07-10','Full-Time'),
(3,15,'Rajendra','Pillay','M','1978-07-13','9000100075','rajendra.pillay@cityhosp.com','MCI-ENDO-003','MBBS MD DM (Endocrinology)',19,1200,'2012-12-01','Full-Time'),
(3,15,'Shweta','Anil','F','1984-01-07','9000100076','shweta.anil@cityhosp.com','MCI-ENDO-004','MBBS MD (Endocrinology)',13,950,'2017-05-20','Full-Time'),
-- PSYCHIATRY (dept_id=16, branch_id=4)
(4,16,'Monika','Bose','F','1975-09-06','9000100077','monika.bose@cityhosp.com','MCI-PSYC-001','MBBS MD (Psychiatry)',22,1000,'2010-01-15','Full-Time'),
(4,16,'Alok','Chatterjee','M','1980-03-24','9000100078','alok.chatterjee@cityhosp.com','MCI-PSYC-002','MBBS MD (Psychiatry)',17,900,'2014-06-01','Full-Time'),
(4,16,'Indira','Das','F','1977-11-01','9000100079','indira.das@cityhosp.com','MCI-PSYC-003','MBBS MD (Psychiatry)',20,950,'2012-02-28','Full-Time'),
(4,16,'Avinash','Roy','M','1983-06-16','9000100080','avinash.roy@cityhosp.com','MCI-PSYC-004','MBBS MD DPM',14,850,'2016-10-20','Full-Time'),
(4,16,'Tanuja','Misra','F','1986-02-08','9000100081','tanuja.misra@cityhosp.com','MCI-PSYC-005','MBBS MD (Psychiatry)',11,800,'2018-08-01','Full-Time'),
-- RHEUMATOLOGY (dept_id=17)
(4,17,'Girish','Pandey','M','1974-05-13','9000100082','girish.pandey@cityhosp.com','MCI-RHEU-001','MBBS MD DM (Rheumatology)',23,1300,'2009-08-01','Full-Time'),
(4,17,'Chetana','Kulkarni','F','1979-09-07','9000100083','chetana.kulkarni@cityhosp.com','MCI-RHEU-002','MBBS MD (Rheumatology)',18,1100,'2013-10-15','Full-Time'),
(4,17,'Nilesh','Apte','M','1982-04-19','9000100084','nilesh.apte@cityhosp.com','MCI-RHEU-003','MBBS MD (Rheumatology)',15,1000,'2016-03-01','Full-Time'),
-- UROLOGY (dept_id=18)
(4,18,'Samir','Bhatt','M','1973-12-22','9000100085','samir.bhatt@cityhosp.com','MCI-UROL-001','MBBS MS MCh (Urology)',24,1500,'2009-04-15','Full-Time'),
(4,18,'Pankaj','Mehrotra','M','1978-08-09','9000100086','pankaj.mehrotra@cityhosp.com','MCI-UROL-002','MBBS MS (Urology)',19,1200,'2012-11-01','Full-Time'),
(4,18,'Leela','Krishnan','F','1983-03-15','9000100087','leela.krishnan@cityhosp.com','MCI-UROL-003','MBBS MS DNB (Urology)',14,1000,'2016-07-20','Full-Time'),
(4,18,'Hemant','Shinde','M','1980-06-28','9000100088','hemant.shinde@cityhosp.com','MCI-UROL-004','MBBS MS (Urology)',17,1100,'2014-01-10','Full-Time'),
-- PLASTIC SURGERY (dept_id=19, branch_id=5)
(5,19,'Varun','Kapila','M','1976-01-04','9000100089','varun.kapila@cityhosp.com','MCI-PLAS-001','MBBS MS MCh (Plastic Surg)',21,2500,'2011-05-01','Full-Time'),
(5,19,'Deepa','Jain','F','1981-07-17','9000100090','deepa.jain@cityhosp.com','MCI-PLAS-002','MBBS MS MCh (Plastic Surg)',16,2200,'2015-09-15','Full-Time'),
(5,19,'Sameer','Khatri','M','1979-11-11','9000100091','sameer.khatri@cityhosp.com','MCI-PLAS-003','MBBS MS (Plastic Surg)',18,2000,'2013-06-01','Full-Time'),
(5,19,'Poornima','Hegde','F','1985-04-29','9000100092','poornima.hegde@cityhosp.com','MCI-PLAS-004','MBBS MS MCh',12,1800,'2018-02-10','Full-Time'),
-- INTERNAL MEDICINE (dept_id=20, branch_id=5)
(5,20,'Jagdish','Sharma','M','1971-10-18','9000100093','jagdish.sharma@cityhosp.com','MCI-INTM-001','MBBS MD (Internal Medicine)',26,1000,'2007-03-01','Full-Time'),
(5,20,'Sulochana','Nair','F','1977-06-07','9000100094','sulochana.nair@cityhosp.com','MCI-INTM-002','MBBS MD (Medicine)',20,900,'2011-12-15','Full-Time'),
(5,20,'Bhaskar','Rao','M','1980-02-15','9000100095','bhaskar.rao@cityhosp.com','MCI-INTM-003','MBBS MD (Medicine)',17,850,'2014-08-01','Full-Time'),
(5,20,'Chandrika','Sood','F','1983-08-23','9000100096','chandrika.sood@cityhosp.com','MCI-INTM-004','MBBS MD (Internal Medicine)',14,800,'2017-04-20','Full-Time'),
(5,20,'Santanu','Dey','M','1978-12-30','9000100097','santanu.dey@cityhosp.com','MCI-INTM-005','MBBS MD (Medicine)',19,900,'2012-07-01','Full-Time'),
-- VISITING/CONSULTANT doctors (mix of branches)
(1,1,'Ramakant','Bhalerao','M','1968-05-09','9000100098','ramakant.bhalerao@cityhosp.com','MCI-CONS-001','MBBS MD DM FACC',29,3000,'2020-01-01','Consultant'),
(2,8,'Geeta','Sethi','F','1970-03-15','9000100099','geeta.sethi@cityhosp.com','MCI-CONS-002','MBBS MD DM (Hemato-Onco)',27,2800,'2020-02-01','Consultant'),
(3,14,'Ramprasad','Balasubramaniam','M','1969-11-22','9000100100','ramprasad.balasubramaniam@cityhosp.com','MCI-CONS-003','MBBS MD DM FACG',28,2600,'2020-03-01','Consultant'),
-- Additional Full-Time doctors to reach 150
(1,1,'Isha','Kohli','F','1988-02-14','9000100101','isha.kohli@cityhosp.com','MCI-CARD-008','MBBS MD',9,800,'2020-06-01','Full-Time'),
(1,2,'Feroz','Khan','M','1987-05-20','9000100102','feroz.khan@cityhosp.com','MCI-ORTH-008','MBBS MS',10,750,'2020-01-15','Full-Time'),
(1,3,'Shalini','Tripathi','F','1989-08-11','9000100103','shalini.tripathi@cityhosp.com','MCI-NEUR-007','MBBS MD',8,900,'2021-03-01','Full-Time'),
(1,4,'Dev','Oberoi','M','1990-01-28','9000100104','dev.oberoi@cityhosp.com','MCI-GSUR-006','MBBS MS',7,800,'2021-07-01','Full-Time'),
(1,5,'Yashna','Puri','F','1991-06-04','9000100105','yashna.puri@cityhosp.com','MCI-EMER-005','MBBS MD',6,600,'2022-01-10','Full-Time'),
(2,6,'Tarun','Bajaj','M','1988-09-17','9000100106','tarun.bajaj@cityhosp.com','MCI-PEDI-008','MBBS MD',9,700,'2020-08-01','Full-Time'),
(2,7,'Richa','Lal','F','1989-03-22','9000100107','richa.lal@cityhosp.com','MCI-GYNO-007','MBBS MS',8,750,'2021-01-15','Full-Time'),
(2,8,'Naman','Arora','M','1990-07-09','9000100108','naman.arora@cityhosp.com','MCI-ONCO-006','MBBS MD',7,1200,'2021-09-01','Full-Time'),
(2,9,'Shipra','Gupta','F','1991-11-25','9000100109','shipra.gupta@cityhosp.com','MCI-PULM-005','MBBS MD',6,800,'2022-03-01','Full-Time'),
(2,10,'Vishal','Ahuja','M','1989-04-13','9000100110','vishal.ahuja@cityhosp.com','MCI-NEPH-005','MBBS MD',8,950,'2020-11-01','Full-Time'),
(3,11,'Priya','Choudhry','F','1990-12-18','9000100111','priya.choudhry@cityhosp.com','MCI-DERM-006','MBBS MD',7,650,'2021-05-01','Full-Time'),
(3,12,'Jayant','Mane','M','1988-08-05','9000100112','jayant.mane@cityhosp.com','MCI-ENTD-005','MBBS MS',9,700,'2020-10-15','Full-Time'),
(3,13,'Sonali','Bhave','F','1989-02-27','9000100113','sonali.bhave@cityhosp.com','MCI-OPHT-005','MBBS MS',8,750,'2021-04-01','Full-Time'),
(3,14,'Karthik','Suresh','M','1991-07-14','9000100114','karthik.suresh@cityhosp.com','MCI-GAST-005','MBBS MD',6,1000,'2022-01-20','Full-Time'),
(3,15,'Minakshi','Pandey','F','1990-05-01','9000100115','minakshi.pandey@cityhosp.com','MCI-ENDO-005','MBBS MD',7,850,'2021-08-01','Full-Time'),
(4,16,'Saurabh','Datta','M','1989-10-08','9000100116','saurabh.datta@cityhosp.com','MCI-PSYC-006','MBBS MD',8,750,'2020-12-01','Full-Time'),
(4,17,'Rohini','Apte','F','1988-06-21','9000100117','rohini.apte@cityhosp.com','MCI-RHEU-004','MBBS MD',9,900,'2020-09-15','Full-Time'),
(4,18,'Harshal','Jha','M','1990-03-06','9000100118','harshal.jha@cityhosp.com','MCI-UROL-005','MBBS MS',7,950,'2021-06-01','Full-Time'),
(5,19,'Madhuri','Kale','F','1991-09-29','9000100119','madhuri.kale@cityhosp.com','MCI-PLAS-005','MBBS MS',6,1500,'2022-04-01','Full-Time'),
(5,20,'Navin','Bhat','M','1989-01-16','9000100120','navin.bhat@cityhosp.com','MCI-INTM-006','MBBS MD',8,700,'2020-07-01','Full-Time'),
-- Part-Time / Visiting
(1,1,'Suhas','Gokhale','M','1965-07-24','9000100121','suhas.gokhale@cityhosp.com','MCI-VIS-001','MBBS MD DM',32,4000,'2021-01-01','Visiting'),
(2,7,'Madhavi','Bhatt','F','1968-04-10','9000100122','madhavi.bhatt@cityhosp.com','MCI-VIS-002','MBBS MD MS',29,3000,'2021-01-01','Visiting'),
(3,13,'Venkat','Subramaniam','M','1967-09-03','9000100123','venkat.subramaniam@cityhosp.com','MCI-VIS-003','MBBS MS FACS',30,3500,'2021-01-01','Visiting'),
(4,16,'Urvashi','Bhardwaj','F','1969-12-14','9000100124','urvashi.bhardwaj@cityhosp.com','MCI-VIS-004','MBBS MD FRCPsych',28,3000,'2021-01-01','Visiting'),
(5,20,'Ashutosh','Tripathi','M','1966-02-19','9000100125','ashutosh.tripathi@cityhosp.com','MCI-VIS-005','MBBS MD FRCP',31,3500,'2021-01-01','Visiting'),
-- More Full-Time to pad to 150
(1,1,'Deepika','Ramesh','F','1987-03-07','9000100126','deepika.ramesh@cityhosp.com','MCI-CARD-009','MBBS MD DM',10,850,'2020-05-01','Full-Time'),
(1,2,'Manish','Thapar','M','1986-11-29','9000100127','manish.thapar@cityhosp.com','MCI-ORTH-009','MBBS MS',11,800,'2019-09-01','Full-Time'),
(1,3,'Bhavana','Saxena','F','1988-06-15','9000100128','bhavana.saxena@cityhosp.com','MCI-NEUR-008','MBBS MD',9,950,'2020-04-01','Full-Time'),
(1,4,'Chetan','More','M','1989-09-04','9000100129','chetan.more@cityhosp.com','MCI-GSUR-007','MBBS MS',8,850,'2021-01-20','Full-Time'),
(2,6,'Fatima','Sheikh','F','1990-04-26','9000100130','fatima.sheikh@cityhosp.com','MCI-PEDI-009','MBBS MD',7,700,'2021-08-15','Full-Time'),
(2,8,'Arnav','Bose','M','1991-08-12','9000100131','arnav.bose@cityhosp.com','MCI-ONCO-007','MBBS MD',6,1100,'2022-02-01','Full-Time'),
(2,9,'Shilpa','Varma','F','1988-01-03','9000100132','shilpa.varma@cityhosp.com','MCI-PULM-006','MBBS MD',9,950,'2020-10-01','Full-Time'),
(3,11,'Vivaan','Seth','M','1987-07-18','9000100133','vivaan.seth@cityhosp.com','MCI-DERM-007','MBBS MD',10,700,'2020-03-01','Full-Time'),
(3,12,'Tanvi','Bendre','F','1990-10-30','9000100134','tanvi.bendre@cityhosp.com','MCI-ENTD-006','MBBS MS',7,650,'2021-11-01','Full-Time'),
(3,14,'Saket','Mittal','M','1988-03-24','9000100135','saket.mittal@cityhosp.com','MCI-GAST-006','MBBS MD',9,1100,'2020-08-15','Full-Time'),
(3,15,'Roshni','Menon','F','1989-12-08','9000100136','roshni.menon@cityhosp.com','MCI-ENDO-006','MBBS MD',8,900,'2021-02-01','Full-Time'),
(4,16,'Nakul','Bhatt','M','1991-05-17','9000100137','nakul.bhatt@cityhosp.com','MCI-PSYC-007','MBBS MD',6,750,'2022-05-01','Full-Time'),
(4,17,'Seema','Joshi','F','1987-08-28','9000100138','seema.joshi@cityhosp.com','MCI-RHEU-005','MBBS MD',10,950,'2020-06-15','Full-Time'),
(4,18,'Vipul','Naik','M','1989-02-05','9000100139','vipul.naik@cityhosp.com','MCI-UROL-006','MBBS MS',8,1000,'2021-03-20','Full-Time'),
(5,19,'Chandni','Mehta','F','1990-11-21','9000100140','chandni.mehta@cityhosp.com','MCI-PLAS-006','MBBS MS',7,1600,'2021-10-01','Full-Time'),
(5,20,'Surendra','Pillai','M','1986-06-11','9000100141','surendra.pillai@cityhosp.com','MCI-INTM-007','MBBS MD',11,800,'2019-12-01','Full-Time'),
(1,5,'Komal','Wadhwa','F','1992-01-09','9000100142','komal.wadhwa@cityhosp.com','MCI-EMER-006','MBBS MD',5,550,'2022-08-01','Full-Time'),
(2,10,'Shirish','Godbole','M','1986-04-03','9000100143','shirish.godbole@cityhosp.com','MCI-NEPH-006','MBBS MD DM',11,1100,'2019-08-15','Full-Time'),
(3,13,'Mukta','Ghate','F','1991-10-14','9000100144','mukta.ghate@cityhosp.com','MCI-OPHT-006','MBBS MS',6,700,'2022-06-01','Full-Time'),
(4,18,'Harshil','Doshi','M','1987-12-27','9000100145','harshil.doshi@cityhosp.com','MCI-UROL-007','MBBS MS MCh',10,1150,'2020-04-15','Full-Time'),
(5,19,'Nirupama','Kamath','F','1989-05-15','9000100146','nirupama.kamath@cityhosp.com','MCI-PLAS-007','MBBS MS',8,1700,'2021-07-01','Full-Time'),
(1,2,'Sumedh','Rane','M','1991-02-18','9000100147','sumedh.rane@cityhosp.com','MCI-ORTH-010','MBBS MS',6,700,'2022-09-01','Full-Time'),
(2,6,'Aishwarya','Singh','F','1992-07-31','9000100148','aishwarya.singh@cityhosp.com','MCI-PEDI-010','MBBS MD',5,650,'2022-11-01','Full-Time'),
(3,14,'Aadesh','Bapat','M','1990-09-22','9000100149','aadesh.bapat@cityhosp.com','MCI-GAST-007','MBBS MD DM',7,1050,'2021-12-01','Full-Time'),
(5,20,'Madhurima','Roy','F','1988-10-06','9000100150','madhurima.roy@cityhosp.com','MCI-INTM-008','MBBS MD',9,850,'2020-09-01','Full-Time');

-- =============================================================================
-- DOCTOR SPECIALIZATIONS (many-to-many)
-- =============================================================================
INSERT INTO doctor_specializations (doctor_id, spec_id, is_primary)
SELECT d.doctor_id,
       CASE d.dept_id
           WHEN 1  THEN 1  WHEN 2  THEN 3  WHEN 3  THEN 5
           WHEN 4  THEN 7  WHEN 5  THEN 9  WHEN 6  THEN 10
           WHEN 7  THEN 12 WHEN 8  THEN 14 WHEN 9  THEN 16
           WHEN 10 THEN 17 WHEN 11 THEN 18 WHEN 12 THEN 19
           WHEN 13 THEN 20 WHEN 14 THEN 21 WHEN 15 THEN 22
           WHEN 16 THEN 23 WHEN 17 THEN 24 WHEN 18 THEN 25
           WHEN 19 THEN 26 WHEN 20 THEN 27
       END,
       TRUE
FROM doctors d;

-- Some doctors have secondary specializations
INSERT INTO doctor_specializations (doctor_id, spec_id, is_primary) VALUES
(3, 2, FALSE),   -- Rahul Verma: secondary Interventional Cardiology
(5, 2, FALSE),   -- Vikram Singh: secondary Interventional Cardiology
(12, 4, FALSE),  -- Ravi Kumar: secondary Spine Surgery
(19, 6, FALSE),  -- Gaurav Mishra: secondary Neurosurgery
(24, 8, FALSE),  -- Usha Menon: secondary Laparoscopic Surgery
(32, 11, FALSE), -- Harish Varma: secondary Neonatology
(43, 15, FALSE), -- Sunil Khare: secondary Radiation Oncology
(44, 15, FALSE), -- Mala Krishnan: primary Radiation Oncology change (already set above)
(69, 8, FALSE),  -- Subramaniam Venkat: secondary Laparoscopic in gastro
(85, 28, FALSE)  -- Samir Bhatt: secondary Anesthesiology for Urology
ON CONFLICT DO NOTHING;

-- =============================================================================
-- DOCTOR SCHEDULES (Mon-Fri slots; some have Sat too)
-- =============================================================================
-- Insert schedules for all doctors: Mon(1)-Fri(5), 09:00-17:00
INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, max_appointments)
SELECT d.doctor_id,
       gs.dow,
       '09:00'::TIME,
       '17:00'::TIME,
       CASE WHEN gs.dow IN (1,3,5) THEN 20 ELSE 15 END
FROM doctors d
CROSS JOIN GENERATE_SERIES(1, 5) AS gs(dow)
WHERE d.employment_type = 'Full-Time';

-- Visiting/Consultant doctors: only 2 days/week
INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, max_appointments)
SELECT d.doctor_id, gs.dow, '10:00'::TIME, '14:00'::TIME, 10
FROM doctors d
CROSS JOIN (VALUES (2),(4)) AS gs(dow)
WHERE d.employment_type IN ('Consultant','Visiting');

-- Update head_doctor_id for departments (first senior doctor per dept)
UPDATE departments SET head_doctor_id = (
    SELECT doctor_id FROM doctors
    WHERE dept_id = departments.dept_id AND is_active = TRUE
    ORDER BY experience_years DESC LIMIT 1
);

SELECT 'insert_doctors.sql completed. Doctors: '
    || (SELECT COUNT(*) FROM doctors)::TEXT AS status;
