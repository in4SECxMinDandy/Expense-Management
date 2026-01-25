# Expense Management - Ứng dụng Quản lý Chi tiêu Cá nhân

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite"/>
</p>

## Giới thiệu

**Expense Management** là ứng dụng quản lý tài chính cá nhân đa nền tảng được xây dựng bằng Flutter, giúp người dùng theo dõi thu nhập, chi tiêu, lập ngân sách và đạt được mục tiêu tiết kiệm. Ứng dụng hỗ trợ giao diện tiếng Việt và có thiết kế hiện đại theo phong cách iOS.

## Tính năng chính

### Quản lý Giao dịch
- Thêm, sửa, xóa giao dịch thu nhập và chi tiêu
- Phân loại giao dịch theo danh mục tùy chỉnh
- Đính kèm hóa đơn/ảnh chụp cho giao dịch
- Ghi chú chi tiết cho từng giao dịch
- Lọc giao dịch theo ngày, tuần, tháng, năm

### Quản lý Danh mục
- Tạo danh mục thu nhập và chi tiêu riêng biệt
- Tùy chỉnh icon cho từng danh mục
- Phân loại linh hoạt theo nhu cầu cá nhân

### Quản lý Ngân sách
- Thiết lập ngân sách hàng tháng cho từng danh mục
- Theo dõi tiến độ chi tiêu so với ngân sách
- Cảnh báo khi chi tiêu gần đạt hoặc vượt ngân sách

### Mục tiêu Tiết kiệm
- Đặt mục tiêu tiết kiệm với số tiền cụ thể
- Theo dõi tiến độ đạt mục tiêu
- Động lực tiết kiệm với giao diện trực quan

### Giao dịch Định kỳ
- Tự động tạo giao dịch lặp lại (tiền thuê nhà, lương, hóa đơn...)
- Tùy chỉnh chu kỳ lặp lại

### Ví điện tử
- Quản lý nhiều ví/tài khoản khác nhau
- Theo dõi số dư từng ví

### Báo cáo & Thống kê
- Biểu đồ chi tiêu theo thời gian (Line Chart)
- Thống kê thu nhập, chi tiêu, tiết kiệm
- Lọc báo cáo theo tháng/năm
- Phân tích chi tiêu theo danh mục

### Phân tích AI
- Insights thông minh về thói quen chi tiêu
- Gợi ý cải thiện tài chính cá nhân

### Xuất dữ liệu
- Xuất báo cáo ra file CSV
- Xuất báo cáo ra file PDF
- Chia sẻ báo cáo qua các ứng dụng khác

### Thông báo
- Nhắc nhở thanh toán hóa đơn
- Cảnh báo ngân sách

### Giao diện
- Hỗ trợ Dark Mode và Light Mode
- Thiết kế hiện đại theo phong cách iOS
- Giao diện hoàn toàn bằng tiếng Việt
- Responsive trên nhiều kích thước màn hình

### Xác thực
- Đăng ký và đăng nhập tài khoản
- Bảo mật dữ liệu người dùng

## Cấu trúc dự án

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart          # Định nghĩa theme ứng dụng
│   └── widgets/
│       └── ios_card.dart           # Widget card theo phong cách iOS
├── models/
│   ├── transaction.dart            # Model giao dịch
│   ├── category.dart               # Model danh mục
│   ├── budget.dart                 # Model ngân sách
│   ├── savings_goal.dart           # Model mục tiêu tiết kiệm
│   ├── recurring_transaction.dart  # Model giao dịch định kỳ
│   ├── wallet.dart                 # Model ví
│   ├── user.dart                   # Model người dùng
│   └── ai_insight.dart             # Model phân tích AI
├── providers/
│   ├── transaction_provider.dart   # State management giao dịch
│   ├── category_provider.dart      # State management danh mục
│   ├── budget_provider.dart        # State management ngân sách
│   ├── savings_goal_provider.dart  # State management mục tiêu
│   ├── recurring_provider.dart     # State management giao dịch định kỳ
│   ├── wallet_provider.dart        # State management ví
│   ├── ai_insight_provider.dart    # State management AI insights
│   ├── theme_provider.dart         # State management theme
│   └── expense_filter_provider.dart# State management bộ lọc
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart       # Màn hình đăng nhập
│   │   └── register_screen.dart    # Màn hình đăng ký
│   ├── settings/
│   │   ├── category_settings_screen.dart    # Cài đặt danh mục
│   │   ├── budget_settings_screen.dart      # Cài đặt ngân sách
│   │   ├── savings_goals_screen.dart        # Mục tiêu tiết kiệm
│   │   ├── recurring_settings_screen.dart   # Giao dịch định kỳ
│   │   ├── wallet_settings_screen.dart      # Cài đặt ví
│   │   ├── ai_insights_screen.dart          # Phân tích AI
│   │   └── profile_edit_screen.dart         # Chỉnh sửa hồ sơ
│   ├── dashboard_screen.dart       # Màn hình tổng quan
│   ├── transactions_screen.dart    # Danh sách giao dịch
│   ├── transaction_detail_screen.dart # Chi tiết giao dịch
│   ├── reports_screen.dart         # Báo cáo & thống kê
│   └── settings_screen.dart        # Màn hình cài đặt
├── services/
│   ├── auth_service.dart           # Xử lý xác thực
│   ├── ai_analysis_service.dart    # Phân tích AI
│   ├── csv_service.dart            # Xuất file CSV
│   ├── pdf_service.dart            # Xuất file PDF
│   └── notification_service.dart   # Thông báo
├── database_helper.dart            # Quản lý cơ sở dữ liệu SQLite
└── main.dart                       # Entry point
```

## Công nghệ sử dụng

| Công nghệ | Mô tả |
|-----------|-------|
| **Flutter** | Framework xây dựng ứng dụng đa nền tảng |
| **Dart** | Ngôn ngữ lập trình |
| **Provider** | State management |
| **SQLite** | Cơ sở dữ liệu local (mobile/desktop) |
| **Hive** | Cơ sở dữ liệu local (web) |
| **fl_chart** | Thư viện biểu đồ |
| **intl** | Hỗ trợ đa ngôn ngữ và định dạng |
| **pdf/printing** | Xuất file PDF |
| **csv** | Xuất file CSV |
| **image_picker** | Chọn ảnh hóa đơn |
| **flutter_local_notifications** | Thông báo local |
| **shared_preferences** | Lưu trữ cài đặt |
| **flutter_secure_storage** | Lưu trữ bảo mật |

## Yêu cầu hệ thống

- Flutter SDK >= 3.10.7
- Dart SDK >= 3.10.7
- Android SDK (cho Android)
- Xcode (cho iOS/macOS)
- Visual Studio (cho Windows)

## Cài đặt và Chạy

### 1. Clone repository

```bash
git clone https://github.com/in4SECxMinDandy/Expense-Management
cd Expense Management
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Chạy ứng dụng

```bash
# Chạy trên thiết bị/emulator mặc định
flutter run

# Chạy trên Android
flutter run -d android

# Chạy trên iOS
flutter run -d ios

# Chạy trên Windows
flutter run -d windows

# Chạy trên Web
flutter run -d chrome
```

### 4. Build ứng dụng

```bash
# Build APK cho Android
flutter build apk --release

# Build cho iOS
flutter build ios --release

# Build cho Windows
flutter build windows --release

# Build cho Web
flutter build web --release
```

## Nền tảng hỗ trợ

| Nền tảng | Trạng thái |
|----------|------------|
| Android | Hỗ trợ |
| iOS | Hỗ trợ |
| Windows | Hỗ trợ |
| macOS | Hỗ trợ |
| Linux | Hỗ trợ |
| Web | Hỗ trợ |

## Screenshots

*Thêm screenshots của ứng dụng tại đây*

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

**Expense Management** - Quản lý chi tiêu thông minh, tiết kiệm hiệu quả!
#   E x p e n s e - M a n a g e m e n t  
 