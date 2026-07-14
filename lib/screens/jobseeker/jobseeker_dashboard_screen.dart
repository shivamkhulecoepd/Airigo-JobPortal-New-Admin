import 'dart:developer';

import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/core/providers/applications_provider.dart';
import 'package:airigo_jobportal/core/providers/jobs_feed_provider.dart';
import 'package:airigo_jobportal/core/providers/jobseeker_notification_provider.dart';
import 'package:airigo_jobportal/models/user_model.dart';
import 'package:airigo_jobportal/core/providers/jobseeker_profile_provider.dart';
import 'package:airigo_jobportal/core/providers/latest_jobs_provider.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_applications_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/search_jobs_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/latest_jobs_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/top_company_jobs_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/empty_state.dart';
import 'package:airigo_jobportal/widgets/job_card_widget.dart';
import 'package:airigo_jobportal/widgets/shimmer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// ─── Import notification providers ───────────────────────────────────────────
import 'package:airigo_jobportal/core/providers/notifications_provider.dart';
// Removed import that doesn't exist: import 'package:airigo_jobportal/core/providers/jobseeker_notification_provider.dart';
import 'package:airigo_jobportal/screens/common/notification_screen.dart';
import 'package:airigo_jobportal/services/notification_manager.dart';

class JobseekerDashboardScreen extends ConsumerStatefulWidget {
  const JobseekerDashboardScreen({super.key});

  @override
  ConsumerState<JobseekerDashboardScreen> createState() =>
      _JobseekerDashboardScreenState();
}

class _JobseekerDashboardScreenState
    extends ConsumerState<JobseekerDashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load jobs feed on dashboard init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(jobsFeedProvider).hasValue) {
        ref.read(jobsFeedProvider.notifier).refresh();
      }

      // Pre-fetch profile data for job applications
      if (ref.read(jobseekerProfileProvider).profile == null) {
        ref.read(jobseekerProfileProvider.notifier).fetchProfile();
      }

      // Register for real-time notification refreshes - only refresh notifications
      NotificationProvidersContainer().registerRefreshJobseeker(
        () => ref
            .read(jobseekerNotificationsProvider.notifier)
            .refreshNotifications(),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refresh();
    }
  }

  Future<void> _refresh() async {
    // Refresh all data in parallel for better performance and responsiveness
    try {
      await Future.wait([
        // Refresh jobs feed
        ref.read(jobsFeedProvider.notifier).refresh(),

        // Refresh current user profile to get latest data
        ref.read(authStateProvider.notifier).refresh(),

        // Refresh applications
        ref.read(applicationsStateProvider.notifier).fetchMyApplications(),

        // Refresh notifications specifically
        ref
            .read(jobseekerNotificationsProvider.notifier)
            .refreshNotifications(),
      ]);
    } catch (e) {
      debugPrint('JobseekerDashboard: Refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final jobsAsync = ref.watch(jobsFeedProvider);
    final isDark = context.isDark;
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    // Watch notification count
    // final notificationCount = ref.watch(unreadNotifCountProvider);
    final notificationCount = ref.watch(jobseekerUnreadNotifCountProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        backgroundColor: theme.scaffoldBackgroundColor,
        child: CustomScrollView(
          slivers: [
            // --- Header & Search Section ---
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: mq.padding.top + 8.h,
                  bottom: 4.h,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                ),
                child: _buildLogoNotification(isDark, user, notificationCount),
              ),
            ),

            // --- Top Companies Carousel ---
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  children: [
                    _buildSearchBar(isDark),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildBox(
                            "assets/icons/Latest-Jobs.png",
                            "Latest Jobs",
                            Colors.blue,
                            LatestJobsScreen(),
                          ),
                        ),
                        SizedBox(width: 16.w), // Add spacing between items
                        Expanded(
                          child: _buildBox(
                            "assets/icons/Top-Company-Jobs.png",
                            "Top Company Jobs",
                            Colors.green,
                            TopCompanyJobsScreen(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Results count ─────────────────────────────────
            // Results count header
            SliverToBoxAdapter(
              child: jobsAsync.when(
                data: (jobs) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jobs for You',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            // builder: (_) => JobseekerExploreScreen(),
                            builder: (_) => SearchJobsScreen(),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Theme.of(context).colorScheme.secondary
                                      .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '${jobs.length} Matches',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ),

            // --- Job Cards List ---
            jobsAsync.when(
              loading: () => const SliverToBoxAdapter(child: ShimmerList()),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorStateWidget(
                  message: 'Failed to load jobs',
                  onRetry: _refresh,
                ),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: const SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        title: 'No Jobs Found',
                        subtitle:
                            'We couldn\'t find any jobs matching your profile. Check back later!',
                        icon: Icons.work_off_rounded,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    bottom: 16.h,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => JobCardWidget(job: jobs[i]),
                      childCount: jobs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Top Row: Logo & Notification
  Widget _buildLogoNotification(
    bool isDark,
    Object? user,
    int notificationCount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/Airigo-jobs-logo.png',
              width: 36.w,
              height: 36.w,
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Airigo Job Portal India',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                Text(
                  user != null && user is UserModel
                      ? 'Welcome back, ${user.name}'
                      : 'Welcome back',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        Stack(
          children: [
            GestureDetector(
              // onTap: () => Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => const NotificationScreen(
              //       viewType: NotificationViewType.jobseeker,
              //     ),
              //   ),
              // ),
              onTap: () {
                log('notificationCount: $notificationCount');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(
                      viewType: NotificationViewType.jobseeker,
                    ),
                  ),
                );
              },
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  Iconsax.notification,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ),
            if (notificationCount > 0)
              Positioned(
                top: 2.w,
                right: 2.w,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF121620) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    notificationCount > 99
                        ? '99+'
                        : notificationCount.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Search Bar
  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(Iconsax.search_normal, color: Colors.grey, size: 20.sp),
          SizedBox(
            width: 8.w,
          ), // Add spacing using SizedBox instead of spacing property
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search jobs, companies, or skills',
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for the attractive box design
  Widget _buildBox(String imgPath, String label, Color color, Widget screen) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.bgDark.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
              blurRadius: 6.r,
              spreadRadius: 0.r,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: isDark
                  ? AppColors.bgDark.withValues(alpha: 0.2)
                  : Colors.white,
              blurRadius: 1.r,
              spreadRadius: 0.r,
              // offset: Offset(-4, -4),
            ),
          ],
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.5),
                    color.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                    color.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Column(
          children: [
            Image.asset(
              imgPath,
              width: 50.w,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.broken_image, size: 50.w, color: Colors.grey),
              fit: BoxFit.cover,
            ),
            SizedBox(
              height: 10.h,
            ), // Add spacing using SizedBox instead of spacing property
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
