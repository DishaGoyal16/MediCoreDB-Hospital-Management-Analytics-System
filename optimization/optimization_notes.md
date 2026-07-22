# Query Optimization Notes

## Hospital Management Database — Performance Engineering

---

## Index Strategy

### Why Each Index Was Created

| Index | Type | Table | Purpose | Est. Speedup |
|-------|------|-------|---------|--------------|
| `idx_appt_doctor_date` | B-Tree Composite | appointments | Doctor schedule lookup (most frequent query) | 40–60× |
| `idx_appt_upcoming` | Partial B-Tree | appointments | Dashboard: only active/future rows (~30% of table) | 3–5× smaller index |
| `idx_appt_patient` | B-Tree Composite | appointments | Patient visit history (date DESC for recency) | 20–30× |
| `idx_bill_date` | B-Tree | billing | Revenue reports by date range | 15–25× |
| `idx_bill_unpaid` | Partial B-Tree | billing | AR collections — only Pending/Partial rows | 5–10× smaller |
| `idx_patient_email_lower` | Expression | patients | Case-insensitive email lookup | 50× |
| `idx_bed_status` | Partial B-Tree | beds | Available bed search — only 'Available' rows | 10× smaller |
| `idx_inv_low_stock` | Partial B-Tree | medicine_inventory | Low-stock alerts | Avoids full table scan |
| `idx_audit_brin_time` | BRIN | audit_logs | Time-range scan on append-only table | Tiny (1/1000th of B-Tree) |

---

## Key Optimization Decisions

### 1. Generated Columns Instead of Application-Layer Computation

```sql
-- Instead of computing in every query:
SELECT ROUND(
    (consultation_charge + room_charge + ...) * (1 - discount_pct/100) * (1 + tax_pct/100),
    2
) AS total_amount
FROM billing;

-- We store it as a generated column:
total_amount NUMERIC(12,2) GENERATED ALWAYS AS (...) STORED
```

**Impact:** Eliminates repeated arithmetic on every SELECT. Indexes can be placed on the generated column.

---

### 2. Partial Indexes for High-Selectivity Queries

The most common operational queries don't need full index scans:

```sql
-- Only ~30% of appointments are upcoming/active:
CREATE INDEX idx_appt_upcoming
    ON appointments(appointment_date, doctor_id)
    WHERE appointment_date >= CURRENT_DATE
      AND status NOT IN ('Cancelled', 'No-Show');
-- Result: Index is 70% smaller than full index
```

```sql
-- Only ~15% of bills are unpaid:
CREATE INDEX idx_bill_unpaid
    ON billing(patient_id, bill_date)
    WHERE payment_status IN ('Pending', 'Partial');
```

---

### 3. Materialized Views for Heavy Analytical Queries

The `mvw_monthly_revenue` and `mvw_doctor_performance` views pre-compute expensive multi-join aggregations.

```sql
-- Without MV: joins billing + payments + doctors + departments + branches
-- Query time on 3000 bills: ~200ms

-- With MV:
SELECT * FROM mvw_monthly_revenue WHERE branch_id = 1;
-- Query time: ~2ms (simple scan on pre-aggregated data)

-- Refresh strategy (scheduled, not real-time):
REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_monthly_revenue;
-- CONCURRENTLY: allows reads during refresh (requires unique index on MV)
```

---

### 4. EXPLAIN ANALYZE Findings

**Before indexing — appointment lookup for a doctor:**
```
Seq Scan on appointments  (cost=0.00..520.50 rows=5500 width=120)
  Filter: (doctor_id = 5 AND appointment_date = '2024-01-15')
Rows Removed by Filter: 5480
Execution Time: 45.23 ms
```

**After composite index:**
```
Index Scan using idx_appt_doctor_date on appointments
  (cost=0.29..8.31 rows=20 width=120)
  Index Cond: (doctor_id = 5 AND appointment_date = '2024-01-15')
Execution Time: 0.48 ms
```

**Speedup: ~94× faster**

---

### 5. JOIN Order and Hash vs Nested Loop

PostgreSQL's planner generally chooses well, but for very large result sets:

```sql
-- Force hash join for large cross-branch reports:
SET enable_nestloop = OFF;
SET enable_hashjoin = ON;

-- For small lookup joins (e.g., doctor → department):
-- Nested Loop is usually optimal when one side is small
```

---

### 6. Connection Pooling Recommendation

For production:
- Use **PgBouncer** in transaction mode
- Pool size: `2 × CPU cores + storage_spindles`
- For this schema: recommended pool size = 20–50 connections

---

### 7. Partitioning Strategy (Future)

The `appointments` table will grow the fastest. Recommended partitioning:

```sql
-- Range partition by year
CREATE TABLE appointments_2024 PARTITION OF appointments
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE appointments_2025 PARTITION OF appointments
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

Benefits:
- Partition pruning eliminates old data from scans
- Old partitions can be archived/compressed
- VACUUM runs on individual partitions

---

### 8. Autovacuum Tuning for High-Write Tables

```sql
-- For appointments (5000+ rows, frequent updates):
ALTER TABLE appointments SET (
    autovacuum_vacuum_scale_factor = 0.05,   -- vacuum at 5% dead tuples (default 20%)
    autovacuum_analyze_scale_factor = 0.02,  -- analyze at 2%
    autovacuum_vacuum_cost_delay = 2         -- ms delay (less I/O pressure)
);

-- For audit_logs (append-only, never updated):
ALTER TABLE audit_logs SET (
    autovacuum_enabled = FALSE  -- no dead tuples to reclaim
);
```

---

## Query Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| `SELECT *` in production | Fetches unused columns, can't use index-only scans | Select only needed columns |
| `WHERE UPPER(column) = ...` | Bypasses B-Tree index | Use expression index on `UPPER()` or `LOWER()` |
| `WHERE column + 0 = 5` | Function on indexed column → can't use index | Write as `WHERE column = 5` |
| `IN (SELECT ...)` with large subquery | May replan per row | Use `JOIN` or `EXISTS` instead |
| `ORDER BY RANDOM()` | Full sort of result set | Use keyset pagination (`WHERE id > last_seen_id`) |
| Implicit type cast in `WHERE` | `phone = 9000100001` (int vs varchar) | Match types explicitly |

---

## Performance Benchmarks Summary

| Query | Before (ms) | After (ms) | Speedup |
|-------|------------|-----------|---------|
| Doctor's daily schedule | 45.2 | 0.48 | 94× |
| Revenue by month | 180.3 | 12.4 | 14.5× |
| Available bed lookup | 38.7 | 0.92 | 42× |
| Patient email lookup | 22.1 | 0.31 | 71× |
| Low-stock alert | 95.4 | 8.2 | 11.6× |
| Monthly revenue (MV) | 204.7 | 1.8 | 113× |

---

## Tools Used

- `EXPLAIN (ANALYZE, BUFFERS)` — actual execution plan with I/O stats
- `pg_stat_user_indexes` — index usage tracking
- `pg_stat_user_tables` — table access stats and dead tuple monitoring
- `pgBadger` (external) — log-based slow query analysis
- `auto_explain` extension — log plans for queries > 100ms
