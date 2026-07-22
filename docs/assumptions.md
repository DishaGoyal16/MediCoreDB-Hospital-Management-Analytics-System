# Design Assumptions

## Hospital Management Database System

---

### Infrastructure Assumptions
1. **Database engine:** PostgreSQL 15 or higher. PL/pgSQL, generated columns, and `GENERATED ALWAYS AS ... STORED` are available.
2. **Single schema:** All objects reside in the `public` schema for simplicity. Production would use separate schemas per module.
3. **Timezone:** All `TIMESTAMPTZ` columns use the database server timezone (IST assumed). Application should convert to UTC for storage.
4. **Character set:** UTF-8 encoding for full Unicode support (names, addresses).

### Organizational Assumptions
5. The hospital operates **5 branches** across Indian cities. The data model supports N branches with no schema changes.
6. Each branch has **4 rooms per department** for seed data. Real hospitals vary widely; the model supports any count.
7. **20 departments** are modeled. Additional departments can be added without schema changes.
8. A doctor belongs to **one primary department** but may have multiple specializations.
9. **Visiting doctors** have reduced schedules (2 days/week) reflected in `doctor_schedules`.

### Clinical Assumptions
10. **One attending doctor** per admission. In reality, multiple doctors can attend — a junction table `admission_doctors` could be added.
11. **OT rooms** have no beds linked to admissions — they are procedure rooms.
12. **Lab tests** are ordered per admission or per OPD visit. Both cases are supported via nullable `admission_id` in `lab_reports`.
13. Prescription quantities are in **units of the medicine's `unit` field** (tablets, ml, etc.).
14. **Blood group** is optional (not all patients know theirs on registration).

### Financial Assumptions
15. **GST is 18%** (default `tax_pct`). This can vary by service type in reality; the column allows any value.
16. **Currency:** Indian Rupees (INR). No multi-currency support in this version.
17. Insurance coverage is **per-claim** (not per-year aggregate). Annual limits would require an additional tracking table.
18. **Discount** is applied before tax: `(subtotal × discount%) taxed on net amount`.

### Data Assumptions
19. **Seed data** uses generate_series for bulk population. Real data would import from HIS/EMR systems.
20. Patient `aadhar_number` is optional and unique when provided. In production, encryption (pgcrypto) should be applied.
21. Doctor `registration_number` maps to state medical council registration numbers.
22. `full_name` generated columns use a simple space join. Multi-part names (prefixes, suffixes) are not modeled.

### Security Assumptions
23. Application connects using role-specific users (`app_doctor`, `app_billing`, etc.), never as `postgres`.
24. **Row-Level Security (RLS)** is not implemented in this version but is noted as a future enhancement.
25. Passwords and API keys are never stored in the database. Connection strings are managed externally.

### Out of Scope
- Telemedicine / video consultation scheduling
- Multi-language UI support
- Pharmacy POS integration
- DICOM / medical imaging storage
- HL7 FHIR API layer
- Real-time notifications (would require pg_notify + application listener)
