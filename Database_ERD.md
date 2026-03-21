# CHƯƠNG 3: THIẾT KẾ HỆ THỐNG

## 3.1. Thiết kế Dữ liệu (Sơ đồ ERD Firebase / Class Diagram)

Hệ thống TaskHero sử dụng cơ sở dữ liệu **Cloud Firestore (NoSQL)**. Tuy nhiên, để biểu diễn cấu trúc dữ liệu một cách trực quan và chuẩn hóa theo góc nhìn thiết kế hướng đối tượng (OOP) và mối quan hệ thực thể, sơ đồ thực thể liên kết (ERD) hoặc Class Diagram dưới đây được sử dụng để định nghĩa cấu trúc của 2 Collection cốt lõi: `users` và `tasks`.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#ffffff', 'primaryBorderColor':'#000000', 'lineColor':'#000000'}}}%%
erDiagram
    %% Định nghĩa bảng users (Dựa theo UserProfile)
    USERS {
        string uid PK "Gốc định danh Firebase Auth"
        string email
        string displayName
        string photoURL
        string pillar "Chuyên ngành (VD: ISTD, ASD)"
        int year "Năm học (1-4)"
        double totalEarned "Tổng doanh thu tích lũy"
        double totalSpent "Tổng chi tiêu tích lũy"
        double thisMonthEarned "Thu nhập/Chi tiêu tháng"
        int tasksCompleted "Số nhiệm vụ đã hoàn thành"
        int tasksPosted "Số nhiệm vụ đã đăng tải"
        double rating "Điểm đánh giá trung bình"
        int totalReviews "Số lượng đánh giá"
        datetime createdAt "Ngày tham gia"
        datetime lastActive "Lần cuối hoạt động"
        boolean isAdmin "Phân quyền quản trị"
        boolean isBlocked "Trạng thái khóa tài khoản"
        boolean isVerified "Trạng thái xác thực"
    }

    %% Định nghĩa bảng tasks (Dựa theo HeroTask)
    TASKS {
        string id PK "Mã định danh Task (Auto-ID)"
        string title "Tiêu đề nhiệm vụ"
        string description "Mô tả chi tiết"
        enum category "Danh mục (food, academic...)"
        double compensation "Thù lao đề xuất"
        enum status "Trạng thái (open, accepted...)"
        enum urgency "Độ khẩn cấp (normal, urgent)"
        int estimatedMinutes "Thời gian ước tính (phút)"
        object pickup "Tọa độ/Địa điểm nhận"
        object delivery "Tọa độ/Địa điểm giao"
        
        string posterId FK "References users.uid"
        string posterName "Rút gọn truy vấn"
        double posterRating "Rút gọn truy vấn"
        
        string heroId FK "References users.uid (nullable)"
        string heroName "Rút gọn truy vấn"
        
        boolean pickedUp "Đã lấy hàng"
        boolean delivered "Đã giao hàng"
        boolean isPaid "Trạng thái nhận thù lao"
        
        datetime createdAt
        datetime acceptedAt
        datetime completedAt
    }

    %% Mối quan hệ giữa các bảng
    USERS ||--o{ TASKS : "Đăng tải (Với tư cách Poster)"
    USERS ||--o{ TASKS : "Nhận thực hiện (Với tư cách Hero)"

```

### Phân tích Thiết kế (Theo chuẩn NoSQL)

- **Nguyên lý Mối quan hệ**: Một `User` có thể đóng vai trò là `Poster` để tạo ra nhiều `Tasks` (1-N). Đồng thời, một `User` khác có thể đóng vai trò là `Hero` để nhận thực hiện nhiều `Tasks` (1-N).
- **Thiết kế Đảo ngược (Denormalization)**: Để tối ưu hóa hiệu suất đọc (Read operations) đặc trưng của Firestore NoSQL, bảng `tasks` chủ động lưu trữ bản sao của một số thông tin từ `users` như `posterName`, `posterRating`, và `heroName`. Điều này giúp hệ thống đổ dữ liệu lên màn hình Feed (Duyệt nhiệm vụ) một cách tức thì mà không cần phải thực hiện truy vấn N+1 (Fetch Task -> Fetch User).
