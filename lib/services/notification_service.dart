import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService - Quản lý thông báo đẩy
/// Hỗ trợ: Android, iOS, Windows, macOS, Linux
/// Web: Không hỗ trợ flutter_local_notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Khởi tạo notification service
  static Future<void> init() async {
    // Web không hỗ trợ local notifications
    if (kIsWeb) {
      debugPrint('NotificationService: Web platform - notifications disabled');
      return;
    }

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Windows settings
      const WindowsInitializationSettings windowsSettings =
          WindowsInitializationSettings(
        appName: 'SpendWise',
        appUserModelId: 'com.example.expense_manager',
        guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
      );

      // Linux settings
      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(
        defaultActionName: 'Open SpendWise',
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
        windows: windowsSettings,
        linux: linuxSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
          // TODO: Navigate to relevant screen based on payload
        },
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
      );

      _initialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Background notification handler (phải là top-level function)
  @pragma('vm:entry-point')
  static void _onBackgroundNotification(NotificationResponse details) {
    debugPrint('Background notification: ${details.payload}');
  }

  /// Yêu cầu quyền thông báo (Android 13+, iOS)
  static Future<bool> requestPermissions() async {
    if (kIsWeb || !_initialized) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Hiển thị thông báo ngay lập tức
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'spendwise_alerts',
    String channelName = 'SpendWise Alerts',
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Alerts for budgets and recurring transactions',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Thông báo cảnh báo ngân sách
  static Future<void> showBudgetAlert({
    required int budgetId,
    required String categoryName,
    required double spentPercent,
  }) async {
    final isOverBudget = spentPercent >= 100;
    await showNotification(
      id: budgetId + 1000, // Offset để tránh trùng ID
      title: isOverBudget ? '⚠️ Vượt ngân sách!' : '📊 Sắp đạt giới hạn',
      body: isOverBudget
          ? 'Danh mục "$categoryName" đã vượt ${(spentPercent - 100).toStringAsFixed(0)}% ngân sách'
          : 'Danh mục "$categoryName" đã dùng ${spentPercent.toStringAsFixed(0)}% ngân sách',
      payload: 'budget:$budgetId',
      channelId: 'budget_alerts',
      channelName: 'Budget Alerts',
    );
  }

  /// Thông báo giao dịch định kỳ sắp đến hạn
  static Future<void> showRecurringReminder({
    required int recurringId,
    required String description,
    required double amount,
    required String type,
    required int daysUntil,
  }) async {
    final amountStr = _formatAmount(amount);
    final typeStr = type == 'income' ? 'thu' : 'chi';

    String title;
    String body;

    if (daysUntil == 0) {
      title = '🔔 Giao dịch định kỳ hôm nay';
      body = '$description: $amountStr ($typeStr)';
    } else if (daysUntil == 1) {
      title = '⏰ Nhắc nhở giao dịch định kỳ';
      body = '$description sẽ thực hiện ngày mai: $amountStr ($typeStr)';
    } else {
      title = '📅 Giao dịch định kỳ sắp đến';
      body = '$description còn $daysUntil ngày: $amountStr ($typeStr)';
    }

    await showNotification(
      id: recurringId + 2000, // Offset để tránh trùng ID
      title: title,
      body: body,
      payload: 'recurring:$recurringId',
      channelId: 'recurring_reminders',
      channelName: 'Recurring Reminders',
    );
  }

  /// Thông báo mục tiêu tiết kiệm đạt được
  static Future<void> showSavingsGoalAchieved({
    required int goalId,
    required String goalName,
    required double targetAmount,
  }) async {
    await showNotification(
      id: goalId + 3000,
      title: '🎉 Đạt mục tiêu tiết kiệm!',
      body: 'Chúc mừng! Bạn đã đạt mục tiêu "$goalName" với ${_formatAmount(targetAmount)}',
      payload: 'goal:$goalId',
      channelId: 'achievements',
      channelName: 'Achievements',
    );
  }

  /// Hủy thông báo theo ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _notifications.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  /// Hủy tất cả thông báo
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb || !_initialized) return;
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  /// Format số tiền gọn
  static String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}tỷ đ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k đ';
    }
    return '${amount.toStringAsFixed(0)} đ';
  }
}
