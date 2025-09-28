import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:tdev_flutter_firebase/src/notification/error.dart';


// --------------------------------------------------------------------------
// Hàm xử lý thông báo chạy nền (Top-level function)
// Cần phải độc lập (static/top-level) để chạy được trong isolate riêng
// --------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Đảm bảo Firebase được khởi tạo nếu chưa có (cần thiết cho các thao tác DB)
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("🔔 [Background] Handled message: ${message.messageId}");
    print("🔔 [Background] Data: ${message.data}");
  }
  // Thêm logic xử lý nền tại đây (ví dụ: cập nhật Realtime DB)
}

// --------------------------------------------------------------------------
// Lớp Dịch vụ Chính
// --------------------------------------------------------------------------
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  // static final _localNotifications = FlutterLocalNotificationsPlugin(); // Kích hoạt nếu dùng Local Notif

  // Init ======================================================================
  /// Khởi tạo Firebase Messaging, yêu cầu quyền và thiết lập Listeners.
  static Future<void> init() async {
    try {
      // 1. Thiết lập trình xử lý thông báo nền
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Yêu cầu quyền thông báo
      await _requestPermission();

      // 3. Thiết lập các Listeners chính
      _setupListeners();

      // 4. Lấy Token lần đầu (nếu cần)
      final token = await _messaging.getToken();
      if (kDebugMode) print('🔔 FCM Token: $token');

    } catch (e) {
      throw NotificationException("Lỗi khi init NotificationService", e);
    }
  }

  // Permissions & Token =======================================================
  static Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      throw NotificationException("Không thể yêu cầu quyền thông báo", e);
    }
  }

  /// Lấy FCM Token hiện tại của thiết bị.
  static Future<String?> get token => _messaging.getToken();

  /// Stream: Lắng nghe khi Token của thiết bị bị thay đổi.
  static Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // Listeners =================================================================
  static void _setupListeners() {
    // 1. Ứng dụng ở Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('🔔 [Foreground] Message received: ${message.notification?.title}');
      // Thường hiển thị Local Notification ở đây
      _handleMessage(message);
    });

    // 2. Ứng dụng được mở từ trạng thái Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('🔔 [Background Open] App opened from message!');
      _handleMessageTap(message);
    });

    // 3. Lấy thông báo nếu ứng dụng mở từ trạng thái Terminated (Đóng hoàn toàn)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) print('🔔 [Terminated Open] App opened from initial message!');
        _handleMessageTap(message);
      }
    });
  }

  /// Hàm xử lý chung khi nhận được tin nhắn (Foreground)
  static void _handleMessage(RemoteMessage message) {
    // Logic chung khi nhận tin nhắn (ví dụ: hiển thị Toast, cập nhật UI)
  }

  /// Hàm xử lý khi người dùng chạm vào thông báo (dùng để điều hướng)
  static void _handleMessageTap(RemoteMessage message) {
    // Logic điều hướng (ví dụ: Navigator.push tới màn hình dựa trên message.data)
  }

  // Topic Subscriptions =======================================================
  /// Đăng ký thiết bị vào một chủ đề.
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      throw NotificationException("Không thể subscribe topic: $topic", e);
    }
  }

  /// Hủy đăng ký khỏi một chủ đề.
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      throw NotificationException("Không thể unsubscribe topic: $topic", e);
    }
  }
}