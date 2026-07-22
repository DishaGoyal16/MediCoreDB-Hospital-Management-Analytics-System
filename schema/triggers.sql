-- =============================================================================
-- FILE: schema/triggers.sql
-- PROJECT: Hospital Management Database System
-- DESCRIPTION: All database triggers — automation, validation, audit.
--              Run AFTER functions.sql.
-- =============================================================================

-- =============================================================================
-- TRIGGER 1: updated_at — auto-stamp all tables with updated_at column
-- =============================================================================
CREATE TRIGGER trg_hospital_branches_updated_at
    BEFORE UPDATE ON hospital_branches
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_departments_updated_at
    BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_doctors_updated_at
    BEFORE UPDATE ON doctors
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_staff_updated_at
    BEFORE UPDATE ON staff
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_nurses_updated_at
    BEFORE UPDATE ON nurses
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_appointments_updated_at
    BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_admissions_updated_at
    BEFORE UPDATE ON admissions
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_billing_updated_at
    BEFORE UPDATE ON billing
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_beds_updated_at
    BEFORE UPDATE ON beds
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_medicines_updated_at
    BEFORE UPDATE ON medicines
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_medicine_inventory_updated_at
    BEFORE UPDATE ON medicine_inventory
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- =============================================================================
-- TRIGGER 2: PREVENT APPOINTMENT DOUBLE-BOOKING
--    A doctor cannot have two confirmed/scheduled appointments at the same
--    date + time slot.
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_prevent_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    v_conflict_count INT;
BEGIN
    IF NEW.status NOT IN ('Scheduled', 'Confirmed') THEN
        RETURN NEW;
    END IF;

    SELECT COUNT(*)
    INTO v_conflict_count
    FROM appointments
    WHERE doctor_id        = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND appointment_time = NEW.appointment_time
      AND status IN ('Scheduled', 'Confirmed')
      AND appointment_id  != COALESCE(NEW.appointment_id, -1);

    IF v_conflict_count > 0 THEN
        RAISE EXCEPTION
            'Doctor % already has an appointment on % at %. Please choose a different time slot.',
            NEW.doctor_id, NEW.appointment_date, NEW.appointment_time
            USING ERRCODE = 'unique_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_double_booking
    BEFORE INSERT OR UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION fn_prevent_double_booking();

-- =============================================================================
-- TRIGGER 3: CHECK DOCTOR IS ON LEAVE DURING APPOINTMENT
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_doctor_leave()
RETURNS TRIGGER AS $$
DECLARE
    v_on_leave BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM leaves
        WHERE doctor_id  = NEW.doctor_id
          AND status     = 'Approved'
          AND leave_from <= NEW.appointment_date
          AND leave_to   >= NEW.appointment_date
    ) INTO v_on_leave;

    IF v_on_leave THEN
        RAISE EXCEPTION
            'Doctor % is on approved leave on %. Cannot book appointment.',
            NEW.doctor_id, NEW.appointment_date
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_doctor_leave
    BEFORE INSERT ON appointments
    FOR EACH ROW EXECUTE FUNCTION fn_check_doctor_leave();

-- =============================================================================
-- TRIGGER 4: UPDATE BED STATUS ON ADMISSION
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_mark_bed_occupied()
RETURNS TRIGGER AS $$
BEGIN
    -- Mark bed as Occupied when a new active admission is created
    UPDATE beds
    SET    status = 'Occupied', updated_at = NOW()
    WHERE  bed_id = NEW.bed_id;

    -- Insert bed allocation history record
    INSERT INTO bed_allocations(bed_id, patient_id, admission_id, allocated_on)
    VALUES (NEW.bed_id, NEW.patient_id, NEW.admission_id, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mark_bed_occupied
    AFTER INSERT ON admissions
    FOR EACH ROW
    WHEN (NEW.status = 'Active')
    EXECUTE FUNCTION fn_mark_bed_occupied();

-- =============================================================================
-- TRIGGER 5: FREE BED ON DISCHARGE / STATUS CHANGE
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_release_bed_on_discharge()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('Discharged', 'Transferred', 'Deceased')
       AND OLD.status = 'Active' THEN

        -- Free the bed
        UPDATE beds
        SET    status = 'Available', updated_at = NOW()
        WHERE  bed_id = OLD.bed_id;

        -- Close bed allocation record
        UPDATE bed_allocations
        SET    released_on = NOW()
        WHERE  admission_id = OLD.admission_id
          AND  released_on IS NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_release_bed_on_discharge
    AFTER UPDATE OF status ON admissions
    FOR EACH ROW EXECUTE FUNCTION fn_release_bed_on_discharge();

-- =============================================================================
-- TRIGGER 6: AUTO-GENERATE BILL ON DISCHARGE
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_generate_bill_on_discharge()
RETURNS TRIGGER AS $$
DECLARE
    v_room_charge       NUMERIC := 0;
    v_medicine_charge   NUMERIC := 0;
    v_lab_charge        NUMERIC := 0;
    v_treatment_charge  NUMERIC := 0;
    v_consult_fee       NUMERIC := 0;
    v_days              INT;
    v_daily_rate        NUMERIC;
    v_bill_exists       BOOLEAN;
    v_patient_branch    INT;
BEGIN
    -- Only generate bill when inserting a new discharge record
    -- Check if bill already exists for this admission
    SELECT EXISTS(
        SELECT 1 FROM billing WHERE admission_id = NEW.admission_id
    ) INTO v_bill_exists;

    IF v_bill_exists THEN
        RETURN NEW;
    END IF;

    -- Calculate length of stay in days
    SELECT GREATEST(
               EXTRACT(EPOCH FROM (NEW.discharge_date -
                       a.admission_date))::INT / 86400, 1
           )
    INTO v_days
    FROM admissions a
    WHERE a.admission_id = NEW.admission_id;

    -- Room daily charge × days
    SELECT COALESCE(r.daily_charge, 0) * v_days
    INTO v_room_charge
    FROM admissions a
    JOIN beds  b ON b.bed_id  = a.bed_id
    JOIN rooms r ON r.room_id = b.room_id
    WHERE a.admission_id = NEW.admission_id;

    -- Sum all treatment costs
    SELECT COALESCE(SUM(cost), 0)
    INTO v_treatment_charge
    FROM treatments
    WHERE admission_id = NEW.admission_id;

    -- Sum all lab report costs
    SELECT COALESCE(SUM(lt.cost), 0)
    INTO v_lab_charge
    FROM lab_reports lr
    JOIN lab_tests lt ON lt.test_id = lr.test_id
    WHERE lr.admission_id = NEW.admission_id;

    -- Sum prescription medicine costs
    SELECT COALESCE(SUM(p.quantity * m.unit_price), 0)
    INTO v_medicine_charge
    FROM prescriptions p
    JOIN medicines m ON m.medicine_id = p.medicine_id
    WHERE p.admission_id = NEW.admission_id;

    -- Doctor consultation fee
    SELECT COALESCE(d.consultation_fee, 0)
    INTO v_consult_fee
    FROM admissions a
    JOIN doctors d ON d.doctor_id = a.doctor_id
    WHERE a.admission_id = NEW.admission_id;

    -- Get branch_id
    SELECT branch_id INTO v_patient_branch
    FROM admissions WHERE admission_id = NEW.admission_id;

    -- Insert bill
    INSERT INTO billing (
        patient_id, admission_id, branch_id, bill_date,
        consultation_charge, room_charge, medicine_charge,
        lab_charge, treatment_charge, other_charge,
        payment_status
    )
    SELECT
        NEW.patient_id, NEW.admission_id, v_patient_branch, CURRENT_DATE,
        v_consult_fee, v_room_charge, v_medicine_charge,
        v_lab_charge, v_treatment_charge, 0,
        'Pending';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_bill_on_discharge
    AFTER INSERT ON discharges
    FOR EACH ROW EXECUTE FUNCTION fn_generate_bill_on_discharge();

-- =============================================================================
-- TRIGGER 7: UPDATE MEDICINE STOCK ON PRESCRIPTION
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_deduct_medicine_stock()
RETURNS TRIGGER AS $$
DECLARE
    v_inv_id    INT;
    v_qty_before INT;
    v_qty_after  INT;
BEGIN
    -- Find inventory record with enough stock (FIFO by received_on)
    SELECT inventory_id, quantity
    INTO v_inv_id, v_qty_before
    FROM medicine_inventory
    WHERE medicine_id = NEW.medicine_id
      AND is_active   = TRUE
      AND expiry_date > CURRENT_DATE
      AND quantity    >= NEW.quantity
    ORDER BY received_on ASC
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Insufficient stock for medicine_id %. Required: %, Available: check inventory.',
            NEW.medicine_id, NEW.quantity
            USING ERRCODE = 'check_violation';
    END IF;

    v_qty_after := v_qty_before - NEW.quantity;

    -- Deduct stock
    UPDATE medicine_inventory
    SET quantity = v_qty_after, updated_at = NOW()
    WHERE inventory_id = v_inv_id;

    -- Log the movement
    INSERT INTO inventory_logs(
        inventory_id, medicine_id, action_type,
        quantity_change, quantity_before, quantity_after,
        reference_id, reference_type, notes
    )
    VALUES (
        v_inv_id, NEW.medicine_id, 'Stock-Out',
        -NEW.quantity, v_qty_before, v_qty_after,
        NEW.prescription_id, 'Prescription',
        'Auto-deducted on prescription insert'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_deduct_medicine_stock
    AFTER INSERT ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION fn_deduct_medicine_stock();

-- =============================================================================
-- TRIGGER 8: LOG INVENTORY STOCK-IN
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_log_inventory_stock_in()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO inventory_logs(
            inventory_id, medicine_id, action_type,
            quantity_change, quantity_before, quantity_after, notes
        )
        VALUES (
            NEW.inventory_id, NEW.medicine_id, 'Stock-In',
            NEW.quantity, 0, NEW.quantity,
            'New inventory batch received'
        );
    ELSIF TG_OP = 'UPDATE' AND NEW.quantity != OLD.quantity THEN
        INSERT INTO inventory_logs(
            inventory_id, medicine_id, action_type,
            quantity_change, quantity_before, quantity_after, notes
        )
        VALUES (
            NEW.inventory_id, NEW.medicine_id,
            CASE WHEN NEW.quantity > OLD.quantity THEN 'Stock-In' ELSE 'Adjustment' END,
            NEW.quantity - OLD.quantity, OLD.quantity, NEW.quantity,
            'Inventory quantity adjusted'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_inventory_stock_in
    AFTER INSERT OR UPDATE OF quantity ON medicine_inventory
    FOR EACH ROW EXECUTE FUNCTION fn_log_inventory_stock_in();

-- =============================================================================
-- TRIGGER 9: UPDATE BILLING STATUS AFTER PAYMENT
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_update_bill_payment_status()
RETURNS TRIGGER AS $$
DECLARE
    v_total_paid   NUMERIC;
    v_bill_total   NUMERIC;
BEGIN
    SELECT COALESCE(SUM(amount_paid), 0)
    INTO v_total_paid
    FROM payments
    WHERE bill_id = NEW.bill_id;

    SELECT total_amount
    INTO v_bill_total
    FROM billing
    WHERE bill_id = NEW.bill_id;

    IF v_total_paid >= v_bill_total THEN
        UPDATE billing SET payment_status = 'Paid', updated_at = NOW()
        WHERE bill_id = NEW.bill_id;
    ELSIF v_total_paid > 0 THEN
        UPDATE billing SET payment_status = 'Partial', updated_at = NOW()
        WHERE bill_id = NEW.bill_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_bill_payment_status
    AFTER INSERT ON payments
    FOR EACH ROW EXECUTE FUNCTION fn_update_bill_payment_status();

-- =============================================================================
-- TRIGGER 10: AUDIT LOG for billing changes
-- =============================================================================
CREATE TRIGGER trg_audit_billing
    AFTER INSERT OR UPDATE OR DELETE ON billing
    FOR EACH ROW EXECUTE FUNCTION fn_write_audit_log();

-- =============================================================================
-- TRIGGER 11: AUDIT LOG for patient changes
-- =============================================================================
CREATE TRIGGER trg_audit_patients
    AFTER INSERT OR UPDATE OR DELETE ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_write_audit_log();

-- =============================================================================
-- TRIGGER 12: PREVENT ADMITTING TO AN OCCUPIED / MAINTENANCE BED
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_bed_availability()
RETURNS TRIGGER AS $$
DECLARE
    v_bed_status VARCHAR;
BEGIN
    SELECT status INTO v_bed_status FROM beds WHERE bed_id = NEW.bed_id;

    IF v_bed_status != 'Available' THEN
        RAISE EXCEPTION
            'Bed % is not available (current status: %). Select an available bed.',
            NEW.bed_id, v_bed_status
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_bed_availability
    BEFORE INSERT ON admissions
    FOR EACH ROW EXECUTE FUNCTION fn_check_bed_availability();

-- =============================================================================
SELECT 'triggers.sql completed successfully.' AS status;
