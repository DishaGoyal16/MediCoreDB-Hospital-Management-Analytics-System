# SQL Concepts Used — Index

## Hospital Management Database System

| Concept | File | Example |
|---------|------|---------|
| **DDL — CREATE TABLE** | schema/create_tables.sql | All 30 tables |
| **Generated Columns** | schema/create_tables.sql | `full_name`, `age`, `total_amount` |
| **CHECK Constraints** | schema/create_tables.sql | `gender IN ('M','F','O')`, `consultation_fee >= 0` |
| **NOT NULL** | schema/create_tables.sql | All primary fields |
| **DEFAULT values** | schema/create_tables.sql | `is_active = TRUE`, `status = 'Scheduled'` |
| **UNIQUE Constraints** | schema/constraints.sql | `(branch_id, dept_code)`, `policy_number` |
| **Foreign Keys** | schema/constraints.sql | All inter-table references |
| **ON DELETE CASCADE** | schema/constraints.sql | `beds → rooms`, `doctor_specializations → doctors` |
| **ON DELETE SET NULL** | schema/constraints.sql | `departments.head_doctor_id` |
| **B-Tree Index** | schema/indexes.sql | `idx_appt_doctor_date`, `idx_bill_date` |
| **Composite Index** | schema/indexes.sql | `idx_appt_doctor_date(doctor_id, appointment_date)` |
| **Partial Index** | schema/indexes.sql | `idx_appt_upcoming WHERE status NOT IN (...)` |
| **Expression Index** | schema/indexes.sql | `idx_patient_email_lower ON LOWER(email)` |
| **BRIN Index** | optimization/indexing_demo.sql | `idx_audit_brin_time` on append-only table |
| **INNER JOIN** | queries/beginner_queries.sql | Q3, Q4, Q8 |
| **LEFT JOIN** | queries/beginner_queries.sql | Q8, Q19 |
| **RIGHT JOIN** | queries/intermediate_queries.sql | I1 |
| **FULL OUTER JOIN** | queries/advanced_queries.sql | A7 |
| **SELF JOIN** | queries/advanced_queries.sql | A8; queries/interview_queries.sql Q11 |
| **CROSS JOIN** | queries/advanced_queries.sql | A12 |
| **LATERAL JOIN** | queries/advanced_queries.sql | A22, A43 |
| **Subquery (nested)** | queries/interview_queries.sql | Q1, Q18 |
| **Correlated Subquery** | queries/advanced_queries.sql | A6 |
| **EXISTS / NOT EXISTS** | queries/advanced_queries.sql | A14, A15 |
| **IN / NOT IN** | queries/interview_queries.sql | Q8, Q28 |
| **CTE (WITH clause)** | queries/advanced_queries.sql | A3, A5, A10, A17 |
| **Recursive CTE** | queries/advanced_queries.sql | A5, A25; queries/interview_queries.sql Q33 |
| **INTERSECT** | queries/interview_queries.sql | Q23 |
| **EXCEPT** | queries/interview_queries.sql | Q24 |
| **UNION ALL** | schema/functions.sql | fn_dept_performance |
| **Window RANK()** | queries/advanced_queries.sql | A2 |
| **Window DENSE_RANK()** | queries/advanced_queries.sql | A2 |
| **Window ROW_NUMBER()** | queries/advanced_queries.sql | A11 |
| **Window LEAD()** | queries/advanced_queries.sql | A4 |
| **Window LAG()** | queries/advanced_queries.sql | A4, A13 |
| **Window NTILE()** | queries/advanced_queries.sql | A9 |
| **Window ROWS BETWEEN** | queries/advanced_queries.sql | A13, A25 |
| **SUM() OVER** | queries/advanced_queries.sql | A1 |
| **AVG() OVER (rolling)** | queries/analytical_queries.sql | AN20 |
| **PERCENTILE_CONT** | queries/advanced_queries.sql | A23 |
| **GROUP BY ROLLUP** | queries/advanced_queries.sql | A20 |
| **GROUP BY CUBE** | (noted in analytical_queries) | Revenue multi-dim |
| **HAVING** | queries/intermediate_queries.sql | I4, I9 |
| **CASE WHEN** | queries/beginner_queries.sql | Q11, multiple |
| **COALESCE** | queries/advanced_queries.sql | A7, A10 |
| **NULLIF** | queries/intermediate_queries.sql | multiple |
| **STRING_AGG** | queries/intermediate_queries.sql | I20 |
| **ARRAY_AGG** | queries/intermediate_queries.sql | I20 |
| **TO_CHAR / DATE functions** | queries/advanced_queries.sql | A19 |
| **EXTRACT** | queries/beginner_queries.sql | Q10 |
| **AGE()** | queries/advanced_queries.sql | A19 |
| **GENERATE_SERIES** | data/generate_large_dataset.sql | Bulk data |
| **Stored Procedures** | schema/procedures.sql | sp_book_appointment, sp_discharge_patient |
| **OUT parameters** | schema/procedures.sql | p_appointment_id, p_discharge_id |
| **Functions (scalar)** | schema/functions.sql | fn_doctor_utilization, fn_bed_occupancy_rate |
| **Functions (table-valued)** | schema/functions.sql | fn_revenue_by_month, fn_dept_performance |
| **PL/pgSQL** | schema/triggers.sql | All trigger functions |
| **EXCEPTION handling** | schema/procedures.sql | RAISE EXCEPTION in all procedures |
| **SAVEPOINT** | (noted — usable within procedures) | |
| **RAISE NOTICE** | schema/procedures.sql | Informational output |
| **BEFORE triggers** | schema/triggers.sql | trg_prevent_double_booking |
| **AFTER triggers** | schema/triggers.sql | trg_mark_bed_occupied, trg_generate_bill |
| **Trigger WHEN clause** | schema/triggers.sql | `WHEN (NEW.status = 'Active')` |
| **Views** | schema/views.sql | 10 regular views |
| **Materialized Views** | schema/views.sql | mvw_monthly_revenue, mvw_doctor_performance |
| **REFRESH MATERIALIZED VIEW CONCURRENTLY** | data/generate_large_dataset.sql | Post-load refresh |
| **RBAC — Roles** | schema/roles_permissions.sql | hospital_admin, hospital_doctor, etc. |
| **GRANT / REVOKE** | schema/roles_permissions.sql | Table and function-level grants |
| **JSONB** | schema/create_tables.sql | audit_logs old_data/new_data |
| **JSONB operators** | queries/advanced_queries.sql | A24 `->>` operator |
| **EXPLAIN ANALYZE** | optimization/explain_analyze.sql | All benchmarks |
| **EXPLAIN BUFFERS** | optimization/explain_analyze.sql | Cache hit analysis |
| **pg_stat_user_indexes** | optimization/indexing_demo.sql | Index usage tracking |
| **OVERLAY / SUBSTRING** | queries/advanced_queries.sql | A18 Aadhaar masking |
| **REPEAT / CHR** | queries/analytical_queries.sql | AN3 density bar |
| **DO $$ block** | data/insert_rooms.sql | Procedural DDL |
| **ON CONFLICT DO NOTHING** | data/generate_large_dataset.sql | Idempotent inserts |
| **ON CONFLICT DO UPDATE** | schema/procedures.sql | sp_refill_inventory upsert |
| **Composite PK** | schema/create_tables.sql | doctor_specializations |
| **UUID extension** | schema/create_tables.sql | uuid-ossp |
| **pgcrypto** | schema/create_tables.sql | Available for encryption |
