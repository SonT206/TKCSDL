# Cơ sở dữ liệu QUẢN LÝ GIAO HÀNG BẰNG MÁY BAY KHÔNG NGƯỜI LÁI CÓ TÍCH HỢP TRÍ TUỆ NHÂN TẠO

Thư mục này chứa mã nguồn PostgreSQL cho nền tảng quản lý giao hàng bằng máy bay không người lái ứng dụng trí tuệ nhân tạo.

## Thành phần

- `01_schema.sql`: tạo schema, 23 bảng, khóa, ràng buộc, chỉ mục và trigger.
- `02_seed_data.sql`: thêm dữ liệu mẫu và mô phỏng một đơn hàng từ lúc tạo đến khi giao thành công.
- `03_test_queries.sql`: các truy vấn kiểm tra và minh họa phục vụ chạy thử hoặc thuyết trình.

## Yêu cầu

- PostgreSQL 14 trở lên.
- Một cơ sở dữ liệu rỗng, ví dụ `smart_drone_delivery_db`.
- Tài khoản PostgreSQL có quyền tạo schema, bảng, hàm và trigger.

## Cách chạy bằng psql

Tạo cơ sở dữ liệu:

```sql
CREATE DATABASE smart_drone_delivery_db;
```

Chạy lần lượt từ Terminal:

```bash
psql -U postgres -d smart_drone_delivery_db -f database/01_schema.sql
psql -U postgres -d smart_drone_delivery_db -f database/02_seed_data.sql
psql -U postgres -d smart_drone_delivery_db -f database/03_test_queries.sql
```

Kết quả của truy vấn đầu tiên trong `03_test_queries.sql` phải là:

```text
total_tables = 23
```

## Cách chạy bằng pgAdmin 4

1. Tạo database có tên `smart_drone_delivery_db`.
2. Mở **Query Tool** của database vừa tạo.
3. Mở và chạy `01_schema.sql`.
4. Mở và chạy `02_seed_data.sql`.
5. Mở và chạy `03_test_queries.sql` để xem kết quả.

## Các quy tắc nghiệp vụ tiêu biểu được thực thi

- Mỗi khách hàng có tối đa một địa chỉ mặc định.
- Địa chỉ của đơn phải thuộc đúng khách hàng tạo đơn.
- Giá trị tọa độ, pin, tải trọng và kích thước phải thuộc miền hợp lệ.
- Một máy bay không được thực hiện đồng thời hai hoạt động đang chạy.
- Tổng khối lượng kiện hàng không được vượt tải trọng máy bay.
- Chỉ nhân viên đang được phân công mới được ghi sự kiện tại trạm.
- Kiện hàng chỉ chuyển sang `IN_TRANSIT` sau sự kiện `PICKUP_CONFIRMED`.
- Xác nhận giao hàng chỉ được tạo khi đơn và hoạt động đều `DELIVERED`.
- Lịch sử trạng thái và nhật ký kiểm toán chỉ cho phép thêm mới.

## Lưu ý bảo mật

Dữ liệu trong `02_seed_data.sql` chỉ dùng để minh họa. Các chuỗi `password_hash` không phải mật khẩu thật. Khi triển khai thực tế, mật khẩu phải được băm bằng BCrypt hoặc Argon2 trong tầng ứng dụng.
