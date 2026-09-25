-- ============================================================================
-- SMARTDRONEDELIVERY - DU LIEU MAU
-- Chay sau 01_schema.sql.
-- Mat khau chi la chuoi minh hoa, khong dung trong moi truong thuc te.
-- ============================================================================

BEGIN;
SET search_path TO smart_drone_delivery, public;

-- 1. Vai tro va quyen
INSERT INTO role(role_name, description) VALUES
    ('SYSTEM_ADMIN', 'Quan tri he thong'),
    ('STATION_OPERATOR', 'Nhan vien van hanh tram'),
    ('CUSTOMER', 'Khach hang');

INSERT INTO permission(permission_name, description) VALUES
    ('MANAGE_USERS', 'Quan ly tai khoan va phan quyen'),
    ('MANAGE_STATIONS', 'Quan ly tram ha canh'),
    ('CREATE_ORDER', 'Tao don giao hang'),
    ('ASSIGN_DRONE', 'Phan cong may bay'),
    ('CONFIRM_PICKUP', 'Xac nhan lay kien hang'),
    ('CONFIRM_DELIVERY', 'Xac nhan giao hang');

INSERT INTO role_permission(role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM role r
CROSS JOIN permission p
WHERE r.role_name = 'SYSTEM_ADMIN';

INSERT INTO role_permission(role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM role r
JOIN permission p ON p.permission_name IN (
    'MANAGE_STATIONS', 'ASSIGN_DRONE', 'CONFIRM_PICKUP', 'CONFIRM_DELIVERY'
)
WHERE r.role_name = 'STATION_OPERATOR';

INSERT INTO role_permission(role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM role r
JOIN permission p ON p.permission_name = 'CREATE_ORDER'
WHERE r.role_name = 'CUSTOMER';

-- 2. Nguoi dung
INSERT INTO app_user(username, password_hash, email, phone_number) VALUES
    ('admin', '$2a$12$demo.admin.hash', 'admin@smartdrone.local', '0901000001'),
    ('operator01', '$2a$12$demo.operator.hash', 'operator01@smartdrone.local', '0901000002'),
    ('customer01', '$2a$12$demo.customer.hash', 'customer01@example.com', '0901000003');

INSERT INTO user_role(user_id, role_id)
SELECT u.user_id, r.role_id
FROM app_user u
JOIN role r ON (
    (u.username = 'admin' AND r.role_name = 'SYSTEM_ADMIN') OR
    (u.username = 'operator01' AND r.role_name = 'STATION_OPERATOR') OR
    (u.username = 'customer01' AND r.role_name = 'CUSTOMER')
);

-- Dat nguoi dung hien tai cho cac trigger ghi lich su.
SELECT set_config(
    'app.current_user_id',
    (SELECT user_id::TEXT FROM app_user WHERE username = 'admin'),
    TRUE
);

-- 3. Khach hang va dia chi
INSERT INTO customer(user_id, customer_name, phone_number, email)
SELECT user_id, 'Nguyen Van An', '0902000001', 'nguyenvanan@example.com'
FROM app_user
WHERE username = 'customer01';

INSERT INTO customer_address(
    customer_id, address_label, address_line, ward, district, city,
    latitude, longitude, is_default
)
SELECT customer_id, 'Nha rieng', '01 Vo Van Ngan', 'Linh Chieu',
       'Thu Duc', 'Thanh pho Ho Chi Minh', 10.850632, 106.771916, TRUE
FROM customer
WHERE email = 'nguyenvanan@example.com';

INSERT INTO customer_address(
    customer_id, address_label, address_line, ward, district, city,
    latitude, longitude, is_default
)
SELECT customer_id, 'Van phong', '02 Nguyen Van Ba', 'Truong Tho',
       'Thu Duc', 'Thanh pho Ho Chi Minh', 10.822753, 106.760407, FALSE
FROM customer
WHERE email = 'nguyenvanan@example.com';

-- 4. Tram ha canh, nhan vien van hanh va may bay
INSERT INTO landing_station(
    station_code, station_name, address, latitude, longitude, capacity, status
) VALUES
    ('ST-THUDUC-01', 'Tram Thu Duc 01', '01 Vo Van Ngan, Thu Duc',
     10.850632, 106.771916, 10, 'AVAILABLE'),
    ('ST-THUDUC-02', 'Tram Thu Duc 02', '02 Nguyen Van Ba, Thu Duc',
     10.822753, 106.760407, 8, 'AVAILABLE');

INSERT INTO station_operator_assignment(station_id, user_id)
SELECT s.station_id, u.user_id
FROM landing_station s
CROSS JOIN app_user u
WHERE s.station_code IN ('ST-THUDUC-01', 'ST-THUDUC-02')
  AND u.username = 'operator01';

INSERT INTO drone(
    serial_number, model, status, max_payload_kg, battery_level, station_id
)
SELECT 'DRONE-SDD-001', 'DJI FlyCart Demo', 'AVAILABLE', 15.00, 96.00, station_id
FROM landing_station
WHERE station_code = 'ST-THUDUC-01';

INSERT INTO drone(
    serial_number, model, status, max_payload_kg, battery_level, station_id
)
SELECT 'DRONE-SDD-002', 'Cargo Drone Demo', 'MAINTENANCE', 20.00, 42.00, station_id
FROM landing_station
WHERE station_code = 'ST-THUDUC-02';

-- 5. Tao don va kien hang
INSERT INTO delivery_order(
    customer_id, delivery_address_id, requested_delivery_time
)
SELECT c.customer_id, ca.address_id, CURRENT_TIMESTAMP + INTERVAL '2 hours'
FROM customer c
JOIN customer_address ca ON ca.customer_id = c.customer_id
WHERE c.email = 'nguyenvanan@example.com'
  AND ca.is_default = TRUE;

INSERT INTO package(
    order_id, description, weight_kg, length_cm, width_cm, height_cm
)
SELECT order_id, 'Tai lieu hoc tap TKCSDL', 2.50, 30.00, 22.00, 10.00
FROM delivery_order
ORDER BY order_id DESC
LIMIT 1;

-- 6. Duyet don va phan cong chuyen bay
UPDATE delivery_order
SET order_status = 'APPROVED'
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

UPDATE delivery_order
SET order_status = 'ASSIGNED'
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

INSERT INTO delivery_activity(
    order_id, drone_id, pickup_station_id, destination_station_id,
    assigned_by, scheduled_at, activity_status
)
SELECT dord.order_id,
       d.drone_id,
       pickup.station_id,
       destination.station_id,
       operator.user_id,
       CURRENT_TIMESTAMP + INTERVAL '30 minutes',
       'ASSIGNED'
FROM delivery_order dord
CROSS JOIN drone d
CROSS JOIN landing_station pickup
CROSS JOIN landing_station destination
CROSS JOIN app_user operator
WHERE dord.order_id = (SELECT MAX(order_id) FROM delivery_order)
  AND d.serial_number = 'DRONE-SDD-001'
  AND pickup.station_code = 'ST-THUDUC-01'
  AND destination.station_code = 'ST-THUDUC-02'
  AND operator.username = 'operator01';

-- 7. Xac nhan lay kien hang tai tram
INSERT INTO package_station_event(
    package_id, station_id, event_type, performed_by, note
)
SELECT p.package_id, s.station_id, 'PICKUP_CONFIRMED', u.user_id,
       'Kien hang da duoc kiem tra va ban giao cho may bay'
FROM package p
JOIN delivery_order dord ON dord.order_id = p.order_id
CROSS JOIN landing_station s
CROSS JOIN app_user u
WHERE dord.order_id = (SELECT MAX(order_id) FROM delivery_order)
  AND s.station_code = 'ST-THUDUC-01'
  AND u.username = 'operator01';

UPDATE package
SET package_status = 'IN_TRANSIT'
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

UPDATE delivery_activity
SET activity_status = 'IN_TRANSIT', started_at = CURRENT_TIMESTAMP
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

UPDATE delivery_order
SET order_status = 'IN_TRANSIT'
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

-- 8. Tuyen duong va du lieu do tu xa
INSERT INTO delivery_route(activity_id, total_distance_km, estimated_duration_min)
SELECT activity_id, 5.750, 18.00
FROM delivery_activity
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

INSERT INTO route_point(route_id, sequence_number, latitude, longitude, altitude_m)
SELECT route_id, 1, 10.850632, 106.771916, 0.00
FROM delivery_route
UNION ALL
SELECT route_id, 2, 10.837100, 106.766200, 65.00
FROM delivery_route
UNION ALL
SELECT route_id, 3, 10.822753, 106.760407, 0.00
FROM delivery_route;

INSERT INTO tracking_record(
    activity_id, latitude, longitude, altitude_m, speed_kmh,
    battery_level, recorded_at
)
SELECT activity_id, 10.850632, 106.771916, 10.00, 15.00, 94.00,
       CURRENT_TIMESTAMP
FROM delivery_activity
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order)
UNION ALL
SELECT activity_id, 10.837100, 106.766200, 65.00, 42.00, 87.00,
       CURRENT_TIMESTAMP + INTERVAL '6 minutes'
FROM delivery_activity
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order)
UNION ALL
SELECT activity_id, 10.822753, 106.760407, 8.00, 12.00, 79.00,
       CURRENT_TIMESTAMP + INTERVAL '15 minutes'
FROM delivery_activity
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

INSERT INTO ai_recommendation(
    order_id, activity_id, recommendation_type, recommended_drone_id,
    estimated_duration_min, confidence_score, model_version
)
SELECT dord.order_id, da.activity_id, 'DRONE_AND_ROUTE', da.drone_id,
       18.00, 0.9325, 'sdd-model-1.0'
FROM delivery_order dord
JOIN delivery_activity da ON da.order_id = dord.order_id
WHERE dord.order_id = (SELECT MAX(order_id) FROM delivery_order);

-- 9. Hoan tat giao hang va tao xac nhan
UPDATE delivery_activity
SET activity_status = 'DELIVERED', ended_at = CURRENT_TIMESTAMP + INTERVAL '18 minutes'
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

UPDATE delivery_order
SET order_status = 'DELIVERED'
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

UPDATE package
SET package_status = 'DELIVERED'
WHERE order_id = (SELECT MAX(order_id) FROM delivery_order);

INSERT INTO delivery_confirmation(
    order_id, activity_id, confirmed_by, receiver_name, receiver_phone,
    confirmation_method, evidence_object_key, note
)
SELECT dord.order_id, da.activity_id, u.user_id, 'Nguyen Van An', '0902000001',
       'PHOTO', 'delivery-evidence/demo-order-001.jpg',
       'Giao hang thanh cong; du lieu minh hoa'
FROM delivery_order dord
JOIN delivery_activity da ON da.order_id = dord.order_id
CROSS JOIN app_user u
WHERE dord.order_id = (SELECT MAX(order_id) FROM delivery_order)
  AND u.username = 'operator01';

INSERT INTO audit_log(
    user_id, entity_name, record_id, action_type, new_value, ip_address
)
SELECT u.user_id, 'delivery_order', dord.order_id, 'DELIVERY_COMPLETED',
       jsonb_build_object('order_status', dord.order_status), '127.0.0.1'
FROM app_user u
CROSS JOIN delivery_order dord
WHERE u.username = 'operator01'
  AND dord.order_id = (SELECT MAX(order_id) FROM delivery_order);

COMMIT;
