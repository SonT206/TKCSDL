-- ============================================================================
-- SMARTDRONEDELIVERY - CAC TRUY VAN KIEM TRA VA MINH HOA
-- Chay sau 01_schema.sql va 02_seed_data.sql.
-- ============================================================================

SET search_path TO smart_drone_delivery, public;

-- 1. Dem 23 bang cua he thong.
SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'smart_drone_delivery'
  AND table_type = 'BASE TABLE';

-- 2. Xem don hang cung khach hang va dia chi giao.
SELECT dord.order_id,
       c.customer_name,
       ca.address_line,
       dord.order_status,
       dord.created_at,
       dord.completed_at
FROM delivery_order dord
JOIN customer c ON c.customer_id = dord.customer_id
JOIN customer_address ca ON ca.address_id = dord.delivery_address_id
ORDER BY dord.created_at DESC;

-- 3. Xem lich su trang thai don hang do trigger tu dong ghi.
SELECT osh.order_id,
       osh.status,
       su.username AS changed_by,
       osh.changed_at
FROM order_status_history osh
LEFT JOIN app_user su ON su.user_id = osh.changed_by
ORDER BY osh.order_id, osh.changed_at;

-- 4. Xem may bay va hoat dong giao hang.
SELECT da.activity_id,
       da.order_id,
       d.serial_number,
       d.model,
       da.activity_status,
       pickup.station_name AS pickup_station,
       destination.station_name AS destination_station,
       da.started_at,
       da.ended_at
FROM delivery_activity da
JOIN drone d ON d.drone_id = da.drone_id
LEFT JOIN landing_station pickup ON pickup.station_id = da.pickup_station_id
LEFT JOIN landing_station destination
       ON destination.station_id = da.destination_station_id
ORDER BY da.created_at DESC;

-- 5. Lay 50 ban ghi do tu xa moi nhat cua moi hoat dong.
SELECT tracking_id,
       activity_id,
       latitude,
       longitude,
       altitude_m,
       speed_kmh,
       battery_level,
       recorded_at
FROM tracking_record
ORDER BY activity_id, recorded_at DESC
LIMIT 50;

-- 6. Xem hanh trinh theo dung thu tu diem.
SELECT dr.route_id,
       dr.activity_id,
       rp.sequence_number,
       rp.latitude,
       rp.longitude,
       rp.altitude_m
FROM delivery_route dr
JOIN route_point rp ON rp.route_id = dr.route_id
ORDER BY dr.route_id, rp.sequence_number;

-- 7. Xem xac nhan giao hang va bang chung.
SELECT dc.confirmation_id,
       dc.order_id,
       dc.activity_id,
       dc.receiver_name,
       dc.confirmation_method,
       dc.evidence_object_key,
       dc.confirmed_at
FROM delivery_confirmation dc
ORDER BY dc.confirmed_at DESC;

-- 8. Xem cac de xuat cua mo hinh AI.
SELECT ar.recommendation_id,
       ar.order_id,
       ar.recommendation_type,
       d.serial_number AS recommended_drone,
       ar.estimated_duration_min,
       ar.confidence_score,
       ar.model_version
FROM ai_recommendation ar
LEFT JOIN drone d ON d.drone_id = ar.recommended_drone_id
ORDER BY ar.created_at DESC;

-- 9. Xem nhat ky kiem toan.
SELECT al.log_id,
       su.username,
       al.entity_name,
       al.record_id,
       al.action_type,
       al.new_value,
       al.action_time
FROM audit_log al
LEFT JOIN app_user su ON su.user_id = al.user_id
ORDER BY al.action_time DESC;

-- 10. Kiem tra tong khoi luong kien hang so voi tai trong may bay.
SELECT da.activity_id,
       d.serial_number,
       SUM(p.weight_kg) AS total_package_weight,
       d.max_payload_kg,
       SUM(p.weight_kg) <= d.max_payload_kg AS payload_is_valid
FROM delivery_activity da
JOIN drone d ON d.drone_id = da.drone_id
JOIN package p ON p.order_id = da.order_id
GROUP BY da.activity_id, d.serial_number, d.max_payload_kg;
-- ============================================================================
-- CAC TINH HUONG TRUY VAN THUC TE
-- ============================================================================

-- 11. Khach hang xem tat ca don giao hang da tao.
-- Thay so 1 bang customer_id can kiem tra.
SELECT
    dord.order_id,
    c.customer_name,
    dord.order_status,
    ca.address_line AS delivery_address,
    dord.requested_delivery_time,
    dord.estimated_arrival_at,
    dord.created_at
FROM delivery_order dord
JOIN customer c
    ON c.customer_id = dord.customer_id
JOIN customer_address ca
    ON ca.address_id = dord.delivery_address_id
WHERE dord.customer_id = 1
ORDER BY dord.created_at DESC;


-- 12. Khach hang xem lich su trang thai cua mot don.
-- Thay so 1 bang order_id can kiem tra.
SELECT
    osh.status_history_id,
    osh.order_id,
    osh.status,
    osh.reason,
    su.username AS changed_by,
    osh.changed_at
FROM order_status_history osh
LEFT JOIN app_user su
    ON su.user_id = osh.changed_by
WHERE osh.order_id = 1
ORDER BY osh.changed_at ASC;


-- 13. Dem so lan giao va so lan len lich lai cua mot don.
SELECT
    da.order_id,
    COUNT(*) AS total_delivery_attempts,
    COUNT(da.previous_activity_id) AS total_reschedules,
    COUNT(*) FILTER (
        WHERE da.activity_status = 'FAILED'
    ) AS failed_attempts,
    COUNT(*) FILTER (
        WHERE da.activity_status = 'DELIVERED'
    ) AS successful_attempts
FROM delivery_activity da
WHERE da.order_id = 1
GROUP BY da.order_id;


-- 14. Xem chuoi cac lan giao cua mot don.
WITH RECURSIVE delivery_chain AS (
    SELECT
        da.activity_id,
        da.order_id,
        da.previous_activity_id,
        da.drone_id,
        da.activity_status,
        da.scheduled_at,
        da.started_at,
        da.ended_at,
        1 AS attempt_number
    FROM delivery_activity da
    WHERE da.order_id = 1
      AND da.previous_activity_id IS NULL

    UNION ALL

    SELECT
        next_da.activity_id,
        next_da.order_id,
        next_da.previous_activity_id,
        next_da.drone_id,
        next_da.activity_status,
        next_da.scheduled_at,
        next_da.started_at,
        next_da.ended_at,
        dc.attempt_number + 1
    FROM delivery_activity next_da
    JOIN delivery_chain dc
        ON next_da.previous_activity_id = dc.activity_id
)
SELECT
    dc.attempt_number,
    dc.activity_id,
    dc.previous_activity_id,
    d.serial_number AS drone,
    dc.activity_status,
    dc.scheduled_at,
    dc.started_at,
    dc.ended_at
FROM delivery_chain dc
JOIN drone d
    ON d.drone_id = dc.drone_id
ORDER BY dc.attempt_number;


-- 15. Xem vi tri moi nhat cua nhung don dang duoc giao.
SELECT DISTINCT ON (da.activity_id)
    da.order_id,
    da.activity_id,
    d.serial_number,
    tr.latitude,
    tr.longitude,
    tr.altitude_m,
    tr.speed_kmh,
    tr.battery_level,
    tr.recorded_at
FROM delivery_activity da
JOIN drone d
    ON d.drone_id = da.drone_id
JOIN tracking_record tr
    ON tr.activity_id = da.activity_id
WHERE da.activity_status = 'IN_TRANSIT'
ORDER BY da.activity_id, tr.recorded_at DESC;