# SƠ ĐỒ USE CASE CHI TIẾT – HỆ THỐNG TASKHERO

> Các sơ đồ dưới đây mô phỏng chuẩn Use Case diagram của UML, với hệ thống mũi tên liên kết `include` (chức năng bắt buộc/gộp), `extend` (chức năng mở rộng) và khung `Hệ Thống` bao quát, được chia thành phần Tổng quát và 4 nhóm cụ thể tương ứng với 4 nhóm Actor chính, tóm gọn 22 Use Case.

---

## SƠ ĐỒ USE CASE TỔNG QUÁT Toàn Hệ Thống

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#ffffff', 'primaryBorderColor':'#000000', 'lineColor':'#000000'}}}%%
flowchart LR
    %% Định nghĩa các tác nhân
    Admin(("👤<br/>Admin")):::actor
    User(("👤<br/>User<br/>(Chung)")):::actor
    Poster(("👤<br/>Poster<br/>(Đăng việc)")):::actor
    Hero(("👤<br/>Hero<br/>(Nhận việc)")):::actor
    
    %% Mối liên hệ tổng quát giữa các đối tượng User
    User -. "<br/>Mở rộng thành" .-> Poster
    User -. "<br/>Mở rộng thành" .-> Hero
    
    %% Ranh giới hệ thống tổng
    subgraph Sys ["Hệ Thống TaskHero (Tổng Quan)"]
        direction TB
        
        %% Admin UCs
        UC_A1(["Quản lý hệ thống<br/>& nền tảng"]):::mainUC
        UC_A2(["Quản lý<br/>người dùng"]):::mainUC
        
        %% User UCs
        UC_U1(["Quản lý<br/>tài khoản & hồ sơ"]):::mainUC
        
        %% Poster UCs
        UC_P1(["Quản lý đăng tải<br/>& nhiệm vụ"]):::mainUC
        UC_P2(["Xác nhận<br/>thanh toán"]):::mainUC
        
        %% Hero UCs
        UC_H1(["Tìm lọc và<br/>Nhận nhiệm vụ"]):::mainUC
        UC_H2(["Theo dõi công việc<br/>đang thực hiện"]):::mainUC
    end
    
    %% Liên kết Actor và Use Case
    Admin --- UC_A1
    Admin --- UC_A2
    
    User --- UC_U1
    
    Poster --- UC_P1
    Poster --- UC_P2
    
    Hero --- UC_H1
    Hero --- UC_H2
    
    %% Styling
    classDef actor fill:transparent,stroke:none,color:#000000;
    classDef mainUC fill:#ffffff,stroke:#000000,stroke-width:1px,color:#000000;
    style Sys fill:transparent,stroke:#000000,stroke-width:1px,rx:20,ry:20
```

---

## 1. Mục tiêu Tác nhân ADMIN (Quản trị viên)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#ffffff', 'primaryBorderColor':'#000000', 'lineColor':'#000000'}}}%%
flowchart LR
    Admin(("👤<br/>Admin")):::actor
    
    subgraph Sys1 ["Hệ Thống (Admin Dashboard)"]
        direction TB
        
        UC1(["Đăng nhập"]):::mainUC
        UC2(["Quản lý<br/>người dùng"]):::mainUC
        UC3(["Quản lý<br/>tài chính & thống kê"]):::mainUC
        UC4(["Xem bảng xếp hạng"]):::mainUC
        
        UC_2_1(["Xem danh sách"]):::subUC
        UC_2_2(["Tìm kiếm"]):::subUC
        UC_2_3(["Xem chi tiết<br/>người dùng"]):::subUC
        
        UC_3_1(["Xem thống kê<br/>hệ thống"]):::subUC
        UC_3_2(["Xem doanh thu<br/>nền tảng"]):::subUC
        UC_3_3(["Xem lịch sử<br/>giao dịch"]):::subUC
        
        UC2 -. "include" .-> UC_2_1
        UC_2_2 -. "extend" .-> UC_2_1
        UC_2_3 -. "extend" .-> UC_2_1
        
        UC3 -. "include" .-> UC_3_1
        UC3 -. "include" .-> UC_3_2
        UC_3_3 -. "extend" .-> UC3
    end
    
    Admin --- UC1
    Admin --- UC2
    Admin --- UC3
    Admin --- UC4
    
    classDef actor fill:transparent,stroke:none,color:#000000;
    classDef mainUC fill:#ffffff,stroke:#000000,stroke-width:1px,color:#000000;
    classDef subUC fill:#d1e1fb,stroke:#7b9ecc,stroke-width:1px,color:#000000;
    style Sys1 fill:transparent,stroke:#000000,stroke-width:1px,rx:20,ry:20
```

---

## 2. Mục tiêu Tác nhân USER (Người dùng chung)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#ffffff', 'primaryBorderColor':'#000000', 'lineColor':'#000000'}}}%%
flowchart LR
    User(("👤<br/>User")):::actor
    
    subgraph Sys2 ["Hệ Thống (Ứng dụng)"]
        direction TB
        
        UC5(["Đăng ký<br/>tài khoản"]):::mainUC
        UC6(["Đăng nhập /<br/>Đăng xuất"]):::mainUC
        UC7(["Quản lý<br/>Hồ sơ"]):::mainUC
        
        UC_6_1(["Khôi phục<br/>mật khẩu"]):::subUC
        UC_7_1(["Cập nhật<br/>mã ngành & năm học"]):::subUC
        UC_7_2(["Xem thống kê<br/>cá nhân"]):::subUC
        
        UC_6_1 -. "extend" .-> UC6
        UC7 -. "include" .-> UC_7_1
        UC_7_2 -. "extend" .-> UC7
    end
    
    User --- UC5
    User --- UC6
    User --- UC7
    
    classDef actor fill:transparent,stroke:none,color:#000000;
    classDef mainUC fill:#ffffff,stroke:#000000,stroke-width:1px,color:#000000;
    classDef subUC fill:#d1e1fb,stroke:#7b9ecc,stroke-width:1px,color:#000000;
    style Sys2 fill:transparent,stroke:#000000,stroke-width:1px,rx:20,ry:20
```

---

## 3. Mục tiêu Tác nhân POSTER (Người đăng việc)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#ffffff', 'primaryBorderColor':'#000000', 'lineColor':'#000000'}}}%%
flowchart LR
    Poster(("👤<br/>Poster<br/>(Người đăng)")):::actor
    
    subgraph Sys3 ["Hệ Thống (Module Đăng việc)"]
        direction TB
        
        UC8(["Quản lý việc<br/>đăng nhiệm vụ"]):::mainUC
        UC9(["Quản lý nhiệm vụ<br/>đã đăng"]):::mainUC
        
        UC_8_1(["Đăng thủ công"]):::subUC
        UC_8_2(["Đăng bằng<br/>giọng nói"]):::subUC
        UC_8_3(["AI Phân tích<br/>& Định dạng"]):::subUC
        
        UC_9_1(["Xem danh sách<br/>nhiệm vụ"]):::subUC
        UC_9_2(["Xác nhận thanh toán<br/>cho Hero"]):::subUC
        
        UC_8_1 -. "extend" .-> UC8
        UC_8_2 -. "extend" .-> UC8
        UC_8_2 -. "include" .-> UC_8_3
        
        UC9 -. "include" .-> UC_9_1
        UC_9_2 -. "extend" .-> UC_9_1
    end
    
    Poster --- UC8
    Poster --- UC9
    
    classDef actor fill:transparent,stroke:none,color:#000000;
    classDef mainUC fill:#ffffff,stroke:#000000,stroke-width:1px,color:#000000;
    classDef subUC fill:#d1e1fb,stroke:#7b9ecc,stroke-width:1px,color:#000000;
    style Sys3 fill:transparent,stroke:#000000,stroke-width:1px,rx:20,ry:20
```

---

## 4. Mục tiêu Tác nhân HERO (Người nhận việc)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#ffffff', 'primaryBorderColor':'#000000', 'lineColor':'#000000'}}}%%
flowchart LR
    Hero(("👤<br/>Hero<br/>(Người nhận)")):::actor
    
    subgraph Sys4 ["Hệ Thống (Module Nhận việc)"]
        direction TB
        
        UC10(["Tìm việc &<br/>Nhận việc"]):::mainUC
        UC11(["Quản lý việc<br/>đang làm"]):::mainUC
        
        UC_10_1(["Duyệt nhiệm vụ<br/>đang mở"]):::subUC
        UC_10_2(["Tìm kiếm theo<br/>từ khóa"]):::subUC
        UC_10_3(["Lọc theo<br/>danh mục"]):::subUC
        UC_10_4(["Nhận thực hiện<br/>nhiệm vụ"]):::subUC
        
        UC_11_1(["Xem danh sách<br/>nhiệm vụ đang nhận"]):::subUC
        UC_11_2(["Xem thu nhập &<br/>trạng thái thanh toán"]):::subUC
        
        UC10 -. "include" .-> UC_10_1
        UC_10_2 -. "extend" .-> UC_10_1
        UC_10_3 -. "extend" .-> UC_10_1
        UC_10_4 -. "extend" .-> UC_10_1
        
        UC11 -. "include" .-> UC_11_1
        UC_11_2 -. "extend" .-> UC11
    end
    
    Hero --- UC10
    Hero --- UC11
    
    classDef actor fill:transparent,stroke:none,color:#000000;
    classDef mainUC fill:#ffffff,stroke:#000000,stroke-width:1px,color:#000000;
    classDef subUC fill:#d1e1fb,stroke:#7b9ecc,stroke-width:1px,color:#000000;
    style Sys4 fill:transparent,stroke:#000000,stroke-width:1px,rx:20,ry:20
```
