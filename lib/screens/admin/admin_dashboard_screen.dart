import 'package:airigo_jobportal/models/admin/admin_stats_model.dart';
import 'package:airigo_jobportal/services/admin/admin_api_service.dart';
import 'package:airigo_jobportal/services/notification_manager.dart';
import 'package:airigo_jobportal/utils/theme.dart';
import 'package:airigo_jobportal/widgets/admin/stat_card.dart';
import 'package:airigo_jobportal/core/providers/admin_notification_provider.dart';
import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/screens/common/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final AdminApiService _apiService = AdminApiService();
  bool _isLoading = true;
  AdminStatsModel? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();

    // Register the refresh callback with the notification manager - only refresh notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationProvidersContainer().registerRefreshAdmin(
        () => ref
            .read(adminNotificationsProvider.notifier)
            .refreshNotifications(),
      );
    });
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Refresh all data in parallel for better performance
      await Future.wait([
        // Refresh dashboard statistics
        _fetchStatsOnly(),

        // Refresh notifications
        ref.read(adminNotificationsProvider.notifier).refreshNotifications(),

        // Refresh current user profile to get latest data
        ref.read(authStateProvider.notifier).refresh(),
      ]);
    } catch (e) {
      debugPrint('AdminDashboard: Refresh failed: $e');
    }
  }

  Future<void> _fetchStatsOnly() async {
    try {
      final response = await _apiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = AdminStatsModel.fromJson(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(
                        viewType: NotificationViewType.admin,
                      ),
                    ),
                  ).then((_) {
                    // Refresh notifications badge after returning
                    ref.invalidate(adminNotificationsProvider);
                  });
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer(
                  builder: (context, ref, _) {
                    final unread = ref.watch(adminUnreadNotifCountProvider);
                    if (unread == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading(isDark)
          : _error != null
          ? _buildErrorView()
          : _stats != null
          ? _buildDashboard(isDark)
          : const Center(child: Text('No data available')),
    );
  }

  /// Shimmer loading effect for dashboard
  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section Shimmer
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32.sp,
                          height: 32.sp,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 20.sp,
                                width: 180.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                height: 14.sp,
                                width: 250.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // User Statistics Section
            _buildShimmerSection(
              isDark,
              baseColor,
              highlightColor,
              'User Statistics',
            ),
            SizedBox(height: 12.h),
            _buildShimmerStatGrid(isDark, baseColor, highlightColor),
            SizedBox(height: 24.h),

            // Job Statistics Section
            _buildShimmerSection(
              isDark,
              baseColor,
              highlightColor,
              'Job Statistics',
            ),
            SizedBox(height: 12.h),
            _buildShimmerStatGrid(isDark, baseColor, highlightColor),
            SizedBox(height: 24.h),

            // Application Statistics Section
            _buildShimmerSection(
              isDark,
              baseColor,
              highlightColor,
              'Application Statistics',
            ),
            SizedBox(height: 12.h),
            _buildShimmerStatGrid(isDark, baseColor, highlightColor),
            SizedBox(height: 24.h),

            // Recruiter Approvals Section
            _buildShimmerSection(
              isDark,
              baseColor,
              highlightColor,
              'Recruiter Approvals',
            ),
            SizedBox(height: 12.h),
            _buildShimmerStatGrid(isDark, baseColor, highlightColor, count: 2),
            SizedBox(height: 24.h),

            // Issues & Reports Section
            _buildShimmerSection(
              isDark,
              baseColor,
              highlightColor,
              'Issues & Reports',
            ),
            SizedBox(height: 12.h),
            _buildShimmerStatGrid(isDark, baseColor, highlightColor),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  /// Build shimmer section title
  Widget _buildShimmerSection(
    bool isDark,
    Color baseColor,
    Color highlightColor,
    String title,
  ) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 18.sp,
        width: 150.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

  /// Build shimmer stat cards grid
  Widget _buildShimmerStatGrid(
    bool isDark,
    Color baseColor,
    Color highlightColor, {
    int count = 4,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.3,
      children: List.generate(count, (index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40.sp,
                  height: 40.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12.sp,
                      width: 80.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 24.sp,
                      width: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 64.sp, color: AppTheme.primaryBrand),
            SizedBox(height: 16.h),
            Text(
              'Failed to load statistics',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(isDark),
            SizedBox(height: 24.h),

            // User Statistics
            Text(
              'User Statistics',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Total Users',
                  value: _stats!.totalUsers.toString(),
                  icon: Iconsax.people,
                  color: AppTheme.primaryBrand,
                  onTap: () {},
                ),
                StatCard(
                  title: 'Jobseekers',
                  value: _stats!.totalJobseekers.toString(),
                  icon: Iconsax.profile_2user,
                  color: const Color(0xFF182E8B),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Recruiters',
                  value: _stats!.totalRecruiters.toString(),
                  icon: Iconsax.building,
                  color: const Color(0xFF7F1A4D),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Active Users',
                  value: _stats!.activeUsers.toString(),
                  icon: Iconsax.task,
                  color: const Color(0xFF10B981),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Job Statistics
            Text(
              'Job Statistics',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Total Jobs',
                  value: _stats!.totalJobs.toString(),
                  icon: Iconsax.briefcase,
                  color: AppTheme.primaryBrand,
                  onTap: () {},
                ),
                StatCard(
                  title: 'Pending Approval',
                  value: _stats!.pendingJobs.toString(),
                  icon: Iconsax.clock,
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Active Jobs',
                  value: _stats!.activeJobs.toString(),
                  icon: Iconsax.task,
                  color: const Color(0xFF10B981),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Rejected',
                  value: _stats!.rejectedJobs.toString(),
                  icon: Iconsax.close_circle,
                  color: const Color(0xFFEF4444),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Application Statistics
            Text(
              'Application Statistics',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Total Applications',
                  value: _stats!.totalApplications.toString(),
                  icon: Iconsax.document_text,
                  color: AppTheme.primaryBrand,
                  onTap: () {},
                ),
                StatCard(
                  title: 'Pending',
                  value: _stats!.pendingApplications.toString(),
                  icon: Iconsax.clock,
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Shortlisted',
                  value: _stats!.shortlistedApplications.toString(),
                  icon: Iconsax.star,
                  color: const Color(0xFF10B981),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Accepted',
                  value: _stats!.acceptedApplications.toString(),
                  icon: Iconsax.tick_circle,
                  color: const Color(0xFF10B981),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Recruiter Approval Stats
            Text(
              'Recruiter Approvals',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Pending Approval',
                  value: _stats!.pendingRecruiters.toString(),
                  icon: Iconsax.clock,
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Approved',
                  value: _stats!.approvedRecruiters.toString(),
                  icon: Iconsax.task,
                  color: const Color(0xFF10B981),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Issues Stats
            Text(
              'Issues & Reports',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Total Issues',
                  value: _stats!.totalIssues.toString(),
                  icon: Iconsax.flag,
                  color: AppTheme.primaryBrand,
                  onTap: () {},
                ),
                StatCard(
                  title: 'Pending',
                  value: _stats!.pendingIssues.toString(),
                  icon: Iconsax.clock,
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
                ),
                StatCard(
                  title: 'In Progress',
                  value: _stats!.inProgressIssues.toString(),
                  icon: Iconsax.refresh,
                  color: const Color(0xFF3B82F6),
                  onTap: () {},
                ),
                StatCard(
                  title: 'Resolved',
                  value: _stats!.resolvedIssues.toString(),
                  icon: Iconsax.task,
                  color: const Color(0xFF10B981),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBrand,
            AppTheme.primaryBrand.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrand.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8.w,
            children: [
              // Icon(
              //   Iconsax.shield_tick,
              //   size: 32.sp,
              //   color: Colors.white,
              // ),
              // SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Admin Control Panel',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Logout Button
              GestureDetector(
                onTap: () => _showLogoutDialog(context, isDark),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Manage users, jobs, and platform analytics',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrand.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.logout,
                    color: AppTheme.primaryBrand,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 16),

                /// Title
                const Text(
                  "Logout?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                /// Subtitle
                Text(
                  "Are you sure you want to logout from your admin account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 24),

                /// Buttons
                Row(
                  children: [
                    /// Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// Logout
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/onboarding',
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrand,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
