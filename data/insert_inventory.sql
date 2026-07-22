-- =============================================================================
-- FILE: data/insert_inventory.sql
-- DESCRIPTION: Seed medicine inventory across all branches.
--              Temporarily disables the auto-log trigger for bulk load.
-- =============================================================================

-- Disable logging trigger during bulk seed (re-enabled at end)
ALTER TABLE medicine_inventory DISABLE TRIGGER trg_log_inventory_stock_in;

INSERT INTO medicine_inventory
    (medicine_id, branch_id, supplier_id, batch_number,
     quantity, reorder_level, expiry_date, purchase_price, received_on)
SELECT
    m.medicine_id,
    b.branch_id,
    ((m.medicine_id % 10) + 1)                                     AS supplier_id,
    'BATCH-' || m.medicine_id || '-' || b.branch_id || '-2024'     AS batch_number,
    -- Stock quantity: high for common meds, lower for specialty
    CASE m.category
        WHEN 'Antibiotic'            THEN 200 + (m.medicine_id % 300)
        WHEN 'Analgesic'             THEN 300 + (m.medicine_id % 200)
        WHEN 'Vitamin/Supplement'    THEN 500 + (m.medicine_id % 500)
        WHEN 'Cardiovascular'        THEN 150 + (m.medicine_id % 200)
        WHEN 'Antidiabetic'          THEN 200 + (m.medicine_id % 150)
        WHEN 'IV Fluid'              THEN 100 + (m.medicine_id % 100)
        WHEN 'Oncology'              THEN 20  + (m.medicine_id % 30)
        ELSE                              100 + (m.medicine_id % 200)
    END                                                             AS quantity,
    -- Reorder level
    CASE m.category
        WHEN 'Oncology'  THEN 10
        WHEN 'IV Fluid'  THEN 50
        ELSE 50
    END                                                             AS reorder_level,
    -- Expiry: 1–3 years out, some expiring soon
    CASE
        WHEN m.medicine_id % 20 = 0 THEN CURRENT_DATE + INTERVAL '30 days'   -- expiring soon
        WHEN m.medicine_id % 15 = 0 THEN CURRENT_DATE + INTERVAL '90 days'   -- short shelf
        ELSE CURRENT_DATE + INTERVAL '1 year' + (INTERVAL '1 day' * (m.medicine_id % 365))
    END                                                             AS expiry_date,
    -- Purchase price ~ 70% of retail
    ROUND(m.unit_price * 0.70, 2)                                  AS purchase_price,
    -- Received date spread over last year
    (CURRENT_DATE - INTERVAL '1 day' * (m.medicine_id % 180))::DATE AS received_on
FROM medicines m
CROSS JOIN hospital_branches b
WHERE m.is_active = TRUE;

-- Add a second batch for high-turnover medicines
INSERT INTO medicine_inventory
    (medicine_id, branch_id, supplier_id, batch_number,
     quantity, reorder_level, expiry_date, purchase_price, received_on)
SELECT
    m.medicine_id,
    b.branch_id,
    ((m.medicine_id % 10) + 1),
    'BATCH-' || m.medicine_id || '-' || b.branch_id || '-2025',
    150 + (m.medicine_id % 100),
    50,
    CURRENT_DATE + INTERVAL '2 years',
    ROUND(m.unit_price * 0.68, 2),
    CURRENT_DATE - INTERVAL '30 days'
FROM medicines m
CROSS JOIN hospital_branches b
WHERE m.category IN ('Antibiotic','Analgesic','Cardiovascular','IV Fluid')
  AND m.medicine_id % 3 = 0;

-- Re-enable the trigger
ALTER TABLE medicine_inventory ENABLE TRIGGER trg_log_inventory_stock_in;

-- Artificially create some low-stock entries for demo purposes
UPDATE medicine_inventory
SET quantity = 5
WHERE medicine_id % 47 = 0 AND branch_id = 1;

UPDATE medicine_inventory
SET quantity = 0
WHERE medicine_id % 73 = 0 AND branch_id = 2;

SELECT 'insert_inventory.sql completed. Inventory records: '
    || (SELECT COUNT(*) FROM medicine_inventory)::TEXT AS status;
