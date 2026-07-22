-- =============================================================================
-- FILE: data/insert_staff.sql
-- DESCRIPTION: Seed data — 100 staff + nurses across all branches.
-- =============================================================================

-- =============================================================================
-- STAFF (100 non-clinical staff)
-- =============================================================================
INSERT INTO staff
    (branch_id, dept_id, first_name, last_name, gender, date_of_birth,
     role, phone, email, joining_date, salary, employment_type)
VALUES
-- Branch 1 Staff
(1,NULL,'Ramona','Kapoor','F','1985-03-14','Head Administrator','9100200001','ramona.kapoor@cityhosp.com','2015-01-01',85000,'Full-Time'),
(1,NULL,'Suresh','Mehta','M','1980-07-22','Senior Accountant','9100200002','suresh.mehta@cityhosp.com','2012-06-01',65000,'Full-Time'),
(1,NULL,'Priti','Sharma','F','1988-11-05','Receptionist','9100200003','priti.sharma@cityhosp.com','2017-03-15',30000,'Full-Time'),
(1,NULL,'Arvind','Joshi','M','1982-09-18','Receptionist','9100200004','arvind.joshi@cityhosp.com','2016-08-01',30000,'Full-Time'),
(1,NULL,'Kavya','Singh','F','1990-04-27','Medical Transcriptionist','9100200005','kavya.singh@cityhosp.com','2018-02-10',35000,'Full-Time'),
(1,NULL,'Rohit','Agarwal','M','1985-12-09','IT Support','9100200006','rohit.agarwal@cityhosp.com','2016-05-01',40000,'Full-Time'),
(1,NULL,'Geeta','Verma','F','1983-06-30','HR Manager','9100200007','geeta.verma@cityhosp.com','2014-09-01',70000,'Full-Time'),
(1,1,'Naman','Gupta','M','1986-02-14','Ward Coordinator','9100200008','naman.gupta@cityhosp.com','2017-07-01',38000,'Full-Time'),
(1,2,'Sunita','Tiwari','F','1989-08-21','Ward Coordinator','9100200009','sunita.tiwari@cityhosp.com','2018-04-15',38000,'Full-Time'),
(1,3,'Sachin','Bose','M','1984-10-03','Ward Coordinator','9100200010','sachin.bose@cityhosp.com','2016-11-01',38000,'Full-Time'),
(1,4,'Manisha','Patel','F','1987-05-16','OT Technician','9100200011','manisha.patel@cityhosp.com','2017-09-01',42000,'Full-Time'),
(1,4,'Vikrant','Rao','M','1985-03-28','OT Technician','9100200012','vikrant.rao@cityhosp.com','2016-01-15',42000,'Full-Time'),
(1,5,'Preeti','Menon','F','1991-11-11','Emergency Coordinator','9100200013','preeti.menon@cityhosp.com','2019-06-01',35000,'Full-Time'),
(1,NULL,'Deepak','Bhatt','M','1983-07-04','Ambulance Coordinator','9100200014','deepak.bhatt@cityhosp.com','2015-03-20',32000,'Full-Time'),
(1,NULL,'Ranjana','Soni','F','1990-01-25','Billing Executive','9100200015','ranjana.soni@cityhosp.com','2018-10-01',32000,'Full-Time'),
(1,NULL,'Harshad','Kulkarni','M','1986-09-13','Billing Executive','9100200016','harshad.kulkarni@cityhosp.com','2017-02-01',32000,'Full-Time'),
(1,NULL,'Swati','Nair','F','1992-04-08','Lab Technician','9100200017','swati.nair@cityhosp.com','2019-03-01',36000,'Full-Time'),
(1,NULL,'Prashant','Desai','M','1984-12-20','Radiology Technician','9100200018','prashant.desai@cityhosp.com','2015-08-01',38000,'Full-Time'),
(1,NULL,'Anjali','Shah','F','1988-06-02','Pharmacist','9100200019','anjali.shah@cityhosp.com','2017-11-15',45000,'Full-Time'),
(1,NULL,'Manoj','Pillay','M','1981-03-17','Pharmacist','9100200020','manoj.pillay@cityhosp.com','2013-04-01',45000,'Full-Time'),
-- Branch 2 Staff
(2,NULL,'Shalini','Chatterjee','F','1984-08-29','Branch Administrator','9100200021','shalini.chatterjee@cityhosp.com','2014-06-01',80000,'Full-Time'),
(2,NULL,'Vijay','Kumar','M','1979-12-15','Senior Accountant','9100200022','vijay.kumar@cityhosp.com','2011-09-01',63000,'Full-Time'),
(2,NULL,'Tanuja','Yadav','F','1989-05-07','Receptionist','9100200023','tanuja.yadav@cityhosp.com','2018-01-15',28000,'Full-Time'),
(2,NULL,'Nitin','Sharma','M','1986-10-21','Receptionist','9100200024','nitin.sharma@cityhosp.com','2017-06-01',28000,'Full-Time'),
(2,6,'Meenal','Patil','F','1990-02-18','Ward Coordinator','9100200025','meenal.patil@cityhosp.com','2019-04-01',36000,'Full-Time'),
(2,7,'Ashwini','Jain','F','1987-07-10','OT Technician','9100200026','ashwini.jain@cityhosp.com','2016-12-01',42000,'Full-Time'),
(2,8,'Samir','Roy','M','1983-04-24','Oncology Coordinator','9100200027','samir.roy@cityhosp.com','2015-02-01',48000,'Full-Time'),
(2,NULL,'Priya','Ghosh','F','1991-11-30','Billing Executive','9100200028','priya.ghosh@cityhosp.com','2019-07-01',30000,'Full-Time'),
(2,NULL,'Ravi','Sinha','M','1985-06-13','Lab Technician','9100200029','ravi.sinha@cityhosp.com','2016-03-15',35000,'Full-Time'),
(2,NULL,'Swapna','Iyer','F','1989-09-05','Pharmacist','9100200030','swapna.iyer@cityhosp.com','2018-05-01',44000,'Full-Time'),
(2,NULL,'Aniket','Bhalerao','M','1982-01-22','IT Support','9100200031','aniket.bhalerao@cityhosp.com','2014-10-01',38000,'Full-Time'),
(2,NULL,'Surekha','Mishra','F','1986-08-14','HR Executive','9100200032','surekha.mishra@cityhosp.com','2017-04-01',42000,'Full-Time'),
(2,NULL,'Dilip','Banerjee','M','1980-03-06','Radiology Technician','9100200033','dilip.banerjee@cityhosp.com','2012-07-01',37000,'Full-Time'),
(2,NULL,'Rashmi','Doshi','F','1991-07-28','Medical Transcriptionist','9100200034','rashmi.doshi@cityhosp.com','2019-02-01',32000,'Full-Time'),
(2,NULL,'Arun','Acharya','M','1984-05-19','Ambulance Coordinator','9100200035','arun.acharya@cityhosp.com','2015-09-01',31000,'Full-Time'),
-- Branch 3 Staff
(3,NULL,'Kalpana','Reddy','F','1983-10-11','Branch Administrator','9100200036','kalpana.reddy@cityhosp.com','2013-05-01',78000,'Full-Time'),
(3,NULL,'Murugan','Pillai','M','1978-02-28','Senior Accountant','9100200037','murugan.pillai@cityhosp.com','2011-02-01',62000,'Full-Time'),
(3,NULL,'Hema','Subramaniam','F','1990-06-16','Receptionist','9100200038','hema.subramaniam@cityhosp.com','2018-08-01',27000,'Full-Time'),
(3,11,'Ranga','Nathan','M','1986-12-04','Ward Coordinator','9100200039','ranga.nathan@cityhosp.com','2016-10-01',35000,'Full-Time'),
(3,12,'Sujatha','Krishnan','F','1988-04-22','Ward Coordinator','9100200040','sujatha.krishnan@cityhosp.com','2017-07-15',35000,'Full-Time'),
(3,NULL,'Hari','Shankar','M','1983-09-07','Lab Technician','9100200041','hari.shankar@cityhosp.com','2015-04-01',35000,'Full-Time'),
(3,NULL,'Chandra','Sekhar','M','1981-07-01','Pharmacist','9100200042','chandra.sekhar@cityhosp.com','2013-09-01',44000,'Full-Time'),
(3,NULL,'Anbu','Selvan','M','1985-03-15','Billing Executive','9100200043','anbu.selvan@cityhosp.com','2016-06-01',30000,'Full-Time'),
(3,NULL,'Meenakshi','Sundaram','F','1989-11-26','OT Technician','9100200044','meenakshi.sundaram@cityhosp.com','2018-03-01',40000,'Full-Time'),
(3,NULL,'Prabhakaran','Nair','M','1982-08-19','Radiology Technician','9100200045','prabhakaran.nair@cityhosp.com','2014-12-01',37000,'Full-Time'),
-- Branch 4 Staff
(4,NULL,'Tapan','Mukhopadhyay','M','1980-05-03','Branch Administrator','9100200046','tapan.mukhopadhyay@cityhosp.com','2012-03-01',76000,'Full-Time'),
(4,NULL,'Sreela','Dasgupta','F','1985-11-17','Senior Accountant','9100200047','sreela.dasgupta@cityhosp.com','2015-07-01',61000,'Full-Time'),
(4,NULL,'Aritra','Chakraborty','M','1990-07-29','Receptionist','9100200048','aritra.chakraborty@cityhosp.com','2019-01-01',27000,'Full-Time'),
(4,16,'Mahua','Sen','F','1987-02-12','Ward Coordinator','9100200049','mahua.sen@cityhosp.com','2017-05-01',36000,'Full-Time'),
(4,17,'Subhajit','Ghosh','M','1984-09-25','Ward Coordinator','9100200050','subhajit.ghosh@cityhosp.com','2016-08-15',36000,'Full-Time'),
(4,NULL,'Debjani','Roy','F','1991-04-08','Lab Technician','9100200051','debjani.roy@cityhosp.com','2019-06-01',34000,'Full-Time'),
(4,NULL,'Soumitra','Bose','M','1983-01-14','Pharmacist','9100200052','soumitra.bose@cityhosp.com','2014-11-01',43000,'Full-Time'),
(4,NULL,'Jayita','Banerjee','F','1988-06-27','Billing Executive','9100200053','jayita.banerjee@cityhosp.com','2017-10-01',30000,'Full-Time'),
(4,NULL,'Pritam','Das','M','1986-10-03','IT Support','9100200054','pritam.das@cityhosp.com','2016-04-01',37000,'Full-Time'),
(4,NULL,'Bratati','Dey','F','1990-03-21','HR Executive','9100200055','bratati.dey@cityhosp.com','2018-09-01',40000,'Full-Time'),
-- Branch 5 Staff
(5,NULL,'Kedar','Sahasrabudhe','M','1979-08-08','Branch Administrator','9100200056','kedar.sahasrabudhe@cityhosp.com','2013-01-01',75000,'Full-Time'),
(5,NULL,'Vrushali','Deshpande','F','1983-12-31','Senior Accountant','9100200057','vrushali.deshpande@cityhosp.com','2014-05-01',60000,'Full-Time'),
(5,NULL,'Amit','Kale','M','1991-05-13','Receptionist','9100200058','amit.kale@cityhosp.com','2019-08-01',26000,'Full-Time'),
(5,19,'Noopur','Wagh','F','1988-09-04','OT Technician','9100200059','noopur.wagh@cityhosp.com','2018-01-01',41000,'Full-Time'),
(5,20,'Sudhanshu','Joshi','M','1985-04-26','Ward Coordinator','9100200060','sudhanshu.joshi@cityhosp.com','2016-07-01',35000,'Full-Time'),
(5,NULL,'Mugdha','Patankar','F','1990-08-18','Lab Technician','9100200061','mugdha.patankar@cityhosp.com','2019-04-01',34000,'Full-Time'),
(5,NULL,'Prasad','Kulkarni','M','1982-06-09','Pharmacist','9100200062','prasad.kulkarni@cityhosp.com','2014-02-01',44000,'Full-Time'),
(5,NULL,'Shubhangi','Bapat','F','1989-01-15','Billing Executive','9100200063','shubhangi.bapat@cityhosp.com','2018-06-01',30000,'Full-Time'),
(5,NULL,'Rahul','Deo','M','1986-07-28','Radiology Technician','9100200064','rahul.deo@cityhosp.com','2017-03-01',37000,'Full-Time'),
(5,NULL,'Pratibha','Moghe','F','1991-10-10','Medical Transcriptionist','9100200065','pratibha.moghe@cityhosp.com','2019-11-01',31000,'Full-Time'),
-- Additional part-time / contract staff
(1,NULL,'Ratan','Lal','M','1975-03-20','Security Officer','9100200066','ratan.lal@cityhosp.com','2010-01-01',22000,'Full-Time'),
(2,NULL,'Abdul','Hamid','M','1978-07-11','Security Officer','9100200067','abdul.hamid@cityhosp.com','2011-03-01',22000,'Full-Time'),
(3,NULL,'Selvam','Rajan','M','1976-11-27','Security Officer','9100200068','selvam.rajan@cityhosp.com','2012-05-01',22000,'Full-Time'),
(4,NULL,'Bikash','Majumdar','M','1980-05-14','Security Officer','9100200069','bikash.majumdar@cityhosp.com','2013-07-01',22000,'Full-Time'),
(5,NULL,'Balu','Kamble','M','1979-09-03','Security Officer','9100200070','balu.kamble@cityhosp.com','2014-09-01',22000,'Full-Time'),
(1,NULL,'Reshma','Ansari','F','1992-04-18','Data Entry Operator','9100200071','reshma.ansari@cityhosp.com','2020-01-15',24000,'Full-Time'),
(2,NULL,'Sanjana','Kaur','F','1993-08-25','Data Entry Operator','9100200072','sanjana.kaur@cityhosp.com','2020-05-01',24000,'Full-Time'),
(3,NULL,'Bharathi','Rajendran','F','1991-12-07','Data Entry Operator','9100200073','bharathi.rajendran@cityhosp.com','2020-09-01',24000,'Full-Time'),
(4,NULL,'Suparna','Mondal','F','1992-03-29','Data Entry Operator','9100200074','suparna.mondal@cityhosp.com','2021-01-01',24000,'Full-Time'),
(5,NULL,'Sonali','Kadam','F','1993-06-16','Data Entry Operator','9100200075','sonali.kadam@cityhosp.com','2021-03-01',24000,'Full-Time'),
(1,NULL,'Ganesh','More','M','1988-02-03','House Supervisor','9100200076','ganesh.more@cityhosp.com','2016-04-01',28000,'Full-Time'),
(2,NULL,'Bhola','Prasad','M','1985-10-29','House Supervisor','9100200077','bhola.prasad@cityhosp.com','2015-06-01',28000,'Full-Time'),
(3,NULL,'Murugesan','Thangavel','M','1986-07-13','House Supervisor','9100200078','murugesan.thangavel@cityhosp.com','2015-10-01',28000,'Full-Time'),
(4,NULL,'Mrinmoy','Sarkar','M','1987-04-06','House Supervisor','9100200079','mrinmoy.sarkar@cityhosp.com','2016-01-01',28000,'Full-Time'),
(5,NULL,'Milind','Naik','M','1988-01-22','House Supervisor','9100200080','milind.naik@cityhosp.com','2016-08-01',28000,'Full-Time'),
(1,NULL,'Fatima','Begum','F','1985-09-11','Dietary Coordinator','9100200081','fatima.begum@cityhosp.com','2015-11-01',35000,'Full-Time'),
(2,NULL,'Pauline','D''Souza','F','1983-06-04','Dietary Coordinator','9100200082','pauline.dsouza@cityhosp.com','2014-03-01',35000,'Full-Time'),
(3,NULL,'Kamala','Ramachandran','F','1984-01-17','Dietary Coordinator','9100200083','kamala.ramachandran@cityhosp.com','2014-07-01',35000,'Full-Time'),
(4,NULL,'Priya','Mondal','F','1986-10-28','Dietary Coordinator','9100200084','priya.mondal@cityhosp.com','2015-04-01',35000,'Full-Time'),
(5,NULL,'Archana','Kulkarni','F','1987-07-15','Dietary Coordinator','9100200085','archana.kulkarni@cityhosp.com','2016-02-01',35000,'Full-Time'),
(1,NULL,'Lalit','Trivedi','M','1980-04-23','Biomedical Engineer','9100200086','lalit.trivedi@cityhosp.com','2013-08-01',55000,'Full-Time'),
(2,NULL,'Jaydeep','Roy','M','1981-11-08','Biomedical Engineer','9100200087','jaydeep.roy@cityhosp.com','2014-01-01',55000,'Full-Time'),
(3,NULL,'Srihari','Venkatesan','M','1982-08-20','Biomedical Engineer','9100200088','srihari.venkatesan@cityhosp.com','2014-05-01',55000,'Full-Time'),
(4,NULL,'Subrata','Sen','M','1983-05-31','Biomedical Engineer','9100200089','subrata.sen@cityhosp.com','2015-02-01',55000,'Full-Time'),
(5,NULL,'Sandesh','Mhatre','M','1984-02-14','Biomedical Engineer','9100200090','sandesh.mhatre@cityhosp.com','2015-09-01',55000,'Full-Time'),
(1,NULL,'Smriti','Sharma','F','1993-12-01','Intern Administrator','9100200091','smriti.sharma@cityhosp.com','2022-01-01',18000,'Contract'),
(2,NULL,'Niraj','Jha','M','1994-03-15','Intern Administrator','9100200092','niraj.jha@cityhosp.com','2022-04-01',18000,'Contract'),
(3,NULL,'Sindhu','Krishnamurthy','F','1993-07-27','Intern Administrator','9100200093','sindhu.krishnamurthy@cityhosp.com','2022-07-01',18000,'Contract'),
(4,NULL,'Avik','Ghosh','M','1994-09-19','Intern Administrator','9100200094','avik.ghosh@cityhosp.com','2022-10-01',18000,'Contract'),
(5,NULL,'Aakanksha','Joshi','F','1994-11-05','Intern Administrator','9100200095','aakanksha.joshi@cityhosp.com','2023-01-01',18000,'Contract'),
(1,NULL,'Nagaraj','Murthy','M','1977-06-18','Chief Pharmacist','9100200096','nagaraj.murthy@cityhosp.com','2010-06-01',70000,'Full-Time'),
(2,NULL,'Vanmala','Gujar','F','1978-09-24','Chief Pharmacist','9100200097','vanmala.gujar@cityhosp.com','2011-09-01',68000,'Full-Time'),
(3,NULL,'Kanagaraj','Subramanian','M','1979-04-12','Chief Pharmacist','9100200098','kanagaraj.subramanian@cityhosp.com','2012-04-01',67000,'Full-Time'),
(4,NULL,'Sharmistha','Basu','F','1980-01-29','Chief Pharmacist','9100200099','sharmistha.basu@cityhosp.com','2013-01-01',66000,'Full-Time'),
(5,NULL,'Sudha','Joshi','F','1981-08-06','Chief Pharmacist','9100200100','sudha.joshi@cityhosp.com','2014-08-01',65000,'Full-Time');

-- =============================================================================
-- NURSES (50 nurses spread across branches)
-- =============================================================================
INSERT INTO nurses
    (branch_id, dept_id, first_name, last_name, gender, date_of_birth,
     phone, email, registration_number, shift, joining_date, salary)
SELECT
    (((i-1) % 5) + 1)                                           AS branch_id,
    (((i-1) % 20) + 1)                                          AS dept_id,
    (ARRAY['Asha','Beena','Chitra','Deepa','Esha','Falak','Gita','Hema',
            'Indira','Jaya','Kamla','Latha','Meena','Neha','Priya',
            'Rita','Sita','Tara','Uma','Vani','Wini','Yamini','Zara',
            'Aarti','Bhumi'])[(i % 25) + 1]                     AS first_name,
    (ARRAY['Nair','Pillai','Krishnan','Menon','Thomas','Philip','Jose',
            'Peter','Paul','John','David','George','Simon','Mary','Sherin',
            'Leena','Sindhu','Parvathy','Anjana','Sreeja'])[(i % 20) + 1] AS last_name,
    CASE WHEN i % 5 = 0 THEN 'M' ELSE 'F' END                   AS gender,
    (DATE '1985-01-01' + (INTERVAL '1 day' * (i * 37 % 3650)))::DATE AS date_of_birth,
    '9300' || LPAD((300000 + i)::TEXT, 6, '0')                  AS phone,
    'nurse' || i || '@cityhosp.com'                              AS email,
    'NMC-' || LPAD(i::TEXT, 5, '0')                             AS registration_number,
    (ARRAY['Morning','Evening','Night','Rotating'])[(i % 4) + 1] AS shift,
    (DATE '2015-01-01' + (INTERVAL '1 day' * (i * 47 % 2920)))::DATE AS joining_date,
    28000 + (i % 10) * 1000                                     AS salary
FROM GENERATE_SERIES(1, 50) AS i;

SELECT 'insert_staff.sql completed. Staff: '
    || (SELECT COUNT(*) FROM staff)::TEXT
    || ', Nurses: '
    || (SELECT COUNT(*) FROM nurses)::TEXT AS status;
