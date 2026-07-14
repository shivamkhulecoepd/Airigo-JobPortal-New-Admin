import 'package:airigo_jobportal/services/notification_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airigo_jobportal/models/notification_model.dart';
import 'package:airigo_jobportal/services/api/notification_service.dart';
import 'package:airigo_jobportal/core/service_locator.dart';

/// Provider that fetches all notifications for the current admin user
/// and filters them to only return admin-relevant types.
final adminNotificationsProvider =
    AsyncNotifierProvider<AdminNotificationsNotifier, List<NotificationModel>>(
  () => AdminNotificationsNotifier(),
);

class AdminNotificationsNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  late final NotificationService _notificationService;

  @override
  Future<List<NotificationModel>> build() async {
    _notificationService = getIt<NotificationService>();
    
    // Register the refresh callback with the notification manager
    NotificationProvidersContainer().setNotificationRefreshCallbacks(
      refreshAll: () => refreshNotifications(),
      refreshAdmin: () => refreshNotifications(),
    );
    
    return await fetchAdminNotifications();
  }

  Future<List<NotificationModel>> fetchAdminNotifications() async {
    try {
      final unarchivedResult = await _notificationService.getUserNotifications(
        page: 1,
        limit: 100,
        unreadOnly: false,
      );

      final archivedResult =
          await _notificationService.getUserArchivedNotifications(
        page: 1,
        limit: 50,
      );

      List<NotificationModel> combined = [];

      if (unarchivedResult['success'] == true) {
        final list = (unarchivedResult['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        combined.addAll(list);
      }

      if (archivedResult['success'] == true) {
        final list = (archivedResult['notifications'] as List).map((json) {
          return NotificationModel.fromJson(json).copyWith(isArchived: true);
        }).toList();
        combined.addAll(list);
      }

      // Deduplicate by ID
      final unique = <String, NotificationModel>{};
      for (final n in combined) {
        unique[n.id] = n;
      }

      // Filter to admin-relevant types only
      final adminNotifs = unique.values
          .where((n) => n.isAdminType || n.isAdminActionType)
          .toList();

      adminNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return adminNotifs;
    } catch (e) {
      return [];
    }
  }

  Future<void> refreshNotifications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchAdminNotifications());
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

  Future<void> archiveNotification(String notificationId) async {
    final result =
        await _notificationService.archiveNotification(notificationId);
    if (result['success'] == true) {
      state = AsyncValue.data(
        (state.value ?? [])
            .map((n) =>
                n.id == notificationId ? n.copyWith(isArchived: true) : n)
            .toList(),
      );
    }
  }
}

/// Derived provider: unread count for the admin notification badge.
final adminUnreadNotifCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(adminNotificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead && !n.isArchived).length;
});
