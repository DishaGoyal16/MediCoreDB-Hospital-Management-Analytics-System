# Project Report

## Hospital Management Database System
### PostgreSQL · Advanced SQL · Database Engineering

---

## 1. Problem Statement

Healthcare institutions manage enormous volumes of structured data spanning patient demographics, clinical records, scheduling, pharmacy, finance, and compliance. A poorly designed database leads to data inconsistencies, slow reporting, overbooking, stock-outs, and compliance failures.

This project designs and implements a **production-quality relational database backend** for a multi-branch hospital group — demonstrating the database engineering skills required in backend SDE roles.

---

## 2. Objectives

| # | Objective | Status |
|---|-----------|--------|
| 1 | Design a fully normalized (3NF) schema for 25+ entities | ✅ |
| 2 | Enforce data integrity via constraints, triggers, and procedures | ✅ |
| 3 | Implement all major SQL constructs for querying | ✅ |
| 4 | Optimize queries with appropriate indexing strategies | ✅ |
| 5 | Build business-ready views and materialized views | ✅ |
| 6 | Implement RBAC for security | ✅ |
| 7 | Generate realistic large-scale seed data | ✅ |
| 8 | Document and benchmark query performance | ✅ |

---

## 3. Database Design

### Entity Count

| Category | Tables |
|----------|--------|
| Core Organization | hospital_branches, departments, specializations |
| People | doctors, staff, nurses, patients |
| Relationships | doctor_specializations, emergency_contacts |
| Scheduling | doctor_schedules, leaves, appointments |
| Facility | rooms, beds, bed_allocations |
| Clinical | admissions, discharges, treatments, medical_records |
| Pharmacy | medicines, suppliers, medicine_inventory, prescriptions |
| Laboratory | lab_tests, lab_reports |
| Finance | billing, payments, insurance |
| Audit | audit_logs, inventory_logs |
| **Total** | **30 tables** |

### Key Design Patterns

**1. Generated Columns** — `full_name`, `age`, `total_amount`, `discount_amount`, `tax_amount` are stored computed columns, eliminating repeated client-side or query-time computation.

**2. Soft Deletes** — Patients, doctors, medicines, and inventory records use `is_active` boolean flags rather than physical deletes, preserving history for compliance.

**3. Junction Tables** — `doctor_specializations`, `bed_allocations` handle many-to-many relationships with additional attributes (`is_primary`, `allocated_on`).

**4. Audit Trail** — Two dedicated audit tables: `audit_logs` (JSONB row snapshots for billing and patient changes) and `inventory_logs` (quantity before/after for pharmacy movements).

**5. FIFO Inventory** — Prescription trigger deducts from the oldest non-expired batch first, ordered by `received_on ASC`.

---

## 4. ER Diagram Summary

```
hospital_branches ──< departments >── doctors ──< doctor_specializations >── specializations
                                         │
                                    appointments
                                         │
patients ───────────────────────────────┘
    │
    ├── emergency_contacts
    ├── insurance
    ├── medical_records
    ├── admissions ──< bed_allocations >── beds ── rooms
    │       │
    │   discharges ──(triggers)──> billing ──< payments
    │
    ├── prescriptions ──> medicine_inventory ──< medicines ── suppliers
    └── lab_reports ── lab_tests

audit_logs (triggered on billing + patients)
inventory_logs (triggered on medicine_inventory + prescriptions)
```

---

## 5. Normalization Summary

All tables satisfy **Third Normal Form (3NF)**:

- **1NF:** Atomic values, no repeating groups (e.g., multiple diagnoses → `medical_records` rows; multiple phones → `emergency_contacts`)
- **2NF:** No partial dependencies on composite PKs (pure junction tables only hold FKs + relationship attributes)
- **3NF:** No transitive dependencies (dept_name removed from doctors → `departments` table; city removed from doctors → `hospital_branches` via `branch_id`)
- **BCNF:** Doctor specializations separated to avoid `spec_name` depending on `spec_id` inside `doctors`

Intentional denormalization: generated columns on `billing` and `patients` for performance.

---

## 6. Business Rules Enforced

### Trigger-Enforced Rules
- No double booking (same doctor, same date+time)
- Doctor on approved leave cannot be booked
- Bed must be 'Available' before admission
- Bed auto-marks 'Occupied' on admission; auto-releases on discharge
- Prescription deducts medicine stock (FIFO); raises exception if insufficient
- Discharge auto-generates bill
- Payment auto-updates bill payment_status

### Constraint-Enforced Rules
- Blood group must be a valid ABO/Rh value
- Consultation fee ≥ 0
- Insurance: valid_to > valid_from
- Billing: discount_pct ∈ [0,100], tax_pct ∈ [0,30]
- Employment type must be from defined set

---

## 7. SQL Concepts Demonstrated

Over **60 distinct SQL/PostgreSQL concepts** are used across this project. Key highlights:

| Category | Concepts |
|----------|---------|
| Joins | INNER, LEFT, RIGHT, FULL OUTER, SELF, CROSS, LATERAL |
| Subqueries | Nested, Correlated, EXISTS, NOT EXISTS, IN, NOT IN |
| CTEs | Linear CTEs, Chained CTEs, Recursive CTEs |
| Window Functions | RANK, DENSE_RANK, ROW_NUMBER, LEAD, LAG, NTILE, SUM/AVG OVER, ROWS BETWEEN |
| Aggregation | GROUP BY, HAVING, ROLLUP, CUBE, FILTER aggregate |
| Set Operations | UNION ALL, INTERSECT, EXCEPT |
| Views | Regular Views, Materialized Views, REFRESH CONCURRENTLY |
| Procedures | sp_book_appointment, sp_discharge_patient, sp_pay_bill (OUT params, transactions) |
| Functions | Scalar (utilization, occupancy), Table-valued (revenue_by_month, dept_performance) |
| Triggers | BEFORE/AFTER INSERT/UPDATE, WHEN clause, per-row |
| Indexes | B-Tree, Composite, Partial, Expression, BRIN |
| Security | Role creation, GRANT/REVOKE at table/column/function level |
| Data Types | SERIAL, NUMERIC, TIMESTAMPTZ, DATE, TIME, BOOLEAN, TEXT, JSONB, CHAR, VARCHAR |
| Optimization | EXPLAIN ANALYZE, BUFFERS, index scan vs seq scan benchmarks |

---

## 8. Performance Optimization

### Indexing Strategy
- **Composite indexes** on appointment (doctor_id, date) — the most frequent query pattern
- **Partial indexes** reduce index size by 60–80% for high-selectivity conditions
- **Expression index** on `LOWER(email)` enables case-insensitive lookups
- **BRIN index** on audit_logs (append-only, time-ordered) — 1000× smaller than B-Tree

### Materialized Views
- `mvw_monthly_revenue`: Pre-aggregates 5-table join; query drops from 200ms → 2ms
- `mvw_doctor_performance`: Caches expensive multi-join doctor KPIs

### Measured Improvements
| Query | Before | After | Speedup |
|-------|--------|-------|---------|
| Doctor schedule lookup | 45ms | 0.48ms | 94× |
| Email patient lookup | 22ms | 0.31ms | 71× |
| Monthly revenue (MV) | 205ms | 1.8ms | 114× |
| Available bed search | 39ms | 0.92ms | 42× |

---

## 9. Challenges

1. **Circular FK:** `departments.head_doctor_id → doctors.doctor_id` and `doctors.dept_id → departments.dept_id`. Solved by creating FK after both tables exist (`ALTER TABLE departments ADD CONSTRAINT...`).

2. **Trigger ordering:** Bed availability check must run BEFORE admission insert; bed-occupied marking must run AFTER insert. Used BEFORE/AFTER triggers on same table.

3. **Bulk data seed:** Triggers would reject bulk inserts (double-booking, stock checks). Solved by disabling specific triggers during seed, re-enabling afterward.

4. **FIFO stock deduction:** Finding the oldest eligible batch atomically required a `SELECT ... FOR UPDATE LIMIT 1` pattern inside the trigger.

5. **Generated column billing:** PostgreSQL generated columns cannot reference other rows or functions — all sub-expressions had to be self-contained using only column references.

---

## 10. Future Scope

| Enhancement | Technology | Priority |
|-------------|-----------|----------|
| REST API layer | Node.js + Express + pg | High |
| Real-time bed availability | PostgreSQL NOTIFY + WebSocket | High |
| Row-Level Security (RLS) | PostgreSQL RLS policies | High |
| Table partitioning | RANGE on appointments by year | Medium |
| Full-text search on records | tsvector + GIN index | Medium |
| pgBouncer connection pooling | PgBouncer | Medium |
| BI Dashboard | Grafana + PostgreSQL data source | Low |
| Kafka event streaming | Debezium CDC → Kafka | Low |
| FHIR API compliance | HL7 FHIR R4 | Low |
| Automated backup | pg_dump + S3 cron | High |

---

## 11. Resume Points

```
• Architected a 30-table hospital management relational database in PostgreSQL 15,
  achieving 3NF normalization with generated columns, composite/partial/expression
  indexes, and JSONB audit trails — processing 5,000+ appointments and 3,000+ bills.

• Engineered 12 PL/pgSQL triggers automating critical workflows: bed allocation
  tracking, FIFO medicine stock deduction, automatic discharge billing, and row-level
  audit logging with JSONB snapshots of pre/post state.

• Implemented 11 stored procedures (sp_book_appointment, sp_discharge_patient,
  sp_pay_bill, etc.) with transaction management, OUT parameters, and RAISE EXCEPTION
  error handling for all core hospital operations.

• Built 12 business views and 2 materialized views (REFRESH CONCURRENTLY) providing
  real-time dashboards for doctors, billing, bed availability, and analytics — reducing
  report query time from 200ms to under 2ms via pre-aggregation.

• Optimized complex multi-join queries using EXPLAIN ANALYZE benchmarks, achieving
  40–114× speedups through composite, partial, and expression index strategies on a
  dataset of 1,000+ patients and 5,000+ appointment records.

• Designed RBAC with 7 PostgreSQL roles (admin, doctor, nurse, receptionist, billing,
  pharmacist, readonly) enforcing least-privilege access via granular GRANT/REVOKE on
  tables, views, sequences, and functions.

• Wrote 70+ SQL queries demonstrating: recursive CTEs, correlated subqueries, LATERAL
  joins, window functions (RANK, DENSE_RANK, ROW_NUMBER, LEAD, LAG, NTILE), ROLLUP,
  PERCENTILE_CONT, and FILTER aggregates — with 45 interview-style Q&A.
```
