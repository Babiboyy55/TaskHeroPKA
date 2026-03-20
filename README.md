# 🦸 Hệ thống dịch vụ Campus TaskHero

> **Nơi sinh viên PKA trở thành anh hùng của nhau, từng nhiệm vụ một!** ⚡

[![Flutter Web](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Hosting-FFCA28?logo=firebase)](https://firebase.google.com)

---

## 🤔 TaskHero là gì?

TaskHero là **chợ nhiệm vụ campus thời gian thực** dành cho sinh viên và nhân viên tại **PKA**. Cần ai đó mua cơm hộ? Muốn được hỗ trợ học tập? Lười đi lấy bưu kiện? 📦

**Đăng lên. Sẽ có hero nhận ngay.** 🦸‍♂️

### 🎯 Khái niệm

| Vai trò | Mô tả |
|---------|-------|
| 🧑‍💼 **Người đăng** | Mô tả nhiệm vụ (giọng nói hoặc văn bản). AI định dạng gọn đẹp. |
| 🦸 **Hero** | Duyệt nhiệm vụ mở, nhận một nhiệm vụ, hoàn thành, nhận thưởng. |
| 🛡️ **Quản trị viên** | Quản lý người dùng, xem thống kê toàn hệ thống, bảo vệ an toàn nền tảng. |

Tất cả cập nhật **thời gian thực** — cả hai bên đều thấy tiến trình trực tiếp trên màn hình chi tiết nhiệm vụ. ✨

---

## 🚀 Tính năng nổi bật

| Tính năng | Mô tả |
|-----------|-------|
| 📊 **Bảng điều khiển trực tiếp** | Thẻ thống kê, nhiệm vụ đang thực hiện, biểu đồ hoạt động — stream từ Firestore |
| 🔍 **Duyệt thông minh** | Lọc theo danh mục, tìm kiếm, phân tab giữa Nhiệm vụ mở / Của tôi |
| 🏃 **Tiến trình thời gian thực** | Trạng thái: `open` → `accepted` → `inProgress` → `completed` |
| 💰 **Thanh toán minh bạch** | Người đăng xác nhận thanh toán → Hero nhận 95% sau khi trừ 5% phí (`isPaid`) |
| ⭐ **Đánh giá Hero** | Đánh giá hero sau khi hoàn thành nhiệm vụ (1–5 sao) |
| 🎙️ **Nhập liệu giọng nói** | Ghi âm trực tiếp trên ứng dụng để đăng nhiệm vụ rảnh tay |
| 🤖 **AI định dạng AI** | Hệ thống tự động phân tích và tạo mô tả nhiệm vụ rõ ràng |
| 🛡️ **Bảng Admin** | Công cụ chuyên dụng cho quản trị viên theo dõi và kiểm duyệt nền tảng |
| 🎨 **Giao diện đẹp** | ShadCN components, chủ đề cam gradient, hiệu ứng mượt mà |
| 📱 **Responsive** | Điện thoại (thanh điều hướng dưới) ↔ Desktop (sidebar) |

---

## 🏗️ Công nghệ sử dụng

```text
┌─────────────────────────────────────────────────────┐
│                    🦸 TaskHero                       │
├──────────────┬──────────────────────────────────────┤
│  Frontend    │  Flutter Web (Dart)                  │
│  UI Library  │  shadcn_ui ^0.45.2                   │
│  Animations  │  flutter_animate ^4.5.2              │
├──────────────┼──────────────────────────────────────┤
│  Xác thực    │  Firebase Auth (Email/Google)        │
│  Cơ sở dữ liệu│ Cloud Firestore (real-time streams) │
│  Hosting     │  Firebase Hosting                    │
│  API & Voice │  http ^1.3.0, record ^6.1.1          │
└──────────────┴──────────────────────────────────────┘
```

---

## 📂 Cấu trúc dự án

```text
lib/
├── main.dart                    # 🏠 App shell, routing, sidebar + bottom nav
├── firebase_options.dart        # 🔥 Cấu hình Firebase
├── config/                      # ⚙️ Cấu hình hệ thống chung
├── models/
│   ├── task_model.dart          # 📋 HeroTask, TaskCategory, TaskStatus...
│   └── user_profile.dart        # 👤 UserProfile với thống kê chi tiết
├── screens/
│   ├── login_screen.dart        # 🔐 Đăng nhập (Email + Google)
│   ├── register_screen.dart     # 📝 Đăng ký tài khoản mới
│   ├── forgot_password_screen.dart # 🔑 Đặt lại mật khẩu cài đặt
│   ├── home_screen.dart         # 📊 Bảng điều khiển với thống kê trực tiếp
│   ├── browse_screen.dart       # 🔍 Duyệt và lọc nhiệm vụ
│   ├── post_task_screen.dart    # ✍️ Tạo nhiệm vụ mới (Voice + AI + Text)
│   ├── profile_screen.dart      # 👤 Hồ sơ, biểu đồ, lịch sử
│   ├── task_detail_screen.dart  # 📱 Chi tiết nhiệm vụ + theo dõi liên tục
│   ├── admin_screen.dart        # 🛡️ Quản lý tổng quan cho admin
│   └── admin_user_detail_screen.dart # 🛡️ Xem trước và khóa tài khoản
├── services/
│   ├── auth_service.dart        # 🔑 Wrapper Firebase Auth
│   ├── firestore_service.dart   # 🗄️ Tất cả CRUD + streams Firestore
│   ├── api_service.dart         # 🤖 Xử lý kết nối API AI cho Voice-to-Text
│   └── audio_service.dart       # 🎙️ Ghi âm trên trình duyệt
├── widgets/
│   ├── task_card.dart           # 🃏 Thẻ nhiệm vụ dùng lại được
│   └── stat_card.dart           # 📈 Thẻ số liệu bảng điều khiển
├── utils/
│   └── currency_format.dart     # 💰 Định dạng tiền VND chuẩn
└── theme/
    └── app_colors.dart          # 🎨 Bảng màu cam
```

---

## 🗄️ Cấu trúc Database

### Collection `users`
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `displayName` | string | Tên người dùng |
| `email` | string | Email |
| `pillar` | string | Khoa/Ngành (VD: ISTD) |
| `year` | int | Năm học (1–5) |
| `totalEarned`, `thisMonth..` | double | Các chuẩn đo thu nhập của hero |
| `totalSpent` | double | Tổng chi khi đăng nhiệm vụ |
| `rating`, `totalReviews` | double | Đánh giá tổng hợp |
| `tasksCompleted`, `..Posted` | int | Thống kê số lượng nhiệm vụ |
| `isAdmin`, `isBlocked` | bool | Quyền hạn và trạng thái định danh |

### Collection `tasks`
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `title`, `description` | string | Nội dung và tiêu đề |
| `category` | string | `food`, `academic`, `tech`, `errands`, `social`, `marketplace` |
| `status` | string | `open` → `accepted` → `inProgress` → `completed` |
| `compensation` | double | Số tiền thưởng (VND) |
| `urgency` | string | `normal`, `urgent`, `emergency` |
| `posterId` / `heroId` | string | Liên kết người liên quan |
| `pickup` / `delivery` | map | `{building, level, landmark}` |
| `isPaid` | bool | Trạng thái đợi người đăng thanh toán |

---

## 🔄 Vòng đời nhiệm vụ

```text
  ┌──────────┐    Hero nhận       ┌─────────────┐   Bắt đầu làm    ┌────────────────┐
  │   MỞ    │ ──────────────────►│  ĐÃ NHẬN    │ ───────────────►│ ĐANG THỰC HIỆN│
  └──────────┘                    └─────────────┘                  └────────────────┘
       │                                                                  │
       │ Người đăng hủy                                                   │ Hoàn thành
       ▼                                                                  ▼
  ┌──────────┐                                                     ┌────────────────┐
  │  ĐÃ HỦY  │                                                     │   HOÀN THÀNH  │
  └──────────┘                                                     │ (isPaid: false)│
                                                                   └────────────────┘
                                                                          │
                                                                          │ Đã trả tiền
                                                                          ▼
                                                                   ┌────────────────┐
                                                                   │   HOÀN THÀNH  │
                                                                   │ (isPaid: true) │
                                                                   └────────────────┘
```

---

## 📋 Danh mục nhiệm vụ

| Emoji | Danh mục | Ví dụ |
|-------|----------|-------|
| 🍔 | Đồ ăn & Vật phẩm | "Mua cơm hộ mình từ căng tin" |
| 📚 | Hỗ trợ học tập | "Giúp mình debug code Python" |
| 🏃 | Việc vặt & Trợ giúp | "Đi lấy bưu kiện giúp mình" |
| 🛠️ | Công nghệ & Thiết bị | "Giúp mình cài đặt laptop" |
| 🤝 | Sự kiện & Xã hội | "Cần người hỗ trợ dọn dẹp hội trường" |
| 💼 | Chợ buôn bán | "Cần bán sách lập trình cũ" |

---

## 🛠️ Bắt đầu với dự án

### Yêu cầu

- 📦 [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10+)
- 🔥 [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- 🌐 Trình duyệt Chrome

### 1. Clone & Cài đặt

```bash
git clone <repo-url>
cd TaskHero
flutter pub get
```

### 2. Cấu hình Firebase

1. **Firebase Auth** — Bật Email/Password + Google Sign-In trong Firebase Console
2. **Cloud Firestore** — Tạo database (đã có security rules trong `firestore.rules`)
3. **Firebase Hosting**

### 3. Chạy Local

```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

### 4. Build & Deploy 🚀

```bash
flutter build web --release
firebase deploy --only hosting
```

---

## 🔒 Bảo mật

- 🔐 Firebase Auth bắt buộc cho tất cả thao tác
- 🛡️ Firestore security rules thực thi quyền truy cập theo user
- 🚫 Người dùng chỉ có thể chỉnh sửa nhiệm vụ/hồ sơ của chính mình
- 👑 Giao diện Admin chỉ mở với tài khoản có thẻ `isAdmin: true`
- 📝 Tất cả ghi vào Firestore đều qua các phương thức service đã được kiểm tra

---

## 📄 Giấy phép

Dự án được xây dựng cho cộng đồng **PKA**.

---

<div align="center">

**Được xây dựng với 🧡 tại PKA**

*Vì mỗi campus đều cần những người anh hùng của mình* 🦸

</div>
