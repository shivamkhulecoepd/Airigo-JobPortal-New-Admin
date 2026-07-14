import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service_locator.dart';
import '../../services/api/notification_service.dart';

// Push Notification Data Model
class PushNotification {
  final String? title;
  final String? body;
  final String? type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  PushNotification({
    this.title,
    this.body,
    this.type,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Push Notifications Service
class PushNotificationService {
  final NotificationService _notificationService;

  PushNotificationService(this._notificationService);

  // Method to store FCM token
  Future<bool> storeFcmToken(String fcmToken, {String deviceType = 'mobile'}) async {
    try {
      final result = await _notificationService.storeFcmToken(fcmToken, deviceType: deviceType);
      return result['success'] ?? false;
    } catch (e) {
      print('Error storing FCM token: $e');
      return false;
    }
  }

  // Method to remove FCM token
  Future<bool> removeFcmToken(String fcmToken) async {
    try {
      final result = await _notificationService.removeFcmToken(fcmToken);
      return result['success'] ?? false;
    } catch (e) {
      print('Error removing FCM token: $e');
      return false;
    }
  }

  // Method to send test notification
  Future<bool> sendTestNotification({String? title, String? body, Map<String, dynamic>? data}) async {
    try {
      final result = await _notificationService.sendTestNotification(title: title, body: body, data: data);
      return result['success'] ?? false;
    } catch (e) {
      print('Error sending test notification: $e');
      return false;
    }
  }

  // Method to get user tokens
  Future<List<dynamic>?> getUserTokens() async {
    try {
      final result = await _notificationService.getUserTokens();
      return result['tokens'] as List<dynamic>?;
    } catch (e) {
      print('Error getting user tokens: $e');
      return null;
    }
  }
}

// Push Notifications Provider using AsyncNotifier pattern like other providers
final pushNotificationsProvider = AsyncNotifierProvider<PushNotificationsNotifier, bool>(() => PushNotificationsNotifier());

class PushNotificationsNotifier extends AsyncNotifier<bool> {
  final PushNotificationService _service;
  
  PushNotificationsNotifier() : _service = PushNotificationService(getIt<NotificationService>());

  @override
  Future<bool> build() async {
    // Initialization happens automatically
    return false; // Initial state
  }

  Future<bool> storeFcmToken(String fcmToken, {String deviceType = 'mobile'}) async {
    return await _service.storeFcmToken(fcmToken, deviceType: deviceType);
  }

  Future<bool> removeFcmToken(String fcmToken) async {
    return await _service.removeFcmToken(fcmToken);
  }

  Future<bool> sendTestNotification({String? title, String? body, Map<String, dynamic>? data}) async {
    return await _service.sendTestNotification(title: title, body: body, data: data);
  }

  Future<List<dynamic>?> getUserTokens() async {
    return await _service.getUserTokens();
  }
}