-- =============================================================================
-- FILE: optimization/explain_analyze.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: EXPLAIN ANALYZE benchmarks — before/after index comparisons.
-- =============================================================================

-- =============================================================================
-- BENCHMARK 1: Appointment lookup by doctor + date
-- =============================================================================

-- Step 1: Check current index usage
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT a.*, p.full_name, p.phone
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.doctor_id = 5
  AND a.appointment_date = CURRENT_DATE;
-- Expected: Index Scan using idx_appt_doctor_date

-- Step 2: Force sequential scan for comparison
SET enable_indexscan = OFF;
SET enable_bitmapscan = OFF;
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.*, p.full_name, p.phone
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.doctor_id = 5
  AND a.appointment_date = CURRENT_DATE;
-- Expected: Seq Scan (slower)

-- Reset
SET enable_indexscan = ON;
SET enable_bitmapscan = ON;

-- =============================================================================
-- BENCHMARK 2: Revenue query — with vs without bill_date index
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT branch_id, ROUND(SUM(total_amount), 2)
FROM billing
WHERE bill_date BETWEEN CURRENT_DATE - 90 AND CURRENT_DATE
GROUP BY branch_id;
-- Expected: Index Scan or Bitmap Heap Scan on idx_bill_date

-- =============================================================================
-- BENCHMARK 3: Patient lookup by email (expression index)
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT patient_id, full_name, phone
FROM patients
WHERE LOWER(email) = 'rahul1@email.com';
-- Expected: Index Scan on idx_patient_email_lower

-- =============================================================================
-- BENCHMARK 4: Low stock alert query (partial index)
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.medicine_name, mi.quantity, mi.reorder_level
FROM medicine_inventory mi
JOIN medicines m ON m.medicine_id = mi.medicine_id
WHERE mi.quantity <= mi.reorder_level
  AND mi.is_active = TRUE
  AND mi.expiry_date > CURRENT_DATE;
-- Expected: Bitmap Scan on idx_inv_low_stock

-- =============================================================================
-- BENCHMARK 5: Complex join — doctor dashboard
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT *
FROM vw_doctor_dashboard
WHERE doctor_id BETWEEN 1 AND 20;

-- =============================================================================
-- BENCHMARK 6: Available bed lookup (most critical for operations)
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.bed_id, r.room_number, r.room_type, r.daily_charge
FROM beds b
JOIN rooms r ON r.room_id = b.room_id
WHERE b.status = 'Available'
  AND r.branch_id = 1
ORDER BY r.daily_charge;
-- Expected: Index Scan on idx_bed_status

-- =============================================================================
-- BENCHMARK 7: Upcoming appointments partial index
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.*, d.full_name AS doctor
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.appointment_date >= CURRENT_DATE
  AND a.status NOT IN ('Cancelled','No-Show')
  AND a.branch_id = 1;
-- Expected: Bitmap Scan on idx_appt_upcoming

-- =============================================================================
-- QUERY STATISTICS: Table sizes and index hit rates
-- =============================================================================
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename))       AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)
                 - pg_relation_size(schemaname||'.'||tablename))       AS index_size,
    n_live_tup                                                          AS row_estimate
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index usage statistics
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan    AS times_used,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Cache hit ratio (should be > 99% in production)
SELECT
    SUM(heap_blks_hit) AS heap_hits,
    SUM(heap_blks_read) AS heap_reads,
    ROUND(
        SUM(heap_blks_hit)::NUMERIC /
        NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0) * 100, 2
    ) AS cache_hit_ratio
FROM pg_statio_user_tables;
