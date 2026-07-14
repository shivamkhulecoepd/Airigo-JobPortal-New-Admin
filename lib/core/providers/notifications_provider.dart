import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:airigo_jobportal/models/notification_model.dart';
import 'package:airigo_jobportal/services/api/notification_service.dart';
import 'package:airigo_jobportal/services/notification_manager.dart';
import 'package:airigo_jobportal/core/service_locator.dart';

// Provider for unread notification count
final unreadNotifCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  final count = notifications.when(
    data: (notifications) => notifications.where((n) => !n.isRead && !n.isArchived).length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
  return count;
});

// Main notifications provider
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  () => NotificationsNotifier(),
);

class NotificationsNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  late final NotificationService _notificationService;

  @override
  Future<List<NotificationModel>> build() async {
    _notificationService = getIt<NotificationService>();
    
    // Register the refresh callback with the notification manager
    NotificationProvidersContainer().setNotificationRefreshCallbacks(
      refreshAll: () => refreshNotifications(),
      refreshJobseeker: () => refreshNotifications(),
      refreshRecruiter: () => refreshNotifications(),
    );
    
    return await fetchNotifications();
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final unarchivedResult = await _notificationService.getUserNotifications(
        page: 1,
        limit: 50,
        unreadOnly: false,
      );
      
      final archivedResult = await _notificationService.getUserArchivedNotifications(
        page: 1,
        limit: 50,
      );

      List<NotificationModel> combinedNotifications = [];

      if (unarchivedResult['success'] == true) {
        final unarchivedList = (unarchivedResult['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        combinedNotifications.addAll(unarchivedList);
      }

      if (archivedResult['success'] == true) {
        final archivedList = (archivedResult['notifications'] as List)
            .map((json) {
              final notif = NotificationModel.fromJson(json);
              return notif.copyWith(isArchived: true);
            })
            .toList();
        combinedNotifications.addAll(archivedList);
      }

      final uniqueNotifications = <String, NotificationModel>{};
      for (var notif in combinedNotifications) {
        uniqueNotifications[notif.id] = notif;
      }

      final finalNotifications = uniqueNotifications.values.toList();
      finalNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return finalNotifications;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> refreshNotifications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchNotifications());
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final currentList = state.value ?? [];
    final updatedList = currentList
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    final previousState = state;
    state = AsyncValue.data(updatedList);

    final result = await _notificationService.markNotificationAsRead(notificationId);
    
    if (result['success'] != true) {
      // Rollback on failure
      state = previousState;
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final currentList = state.value ?? [];
    final updatedList = currentList
        .map((n) => n.copyWith(isRead: true))
        .toList();
    final previousState = state;
    state = AsyncValue.data(updatedList);

    final result = await _notificationService.markAllNotificationsAsRead();
    
    if (result['success'] != true) {
      // Rollback on failure
      state = previousState;
    }
  }

  Future<void> clearAllNotifications() async {
    state = const AsyncValue.data([]);
  }

  Future<void> archiveNotification(String notificationId) async {
    final result = await _notificationService.archiveNotification(notificationId);
    if (result['success'] == true) {
      state = AsyncValue.data(
        (state.value ?? []).map((n) => n.id == notificationId ? n.copyWith(isArchived: true) : n).toList()
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final result = await _notificationService.deleteNotification(notificationId);
    if (result['success'] == true) {
      state = AsyncValue.data(
        (state.value ?? []).where((n) => n.id != notificationId).toList()
      );
    }
  }
}