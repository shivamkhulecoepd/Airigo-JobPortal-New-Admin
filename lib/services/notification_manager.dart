import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:airigo_jobportal/services/firebase_messaging_service.dart';
import 'package:airigo_jobportal/services/api/notification_service.dart';
import 'package:airigo_jobportal/core/service_locator.dart';
import 'package:flutter/foundation.dart';

// Global container to hold providers references for updating when new notifications arrive
class NotificationProvidersContainer {
  static final NotificationProvidersContainer _instance = NotificationProvidersContainer._internal();
  factory NotificationProvidersContainer() => _instance;
  NotificationProvidersContainer._internal();

  // Lists of callbacks to allow multiple providers to register
  final List<VoidCallback> _refreshAllCallbacks = [];
  final List<VoidCallback> _refreshRecruiterCallbacks = [];
  final List<VoidCallback> _refreshJobseekerCallbacks = [];
  final List<VoidCallback> _refreshAdminCallbacks = [];

  void setNotificationRefreshCallbacks({
    VoidCallback? refreshAll,
    VoidCallback? refreshRecruiter,
    VoidCallback? refreshJobseeker,
    VoidCallback? refreshAdmin,
  }) {
    if (refreshAll != null && !_refreshAllCallbacks.contains(refreshAll)) {
      _refreshAllCallbacks.add(refreshAll);
    }
    if (refreshRecruiter != null && !_refreshRecruiterCallbacks.contains(refreshRecruiter)) {
      _refreshRecruiterCallbacks.add(refreshRecruiter);
    }
    if (refreshJobseeker != null && !_refreshJobseekerCallbacks.contains(refreshJobseeker)) {
      _refreshJobseekerCallbacks.add(refreshJobseeker);
    }
    if (refreshAdmin != null && !_refreshAdminCallbacks.contains(refreshAdmin)) {
      _refreshAdminCallbacks.add(refreshAdmin);
    }
  }

  void registerRefreshRecruiter(VoidCallback callback) {
    if (!_refreshRecruiterCallbacks.contains(callback)) {
      _refreshRecruiterCallbacks.add(callback);
    }
  }

  void registerRefreshJobseeker(VoidCallback callback) {
    if (!_refreshJobseekerCallbacks.contains(callback)) {
      _refreshJobseekerCallbacks.add(callback);
    }
  }

  void registerRefreshAdmin(VoidCallback callback) {
    if (!_refreshAdminCallbacks.contains(callback)) {
      _refreshAdminCallbacks.add(callback);
    }
  }

  /// Convenience method for FCM service
  void refreshAll() {
    triggerNotificationRefresh();
  }

  void triggerNotificationRefresh({String? userType}) {
    debugPrint('Triggering notification refresh for userType: $userType');
    
    // Trigger specific callbacks
    if (userType == 'recruiter') {
      for (var cb in _refreshRecruiterCallbacks) { cb(); }
    } else if (userType == 'jobseeker') {
      for (var cb in _refreshJobseekerCallbacks) { cb(); }
    } else if (userType == 'admin') {
      for (var cb in _refreshAdminCallbacks) { cb(); }
    } else {
      // Refresh everything if userType is null or 'all'
      for (var cb in _refreshAllCallbacks) { cb(); }
      for (var cb in _refreshRecruiterCallbacks) { cb(); }
      for (var cb in _refreshJobseekerCallbacks) { cb(); }
      for (var cb in _refreshAdminCallbacks) { cb(); }
    }
  }
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = getIt<NotificationService>();
  StreamSubscription? _tokenRefreshSubscription;

  Future<void> initialize() async {
    debugPrint('NotificationManager: Initializing...');
    
    // Listen for token refreshes
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
    
    // Get and store current token
    final token = await FirebaseMessagingService.getToken();
    if (token != null) {
      debugPrint('NotificationManager: Initial token found: ${token.substring(0, 20)}...');
      await _storeTokenOnServer(token);
    } else {
      debugPrint('NotificationManager: No initial token found');
    }
    
    debugPrint('NotificationManager: Initialization complete');
  }

  void _onTokenRefresh(String token) async {
    await _storeTokenOnServer(token);
  }

  Future<void> _storeTokenOnServer(String fcmToken) async {
    try {
      await _notificationService.storeFcmToken(fcmToken);
      debugPrint('Successfully stored FCM token on server: $fcmToken');
    } catch (e) {
      debugPrint('Failed to store FCM token on server: $e');
    }
  }

  Future<void> subscribeToRecruiterTopics(String userId) async {
    // Subscribe to recruiter-specific topics
    await FirebaseMessagingService.subscribeToTopic('recruiter_$userId');
    await FirebaseMessagingService.subscribeToTopic('recruiter_notifications');
    await FirebaseMessagingService.subscribeToTopic('all_notifications');
  }

  Future<void> subscribeToJobseekerTopics(String userId) async {
    // Subscribe to jobseeker-specific topics
    await FirebaseMessagingService.subscribeToTopic('jobseeker_$userId');
    await FirebaseMessagingService.subscribeToTopic('jobseeker_notifications');
    await FirebaseMessagingService.subscribeToTopic('all_notifications');
  }

  Future<void> subscribeToAdminTopics() async {
    // Subscribe to admin-specific topics
    await FirebaseMessagingService.subscribeToTopic('admin_notifications');
    await FirebaseMessagingService.subscribeToTopic('all_notifications');
  }

  Future<void> unsubscribeFromTopics(String userId, String userType) async {
    if (userType == 'recruiter') {
      await FirebaseMessagingService.unsubscribeFromTopic('recruiter_$userId');
      await FirebaseMessagingService.unsubscribeFromTopic('recruiter_notifications');
    } else if (userType == 'jobseeker') {
      await FirebaseMessagingService.unsubscribeFromTopic('jobseeker_$userId');
      await FirebaseMessagingService.unsubscribeFromTopic('jobseeker_notifications');
    }
    await FirebaseMessagingService.unsubscribeFromTopic('all_notifications');
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
  }
}