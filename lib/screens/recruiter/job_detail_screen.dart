import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/core/providers/jobs_provider.dart';
import 'package:airigo_jobportal/models/application_model.dart';
import 'package:airigo_jobportal/screens/recruiter/applicant_review_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/applicants_list_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/job_post_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/job_model.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({required this.jobId, super.key});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  List<ApplicationModel> _jobApplications = [];
  bool _isLoadingApplications = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobApplications());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJobApplications() async {
    setState(() => _isLoadingApplications = true);
    try {
      final jobsState = ref.read(jobsStateProvider).value;
      if (jobsState != null) {
        final apps = jobsState.recentApplications
            .where((app) => app.jobId.toString() == widget.jobId)
            .toList();
        setState(() {
          _jobApplications = apps;
          _isLoadingApplications = false;
        });
      } else {
        setState(() => _isLoadingApplications = false);
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
      setState(() => _isLoadingApplications = false);
    }
  }

  Future<void> _refreshData() async {
    await ref.read(jobsStateProvider.notifier).loadRecruiterJobs();
    await _loadJobApplications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jobsAsync = ref.watch(jobsStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // appBar: _buildAppBar(isDark),
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        // forceMaterialTransparency: true,
        elevation: 1,
        shadowColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

        title: Text(
          'Job Details',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18.sp,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          _AppBarIconButton(
            icon: Icons.share_outlined,
            isDark: isDark,
            onTap: () {},
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            color: isDark ? Colors.grey.shade800 : Colors.white,
            icon: _AppBarIconButton(
              icon: Icons.more_vert_rounded,
              isDark: isDark,
              onTap: null,
            ),
            onSelected: (v) => _handleMenuAction(v, context),
            itemBuilder: (_) => [
              _popupItem(
                'edit',
                Icons.edit_outlined,
                'Edit Job',
                isDark,
                theme,
              ),
              _popupItem(
                'applicants',
                Icons.people_outline,
                'View All Applicants',
                isDark,
                theme,
              ),
              _popupItem(
                'pause',
                Icons.pause_circle_outline,
                'Pause Job',
                isDark,
                theme,
              ),
              const PopupMenuDivider(),
              _popupItemDanger('delete', Icons.delete_outline, 'Delete Job'),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshData,
        child: jobsAsync.when(
          data: (state) {
            final job = state.recruiterJobs.firstWhere(
              (j) => j.id.toString() == widget.jobId,
              orElse: () => throw Exception('Job not found'),
            );
            return FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                child: Column(
                  spacing: 14.h,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJobHeader(job, isDark),
                    _buildStatisticsCard(job, isDark),
                    _buildJobDescription(job, isDark),
                    _buildSkillsSection(job, isDark),
                    _buildRequirements(job, isDark),
                    _buildRecentApplicants(job, isDark),
                  ],
                ),
              ),
            );
          },
          loading: () => _buildJobDetailShimmer(theme, isDark),
          error: (err, _) => _buildErrorState(err, isDark),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(isDark),
    );
  }

  PopupMenuItem<String> _popupItem(
    String value,
    IconData icon,
    String label,
    bool isDark,
    ThemeData theme,
  ) {
    return PopupMenuItem(
      value: value,
      height: 42.h,
      child: Row(
        children: [
          Icon(icon, size: 17.sp, color: theme.colorScheme.onSurface),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItemDanger(
    String value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      height: 42.h,
      child: Row(
        children: [
          Icon(icon, size: 17.sp, color: AppColors.error),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Job Header ────────────────────────────────────────────────────────────
  Widget _buildJobHeader(JobModel job, bool isDark) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo with gradient border
              _CompanyLogo(url: job.companyLogoUrl, isDark: isDark),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),
                    Text(
                      job.designation,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      spacing: 8.w,
                      children: [
                        Icon(Icons.business_rounded, size: 13.sp),
                        Expanded(
                          child: Text(
                            job.companyName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _StatusBadge(job: job),
            ],
          ),

          SizedBox(height: 16.h),
          // ── Meta chips ──
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _MetaChip(
                icon: Icons.location_on_outlined,
                title: "Location: ",
                label: job.location,
                isDark: isDark,
              ),
              _MetaChip(
                icon: Icons.work_outline_rounded,
                title: "Job Type: ",
                label: job.jobType,
                isDark: isDark,
              ),
              _MetaChip(
                icon: Icons.category_outlined,
                title: "Category: ",
                label: job.category,
                isDark: isDark,
              ),
              _MetaChip(
                icon: Icons.payments_outlined,
                title: "CTC: ",
                label: job.ctc,
                isDark: isDark,
                highlight: true,
              ),
            ],
          ),

          if (job.isUrgentHiring == true) ...[
            SizedBox(height: 14.h),
            _UrgentBadge(),
          ],

          // ── Posted date row ──
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12.sp),
              SizedBox(width: 5.w),
              Text(
                'Posted ${_timeAgo(job.createdAt)}',
                style: TextStyle(fontSize: 11.sp),
              ),
              const Spacer(),
              Icon(Icons.visibility_outlined, size: 12.sp),
              SizedBox(width: 5.w),
              Text(
                '${job.applicantsCount ?? 0} views',
                style: TextStyle(fontSize: 11.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Statistics ────────────────────────────────────────────────────────────
  Widget _buildStatisticsCard(JobModel job, bool isDark) {
    final total = _jobApplications.length;
    final pending = _jobApplications
        .where((a) => a.status == ApplicationStatus.pending)
        .length;
    final shortlisted = _jobApplications
        .where((a) => a.status == ApplicationStatus.shortlisted)
        .length;
    final rejected = _jobApplications
        .where((a) => a.status == ApplicationStatus.rejected)
        .length;

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Applications',
            subtitle: 'Overview',
            isDark: isDark,
            action: _TextAction(
              label: 'View All',
              onTap: () => _openApplicants(),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            spacing: 6.w,
            children: [
              Expanded(
                child: _StatTile(
                  count: total,
                  label: 'Total',
                  color: AppColors.secondary,
                  icon: Icons.group_outlined,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatTile(
                  count: pending,
                  label: 'Pending',
                  color: AppColors.warning,
                  icon: Icons.hourglass_top_outlined,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatTile(
                  count: shortlisted,
                  label: 'Shortlisted',
                  color: AppColors.success,
                  icon: Icons.verified_outlined,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatTile(
                  count: rejected,
                  label: 'Rejected',
                  color: AppColors.error,
                  icon: Icons.cancel_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            SizedBox(height: 16.h),
            _ApplicationProgressBar(
              total: total,
              pending: pending,
              shortlisted: shortlisted,
              rejected: rejected,
            ),
          ],
        ],
      ),
    );
  }

  // ── Description ───────────────────────────────────────────────────────────
  Widget _buildJobDescription(JobModel job, bool isDark) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Job Description',
            isDark: isDark,
            icon: Icons.description_outlined,
          ),
          SizedBox(height: 12.h),
          Text(
            job.description ?? 'No description provided.',
            style: TextStyle(
              fontSize: 13.5.sp,
              height: 1.7,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Skills Section ────────────────────────────────────────────────────────
  Widget _buildSkillsSection(JobModel job, bool isDark) {
    if (job.skillsRequired == null || job.skillsRequired!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Required Skills',
            isDark: isDark,
            icon: Icons.stars_outlined,
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: job.skillsRequired!
                .map((skill) => _SkillChip(skill: skill))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Requirements ──────────────────────────────────────────────────────────
  Widget _buildRequirements(JobModel job, bool isDark) {
    if (job.requirements == null || job.requirements!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Requirements',
            isDark: isDark,
            icon: Icons.checklist_rounded,
          ),
          SizedBox(height: 14.h),
          ...job.requirements!.asMap().entries.map(
            (entry) => _RequirementRow(
              text: entry.value,
              index: entry.key,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Applicants ─────────────────────────────────────────────────────
  Widget _buildRecentApplicants(JobModel job, bool isDark) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recent Applicants',
            isDark: isDark,
            icon: Icons.people_alt_outlined,
            action: _jobApplications.isNotEmpty
                ? _TextAction(label: 'View All', onTap: _openApplicants)
                : null,
          ),
          SizedBox(height: 14.h),
          if (_isLoadingApplications)
            _LoadingState()
          else if (_jobApplications.isEmpty)
            _EmptyApplicants(isDark: isDark)
          else
            ..._jobApplications
                .take(5)
                .map(
                  (app) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplicantReviewScreen(application: app),
                      ),
                    ),
                    child: _ApplicantRow(app: app, isDark: isDark),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Bottom Actions ────────────────────────────────────────────────────────
  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editJob,
              icon: Icon(Icons.edit_outlined, size: 16.sp),
              label: Text(
                'Edit Job',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                side: BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _openApplicants,
              icon: Icon(Icons.people_rounded, size: 17.sp),
              label: Text(
                'View Applicants${_jobApplications.isNotEmpty ? ' (${_jobApplications.length})' : ''}',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────────────────────
  Widget _buildErrorState(Object err, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36.sp,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              err.toString(),
              style: TextStyle(fontSize: 11.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _openApplicants() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ApplicantsListScreen(isBackButton: true, jobId: widget.jobId),
    ),
  );

  void _handleMenuAction(String action, BuildContext ctx) {
    switch (action) {
      case 'edit':
        _editJob();
        break;
      case 'applicants':
        _openApplicants();
        break;
      case 'pause':
        _toggleJobStatus();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _editJob() {
    final state = ref.read(jobsStateProvider).value;
    if (state == null) return;
    final job = state.recruiterJobs.firstWhere(
      (j) => j.id.toString() == widget.jobId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobPostScreen(job: job, isBackButton: true),
      ),
    );
  }

  Future<void> _toggleJobStatus() async {
    try {
      final state = ref.read(jobsStateProvider).value;
      if (state == null) return;
      final job = state.recruiterJobs.firstWhere(
        (j) => j.id.toString() == widget.jobId,
      );
      final newStatus = job.isActive == false;
      await ref
          .read(jobsStateProvider.notifier)
          .updateJob(job.id.toString(), isActive: newStatus);
      _showSnack(newStatus ? 'Job activated' : 'Job paused');
      await _refreshData();
    } catch (_) {
      _showSnack('Failed to update job status', isError: true);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Delete Job?',
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'This will permanently remove the job posting and all associated applications. This cannot be undone.',
          style: TextStyle(fontSize: 13.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteJob();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJob() async {
    try {
      await ref.read(jobsStateProvider.notifier).deleteJob(widget.jobId);
      if (mounted) {
        _showSnack('Job deleted successfully');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to delete job', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    AppScaffoldFeedback.show(
      context,
      message: msg,
      type: isError ? ResponseType.error : ResponseType.warning,
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  // ── Shimmer Loading Widget ─────────────────────────────────────────────
  Widget _buildJobDetailShimmer(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        spacing: 14.h,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job header shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Container(
              height: 180.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Statistics shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Container(
              height: 150.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Description shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Skills shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Requirements shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Applicants shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            highlightColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Container(
              height: 250.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets (extracted for clarity and reuse)
// ─────────────────────────────────────────────────────────────────────────────

/// Generic card container
class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Section header with optional icon + action
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isDark;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 15.sp, color: AppColors.primary),
          ),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 11.sp)),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Company logo widget
class _CompanyLogo extends StatelessWidget {
  final String? url;
  final bool isDark;

  const _CompanyLogo({this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ShimmerImage(
        imageUrl: url != null && url!.isNotEmpty ? url! : '',
        width: 60.w,
        height: 60.w,
        borderRadius: 13.r,
        errorWidget: _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Icon(
        Icons.business_rounded,
        size: 26.sp,
        color: AppColors.primary,
      ),
    );
  }
}

/// Status badge
class _StatusBadge extends StatelessWidget {
  final JobModel job;

  const _StatusBadge({required this.job});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    late IconData icon;
    final theme = Theme.of(context);

    final status = job.approvalStatus.toLowerCase();
    if (status == 'pending' || status == 'pending_approval') {
      bg = AppColors.warning.withValues(alpha: 0.12);
      fg = AppColors.warning;
      label = 'Pending';
      icon = Icons.schedule_rounded;
    } else if (status == 'rejected') {
      bg = AppColors.error.withValues(alpha: 0.10);
      fg = AppColors.error;
      label = 'Rejected';
      icon = Icons.block_rounded;
    } else if (job.isActive == false) {
      bg = const Color(0xFF64748B).withValues(alpha: 0.10);
      fg = const Color(0xFF64748B);
      label = 'Closed';
      icon = Icons.lock_outline_rounded;
    } else {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      label = 'Active';
      icon = Icons.circle;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: label == 'Active' ? 8.sp : 11.sp, color: fg),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Meta chip
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final bool isDark;
  final bool highlight;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.title,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? AppColors.success.withValues(alpha: 0.08)
        : isDark
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final fg = highlight
        ? AppColors.success
        : isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black54;
    final border = highlight
        ? AppColors.success.withValues(alpha: 0.2)
        : Colors.transparent;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        // border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: fg),
          SizedBox(width: 5.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: fg,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              highlight ? '₹$label' : label,
              style: TextStyle(
                fontSize: 13.sp,
                color: fg,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Urgent badge
class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 15.sp, color: AppColors.primary),
          SizedBox(width: 5.w),
          Text(
            'Urgent Hiring',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat tile in the statistics card
class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 5.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(height: 6.h),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Segmented progress bar showing application pipeline
class _ApplicationProgressBar extends StatelessWidget {
  final int total, pending, shortlisted, rejected;

  const _ApplicationProgressBar({
    required this.total,
    required this.pending,
    required this.shortlisted,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Application Pipeline',
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: Row(
            children: [
              _bar(AppColors.success, shortlisted / total),
              _bar(AppColors.warning, pending / total),
              _bar(AppColors.error, rejected / total),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            _legend(AppColors.success, 'Shortlisted'),
            SizedBox(width: 12.w),
            _legend(AppColors.warning, 'Pending'),
            SizedBox(width: 12.w),
            _legend(AppColors.error, 'Rejected'),
          ],
        ),
      ],
    );
  }

  Widget _bar(Color color, double fraction) => Expanded(
    flex: (fraction * 100).round().clamp(1, 100),
    child: Container(height: 6.h, color: color),
  );

  Widget _legend(Color color, String label) => Row(
    children: [
      Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      SizedBox(width: 4.w),
      Text(label, style: TextStyle(fontSize: 10.sp)),
    ],
  );
}

/// Requirement bullet row
class _RequirementRow extends StatelessWidget {
  final String text;
  final int index;
  final bool isDark;

  const _RequirementRow({
    required this.text,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(top: 5.h),
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13.sp, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

/// Skill chip widget
class _SkillChip extends StatelessWidget {
  final String skill;

  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 6.w),
          Text(
            skill,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Applicant row card
class _ApplicantRow extends StatelessWidget {
  final ApplicationModel app;
  final bool isDark;

  const _ApplicantRow({required this.app, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = app.status == ApplicationStatus.accepted
        ? AppColors.success
        : app.status == ApplicationStatus.shortlisted
        ? AppColors.secondary
        : app.status == ApplicationStatus.pending
        ? AppColors.warning
        : app.status == ApplicationStatus.rejected
        ? AppColors.error
        : AppColors.error;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundImage:
                    app.jobseekerPhotoUrl != null &&
                        app.jobseekerPhotoUrl!.isNotEmpty
                    ? NetworkImage(app.jobseekerPhotoUrl!)
                    : null,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: app.jobseekerPhotoUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 20.sp,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 1.5),
                  ),
                ),
              ),
            ],
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  app.jobseekerCurrentRole ?? 'Applied for role',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  app.status.label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Icon(Icons.chevron_right_rounded, size: 16.sp),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loading shimmer placeholder
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

/// Empty applicants state
class _EmptyApplicants extends StatelessWidget {
  final bool isDark;

  const _EmptyApplicants({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 32.sp,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            SizedBox(height: 12.h),
            Text('No applicants yet', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 4.h),
            Text(
              'Share this job to attract candidates',
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}

/// AppBar icon button
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.1),
          ),
        ),
        child: Icon(icon, size: 18.sp, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
