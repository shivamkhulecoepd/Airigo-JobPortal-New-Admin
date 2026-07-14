import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airigo_jobportal/models/notification_model.dart';
import 'package:airigo_jobportal/services/api/notification_service.dart';
import 'package:airigo_jobportal/core/service_locator.dart';
import 'package:airigo_jobportal/services/notification_manager.dart';

final recruiterNotificationsProvider =
    AsyncNotifierProvider<RecruiterNotificationsNotifier, List<NotificationModel>>(
  () => RecruiterNotificationsNotifier(),
);

class RecruiterNotificationsNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  late final NotificationService _notificationService;

  @override
  Future<List<NotificationModel>> build() async {
    _notificationService = getIt<NotificationService>();
    // Register the refresh callback for this provider
    NotificationProvidersContainer().setNotificationRefreshCallbacks(
      refreshAll: () => refreshNotifications(),
      refreshRecruiter: () => refreshNotifications(),
      refreshJobseeker: () {
        // Do nothing for jobseeker-specific refresh in this provider
      },
    );
    return await fetchRecruiterNotifications();
  }

  Future<List<NotificationModel>> fetchRecruiterNotifications() async {
    try {
      // Fetch unarchived recruiter-specific notifications
      final unarchivedResult = await _notificationService.getUserNotifications(
        page: 1,
        limit: 50,
        unreadOnly: false,
      );

      // Fetch archived recruiter-specific notifications
      final archivedResult = await _notificationService.getUserArchivedNotifications(
        page: 1,
        limit: 50,
      );

      List<NotificationModel> combinedNotifications = [];

      if (unarchivedResult['success'] == true) {
        final notifications = (unarchivedResult['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        combinedNotifications.addAll(notifications);
      }

      if (archivedResult['success'] == true) {
        final notifications = (archivedResult['notifications'] as List)
            .map((json) {
              final notif = NotificationModel.fromJson(json);
              return notif.copyWith(isArchived: true);
            })
            .toList();
        combinedNotifications.addAll(notifications);
      }

      // Filter for recruiter-specific notification types and deduplicate
      final uniqueNotifications = <String, NotificationModel>{};
      for (var notif in combinedNotifications) {
        if (notif.isRecruiterType) {
          uniqueNotifications[notif.id] = notif;
        }
      }

      final recruiterNotifications = uniqueNotifications.values.toList();
      recruiterNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return recruiterNotifications;
    } catch (e) {
      print('Error fetching recruiter notifications: $e');
      return [];
    }
  }

  Future<void> refreshNotifications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchRecruiterNotifications());
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

  int get unreadCount =>
      (state.value ?? []).where((n) => !n.isRead).length;

  NotificationModel? getMostRecentUnread() {
    final unreadList = (state.value ?? []).where((n) => !n.isRead).toList();
    if (unreadList.isEmpty) return null;
    
    return unreadList.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }
}

final recruiterUnreadNotifCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(recruiterNotificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead && !n.isArchived).length;
});