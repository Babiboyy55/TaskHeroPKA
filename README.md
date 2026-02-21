# 🦸 TaskHero — Chợ Nhiệm Vụ Campus

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

Tất cả cập nhật **thời gian thực** — cả hai bên đều thấy tiến trình trực tiếp trên màn hình chi tiết nhiệm vụ. ✨

---

## 🚀 Tính năng nổi bật

| Tính năng | Mô tả |
|-----------|-------|
| 📊 **Bảng điều khiển trực tiếp** | Thẻ thống kê, nhiệm vụ đang thực hiện, nhiệm vụ gần đây, biểu đồ hoạt động — tất cả stream từ Firestore |
| 🔍 **Duyệt thông minh** | Lọc theo danh mục, tìm kiếm theo từ khóa, phân tab giữa Nhiệm vụ mở / Của tôi |
| 🏃 **Tiến trình thời gian thực** | Trạng thái nhiệm vụ: `open` → `accepted` → `completed` |
| 💰 **Thanh toán** | Người đăng giải phóng thanh toán → Hero nhận 95% (5% phí nền tảng) |
| ⭐ **Hệ thống đánh giá** | Đánh giá hero sau khi hoàn thành nhiệm vụ (1–5 sao) |
| 🎨 **Giao diện đẹp** | ShadCN components, chủ đề cam gradient, hiệu ứng hover, thiết kế responsive |
| 📱 **Responsive** | Điện thoại (thanh điều hướng dưới) ↔ Desktop (sidebar) |

---

## 🏗️ Công nghệ sử dụng

```
┌─────────────────────────────────────────────────────┐
│                    🦸 TaskHero                       │
├──────────────┬──────────────────────────────────────┤
│  Frontend    │  Flutter Web (Dart)                  │
│  UI Library  │  shadcn_ui                           │
│  Animations  │  flutter_animate                     │
│  Icons       │  Lucide Icons                        │
├──────────────┼──────────────────────────────────────┤
│  Xác thực    │  Firebase Auth (Email/Google)        │
│  Cơ sở dữ liệu│ Cloud Firestore (real-time streams) │
│  Hosting     │  Firebase Hosting                    │
└──────────────┴──────────────────────────────────────┘
```

---

## 📂 Cấu trúc dự án

```
lib/
├── main.dart                    # 🏠 App shell, routing, sidebar + bottom nav
├── firebase_options.dart        # 🔥 Cấu hình Firebase
├── models/
│   ├── task_model.dart          # 📋 HeroTask, TaskCategory, TaskStatus...
│   └── user_profile.dart        # 👤 UserProfile với Firestore serialization
├── screens/
│   ├── login_screen.dart        # 🔐 Đăng nhập (Email + Google)
│   ├── register_screen.dart     # 📝 Đăng ký tài khoản mới
│   ├── home_screen.dart         # 📊 Bảng điều khiển với thống kê trực tiếp
│   ├── browse_screen.dart       # 🔍 Duyệt và lọc nhiệm vụ
│   ├── post_task_screen.dart    # ✍️ Tạo nhiệm vụ mới
│   ├── profile_screen.dart      # 👤 Hồ sơ, lịch sử nhiệm vụ
│   └── task_detail_screen.dart  # 📱 Chi tiết nhiệm vụ + theo dõi tiến trình
├── services/
│   ├── auth_service.dart        # 🔑 Wrapper Firebase Auth
│   ├── firestore_service.dart   # 🗄️ Tất cả CRUD + streams Firestore
│   └── audio_service.dart       # 🎙️ Ghi âm trên trình duyệt
├── widgets/
│   ├── task_card.dart           # 🃏 Thẻ nhiệm vụ dùng lại được
│   └── stat_card.dart           # 📈 Thẻ số liệu bảng điều khiển
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
| `pillar` | string | Khoa/Ngành |
| `year` | int | Năm học (1–5) |
| `totalEarned` | double | Tổng thu nhập khi làm hero |
| `rating` | double | Điểm đánh giá trung bình |
| `tasksCompleted` | int | Số nhiệm vụ đã hoàn thành |
| `tasksPosted` | int | Số nhiệm vụ đã đăng |

### Collection `tasks`
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `title` | string | Tiêu đề nhiệm vụ |
| `description` | string | Mô tả chi tiết |
| `category` | string | Danh mục (food, academic, tech...) |
| `status` | string | `open` → `accepted` → `completed` |
| `compensation` | double | Số tiền thưởng (VND) |
| `posterId` / `heroId` | string | UID người dùng liên kết |
| `pickup` / `delivery` | map | `{building, level, landmark}` |
| `urgency` | string | `low` / `normal` / `high` / `urgent` |

---

## 🔄 Vòng đời nhiệm vụ

```
  ┌──────────┐    Hero nhận       ┌─────────────┐    Hoàn thành    ┌───────────┐
  │   MỞ    │ ──────────────────►│  ĐÃ NHẬN    │ ───────────────►│ HOÀN THÀNH│
  └──────────┘                    └─────────────┘                  └───────────┘
       │
       │ Người đăng hủy
       ▼
  ┌──────────┐
  │  ĐÃ HỦY  │
  └──────────┘
```

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
3. **Firebase Hosting** — Đã cấu hình sẵn

### 3. Chạy Local

```bash
flutter run -d chrome
```

### 4. Build & Deploy 🚀

```bash
flutter build web --release
firebase deploy --only hosting
```

---

## 📋 Danh mục nhiệm vụ

| Emoji | Danh mục | Ví dụ |
|-------|----------|-------|
| 🍔 | Thực phẩm & Giao hàng | "Mua cơm hộ mình từ căng tin" |
| 📚 | Hỗ trợ học tập | "Giúp mình debug code Python" |
| 🏃 | Việc vặt & Hậu cần | "Đi lấy bưu kiện giúp mình" |
| 💻 | Công nghệ & Kỹ thuật số | "Giúp mình cài đặt laptop" |
| 🎨 | Sáng tạo & Thiết kế | "Thiết kế poster cho CLB mình" |
| ❓ | Khác | Tất cả mọi thứ khác! |

---

## 🔒 Bảo mật

- 🔐 Firebase Auth bắt buộc cho tất cả thao tác
- 🛡️ Firestore security rules thực thi quyền truy cập theo user
- 🚫 Người dùng chỉ có thể chỉnh sửa nhiệm vụ/hồ sơ của chính mình
- 📝 Tất cả ghi vào Firestore đều qua các phương thức service đã được kiểm tra

---

## 📄 Giấy phép

Dự án được xây dựng cho cộng đồng **PKA**.

---

<div align="center">

**Được xây dựng với 🧡 tại PKA**

*Vì mỗi campus đều cần những người anh hùng của mình* 🦸

</div>
