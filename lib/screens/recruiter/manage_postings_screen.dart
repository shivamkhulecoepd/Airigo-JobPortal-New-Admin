// manage_postings_screen.dart
// Dependencies: flutter_screenutil: ^5.9.0

import 'dart:developer';

import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../models/job_model.dart';
import 'job_detail_screen.dart';
import 'applicants_list_screen.dart';
import 'job_post_screen.dart';

// Using AppColors instead of hardcoded colors

// ─── Models ───────────────────────────────────────────────────────────────────
enum PostingStatus { active, closed, pendingReview, rejected }

class JobPosting {
  final String id;
  final String title;
  final String location;
  final String companyLogoUrl;
  final PostingStatus status;
  final int applicantCount;
  final String applicantSubtitle;
  final List<String> avatarUrls;

  const JobPosting({
    required this.id,
    required this.title,
    required this.location,
    required this.companyLogoUrl,
    required this.status,
    required this.applicantCount,
    required this.applicantSubtitle,
    required this.avatarUrls,
  });
}

class ManagePostingsScreen extends ConsumerStatefulWidget {
  const ManagePostingsScreen({super.key});
  @override
  ConsumerState<ManagePostingsScreen> createState() =>
      _ManagePostingsScreenState();
}

class _ManagePostingsScreenState extends ConsumerState<ManagePostingsScreen> {
  int _selectedFilter = 0; // 0=All, 1=Active, 2=Closed
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final _filters = ['All', 'Active', 'Pending', 'Rejected', 'Closed'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );

    // Load jobs when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  Future<void> _loadJobs() async {
    // Load recruiter's jobs which will update the state
    await ref.read(jobsStateProvider.notifier).loadRecruiterJobs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<JobPosting> _getFiltered(JobsState jobsState) {
    List<JobPosting> postings = jobsState.recruiterJobs.map((job) {
      // Map JobModel to JobPosting
      return JobPosting(
        id: job.id.toString(),
        title: job.designation,
        location: job.location,
        companyLogoUrl: job.companyLogoUrl ?? '',
        status: _convertJobStatus(job.approvalStatus, job.isActive),
        applicantCount: job.applicantsCount ?? 0,
        applicantSubtitle:
            'Posted ${job.createdAt.toString().split(' ')[0]}',
        avatarUrls: job.recentApplicantPhotos,
      );
    }).toList();

    // Apply search filter
    var list = postings.where((p) {
      if (_searchQuery.isNotEmpty) {
        return p.title.toLowerCase().contains(_searchQuery) ||
            p.location.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    // Apply status filter mapping to _filters = ['All', 'Active', 'Pending', 'Rejected', 'Closed'];
    if (_selectedFilter == 1) {
      // Active
      list = list.where((p) => p.status == PostingStatus.active).toList();
    } else if (_selectedFilter == 2) {
      // Pending
      list = list
          .where((p) => p.status == PostingStatus.pendingReview)
          .toList();
    } else if (_selectedFilter == 3) {
      // Rejected
      list = list.where((p) => p.status == PostingStatus.rejected).toList();
    } else if (_selectedFilter == 4) {
      // Closed
      list = list.where((p) => p.status == PostingStatus.closed).toList();
    }
    return list;
  }

  PostingStatus _convertJobStatus(String? approvalStatus, bool? isActive) {
    if (approvalStatus?.toLowerCase() == 'pending' ||
        approvalStatus?.toLowerCase() == 'pending_approval') {
      return PostingStatus.pendingReview;
    } else if (approvalStatus?.toLowerCase() == 'rejected') {
      return PostingStatus.rejected;
    } else if (isActive == false) {
      return PostingStatus.closed;
    } else {
      return PostingStatus.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
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
          'Manage Jobs',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Reload jobs when pulled to refresh
          await ref.refresh(jobsStateProvider.notifier).loadRecruiterJobs();
        },
        child: Column(
          children: [
            _buildSearchBar(theme),
            _buildFilterTabs(theme),
            Expanded(
              child: jobsAsync.when(
                data: (jobsState) {
                  final filteredPostings = _getFiltered(jobsState);
                  return _buildPostingsList(theme, filteredPostings);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
            // _buildPostNewJobCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 10.h),

      child: Row(
        spacing: 8.w,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
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

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(width: 12.w),
          Icon(
            Icons.search,
            size: 18.sp,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                hintText: 'Search by job title, ID, or keywords...',
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
                size: 16.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  Widget _buildPostingsList(ThemeData theme, List<JobPosting> list) {
    // Already watching jobsAsync in build method
    final jobsAsync = ref.read(jobsStateProvider);

    if (jobsAsync.isLoading && list.isEmpty) {
      return _buildPostingsShimmer(theme);
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 40.sp,
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
            SizedBox(height: 10.h),
            Text(
              jobsAsync.error != null
                  ? 'Error loading jobs'
                  : 'No postings found',
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (jobsAsync.error != null) ...[
              SizedBox(height: 8.h),
              Text(
                jobsAsync.error.toString(),
                style: TextStyle(fontSize: 12.sp, color: Colors.red),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(onPressed: _loadJobs, child: Text('Retry')),
            ],
          ],
        ),
      );
    }
    // return Column(children: list.map((p) => _postingCard(p)).toList());
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      itemCount: list.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) => _postingCard(list[i], theme),
    );
  }

  Widget _postingCard(JobPosting posting, ThemeData theme) {
    final isClosed = posting.status == PostingStatus.closed;
    final isPending = posting.status == PostingStatus.pendingReview;
    final isRejected = posting.status == PostingStatus.rejected;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(jobId: posting.id),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          // color: theme.colorScheme.surface,
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isPending
                ? const Color(0xFFFDE68A).withValues(alpha: 0.5)
                : isRejected
                ? Colors.red.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.15),
            style: BorderStyle.solid,
            width: (isPending || isRejected) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: isClosed ? 0.75 : 1.0,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge + menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusBadge(posting.status),
                    GestureDetector(
                      onTap: () => _showPostingMenu(posting),
                      child: Icon(
                        Icons.more_vert,
                        size: 20.sp,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // Title
                Row(
                  spacing: 12.w,
                  children: [
                    ShimmerImage(
                      imageUrl: posting.companyLogoUrl,
                      width: 44.w,
                      height: 44.w,
                      borderRadius: 8.r,
                      errorWidget: Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 16.sp,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            posting.title,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: isClosed
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    )
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13.sp,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                posting.location,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Pending review or Rejected special layout
                if (isPending || isRejected)
                  _statusFeedbackRow(posting)
                else ...[
                  // Applicant avatars + count
                  _applicantRow(posting),
                  SizedBox(height: 12.h),
                  _actionButtons(posting, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusFeedbackRow(JobPosting posting) {
    final isRejected = posting.status == PostingStatus.rejected;
    final color = isRejected ? Colors.red : AppColors.warning;
    final bgColor = isRejected
        ? Colors.red.withValues(alpha: 0.1)
        : const Color(0xFFFEF9C3);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(
                isRejected ? Icons.error_outline : Icons.hourglass_top_outlined,
                size: 16.sp,
                color: color,
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejected ? 'Job Rejected' : 'Awaiting Approval',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isRejected ? Colors.red : AppColors.textDark,
                  ),
                ),
                Text(
                  isRejected
                      ? 'Click edit to view reason'
                      : posting.applicantSubtitle,
                  style: TextStyle(fontSize: 11.sp, color: color),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _editDraft(posting),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isRejected ? Colors.red : AppColors.secondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 11.h),
            ),
            child: Text(
              isRejected ? 'Fix & Resubmit' : 'Edit Draft',
              style: TextStyle(
                color: isRejected ? Colors.red : AppColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _applicantRow(JobPosting posting) {
    final isClosed = posting.status == PostingStatus.closed;
    return Row(
      children: [
        // Stacked avatars
        SizedBox(
          height: 28.w,
          width: (posting.avatarUrls.length.clamp(0, 3) * 20 + 10).w,
          child: Stack(
            children: [
              ...posting.avatarUrls
                  .take(3)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (e) => Positioned(
                      left: (e.key * 18).w,
                      child: ShimmerImage(
                        imageUrl: e.value.isNotEmpty ? e.value : '',
                        width: 28.w,
                        height: 28.w,
                        borderRadius: 14.r,
                        errorWidget: CircleAvatar(
                          radius: 14.r,
                          backgroundColor: AppColors.secondary
                              .withValues(alpha: 0.15),
                          child: Icon(
                            Icons.person,
                            size: 14.sp,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        if (posting.applicantCount > 3) ...[
          SizedBox(width: 4.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              '+${posting.applicantCount - 3}',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${posting.applicantCount} Applicants',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              posting.applicantSubtitle,
              style: TextStyle(
                fontSize: 11.sp,
                color: isClosed ? AppColors.textMuted : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButtons(JobPosting posting, ThemeData theme) {
    final isClosed = posting.status == PostingStatus.closed;
    if (isClosed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(jobId: posting.id),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 11.h),
          ),
          child: Text(
            'View Details',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobDetailScreen(jobId: posting.id),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.tertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              elevation: 2,
              shadowColor: theme.colorScheme.tertiary.withValues(alpha: 0.3),
            ),
            child: Text(
              'Manage',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ApplicantsListScreen(
                  isBackButton: true,
                  jobId: posting.id,
                ),
              ),
            ),
            icon: Icon(
              Icons.people_outline,
              color: theme.colorScheme.tertiary,
              size: 20.sp,
            ),
            padding: EdgeInsets.all(10.w),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(PostingStatus status) {
    final cfg = switch (status) {
      PostingStatus.active => (
        label: 'ACTIVE',
        bg: const Color(0xFFECFDF5),
        fg: AppColors.success,
      ),
      PostingStatus.closed => (
        label: 'CLOSED',
        bg: const Color(0xFFF1F5F9),
        fg: AppColors.textMuted,
      ),
      PostingStatus.pendingReview => (
        label: 'PENDING REVIEW',
        bg: const Color(0xFFFEF9C3),
        fg: AppColors.warning,
      ),
      PostingStatus.rejected => (
        label: 'REJECTED',
        bg: const Color(0xFFFFEBEE),
        fg: Colors.red,
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(6.r),
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

  Widget _buildPostNewJobCTA() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/recruiter/post-job'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: AppColors.secondary, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              'Post New Job',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Reach thousands of top candidates instantly.',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostingMenu(JobPosting posting) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (_) => Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              posting.title,
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            _menuItem(
              Icons.visibility_outlined,
              'View Details',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailScreen(jobId: posting.id),
                  ),
                );
              },
            ),
            _menuItem(
              Icons.edit_outlined,
              'Edit Posting',
              () {
                Navigator.pop(context);
                _navigateToEditJob(posting);
              },
            ),
            _menuItem(
              Icons.people_outline,
              'View Applicants',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicantsListScreen(
                      isBackButton: true,
                      jobId: posting.id,
                    ),
                  ),
                );
              },
            ),
            _menuItem(
              Icons.pause_circle_outline,
              'Pause Posting',
              () => _showSnack('Paused'),
            ),
            _menuItem(
              Icons.delete_outline,
              'Delete Posting',
              () => _confirmDelete(posting),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22.sp),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _confirmDelete(JobPosting posting) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          'Delete "${posting.title}"?',
          style: TextStyle(fontSize: 15.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              // Remove the job from the provider
              ref.read(jobsStateProvider.notifier).deleteJob(posting.id);
              _showSnack('Posting deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editDraft(JobPosting posting) => _navigateToEditJob(posting);

  void _navigateToEditJob(JobPosting posting) {
    // Get the job data from the provider state
    final jobsState = ref.read(jobsStateProvider).value;
    if (jobsState == null) {
      _showSnack('Unable to load job details');
      return;
    }

    final job = jobsState.recruiterJobs.firstWhere(
      (j) => j.id.toString() == posting.id,
      orElse: () => throw Exception('Job not found'),
    );

    // Navigate to JobPostScreen with job data for editing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobPostScreen(
          job: job,
          isBackButton: true,
        ),
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

  // ── Shimmer Loading Widget ─────────────────────────────────────────────
  Widget _buildPostingsShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          height: 180.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }
}
