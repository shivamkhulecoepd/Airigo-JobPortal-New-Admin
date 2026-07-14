import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/core/providers/jobs_provider.dart';
import 'package:airigo_jobportal/models/job_model.dart';
import 'package:airigo_jobportal/models/recruiter_model.dart';
import 'package:airigo_jobportal/screens/recruiter/job_post_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/applicants_list_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_main_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/job_detail_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:airigo_jobportal/models/application_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';
import 'applicant_review_screen.dart';
import 'package:airigo_jobportal/screens/common/notification_screen.dart'; // Import the common notifications screen
import 'package:airigo_jobportal/core/providers/recruiter_notification_provider.dart'; // Import recruiter notification provider
import 'package:airigo_jobportal/services/notification_manager.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
// Using AppColors instead of hardcoded colors

// ─── Data Models ──────────────────────────────────────────────────────────────
enum ApplicantStatus { newApp, shortlisted, reviewing, interviewing }

class RecentApplicant {
  final String name;
  final String role;
  final String avatarUrl;
  final ApplicantStatus status;

  const RecentApplicant({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.status,
  });
}

class StatCard {
  final IconData icon;
  final String label;
  final String value;
  final String change;

  const StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
  });
}

// ─── Dynamic Data ───────────────────────────────────────────────────────────
// Data will be loaded dynamically from the providers

// ─── Screen ───────────────────────────────────────────────────────────────────
class RecruiterDashboardScreen extends ConsumerStatefulWidget {
  const RecruiterDashboardScreen({super.key});
  @override
  ConsumerState<RecruiterDashboardScreen> createState() =>
      _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState
    extends ConsumerState<RecruiterDashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();

      // Register for notification refreshes
      NotificationProvidersContainer().setNotificationRefreshCallbacks(
        refreshRecruiter: () {
          if (mounted) {
            debugPrint(
              'RecruiterDashboardScreen: Notification received, refreshing data...',
            );
            _loadDashboardData();
          }
        },
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
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    // Refresh all data in parallel for better performance
    await Future.wait([
      // Load recruiter's jobs which will also update the state
      ref.read(jobsStateProvider.notifier).loadRecruiterJobs(),
      
      // Load recruiter notifications
      ref.read(recruiterNotificationsProvider.notifier).refreshNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobsAsync = ref.watch(jobsStateProvider);
    final recruiter = ref.watch(currentRecruiterProvider);
    final notificationCount = ref.watch(
      recruiterUnreadNotifCountProvider,
    ); // Watch unread notification count

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        // forceMaterialTransparency: true,
        elevation: 1,
        shadowColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

        leading: Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Image.asset('assets/icons/Airigo-jobs-logo.png'),
        ),
        leadingWidth: 44.w,

        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => _showNotifications(context),
                iconSize: 22.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                icon: Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      notificationCount > 99
                          ? '99+'
                          : notificationCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: jobsAsync.when(
          data: (jobsState) {
            final isLoading = jobsState.isLoading;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcome(theme),
                  if (isLoading && jobsState.recruiterJobs.isEmpty)
                    Column(
                      children: [
                        _buildStatsShimmer(theme, isDark),
                        SizedBox(height: 16.h),
                        _buildJobSummaryShimmer(theme, isDark),
                        SizedBox(height: 16.h),
                        _buildApplicantsShimmer(theme, isDark),
                      ],
                    )
                  else ...[
                    _buildStatsRow(theme, jobsAsync),
                    _buildJobPostingsSummary(theme, jobsAsync),
                    _buildRecentApplicants(theme, recruiter),
                  ],
                  if (jobsState.errorMessage != null &&
                      jobsState.recruiterJobs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Error: ${jobsState.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  SizedBox(height: 80.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        elevation: 6,
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => RecruiterMainScreen(index: 2),
          ),
          (route) => false,
        ),
        child: Icon(Icons.add, size: 28.sp, color: Colors.white),
      ),
    );
  }

  //── Welcome ────────────────────────────────────────────────────────────────
  Widget _buildWelcome(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, Recruiter!',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Here is what's happening with your job postings.",
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, AsyncValue<JobsState> jobsAsync) {
    if (jobsAsync.value?.isLoading == true &&
        jobsAsync.value?.recruiterJobs.isEmpty == true) {
      return const SizedBox.shrink(); // Handled by main view
    }

    // Create stats based on loaded jobs data
    final stats = _calculateStats(jobsAsync);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: List.generate(
          stats.length,
          (i) => Padding(
            padding: EdgeInsets.only(right: i == stats.length - 1 ? 0 : 12.w),
            child: GestureDetector(
              onTap: () {
                if (i == 0) {
                  // Active Jobs stat -> Navigate to Manage Postings with active filter
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecruiterMainScreen(index: 1),
                    ),
                    (route) => false,
                  );
                } else if (i == 1) {
                  // Applicants stat -> Navigate to All Applicants
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplicantsListScreen(isBackButton: true),
                    ),
                  );
                } else if (i == 2) {
                  // Shortlisted stat -> Navigate to Applicants filtered by shortlisted
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplicantsListScreen(isBackButton: true),
                    ),
                  );
                }
              },
              child: _statCard(stats[i], theme),
            ),
          ),
        ),
      ),
    );
  }

  List<StatCard> _calculateStats(AsyncValue<JobsState> jobsAsync) {
    int activeJobs = 0;
    int totalApplicants = 0;
    int shortlisted = 0;

    if (jobsAsync.hasValue && jobsAsync.value != null) {
      final jobsState = jobsAsync.value!;
      final jobs = jobsState.recruiterJobs;
      activeJobs = jobs.where((j) => j.isActive).length;

      // Use stats from backend if available
      final stats = jobsState.applicantStats;
      if (stats != null) {
        totalApplicants =
            int.tryParse(stats['total_applications']?.toString() ?? '0') ?? 0;
        shortlisted =
            int.tryParse(stats['shortlisted']?.toString() ?? '0') ?? 0;
      } else {
        // Fallback to local calculation if stats not loaded yet
        totalApplicants = jobsState.recentApplications.length;
        shortlisted = jobsState.recentApplications
            .where((a) => a.status == ApplicationStatus.shortlisted)
            .length;
      }
    }

    return [
      StatCard(
        icon: Icons.assignment_outlined,
        label: 'ACTIVE JOBS',
        value: activeJobs.toString(),
        change: '+0%',
      ),
      StatCard(
        icon: Icons.group_outlined,
        label: 'APPLICANTS',
        value: totalApplicants.toString(),
        change: '+0%',
      ),
      StatCard(
        icon: Icons.star_outline,
        label: 'SHORTLISTED',
        value: shortlisted.toString(),
        change: '+0%',
      ),
    ];
  }

  Widget _buildJobPostingsSummary(
    ThemeData theme,
    AsyncValue<JobsState> jobsAsync,
  ) {
    if (!jobsAsync.hasValue || jobsAsync.value!.recruiterJobs.isEmpty) {
      return const SizedBox.shrink();
    }

    final jobs = jobsAsync.value!.recruiterJobs.take(3).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Job Postings',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to postings tab
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecruiterMainScreen(index: 1),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  'Manage All',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...jobs.map((job) => _jobSummaryCard(job, theme)),
        ],
      ),
    );
  }

  Widget _jobSummaryCard(JobModel job, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(jobId: job.id.toString()),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: ShimmerImage(
                imageUrl: job.companyLogoUrl ?? '',
                width: 44.w,
                height: 44.w,
                borderRadius: 10.r,
                errorWidget: Icon(
                  Icons.work_outline,
                  color: theme.colorScheme.primary,
                  size: 22.sp,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.designation,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    spacing: 10.w,
                    children: [
                      Text(
                        '${job.applicantsCount ?? 0} Applicants',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (job.recentApplicantPhotos.isNotEmpty) ...[
                        _buildAvatarStack(job.recentApplicantPhotos),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<String> photos) {
    return Container(
      // height: 25.h,
      // width: 45.w,
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        children: List.generate(photos.length, (i) {
          return Positioned(
            left: i * 12.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 10.r,
                backgroundImage: NetworkImage(photos[i]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _statCard(StatCard card, ThemeData theme) {
    return Container(
      width: 150.w,
      padding: EdgeInsets.only(
        left: 14.w,
        right: 14.w,
        top: 14.h,
        bottom: 10.h,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(card.icon, color: theme.colorScheme.primary, size: 22.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  card.change,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.label,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                card.value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //── Recent Applicants──────────────────────────────────────────────────────
  Widget _buildRecentApplicants(ThemeData theme, RecruiterModel? recruiter) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Applicants',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecruiterMainScreen(index: 3),
                  ),
                  (route) => false,
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Real applicants cards
          Consumer(
            builder: (context, ref, child) {
              final jobsAsync = ref.watch(jobsStateProvider);
              final isLoading = jobsAsync.value?.isLoading ?? false;
              if (isLoading &&
                  (!jobsAsync.hasValue ||
                      jobsAsync.value!.recentApplications.isEmpty)) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!jobsAsync.hasValue ||
                  jobsAsync.value!.recentApplications.isEmpty) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Center(
                    child: Text(
                      'No recent applicants found.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final recentApps = jobsAsync.value!.recentApplications;

              return Column(
                children: recentApps
                    .map(
                      (app) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ApplicantReviewScreen(application: app),
                            ),
                          );
                        },
                        child: _applicantCard(app, theme),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _applicantCard(ApplicationModel app, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ShimmerImage(
            imageUrl: app.jobseekerPhotoUrl ?? '',
            width: 48.w,
            height: 48.w,
            borderRadius: 24.r,
            errorWidget: CircleAvatar(
              radius: 24.r,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
                size: 22.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.jobseekerName ?? 'Unknown Applicant',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  app.jobseekerCurrentRole ?? 'Applied for ${app.jobTitle}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _applicantStatusBadge(app.status.label, theme),
        ],
      ),
    );
  }

  Widget _applicantStatusBadge(String status, ThemeData theme) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade600;

    if (status.toLowerCase().contains('accepted')) {
      bg = const Color(0xFFECFDF5);
      fg = AppColors.success;
    } else if (status.toLowerCase().contains('shortlisted')) {
      bg = const Color(0xFFEFF6FF);
      fg = AppColors.secondary;
    } else if (status.toLowerCase().contains('pending')) {
      bg = const Color(0xFFFFFBEB);
      fg = AppColors.warning;
    } else if (status.toLowerCase().contains('rejected')) {
      bg = const Color(0xFFFFFBEB);
      fg = AppColors.error;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _statusBadge(ApplicantStatus status, ThemeData theme) {
    final cfg = switch (status) {
      ApplicantStatus.newApp => (
        label: 'NEW',
        bg: theme.colorScheme.primary.withValues(alpha: 0.2),
        fg: theme.colorScheme.primary,
      ),
      ApplicantStatus.shortlisted => (
        label: 'SHORTLISTED',
        bg: AppColors.success.withValues(alpha: 0.2),
        fg: AppColors.success,
      ),
      ApplicantStatus.reviewing => (
        label: 'REVIEWING',
        bg: AppColors.warning.withValues(alpha: 0.2),
        fg: AppColors.warning,
      ),
      ApplicantStatus.interviewing => (
        label: 'INTERVIEWING',
        bg: theme.colorScheme.primary.withValues(alpha: 0.2),
        fg: theme.colorScheme.primary,
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
          color: cfg.fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAddJobDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        final titleCtrl = TextEditingController();
        final deptCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Post New Job',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _formField(titleCtrl, 'Job Title', theme),
              SizedBox(height: 10.h),
              _formField(deptCtrl, 'Department / Location', theme),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showSnack('Job "${titleCtrl.text}" posted!');
                  },
                  child: Text(
                    'Post Job',
                    style: TextStyle(
                      color: theme.scaffoldBackgroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _formField(TextEditingController ctrl, String hint, ThemeData theme) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13.sp,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NotificationScreen(viewType: NotificationViewType.recruiter),
      ),
    );
  }

  // ── Shimmer Loading Widgets ─────────────────────────────────────────────
  Widget _buildStatsShimmer(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 12.w),
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              highlightColor: isDark
                  ? Colors.grey.shade700
                  : Colors.grey.shade100,
              child: Container(
                width: 150.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobSummaryShimmer(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade100,
            child: Container(
              width: 150.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ...List.generate(
            3,
            (i) => Shimmer.fromColors(
              baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              highlightColor: isDark
                  ? Colors.grey.shade700
                  : Colors.grey.shade100,
              child: Container(
                margin: EdgeInsets.only(bottom: 12.h),
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantsShimmer(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade100,
            child: Container(
              width: 180.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ...List.generate(
            3,
            (i) => Shimmer.fromColors(
              baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              highlightColor: isDark
                  ? Colors.grey.shade700
                  : Colors.grey.shade100,
              child: Container(
                margin: EdgeInsets.only(bottom: 10.h),
                height: 72.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
