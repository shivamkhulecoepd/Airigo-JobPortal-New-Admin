import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airigo_jobportal/core/providers/notifications_provider.dart';
import 'package:airigo_jobportal/core/providers/jobseeker_notification_provider.dart';
import 'package:airigo_jobportal/core/providers/recruiter_notification_provider.dart';
import 'package:airigo_jobportal/core/providers/admin_notification_provider.dart';
import 'package:airigo_jobportal/models/notification_model.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum NotificationViewType { all, jobseeker, recruiter, admin }

class NotificationScreen extends ConsumerStatefulWidget {
  final NotificationViewType viewType;

  const NotificationScreen({
    super.key,
    this.viewType = NotificationViewType.all,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Force a refresh when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getNotifier().refreshNotifications();
    });
  }

  dynamic _getNotifier() {
    switch (widget.viewType) {
      case NotificationViewType.jobseeker:
        return ref.read(jobseekerNotificationsProvider.notifier);
      case NotificationViewType.recruiter:
        return ref.read(recruiterNotificationsProvider.notifier);
      case NotificationViewType.admin:
        return ref.read(adminNotificationsProvider.notifier);
      case NotificationViewType.all:
      return ref.read(notificationsProvider.notifier);
    }
  }

  AsyncValue<List<NotificationModel>> _getNotifications() {
    switch (widget.viewType) {
      case NotificationViewType.jobseeker:
        return ref.watch(jobseekerNotificationsProvider);
      case NotificationViewType.recruiter:
        return ref.watch(recruiterNotificationsProvider);
      case NotificationViewType.admin:
        return ref.watch(adminNotificationsProvider);
      case NotificationViewType.all:
      return ref.watch(notificationsProvider);
    }
  }

  int _getUnreadCount() {
    switch (widget.viewType) {
      case NotificationViewType.jobseeker:
        return ref.watch(jobseekerUnreadNotifCountProvider);
      case NotificationViewType.recruiter:
        return ref.watch(recruiterUnreadNotifCountProvider);
      case NotificationViewType.admin:
        return ref.watch(adminUnreadNotifCountProvider);
      case NotificationViewType.all:
      return ref.watch(unreadNotifCountProvider);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NotificationModel> _getFilteredNotifications(
    List<NotificationModel> allNotifications,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 0: // All (not archived)
        return allNotifications.where((n) => !n.isArchived).toList();
      case 1: // Unread (not archived)
        return allNotifications
            .where((n) => !n.isRead && !n.isArchived)
            .toList();
      case 2: // Archived
        return allNotifications.where((n) => n.isArchived).toList();
      default:
        return [];
    }
  }

  Future<void> _markAllRead() async {
    await _getNotifier().markAllAsRead();
  }

  Future<void> _markRead(NotificationModel notification) async {
    await _getNotifier().markAsRead(notification.id);
  }

  void _archiveNotif(NotificationModel notification) {
    _getNotifier().archiveNotification(notification.id);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _getUnreadCount();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: false,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: theme.colorScheme.onSurface,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.transparent,
                // forceMaterialTransparency: true,
                elevation: 1,
                shadowColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,

                automaticallyImplyLeading: false,

                title: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                actions: [
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: EdgeInsets.only(left: 16.w, right: 8.w, top: 12.h),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             IconButton(
              //               onPressed: () => Navigator.pop(context),
              //               icon: const Icon(Icons.arrow_back_ios),
              //               padding: EdgeInsets.zero,
              //               constraints: const BoxConstraints(),
              //             ),
              //             if (unreadCount > 0)
              //               TextButton(
              //                 onPressed: _markAllRead,
              //                 child: Text(
              //                   'Mark all read',
              //                   style: TextStyle(
              //                     fontSize: 13.sp,
              //                     color: theme.colorScheme.primary,
              //                     fontWeight: FontWeight.w600,
              //                   ),
              //                 ),
              //               ),
              //           ],
              //         ),
              //         SizedBox(height: 8.h),
              //         Text(
              //           'Notifications',
              //           style: TextStyle(
              //             fontSize: 28.sp,
              //             fontWeight: FontWeight.bold,
              //             color: theme.colorScheme.onSurface,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    tabs: [
                      Tab(text: 'All'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Unread'),
                            if (unreadCount > 0) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(text: 'Archived'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: List.generate(
              3,
              (index) => _buildNotificationList(theme, index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(ThemeData theme, int tabIndex) {
    final notificationsAsync = _getNotifications();

    return notificationsAsync.when(
      data: (notifications) {
        final filteredList = _getFilteredNotifications(notifications, tabIndex);

        return RefreshIndicator(
          onRefresh: () async => _getNotifier().refreshNotifications(),
          child: filteredList.isEmpty
              ? _buildEmptyState(theme, tabIndex)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) =>
                      _notificationCard(theme, filteredList[index]),
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(theme, error),
    );
  }

  Widget _buildEmptyState(ThemeData theme, int tabIndex) {
    IconData icon;
    String title;

    if (tabIndex == 2) {
      icon = Icons.archive_outlined;
      title = 'No archived notifications';
    } else {
      icon = Icons.notifications_off_outlined;
      title = 'No notifications found';
    }

    return ListView(
      children: [
        SizedBox(height: 100.h),
        Center(
          child: Column(
            children: [
              Icon(
                icon,
                size: 64.sp,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16),
          Text('Failed to load notifications'),
          TextButton(
            onPressed: () => _getNotifier().refreshNotifications(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(ThemeData theme, NotificationModel notification) {
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade400,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Icon(Icons.archive_outlined, color: Colors.white, size: 24.sp),
      ),
      onDismissed: (_) => _archiveNotif(notification),
      child: GestureDetector(
        onTap: () => _markRead(notification),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? Colors.white10 : Colors.grey.shade100)
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: notification.type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  notification.type.icon,
                  color: notification.type.color,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => true;
}
