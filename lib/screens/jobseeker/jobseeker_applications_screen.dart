import 'dart:convert';
import 'dart:developer';

import 'package:airigo_jobportal/core/providers/applications_provider.dart';
import 'package:airigo_jobportal/models/application_model.dart';
import 'package:airigo_jobportal/screens/common/job_detail_screen.dart';
import 'package:airigo_jobportal/screens/common/recruiter_profile_info.dart';
import 'package:airigo_jobportal/services/api/job_service.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppStatus { shortlisted, pending, rejected, closed, accepted, withdrawn }

// ─── Static Data Removed ──────────────────────────────────────────────────────────────
// Removed the static applications list as we'll now use API data

const _tabs = ['All', 'Pending', 'Shortlisted', 'Rejected', 'Closed'];

class JobseekerApplicationsScreen extends ConsumerStatefulWidget {
  const JobseekerApplicationsScreen({super.key});

  @override
  ConsumerState<JobseekerApplicationsScreen> createState() =>
      _JobseekerApplicationsScreenState();
}

class _JobseekerApplicationsScreenState
    extends ConsumerState<JobseekerApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Fetch applications via the actual provider instance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(applicationsStateProvider.notifier).fetchMyApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ApplicationModel> _getFilteredApplications(
    List<ApplicationModel> applications,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 0:
        return applications;

      case 1:
        return applications
            .where((app) => app.status == ApplicationStatus.pending)
            .toList();

      case 2:
        return applications
            .where((app) => app.status == ApplicationStatus.shortlisted)
            .toList();

      case 3:
        return applications
            .where((app) => app.status == ApplicationStatus.rejected)
            .toList();

      case 4:
        return applications
            .where((app) => app.status == ApplicationStatus.withdrawn)
            .toList();

      default:
        return applications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(applicationsStateProvider);
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 16.w),
                  child: Text(
                    'Applications',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              /// PINNED TAB BAR
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
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
              ),
            ];
          },

          /// BODY
          body: applicationsAsync.when(
            data: (applications) {
              return TabBarView(
                controller: _tabController,
                children: List.generate(
                  _tabs.length,
                  (index) => _buildApplicationList(
                    context,
                    ref,
                    theme,
                    isDark,
                    index,
                    AsyncValue.data(applications),
                  ),
                ),
              );
            },
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error loading applications'),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(applicationsStateProvider.notifier)
                          .fetchMyApplications(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// APPLICATION LIST
  Widget _buildApplicationList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    int tabIndex,
    AsyncValue<List<ApplicationModel>> applicationsAsync,
  ) {
    return RefreshIndicator(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      color: theme.colorScheme.primary,
      onRefresh: () async {
        // Fetch fresh application data from API
        await ref
            .read(applicationsStateProvider.notifier)
            .fetchMyApplications();
      },
      child: applicationsAsync.when(
        data: (applications) {
          // log("All Fetched Applications on Applications screen: ${json.encode(applications)}");
          log("applicationsAsync = ${json.encode(applications)}");
          final filteredList = _getFilteredApplications(applications, tabIndex);
          return filteredList.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 200.h),
                    Center(
                      child: Text(
                        "No applications found",
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) => _applicationCard(
                    context,
                    theme,
                    isDark,
                    filteredList[index],
                    ref,
                  ),
                );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  /// APPLICATION CARD
  Widget _applicationCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    ApplicationModel item,
    WidgetRef ref,
  ) {
    final isClosed = item.status == ApplicationStatus.withdrawn;
    final appStatus = _convertToAppStatus(item.status);

    // recruiterPhotoUrl is now mapped directly from the API response
    final effectivePhotoUrl = item.recruiterPhotoUrl;

    return GestureDetector(
      onTap: () async {
        // Fetch full job details and navigate to job detail screen
        try {
          final jobService = JobService();
          final jobResult = await jobService.getJobById(item.jobId);

          if (jobResult['success'] == true && jobResult['job'] != null) {
            final job = jobResult['job'];

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailScreen(job: job),
              ),
            );
          } else {
            // If unable to fetch job details, show a snackbar
            AppScaffoldFeedback.show(
              context,
              message: 'Unable to load job details as ${jobResult['message']}',
              type: ResponseType.error,
            );
          }
        } catch (e) {
          AppScaffoldFeedback.show(
            context,
            message: 'Error loading job details: $e',
            type: ResponseType.error,
          );
        }
      },
      child: Opacity(
        opacity: isClosed ? 0.75 : 1,
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? theme.dividerColor.withValues(alpha: 0.2)
                  : theme.dividerColor.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _companyLogo(theme, item.companyLogoUrl, isClosed),
                  SizedBox(width: 12.w),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBadge(appStatus),
                        SizedBox(height: 3.h),

                        Text(
                          item.jobTitle,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        Text(
                          '${item.company} • Applied ${DateTime.now().difference(item.appliedAt).inDays} days ago',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.secondary,
                          ),
                        ),

                        // Display additional job information
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              item.location,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (item.ctcMin != 0 || item.ctcMax != 0) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 14.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '₹${item.ctcMin.toInt()}-${item.ctcMax.toInt()} LPA',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.work, size: 14.sp, color: Colors.grey),
                            SizedBox(width: 4.w),
                            Text(
                              item.jobType,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.more_vert,
                    color: const Color(0xFF94A3B8),
                    size: 20.sp,
                  ),
                ],
              ),

              if (item.recruiterUserId != null) ...[
                SizedBox(height: 12.h),
                _recruiterChatRow(
                  context,
                  theme,
                  isDark,
                  RecruiterInfo(
                    name: item.recruiterName ?? 'Recruiter',
                    avatarUrl: effectivePhotoUrl ?? '',
                    preview: 'Recruiter',
                  ),
                  item.recruiterUserId!,
                  ref,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  AppStatus _convertToAppStatus(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.shortlisted:
        return AppStatus.shortlisted;
      case ApplicationStatus.accepted:
        return AppStatus.shortlisted;
      case ApplicationStatus.rejected:
        return AppStatus.rejected;
      case ApplicationStatus.withdrawn:
        return AppStatus.closed;
      case ApplicationStatus.pending:
        return AppStatus.pending;
    }
  }

  Widget _companyLogo(ThemeData theme, String url, bool grayscale) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: 52.w,
              height: 52.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52.w,
                height: 52.w,
                color: const Color(0xFFEFF6FF),
                child: Icon(
                  Icons.business,
                  color: theme.colorScheme.primary,
                  size: 24.sp,
                ),
              ),
            )
          : Container(
              width: 52.w,
              height: 52.w,
              color: const Color(0xFFEFF6FF),
              child: Icon(
                Icons.business,
                color: theme.colorScheme.primary,
                size: 24.sp,
              ),
            ),
    );
  }

  Widget _statusBadge(AppStatus status) {
    final cfg = switch (status) {
      AppStatus.shortlisted => (
        label: 'Shortlisted',
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF15803D),
      ),
      AppStatus.pending => (
        label: 'Pending',
        bg: const Color(0xFFFEF9C3),
        fg: const Color(0xFFB45309),
      ),
      AppStatus.rejected => (
        label: 'Rejected',
        bg: const Color(0xFFEEE2E2),
        fg: const Color(0xFFB91C1C),
      ),
      AppStatus.closed => (
        label: 'Closed',
        bg: const Color(0xFFE9E2FE),
        fg: const Color(0xFF490FBF),
      ),
      AppStatus.accepted => (
        label: 'Accepted',
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF15803D),
      ),
      AppStatus.withdrawn => (
        label: 'Withdrawn',
        bg: const Color(0xFFE9E2FE),
        fg: const Color(0xFF490FBF),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: cfg.fg,
        ),
      ),
    );
  }

  Widget _recruiterChatRow(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    RecruiterInfo recruiter,
    int recruiterUserId,
    WidgetRef ref,
  ) {
    // Get initials for placeholder
    String initials = '';
    if (recruiter.name.isNotEmpty) {
      final nameParts = recruiter.name.trim().split(' ');
      if (nameParts.length >= 2) {
        initials = '${nameParts[0][0]}${nameParts.last[0]}'.toUpperCase();
      } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
        initials = nameParts[0][0].toUpperCase();
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? theme.dividerColor.withValues(alpha: 0.2)
              : theme.dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Recruiter Avatar with error handling
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: recruiter.avatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      recruiter.avatarUrl,
                      width: 36.r,
                      height: 36.r,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        log('Error loading recruiter image: $error');
                        return Text(
                          initials.isNotEmpty ? initials : 'R',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    initials.isNotEmpty ? initials : 'R',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          SizedBox(width: 10.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recruiter.name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  recruiter.preview,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () async {
              // Show loading indicator
              final scaffoldKey = ScaffoldMessenger.of(context);
              scaffoldKey.hideCurrentSnackBar();
              scaffoldKey.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 12),
                      Text('Loading recruiter profile...'),
                    ],
                  ),
                  duration: Duration(seconds: 10),
                ),
              );

              try {
                // First check if recruiter profile is already cached
                Map<String, dynamic>? cachedProfile = ref
                    .read(applicationsStateProvider.notifier)
                    .getCachedRecruiterProfile(recruiterUserId);

                // If not cached, trigger a fetch (the background prefetching should have handled this)
                if (cachedProfile == null) {
                  // Fetch all applications again to ensure background prefetching happened
                  await ref
                      .read(applicationsStateProvider.notifier)
                      .fetchMyApplications();

                  // Try to get from cache again
                  cachedProfile = ref
                      .read(applicationsStateProvider.notifier)
                      .getCachedRecruiterProfile(recruiterUserId);
                }

                // Hide the loading snackbar
                scaffoldKey.hideCurrentSnackBar();

                // Prepare recruiter profile data for the screen
                String name =
                    cachedProfile?['recruiter_name'] ??
                    cachedProfile?['name'] ??
                    recruiter.name;
                String designation =
                    cachedProfile?['designation'] ?? 'Recruiter';
                String companyName =
                    cachedProfile?['company_name'] ??
                    cachedProfile?['company'] ??
                    'Company';
                String email =
                    cachedProfile?['email'] ??
                    cachedProfile?['user_email'] ??
                    'contact@company.com';
                String contact = cachedProfile?['phone'] ?? 'Contact Info';
                String location = cachedProfile?['location'] ?? 'Location';
                String photoUrl =
                    cachedProfile?['photo_url'] ??
                    cachedProfile?['profile_image_url'] ??
                    recruiter.avatarUrl;
                String? companyWebsite = cachedProfile?['company_website'];
                String? about =
                    cachedProfile?['bio'] ?? cachedProfile?['about'];
                String? approvalStatus = cachedProfile?['approval_status'];
                String? joinedDate = cachedProfile?['created_at'];
                int? postedJobsCount = cachedProfile?['posted_jobs_count'];

                // Navigate to recruiter profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecruiterProfileInfo(
                      user: 'jobseeker',
                      name: name,
                      designation: designation,
                      companyName: companyName,
                      email: email,
                      contact: contact,
                      location: location,
                      photoUrl: photoUrl,
                      companyWebsite: companyWebsite,
                      about: about,
                      approvalStatus: approvalStatus,
                      joinedDate: joinedDate,
                      postedJobsCount: postedJobsCount,
                      recruiterUserId: recruiterUserId.toString(),
                    ),
                  ),
                );
              } catch (e) {
                // Hide the loading snackbar
                scaffoldKey.hideCurrentSnackBar();

                // Show error message
                scaffoldKey.showSnackBar(
                  SnackBar(
                    content: Text('Error loading recruiter profile: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              "Recruiter Profile",
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
      alignment: Alignment.centerLeft,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

class RecruiterInfo {
  final String name;
  final String avatarUrl;
  final String preview;

  const RecruiterInfo({
    required this.name,
    required this.avatarUrl,
    required this.preview,
  });
}
