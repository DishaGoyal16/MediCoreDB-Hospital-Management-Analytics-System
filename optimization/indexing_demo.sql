-- =============================================================================
-- FILE: optimization/indexing_demo.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: Demonstrates impact of different index types on query plans.
-- =============================================================================

-- =============================================================================
-- DEMO 1: B-Tree vs No Index — appointment date range scan
-- =============================================================================

-- Check if index exists
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'appointments'
  AND indexname = 'idx_appt_doctor_date';

-- With index (already created in indexes.sql):
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), AVG(EXTRACT(HOUR FROM appointment_time))
FROM appointments
WHERE doctor_id = 10
  AND appointment_date BETWEEN '2023-01-01' AND '2023-12-31';

-- Temporarily drop and re-create to demonstrate:
-- DROP INDEX IF EXISTS idx_appt_doctor_date;
-- (run EXPLAIN ANALYZE here to see Seq Scan cost)
-- CREATE INDEX idx_appt_doctor_date ON appointments(doctor_id, appointment_date);

-- =============================================================================
-- DEMO 2: Partial Index — show that it's smaller and faster
-- =============================================================================

-- Size comparison between full and partial indexes
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE tablename = 'appointments'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Query that benefits from partial index on upcoming appointments
EXPLAIN (ANALYZE, BUFFERS)
SELECT appointment_id, patient_id, doctor_id, appointment_date, appointment_time, status
FROM appointments
WHERE appointment_date >= CURRENT_DATE
  AND status NOT IN ('Cancelled','No-Show');

-- =============================================================================
-- DEMO 3: Composite Index — column order matters
-- =============================================================================

-- Query using leading column → uses index
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM appointments WHERE doctor_id = 5;

-- Query using non-leading column → may not use composite index efficiently
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM appointments WHERE appointment_date = CURRENT_DATE;
-- This uses idx_appt_branch_date or idx_appt_upcoming instead

-- =============================================================================
-- DEMO 4: Expression Index — case-insensitive search
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM patients WHERE LOWER(email) = 'priya1@email.com';
-- Uses idx_patient_email_lower (expression index)

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM patients WHERE email = 'Priya1@Email.Com';
-- Does NOT use the expression index — wrong case

-- =============================================================================
-- DEMO 5: Index covering SORT eliminates sort step
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT patient_id, appointment_date
FROM appointments
WHERE patient_id = 42
ORDER BY appointment_date DESC;
-- Index idx_appt_patient already has patient_id ASC, appt_date DESC
-- → no additional sort step needed

-- =============================================================================
-- DEMO 6: BRIN index opportunity (sequential access pattern)
-- =============================================================================
-- For audit_logs (ever-growing, time-ordered) a BRIN index is very efficient:
CREATE INDEX IF NOT EXISTS idx_audit_brin_time
    ON audit_logs USING brin(changed_at)
    WITH (pages_per_range = 64);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM audit_logs
WHERE changed_at >= NOW() - INTERVAL '7 days';
-- BRIN scan: tiny index, effective for time-series append-only tables

-- =============================================================================
-- DEMO 7: Index bloat check — identify indexes to REINDEX
-- =============================================================================
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan,
    CASE WHEN idx_scan = 0 THEN '⚠ Unused index — consider dropping'
         ELSE 'Active'
    END AS usage_status
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- =============================================================================
-- DEMO 8: VACUUM and ANALYZE for fresh statistics
-- =============================================================================
-- Run before benchmarking:
ANALYZE appointments;
ANALYZE billing;
ANALYZE patients;
ANALYZE medicine_inventory;

-- Check statistics staleness:
SELECT
    relname AS table_name,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    n_dead_tup AS dead_tuples
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

SELECT 'indexing_demo.sql completed.' AS status;
