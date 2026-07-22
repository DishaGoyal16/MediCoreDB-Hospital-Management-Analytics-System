-- =============================================================================
-- FILE: data/insert_rooms.sql
-- DESCRIPTION: Seed data — 500 rooms + beds across all branches/departments.
-- =============================================================================

-- =============================================================================
-- ROOMS — 100 per branch, mix of types
-- =============================================================================
DO $$
DECLARE
    v_branch_id  INT;
    v_dept_id    INT;
    v_room_num   INT := 1;
    v_floor      INT;
    v_type       VARCHAR(30);
    v_beds       INT;
    v_charge     NUMERIC;
    room_counter INT := 0;
    dept_row     RECORD;
    type_arr     TEXT[] := ARRAY['General','Semi-Private','Private','ICU','Emergency'];
    type_beds    INT[]  := ARRAY[6, 4, 2, 4, 8];
    type_charge  NUMERIC[] := ARRAY[800, 2000, 4000, 8000, 0];
BEGIN
    FOR v_branch_id IN 1..5 LOOP
        v_room_num := 1;
        FOR dept_row IN
            SELECT dept_id, floor_no
            FROM departments
            WHERE branch_id = v_branch_id
            ORDER BY dept_id
        LOOP
            -- 4 rooms per department, varying types
            FOR j IN 1..4 LOOP
                room_counter := room_counter + 1;
                v_type   := type_arr[((room_counter - 1) % 5) + 1];
                v_beds   := type_beds[((room_counter - 1) % 5) + 1];
                v_charge := type_charge[((room_counter - 1) % 5) + 1];
                v_floor  := dept_row.floor_no;

                INSERT INTO rooms (branch_id, dept_id, room_number, room_type,
                                   floor_no, total_beds, daily_charge)
                VALUES (v_branch_id, dept_row.dept_id,
                        'R' || LPAD(v_room_num::TEXT, 3, '0'),
                        v_type, v_floor, v_beds, v_charge);
                v_room_num := v_room_num + 1;
            END LOOP;
        END LOOP;

        -- Add ICU and OT rooms per branch
        INSERT INTO rooms (branch_id, dept_id, room_number, room_type, floor_no, total_beds, daily_charge)
        SELECT v_branch_id,
               dept_id,
               'ICU' || LPAD(v_room_num::TEXT, 2, '0'),
               'ICU', 1, 8, 12000
        FROM departments WHERE branch_id = v_branch_id ORDER BY dept_id LIMIT 1;
        v_room_num := v_room_num + 1;

        INSERT INTO rooms (branch_id, dept_id, room_number, room_type, floor_no, total_beds, daily_charge)
        SELECT v_branch_id,
               dept_id,
               'OT' || LPAD(v_room_num::TEXT, 2, '0'),
               'OT', 1, 2, 0
        FROM departments WHERE branch_id = v_branch_id ORDER BY dept_id LIMIT 1;
        v_room_num := v_room_num + 1;

        INSERT INTO rooms (branch_id, dept_id, room_number, room_type, floor_no, total_beds, daily_charge)
        SELECT v_branch_id,
               dept_id,
               'NICU' || v_room_num::TEXT,
               'NICU', 2, 6, 15000
        FROM departments WHERE branch_id = v_branch_id ORDER BY dept_id LIMIT 1;
        v_room_num := v_room_num + 1;

        INSERT INTO rooms (branch_id, dept_id, room_number, room_type, floor_no, total_beds, daily_charge)
        SELECT v_branch_id,
               dept_id,
               'ISO' || v_room_num::TEXT,
               'Isolation', 3, 4, 6000
        FROM departments WHERE branch_id = v_branch_id ORDER BY dept_id LIMIT 1;

    END LOOP;
END;
$$;

-- =============================================================================
-- BEDS — auto-generate based on rooms
-- =============================================================================
INSERT INTO beds (room_id, bed_number, bed_type, status)
SELECT
    r.room_id,
    'B' || LPAD(gs.n::TEXT, 2, '0')                                AS bed_number,
    CASE r.room_type
        WHEN 'ICU'       THEN 'ICU'
        WHEN 'NICU'      THEN 'ICU'
        WHEN 'OT'        THEN 'Standard'
        WHEN 'General'   THEN (ARRAY['Standard','Standard','Standard','Bariatric'])[gs.n % 4 + 1]
        ELSE 'Standard'
    END                                                              AS bed_type,
    'Available'                                                      AS status
FROM rooms r
CROSS JOIN GENERATE_SERIES(1, r.total_beds) AS gs(n);

-- Mark some beds as under maintenance (realistic)
UPDATE beds
SET status = 'Maintenance'
WHERE bed_id % 50 = 0;

SELECT 'insert_rooms.sql completed. Rooms: '
    || (SELECT COUNT(*) FROM rooms)::TEXT
    || ', Beds: '
    || (SELECT COUNT(*) FROM beds)::TEXT
    || ', Available: '
    || (SELECT COUNT(*) FROM beds WHERE status = 'Available')::TEXT AS status;
