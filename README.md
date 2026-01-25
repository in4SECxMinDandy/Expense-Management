# Expense Management

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue?style=for-the-badge" alt="Platform"/>
</p>

<p align="center">
  <b>Ứng dụng Quản lý Chi tiêu Cá nhân đa nền tảng</b>
</p>

---

## Giới thiệu

**Expense Management** là ứng dụng quản lý tài chính cá nhân đa nền tảng được xây dựng bằng Flutter, giúp người dùng theo dõi thu nhập, chi tiêu, lập ngân sách và đạt được mục tiêu tiết kiệm. Ứng dụng hỗ trợ giao diện tiếng Việt và có thiết kế hiện đại theo phong cách iOS.

## Tính năng chính

| Tính năng | Mô tả |
|-----------|-------|
| **Quản lý Giao dịch** | Thêm, sửa, xóa giao dịch thu nhập và chi tiêu với hóa đơn đính kèm |
| **Quản lý Danh mục** | Tạo danh mục tùy chỉnh với icon riêng |
| **Quản lý Ngân sách** | Thiết lập và theo dõi ngân sách hàng tháng |
| **Mục tiêu Tiết kiệm** | Đặt và theo dõi mục tiêu tiết kiệm |
| **Giao dịch Định kỳ** | Tự động tạo giao dịch lặp lại |
| **Ví điện tử** | Quản lý nhiều ví/tài khoản khác nhau |
| **Báo cáo & Thống kê** | Biểu đồ chi tiêu, phân tích theo danh mục |
| **Phân tích AI** | Insights thông minh về thói quen chi tiêu |
| **Xuất dữ liệu** | Xuất báo cáo CSV/PDF |
| **Dark/Light Mode** | Hỗ trợ cả hai chế độ giao diện |

## Cấu trúc dự án

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       └── ios_card.dart
├── models/
│   ├── transaction.dart
│   ├── category.dart
│   ├── budget.dart
│   ├── savings_goal.dart
│   ├── recurring_transaction.dart
│   ├── wallet.dart
│   ├── user.dart
│   └── ai_insight.dart
├── providers/
│   ├── transaction_provider.dart
│   ├── category_provider.dart
│   ├── budget_provider.dart
│   ├── savings_goal_provider.dart
│   ├── recurring_provider.dart
│   ├── wallet_provider.dart
│   ├── ai_insight_provider.dart
│   ├── theme_provider.dart
│   └── expense_filter_provider.dart
├── screens/
│   ├── auth/
│   ├── settings/
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── reports_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── ai_analysis_service.dart
│   ├── csv_service.dart
│   ├── pdf_service.dart
│   └── notification_service.dart
├── database_helper.dart
└── main.dart
```

## Công nghệ sử dụng

| Công nghệ | Mô tả |
|-----------|-------|
| **Flutter** | Framework xây dựng ứng dụng đa nền tảng |
| **Dart** | Ngôn ngữ lập trình |
| **Provider** | State management |
| **SQLite/Hive** | Cơ sở dữ liệu local |
| **fl_chart** | Thư viện biểu đồ |
| **pdf/printing** | Xuất file PDF |
| **flutter_local_notifications** | Thông báo local |

## Yêu cầu hệ thống

- Flutter SDK >= 3.10.7
- Dart SDK >= 3.10.7
- Android SDK (cho Android)
- Xcode (cho iOS/macOS)
- Visual Studio (cho Windows)

## Cài đặt và Chạy

### 1. Clone repository

```bash
git clone https://github.com/in4SECxMinDandy/Expense-Management.git
cd Expense-Management
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Chạy ứng dụng

```bash
# Chạy trên thiết bị mặc định
flutter run

# Chạy trên nền tảng cụ thể
flutter run -d android
flutter run -d ios
flutter run -d windows
flutter run -d chrome
```

### 4. Build ứng dụng

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

## Nền tảng hỗ trợ

| Nền tảng | Trạng thái |
|----------|:----------:|
| Android | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Web | ✅ |

## Demo 

![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)
![alt text](image-4.png)
![alt text](image-5.png)
![alt text](image-6.png)
![alt text](image-7.png)
![alt text](image-8.png)

## Đóng góp

Mọi đóng góp đều được hoan nghênh! Vui lòng:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/TinhNangMoi`)
3. Commit thay đổi (`git commit -m 'Thêm tính năng mới'`)
4. Push lên branch (`git push origin feature/TinhNangMoi`)
5. Tạo Pull Request

## Giấy phép

Dự án này được phát hành dưới giấy phép MIT.

## Liên hệ

Nếu bạn có câu hỏi hoặc góp ý, vui lòng tạo issue trên GitHub.

---

<p align="center">
  <b>Expense Management</b> - Quản lý chi tiêu thông minh, tiết kiệm hiệu quả!
</p>
