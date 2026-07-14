import 'package:airigo_jobportal/screens/recruiter/applicant_review_screen.dart';
import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/core/providers/jobs_provider.dart';
import 'package:airigo_jobportal/models/application_model.dart';
import 'package:airigo_jobportal/models/recruiter_model.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
class Candidate {
  final String name;
  final String currentRole;
  final String avatarUrl;
  final ApplicationStatus status;
  final String appliedAgo;

  const Candidate({
    required this.name,
    required this.currentRole,
    required this.avatarUrl,
    required this.status,
    required this.appliedAgo,
  });
}

class ApplicantsListScreen extends ConsumerStatefulWidget {
  final bool isBackButton;
  final String? jobId; // Optional: Filter by specific job
  
  const ApplicantsListScreen({
    required this.isBackButton,
    this.jobId,
    super.key,
  });
  @override
  ConsumerState<ApplicantsListScreen> createState() =>
      _ApplicantsListScreenState();
}

class _ApplicantsListScreenState extends ConsumerState<ApplicantsListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0; // 0=All, 1=Pending, 2=Shortlisted, 3=Accepted, 4=Rejected
  bool _isLoadingState = false;

  final _filters = [
    'All',
    'Pending',
    'Shortlisted',
    'Accepted',
    'Rejected'
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );

    // Re-trigger the global load just in case, but rely on watching the state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsStateProvider.notifier).loadRecruiterJobs();
    });
  }

  // We no longer need _loadApplicantsData since we watch the provider

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Candidate> _getFilteredCandidates(List<ApplicationModel> applications) {
    var candidates = _convertApplicationsToCandidates(applications);

    // Apply search filter
    var list = candidates.where((c) {
      if (_searchQuery.isNotEmpty) {
        return c.name.toLowerCase().contains(_searchQuery) ||
            c.currentRole.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    // Apply status filter
    // Filter 0 = All, 1 = Pending, 2 = Shortlisted, 3 = Accepted, 4 = Rejected
    if (_selectedFilter == 1) {
      list = list
          .where((c) => c.status == ApplicationStatus.pending)
          .toList();
    } else if (_selectedFilter == 2) {
      list = list
          .where((c) => c.status == ApplicationStatus.shortlisted)
          .toList();
    } else if (_selectedFilter == 3) {
      list = list
          .where((c) => c.status == ApplicationStatus.accepted)
          .toList();
    } else if (_selectedFilter == 4) {
      list = list
          .where((c) => c.status == ApplicationStatus.rejected)
          .toList();
    }
    return list;
  }

  // Convert backend application data to Candidate model
  List<Candidate> _convertApplicationsToCandidates(
    List<ApplicationModel> applications,
  ) {
    if (applications.isEmpty) {
      return [];
    }

    return applications
        .map((app) {
          return Candidate(
            name: app.jobseekerName ?? 'Unknown Applicant',
            currentRole: app.jobseekerCurrentRole ?? 'Job Seeker',
            avatarUrl:
                app.jobseekerPhotoUrl ?? 'https://via.placeholder.com/150',
            status: app.status,
            appliedAgo: 'Applied ${app.appliedAt.toString().split(' ')[0]}',
          );
        })
        .cast<Candidate>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobsAsync = ref.watch(jobsStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        // forceMaterialTransparency: true,
        elevation: 1,
        shadowColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

        automaticallyImplyLeading: false,

        title: Text(
          widget.jobId != null ? 'Job Applicants' : 'All Applicants',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: widget.isBackButton
            ? IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18.sp,
                  color: theme.colorScheme.onSurface,
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Reload applications and jobs data from API
          await ref.read(jobsStateProvider.notifier).loadRecruiterJobs();
        },
        child: Column(
          children: [
            _buildSearchBar(theme),
            _buildFilterTabs(theme),
            SizedBox(height: 10.h),
            Expanded(
              child: jobsAsync.when(
                data: (state) {
                  // Get all applications
                  var applications = state.recentApplications;
                  
                  // Filter by jobId if provided
                  if (widget.jobId != null) {
                    applications = applications
                        .where((app) => app.jobId.toString() == widget.jobId)
                        .toList();
                  }
                  
                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    applications = applications.where((app) {
                      final name = app.jobseekerName?.toLowerCase() ?? '';
                      final role = app.jobseekerCurrentRole?.toLowerCase() ?? '';
                      return name.contains(_searchQuery) || 
                             role.contains(_searchQuery);
                    }).toList();
                  }
                  
                  // Apply status filter
                  // Filter 0 = All, 1 = Pending, 2 = Shortlisted, 3 = Accepted, 4 = Rejected
                  if (_selectedFilter == 1) {
                    applications = applications
                        .where((app) => app.status == ApplicationStatus.pending)
                        .toList();
                  } else if (_selectedFilter == 2) {
                    applications = applications
                        .where((app) => app.status == ApplicationStatus.shortlisted)
                        .toList();
                  } else if (_selectedFilter == 3) {
                    applications = applications
                        .where((app) => app.status == ApplicationStatus.accepted)
                        .toList();
                  } else if (_selectedFilter == 4) {
                    applications = applications
                        .where((app) => app.status == ApplicationStatus.rejected)
                        .toList();
                  }
                  
                  return _buildCandidateList(applications, theme);
                },
                loading: () => _buildApplicantsListShimmer(theme),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 40.sp, color: Colors.red),
                      SizedBox(height: 10.h),
                      Text(
                        'Error loading applicants',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        e.toString(),
                        style: TextStyle(fontSize: 12.sp, color: Colors.red),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(jobsStateProvider.notifier).loadRecruiterJobs();
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(MediaQueryData mq) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: mq.padding.top),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        child: Row(
          children: [
            if (widget.isBackButton)
              _circleBtn(
                Icons.arrow_back_ios_rounded,
                AppColors.secondary,
                () => Navigator.of(context).maybePop(),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Applicants',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'HireFlow Portal',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _circleBtn(Icons.more_vert, AppColors.textMuted, () {}),
          ],
        ),
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          SizedBox(width: 12.w),
          Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search applicants by name or skill',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(
                Icons.close,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 18.sp,
              ),
            ),
          SizedBox(width: 14.w),
        ],
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final active = _selectedFilter == i;
          return Center(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: active ? AppColors.secondary : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        spacing: 8.w,
        children: List.generate(_filters.length, (i) {
          final active = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Candidate List ─────────────────────────────────────────────────────────
  Widget _buildCandidateList(List<ApplicationModel> applications, ThemeData theme) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40.sp, color: theme.dividerColor.withValues(alpha: 0.15)),
            SizedBox(height: 10.h),
            Text(
              'No candidates found',
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (widget.jobId != null) ...[
              SizedBox(height: 8.h),
              Text(
                'This job has no applicants yet.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      itemCount: applications.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) => _applicantCard(applications[i], theme),
    );
  }

  Widget _applicantCard(ApplicationModel app, ThemeData theme) {
    final statusCfg = _statusConfig(app.status);
    final isNew = app.status == ApplicationStatus.pending;

    return Opacity(
      opacity: isNew ? 0.85 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicantReviewScreen(application: app),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                // Top row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: app.jobseekerPhotoUrl != null && app.jobseekerPhotoUrl!.isNotEmpty
                          ? ShimmerImage(
                              imageUrl: app.jobseekerPhotoUrl!,
                              width: 54.w,
                              height: 54.w,
                              borderRadius: 10.r,
                              errorWidget: CircleAvatar(
                                radius: 27.r,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person,
                                  color: theme.colorScheme.primary,
                                  size: 26.sp,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 27.r,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.primary,
                                size: 26.sp,
                              ),
                            ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  app.jobseekerName ?? 'Unknown Applicant',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            app.jobseekerCurrentRole ?? app.jobTitle ?? 'Applied Position',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Divider(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
                // Bottom row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: statusCfg.$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          statusCfg.$1,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Applied ${_getTimeAgo(app.appliedAt)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  (String, Color) _statusConfig(ApplicationStatus status) {
    return switch (status) {
      ApplicationStatus.pending => ('Pending', const Color(0xFFCBD5E1)),
      ApplicationStatus.shortlisted => ('Shortlisted', const Color(0xFF22C55E)),
      ApplicationStatus.accepted => ('Accepted', const Color(0xFFF97316)),
      ApplicationStatus.rejected => ('Rejected', const Color(0xFFEF4444)),
      ApplicationStatus.withdrawn => ('Withdrawn', const Color(0xFF6B7280)),
    };
  }

  void _openApplicantReview(Candidate c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening review for ${c.name}'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Shimmer Loading Widget ─────────────────────────────────────────────
  Widget _buildApplicantsListShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }
}

// ── Reusable circle button ────────────────────────────────────────────────────
Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20.sp, color: color),
    ),
  );
}
