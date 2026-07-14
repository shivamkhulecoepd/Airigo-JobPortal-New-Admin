import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:airigo_jobportal/core/service_locator.dart';
import 'package:airigo_jobportal/services/api/notification_service.dart';
import 'package:airigo_jobportal/services/notification_manager.dart';

// Import background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Firebase Messaging background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      // Request permission for iOS and Android 13+
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      debugPrint('User granted permission: ${settings.authorizationStatus}');
      
      // Initialize local notifications plugin
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings = 
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      
      // Create notification channel for Android
      await _createNotificationChannel();
      
      _isInitialized = true;
      // Setup listeners
      _setupForegroundMessageListener();
      
      debugPrint('Firebase Messaging Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }
  
  /// Create notification channel for Android 8.0+
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'airigo_notification_channel',
      'Airigo Notification Channel',
      description: 'Channel for Airigo app notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );
    
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    debugPrint('Notification channel created');
  }
  
  /// Handle notification tap response
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation or other actions based on notification data
  }
  
  /// Handle notification tap from remote message
  static void _onNotificationTapFromRemoteMessage(RemoteMessage message) {
    // Handle navigation based on notification type
    final data = message.data;
    final notificationType = data['type'] ?? '';
    
    debugPrint('Notification tapped with type: $notificationType');
    debugPrint('Notification data: $data');
    // You can implement navigation logic based on notification type
    // For example, navigate to specific screens based on the notification
  }

  /// Handle foreground messages
  static void _setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      _showLocalNotification(message);
      // Refresh notification providers when new notification arrives
      _refreshNotificationProviders();
    });

    // Handle notification tap (app opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Background message opened app: ${message.notification?.title}');
      _onNotificationTapFromRemoteMessage(message);
      // Refresh notification providers when new notification arrives
      _refreshNotificationProviders();
    });
  }

  static void _showLocalNotification(RemoteMessage message) async {
    if (message.notification != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'airigo_notification_channel',
        'Airigo Notification Channel',
        channelDescription: 'Channel for Airigo app notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformChannelSpecifics = 
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotificationsPlugin.show(
        0,
        message.notification!.title,
        message.notification!.body,
        platformChannelSpecifics,
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification type
    final data = message.data;
    final notificationType = data['type'] ?? '';
    
    // You can implement navigation logic based on notification type
    // For example, navigate to specific screens based on the notification
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Add the missing method
  static Stream<String?> getTokenStream() {
    return _firebaseMessaging.onTokenRefresh.map((event) => event);
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  static Future<void> storeTokenOnServer(String fcmToken) async {
    final notificationService = getIt<NotificationService>();
    await notificationService.storeFcmToken(fcmToken);
  }

  // New method to refresh notification providers when new notifications arrive
  static void _refreshNotificationProviders() {
    // Trigger refresh via the NotificationProvidersContainer
    NotificationProvidersContainer().triggerNotificationRefresh();
    debugPrint('New notification received, notification providers refresh triggered');
  }
}