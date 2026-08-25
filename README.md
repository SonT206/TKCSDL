# TKCSDL - Thiết kế cơ sở dữ liệu Drone Delivery

## 📌 Giới thiệu
Dự án này xây dựng mô hình cơ sở dữ liệu cho hệ thống giao hàng bằng drone. 
Mục tiêu là quản lý toàn bộ quy trình từ khách hàng đặt đơn, phân bổ drone, 
theo dõi vận chuyển, xác nhận giao hàng, cho đến kiểm toán hành động của nhân viên.

## 🏗️ Cấu trúc tài liệu
Tài liệu được viết bằng LaTeX, gồm các chương chính:
- **Chương 1: Giới thiệu** – Bối cảnh, mục tiêu, phạm vi.
- **Chương 2: Phân tích hệ thống** – Use case, yêu cầu nghiệp vụ, mô hình khái niệm.
- **Chương 3: Thiết kế CSDL** – ERD, thiết kế logic, thiết kế vật lý.
- **Chương 4: Kiểm thử và Đánh giá** – Các test case, tiêu chí đánh giá, kết quả.
- **Chương 5: Kết luận và Hướng phát triển** – Tóm tắt, đề xuất cải tiến.

## 🔑 Các thực thể chính
- **Customer**: Quản lý thông tin khách hàng.
- **DeliveryOrder**: Đơn hàng trung tâm của hệ thống.
- **Package**: Chi tiết từng kiện hàng.
- **Drone**: Thiết bị bay thực hiện giao hàng.
- **LandingStation**: Trạm xuất phát và hạ cánh.
- **Tracking**: Theo dõi vị trí và tiến độ đơn hàng.
- **DeliveryWorkflow**: Quản lý trạng thái giao hàng.
- **Confirmation**: Xác nhận từ khách hàng.
- **User**: Nhân viên hệ thống.
- **AuditLog**: Nhật ký hành động để kiểm toán.

## ⚙️ Cách sử dụng
1. Clone repository:
   ```bash
   git clone https://github.com/SonT206/TKCSDL.git
