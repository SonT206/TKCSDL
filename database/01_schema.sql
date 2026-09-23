-- ============================================================================
-- SMARTDRONEDELIVERY - LUOC DO CO SO DU LIEU POSTGRESQL
-- Tac gia dong gop: Nguyen Quoc Dung
-- Mo ta: Tao 23 bang, rang buoc, chi muc va trigger nghiep vu chinh.
-- Yeu cau: PostgreSQL 14 tro len. Chay tren mot co so du lieu rong.
-- ============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS smart_drone_delivery;
SET search_path TO smart_drone_delivery, public;

-- --------------------------------------------------------------------------
-- 1. NGUOI DUNG VA PHAN QUYEN
-- --------------------------------------------------------------------------

CREATE TABLE system_user (
    user_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email         VARCHAR(255) UNIQUE,
    phone_number  VARCHAR(20) UNIQUE,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role (
    role_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name   VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE permission (
    permission_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description     VARCHAR(255)
);

CREATE TABLE user_role (
    user_id     BIGINT NOT NULL,
    role_id     BIGINT NOT NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id)
        REFERENCES system_user(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id)
        REFERENCES role(role_id) ON DELETE CASCADE
);

CREATE TABLE role_permission (
    role_id       BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role FOREIGN KEY (role_id)
        REFERENCES role(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id)
        REFERENCES permission(permission_id) ON DELETE CASCADE
);

-- --------------------------------------------------------------------------
-- 2. KHACH HANG VA DIA CHI
-- --------------------------------------------------------------------------

CREATE TABLE customer (
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       BIGINT UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    phone_number  VARCHAR(20) UNIQUE,
    email         VARCHAR(255) UNIQUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_user FOREIGN KEY (user_id)
        REFERENCES system_user(user_id) ON DELETE RESTRICT
);

CREATE TABLE customer_address (
    address_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   BIGINT NOT NULL,
    address_label VARCHAR(50),
    address_line  VARCHAR(255) NOT NULL,
    ward          VARCHAR(100),
    district      VARCHAR(100),
    city          VARCHAR(100),
    latitude      NUMERIC(9,6),
    longitude     NUMERIC(9,6),
    is_default    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_address_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_address_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT fk_address_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id) ON DELETE RESTRICT,
    CONSTRAINT uq_customer_address UNIQUE (address_id, customer_id)
);

-- --------------------------------------------------------------------------
-- 3. TRAM HA CANH VA NHAN VIEN VAN HANH
-- --------------------------------------------------------------------------

CREATE TABLE landing_station (
    station_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    station_code VARCHAR(50) NOT NULL UNIQUE,
    station_name VARCHAR(100) NOT NULL,
    address      VARCHAR(255),
    latitude     NUMERIC(9,6),
    longitude    NUMERIC(9,6),
    capacity     INTEGER NOT NULL DEFAULT 0,
    status       VARCHAR(30) NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_station_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_station_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_station_capacity CHECK (capacity >= 0),
    CONSTRAINT chk_station_status CHECK (
        status IN ('AVAILABLE', 'FULL', 'MAINTENANCE', 'OFFLINE')
    )
);

CREATE TABLE station_status_history (
    history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    station_id BIGINT NOT NULL,
    status     VARCHAR(30) NOT NULL,
    changed_by BIGINT,
    reason     VARCHAR(255),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_station_history_status CHECK (
        status IN ('AVAILABLE', 'FULL', 'MAINTENANCE', 'OFFLINE')
    ),
    CONSTRAINT fk_station_history_station FOREIGN KEY (station_id)
        REFERENCES landing_station(station_id) ON DELETE RESTRICT,
    CONSTRAINT fk_station_history_user FOREIGN KEY (changed_by)
        REFERENCES system_user(user_id) ON DELETE SET NULL
);

CREATE TABLE station_operator_assignment (
    assignment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    station_id    BIGINT NOT NULL,
    user_id       BIGINT NOT NULL,
    assigned_from TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_to   TIMESTAMPTZ,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_assignment_station FOREIGN KEY (station_id)
        REFERENCES landing_station(station_id) ON DELETE RESTRICT,
    CONSTRAINT fk_assignment_user FOREIGN KEY (user_id)
        REFERENCES system_user(user_id) ON DELETE RESTRICT,
    CONSTRAINT chk_assignment_interval CHECK (
        assigned_to IS NULL OR assigned_from < assigned_to
    )
);

-- --------------------------------------------------------------------------
-- 4. MAY BAY KHONG NGUOI LAI
-- --------------------------------------------------------------------------

CREATE TABLE drone (
    drone_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    serial_number  VARCHAR(100) NOT NULL UNIQUE,
    model          VARCHAR(100),
    status         VARCHAR(30) NOT NULL,
    max_payload_kg NUMERIC(10,2) NOT NULL,
    battery_level  NUMERIC(5,2),
    station_id     BIGINT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_drone_status CHECK (
        status IN ('AVAILABLE', 'BUSY', 'MAINTENANCE', 'OFFLINE')
    ),
    CONSTRAINT chk_drone_payload CHECK (max_payload_kg > 0),
    CONSTRAINT chk_drone_battery CHECK (battery_level BETWEEN 0 AND 100),
    CONSTRAINT fk_drone_station FOREIGN KEY (station_id)
        REFERENCES landing_station(station_id) ON DELETE SET NULL
);

-- --------------------------------------------------------------------------
-- 5. DON GIAO HANG VA KIEN HANG
-- --------------------------------------------------------------------------

CREATE TABLE delivery_order (
    order_id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id             BIGINT NOT NULL,
    delivery_address_id     BIGINT NOT NULL,
    order_status            VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    requested_delivery_time TIMESTAMPTZ,
    estimated_arrival_at    TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at            TIMESTAMPTZ,
    cancelled_at            TIMESTAMPTZ,
    cancellation_reason     VARCHAR(255),
    CONSTRAINT chk_order_status CHECK (
        order_status IN (
            'PENDING', 'APPROVED', 'REJECTED', 'ASSIGNED',
            'IN_TRANSIT', 'DELIVERED', 'FAILED', 'CANCELLED'
        )
    ),
    CONSTRAINT chk_order_completion CHECK (
        completed_at IS NULL OR completed_at >= created_at
    ),
    CONSTRAINT chk_order_cancellation CHECK (
        cancelled_at IS NULL OR cancelled_at >= created_at
    ),
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_order_address FOREIGN KEY (delivery_address_id, customer_id)
        REFERENCES customer_address(address_id, customer_id) ON DELETE RESTRICT
);

CREATE TABLE package (
    package_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id       BIGINT NOT NULL,
    description    VARCHAR(500),
    weight_kg      NUMERIC(10,2) NOT NULL,
    length_cm      NUMERIC(10,2),
    width_cm       NUMERIC(10,2),
    height_cm      NUMERIC(10,2),
    package_status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_package_weight CHECK (weight_kg > 0),
    CONSTRAINT chk_package_length CHECK (length_cm IS NULL OR length_cm > 0),
    CONSTRAINT chk_package_width CHECK (width_cm IS NULL OR width_cm > 0),
    CONSTRAINT chk_package_height CHECK (height_cm IS NULL OR height_cm > 0),
    CONSTRAINT chk_package_status CHECK (
        package_status IN (
            'CREATED', 'AT_STATION', 'PICKED_UP', 'IN_TRANSIT',
            'DELIVERED', 'FAILED', 'RETURNED', 'DAMAGED'
        )
    ),
    CONSTRAINT fk_package_order FOREIGN KEY (order_id)
        REFERENCES delivery_order(order_id) ON DELETE RESTRICT
);

CREATE TABLE order_status_history (
    status_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id          BIGINT NOT NULL,
    status            VARCHAR(30) NOT NULL,
    changed_by        BIGINT,
    reason            VARCHAR(255),
    changed_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_order_history_status CHECK (
        status IN (
            'PENDING', 'APPROVED', 'REJECTED', 'ASSIGNED',
            'IN_TRANSIT', 'DELIVERED', 'FAILED', 'CANCELLED'
        )
    ),
    CONSTRAINT fk_order_history_order FOREIGN KEY (order_id)
        REFERENCES delivery_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_order_history_user FOREIGN KEY (changed_by)
        REFERENCES system_user(user_id) ON DELETE SET NULL
);

-- --------------------------------------------------------------------------
-- 6. HOAT DONG GIAO HANG VA SU KIEN
-- --------------------------------------------------------------------------

CREATE TABLE delivery_activity (
    activity_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id               BIGINT NOT NULL,
    drone_id               BIGINT NOT NULL,
    pickup_station_id      BIGINT,
    destination_station_id BIGINT,
    assigned_by            BIGINT,
    scheduled_at           TIMESTAMPTZ,
    activity_status        VARCHAR(30) NOT NULL DEFAULT 'ASSIGNED',
    started_at             TIMESTAMPTZ,
    ended_at               TIMESTAMPTZ,
    previous_activity_id   BIGINT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_activity_status CHECK (
        activity_status IN (
            'ASSIGNED', 'PREPARING', 'IN_TRANSIT',
            'DELIVERED', 'FAILED', 'CANCELLED'
        )
    ),
    CONSTRAINT chk_activity_time CHECK (
        ended_at IS NULL OR (started_at IS NOT NULL AND started_at <= ended_at)
    ),
    CONSTRAINT chk_activity_reschedule CHECK (
        previous_activity_id IS NULL OR previous_activity_id <> activity_id
    ),
    CONSTRAINT fk_activity_order FOREIGN KEY (order_id)
        REFERENCES delivery_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_activity_drone FOREIGN KEY (drone_id)
        REFERENCES drone(drone_id) ON DELETE RESTRICT,
    CONSTRAINT fk_activity_pickup_station FOREIGN KEY (pickup_station_id)
        REFERENCES landing_station(station_id) ON DELETE SET NULL,
    CONSTRAINT fk_activity_destination_station FOREIGN KEY (destination_station_id)
        REFERENCES landing_station(station_id) ON DELETE SET NULL,
    CONSTRAINT fk_activity_user FOREIGN KEY (assigned_by)
        REFERENCES system_user(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_activity_previous FOREIGN KEY (previous_activity_id)
        REFERENCES delivery_activity(activity_id) ON DELETE SET NULL
);

CREATE TABLE package_station_event (
    event_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    package_id   BIGINT NOT NULL,
    station_id   BIGINT NOT NULL,
    event_type   VARCHAR(30) NOT NULL,
    performed_by BIGINT,
    occurred_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note         VARCHAR(255),
    CONSTRAINT chk_station_event_type CHECK (
        event_type IN ('ARRIVED', 'PICKUP_CONFIRMED', 'LOADED', 'UNLOADED')
    ),
    CONSTRAINT fk_station_event_package FOREIGN KEY (package_id)
        REFERENCES package(package_id) ON DELETE RESTRICT,
    CONSTRAINT fk_station_event_station FOREIGN KEY (station_id)
        REFERENCES landing_station(station_id) ON DELETE RESTRICT,
    CONSTRAINT fk_station_event_user FOREIGN KEY (performed_by)
        REFERENCES system_user(user_id) ON DELETE SET NULL
);

CREATE TABLE tracking_record (
    tracking_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    activity_id   BIGINT NOT NULL,
    latitude      NUMERIC(9,6),
    longitude     NUMERIC(9,6),
    altitude_m    NUMERIC(10,2),
    speed_kmh     NUMERIC(10,2),
    battery_level NUMERIC(5,2),
    recorded_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_tracking_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_tracking_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_tracking_altitude CHECK (altitude_m IS NULL OR altitude_m >= 0),
    CONSTRAINT chk_tracking_speed CHECK (speed_kmh IS NULL OR speed_kmh >= 0),
    CONSTRAINT chk_tracking_battery CHECK (battery_level BETWEEN 0 AND 100),
    CONSTRAINT fk_tracking_activity FOREIGN KEY (activity_id)
        REFERENCES delivery_activity(activity_id) ON DELETE RESTRICT
);

CREATE TABLE delivery_confirmation (
    confirmation_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            BIGINT NOT NULL UNIQUE,
    activity_id         BIGINT NOT NULL UNIQUE,
    confirmed_by        BIGINT,
    receiver_name       VARCHAR(100) NOT NULL,
    receiver_phone      VARCHAR(20),
    confirmation_method VARCHAR(30) NOT NULL,
    evidence_object_key VARCHAR(255),
    confirmed_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note                VARCHAR(500),
    CONSTRAINT chk_confirmation_method CHECK (
        confirmation_method IN ('SIGNATURE', 'OTP', 'PHOTO', 'MANUAL')
    ),
    CONSTRAINT fk_confirmation_order FOREIGN KEY (order_id)
        REFERENCES delivery_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_confirmation_activity FOREIGN KEY (activity_id)
        REFERENCES delivery_activity(activity_id) ON DELETE RESTRICT,
    CONSTRAINT fk_confirmation_user FOREIGN KEY (confirmed_by)
        REFERENCES system_user(user_id) ON DELETE SET NULL
);

CREATE TABLE delivery_exception (
    exception_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    activity_id    BIGINT NOT NULL,
    exception_type VARCHAR(50) NOT NULL,
    description    TEXT,
    detected_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at    TIMESTAMPTZ,
    resolved_by    BIGINT,
    resolution     TEXT,
    CONSTRAINT chk_exception_time CHECK (
        resolved_at IS NULL OR detected_at <= resolved_at
    ),
    CONSTRAINT fk_exception_activity FOREIGN KEY (activity_id)
        REFERENCES delivery_activity(activity_id) ON DELETE RESTRICT,
    CONSTRAINT fk_exception_resolver FOREIGN KEY (resolved_by)
        REFERENCES system_user(user_id) ON DELETE SET NULL
);

-- --------------------------------------------------------------------------
-- 7. KIEM TOAN, TUYEN DUONG VA TRI TUE NHAN TAO
-- --------------------------------------------------------------------------

CREATE TABLE audit_log (
    log_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT,
    entity_name VARCHAR(100) NOT NULL,
    record_id   BIGINT,
    action_type VARCHAR(50) NOT NULL,
    old_value   JSONB,
    new_value   JSONB,
    action_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address  INET,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id)
        REFERENCES system_user(user_id) ON DELETE SET NULL
);

CREATE TABLE delivery_route (
    route_id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    activity_id            BIGINT NOT NULL UNIQUE,
    total_distance_km      NUMERIC(12,3),
    estimated_duration_min NUMERIC(10,2),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_route_distance CHECK (
        total_distance_km IS NULL OR total_distance_km >= 0
    ),
    CONSTRAINT chk_route_duration CHECK (
        estimated_duration_min IS NULL OR estimated_duration_min >= 0
    ),
    CONSTRAINT fk_route_activity FOREIGN KEY (activity_id)
        REFERENCES delivery_activity(activity_id) ON DELETE RESTRICT
);

CREATE TABLE route_point (
    route_point_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    route_id        BIGINT NOT NULL,
    sequence_number INTEGER NOT NULL,
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    altitude_m      NUMERIC(10,2),
    CONSTRAINT chk_route_point_sequence CHECK (sequence_number > 0),
    CONSTRAINT chk_route_point_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_route_point_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_route_point_altitude CHECK (altitude_m IS NULL OR altitude_m >= 0),
    CONSTRAINT fk_route_point_route FOREIGN KEY (route_id)
        REFERENCES delivery_route(route_id) ON DELETE CASCADE,
    CONSTRAINT uq_route_point_sequence UNIQUE (route_id, sequence_number)
);

CREATE TABLE ai_recommendation (
    recommendation_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id               BIGINT NOT NULL,
    activity_id            BIGINT,
    recommendation_type    VARCHAR(50) NOT NULL,
    recommended_drone_id   BIGINT,
    estimated_duration_min NUMERIC(10,2),
    confidence_score       NUMERIC(5,4),
    model_version          VARCHAR(50),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ai_duration CHECK (
        estimated_duration_min IS NULL OR estimated_duration_min >= 0
    ),
    CONSTRAINT chk_ai_confidence CHECK (confidence_score BETWEEN 0 AND 1),
    CONSTRAINT fk_ai_order FOREIGN KEY (order_id)
        REFERENCES delivery_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ai_activity FOREIGN KEY (activity_id)
        REFERENCES delivery_activity(activity_id) ON DELETE SET NULL,
    CONSTRAINT fk_ai_drone FOREIGN KEY (recommended_drone_id)
        REFERENCES drone(drone_id) ON DELETE SET NULL
);

-- --------------------------------------------------------------------------
-- 8. CHI MUC
-- --------------------------------------------------------------------------

CREATE INDEX idx_customer_user ON customer(user_id);
CREATE INDEX idx_address_customer ON customer_address(customer_id);
CREATE INDEX idx_order_customer ON delivery_order(customer_id);
CREATE INDEX idx_order_address ON delivery_order(delivery_address_id);
CREATE INDEX idx_order_status ON delivery_order(order_status);
CREATE INDEX idx_package_order ON package(order_id);
CREATE INDEX idx_order_history_order ON order_status_history(order_id, changed_at DESC);
CREATE INDEX idx_station_history_station ON station_status_history(station_id, changed_at DESC);
CREATE INDEX idx_assignment_station ON station_operator_assignment(station_id);
CREATE INDEX idx_assignment_user ON station_operator_assignment(user_id);
CREATE INDEX idx_drone_station ON drone(station_id);
CREATE INDEX idx_activity_order ON delivery_activity(order_id);
CREATE INDEX idx_activity_drone ON delivery_activity(drone_id);
CREATE INDEX idx_activity_previous ON delivery_activity(previous_activity_id);
CREATE INDEX idx_station_event_package ON package_station_event(package_id, occurred_at);
CREATE INDEX idx_station_event_station ON package_station_event(station_id);
CREATE INDEX idx_tracking_activity_time ON tracking_record(activity_id, recorded_at DESC);
CREATE INDEX idx_exception_activity ON delivery_exception(activity_id);
CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_time ON audit_log(action_time DESC);
CREATE INDEX idx_ai_order ON ai_recommendation(order_id);

-- BR-05: Moi khach hang co toi da mot dia chi mac dinh.
CREATE UNIQUE INDEX uq_customer_default_address
    ON customer_address(customer_id)
    WHERE is_default = TRUE;

-- BR-16: Mot may bay khong co hai hoat dong dang dien ra cung luc.
CREATE UNIQUE INDEX uq_drone_active_activity
    ON delivery_activity(drone_id)
    WHERE activity_status IN ('ASSIGNED', 'PREPARING', 'IN_TRANSIT');

-- Mot nhan vien khong co hai phan cong dang hoat dong tai cung mot tram.
CREATE UNIQUE INDEX uq_active_station_operator
    ON station_operator_assignment(station_id, user_id)
    WHERE is_active = TRUE;

-- --------------------------------------------------------------------------
-- 9. HAM VA TRIGGER NGHIEP VU
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_system_user_updated_at
BEFORE UPDATE ON system_user
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- BR-12, BR-13, BR-14: Kiem tra chuyen trang thai don hang.
CREATE OR REPLACE FUNCTION fn_validate_order_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.order_status = OLD.order_status THEN
        RETURN NEW;
    END IF;

    IF NOT (
        (OLD.order_status = 'PENDING' AND NEW.order_status IN ('APPROVED', 'REJECTED', 'CANCELLED')) OR
        (OLD.order_status = 'APPROVED' AND NEW.order_status IN ('ASSIGNED', 'CANCELLED')) OR
        (OLD.order_status = 'ASSIGNED' AND NEW.order_status IN ('IN_TRANSIT', 'FAILED', 'CANCELLED')) OR
        (OLD.order_status = 'IN_TRANSIT' AND NEW.order_status IN ('DELIVERED', 'FAILED', 'CANCELLED')) OR
        (OLD.order_status = 'FAILED' AND NEW.order_status IN ('ASSIGNED', 'CANCELLED'))
    ) THEN
        RAISE EXCEPTION 'Chuyen trang thai don hang khong hop le: % -> %',
            OLD.order_status, NEW.order_status;
    END IF;

    IF NEW.order_status = 'DELIVERED' AND NEW.completed_at IS NULL THEN
        NEW.completed_at := CURRENT_TIMESTAMP;
    END IF;

    IF NEW.order_status = 'CANCELLED' AND NEW.cancelled_at IS NULL THEN
        NEW.cancelled_at := CURRENT_TIMESTAMP;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_order_status
BEFORE UPDATE OF order_status ON delivery_order
FOR EACH ROW EXECUTE FUNCTION fn_validate_order_status_transition();

-- BR-11: Tu dong ghi lich su trang thai don hang.
CREATE OR REPLACE FUNCTION fn_log_order_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    v_user_id := NULLIF(current_setting('app.current_user_id', TRUE), '')::BIGINT;

    IF TG_OP = 'INSERT' OR NEW.order_status IS DISTINCT FROM OLD.order_status THEN
        INSERT INTO order_status_history(order_id, status, changed_by)
        VALUES (NEW.order_id, NEW.order_status, v_user_id);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_order_status
AFTER INSERT OR UPDATE OF order_status ON delivery_order
FOR EACH ROW EXECUTE FUNCTION fn_log_order_status();

-- BR-26: Tu dong ghi lich su trang thai tram.
CREATE OR REPLACE FUNCTION fn_log_station_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    v_user_id := NULLIF(current_setting('app.current_user_id', TRUE), '')::BIGINT;

    IF TG_OP = 'INSERT' OR NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO station_status_history(station_id, status, changed_by)
        VALUES (NEW.station_id, NEW.status, v_user_id);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_station_status
AFTER INSERT OR UPDATE OF status ON landing_station
FOR EACH ROW EXECUTE FUNCTION fn_log_station_status();

-- BR-17, BR-18: May bay phai san sang va du tai trong khi duoc phan cong.
CREATE OR REPLACE FUNCTION fn_validate_delivery_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_drone_status VARCHAR(30);
    v_max_payload  NUMERIC(10,2);
    v_total_weight NUMERIC(12,2);
BEGIN
    IF NEW.activity_status IN ('ASSIGNED', 'PREPARING', 'IN_TRANSIT') THEN
        SELECT status, max_payload_kg
        INTO v_drone_status, v_max_payload
        FROM drone
        WHERE drone_id = NEW.drone_id;

        SELECT COALESCE(SUM(weight_kg), 0)
        INTO v_total_weight
        FROM package
        WHERE order_id = NEW.order_id;

        IF TG_OP = 'INSERT' AND v_drone_status <> 'AVAILABLE' THEN
            RAISE EXCEPTION 'May bay % khong o trang thai AVAILABLE', NEW.drone_id;
        END IF;

        IF v_total_weight = 0 THEN
            RAISE EXCEPTION 'Don hang % chua co kien hang', NEW.order_id;
        END IF;

        IF v_total_weight > v_max_payload THEN
            RAISE EXCEPTION 'Tong khoi luong % kg vuot tai trong % kg cua may bay',
                v_total_weight, v_max_payload;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_delivery_activity
BEFORE INSERT OR UPDATE OF drone_id, order_id, activity_status ON delivery_activity
FOR EACH ROW EXECUTE FUNCTION fn_validate_delivery_activity();

-- BR-28: Nguoi ghi su kien phai duoc phan cong tai tram.
CREATE OR REPLACE FUNCTION fn_validate_station_operator()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.performed_by IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM station_operator_assignment soa
        WHERE soa.station_id = NEW.station_id
          AND soa.user_id = NEW.performed_by
          AND soa.is_active = TRUE
          AND soa.assigned_from <= NEW.occurred_at
          AND (soa.assigned_to IS NULL OR NEW.occurred_at < soa.assigned_to)
    ) THEN
        RAISE EXCEPTION 'Nguoi dung % khong duoc phan cong tai tram %',
            NEW.performed_by, NEW.station_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_station_operator
BEFORE INSERT OR UPDATE ON package_station_event
FOR EACH ROW EXECUTE FUNCTION fn_validate_station_operator();

-- BR-32: Kien hang chi vao IN_TRANSIT sau khi da xac nhan lay hang.
CREATE OR REPLACE FUNCTION fn_validate_package_in_transit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.package_status = 'IN_TRANSIT'
       AND OLD.package_status IS DISTINCT FROM NEW.package_status
       AND NOT EXISTS (
           SELECT 1
           FROM package_station_event pse
           WHERE pse.package_id = NEW.package_id
             AND pse.event_type = 'PICKUP_CONFIRMED'
       ) THEN
        RAISE EXCEPTION 'Kien hang % chua co su kien PICKUP_CONFIRMED', NEW.package_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_package_in_transit
BEFORE UPDATE OF package_status ON package
FOR EACH ROW EXECUTE FUNCTION fn_validate_package_in_transit();

-- BR-33, BR-34, BR-35: Xac nhan phai thuoc don va hoat dong da giao thanh cong.
CREATE OR REPLACE FUNCTION fn_validate_delivery_confirmation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM delivery_activity da
        JOIN delivery_order dord ON dord.order_id = da.order_id
        WHERE da.activity_id = NEW.activity_id
          AND da.order_id = NEW.order_id
          AND da.activity_status = 'DELIVERED'
          AND dord.order_status = 'DELIVERED'
    ) THEN
        RAISE EXCEPTION 'Xac nhan phai lien ket voi don va hoat dong DELIVERED';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_delivery_confirmation
BEFORE INSERT OR UPDATE ON delivery_confirmation
FOR EACH ROW EXECUTE FUNCTION fn_validate_delivery_confirmation();

-- BR-11, BR-26, BR-39: Cac bang lich su va kiem toan chi duoc ghi noi tiep.
CREATE OR REPLACE FUNCTION fn_prevent_history_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Bang % chi cho phep INSERT; khong duoc UPDATE hoac DELETE', TG_TABLE_NAME;
END;
$$;

CREATE TRIGGER trg_protect_order_history
BEFORE UPDATE OR DELETE ON order_status_history
FOR EACH ROW EXECUTE FUNCTION fn_prevent_history_mutation();

CREATE TRIGGER trg_protect_station_history
BEFORE UPDATE OR DELETE ON station_status_history
FOR EACH ROW EXECUTE FUNCTION fn_prevent_history_mutation();

CREATE TRIGGER trg_protect_audit_log
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION fn_prevent_history_mutation();

COMMIT;

-- Ket qua mong doi: 23 bang trong schema smart_drone_delivery.
