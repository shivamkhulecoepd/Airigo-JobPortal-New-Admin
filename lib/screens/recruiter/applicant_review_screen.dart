import 'dart:developer';

import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../models/application_model.dart';
import '../../models/recruiter_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'job_detail_screen.dart';

class ApplicantReviewScreen extends ConsumerStatefulWidget {
  final ApplicationModel? application;
  const ApplicantReviewScreen({this.application, super.key});
  @override
  ConsumerState<ApplicantReviewScreen> createState() =>
      _ApplicantReviewScreenState();
}

class _ApplicantReviewScreenState extends ConsumerState<ApplicantReviewScreen> {
  String _selectedStatus =
      'pending'; // Initialize with the current status from the application
  String _selectedAction = 'shortlist'; // Add this field
  final _noteCtrl = TextEditingController();
  final List<String> _savedNotes = [];
  final List<String> _noteAuthors = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();

    // Log all application data in a readable format
    final app = widget.application;
    if (app != null) {
      log('=== APPLICATION DATA ===');
      log('ID: ${app.id}');
      log('Job ID: ${app.jobId}');
      log('Job Title: ${app.jobTitle}');
      log('Company: ${app.company}');
      log('Location: ${app.location}');
      log('Job Type: ${app.jobType}');
      log('Status: ${app.status.label}');
      log('CTC: ${app.ctcMin}-${app.ctcMax} LPA');
      log('\n--- JOBSEEKER DETAILS ---');
      log('Name: ${app.jobseekerName ?? "N/A"}');
      log('Email: ${app.jobseekerEmail ?? "N/A"}');
      log('Phone: ${app.jobseekerPhone ?? "N/A"}');
      log('Photo URL: ${app.jobseekerPhotoUrl ?? "N/A"}');
      log('Current Role: ${app.jobseekerCurrentRole ?? "N/A"}');
      log('Bio: ${app.jobseekerBio ?? "N/A"}');
      log('Qualification: ${app.jobseekerQualification ?? "N/A"}');
      log(
        'Experience: ${app.jobseekerExperience != null ? "${app.jobseekerExperience} years" : "N/A"}',
      );
      log('Skills: ${app.jobseekerSkills?.join(", ") ?? "N/A"}');
      log('Resume URL: ${app.resumeUrl}');
      log('\n--- RECRUITER DETAILS ---');
      log('Recruiter Name: ${app.recruiterName ?? "N/A"}');
      log('Company Website: ${app.companyWebsite ?? "N/A"}');
      log('Company URL: ${app.companyUrl ?? "N/A"}');
      log('Category: ${app.category ?? "N/A"}');
      log('\n--- DATES ---');
      log('Applied At: ${app.appliedAt}');
      log('Updated At: ${app.updatedAt ?? "N/A"}');
      log('========================');
    }

    // Initialize with the current application status in lowercase for consistency
    _selectedStatus = (widget.application?.status.label ?? 'Pending')
        .toLowerCase();

    // Load applicant data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplicantData();
    });
  }

  String _mapToDisplayStatus(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'shortlisted':
        return 'Shortlisted';
      case 'accepted':
        return 'Offer Extended';
      case 'rejected':
        return 'Rejected';
      default:
        return backendStatus;
    }
  }

  String _mapToBackendStatus(String displayStatus) {
    switch (displayStatus.toLowerCase()) {
      case 'pending':
        return 'pending';
      case 'shortlisted':
        return 'shortlisted';
      case 'reviewing':
      case 'phone screened':
        return 'reviewing';
      case 'offer extended':
        return 'accepted';
      case 'rejected':
        return 'rejected';
      default:
        return displayStatus.toLowerCase();
    }
  }

  // Helper method to convert status string to ApplicationStatus object
  ApplicationStatus _getStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'shortlisted':
        return ApplicationStatus.shortlisted;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }

  Future<void> _loadApplicantData() async {
    setState(() => _isLoadingData = true);
    // Here we would load the specific applicant data from the backend
    // For now, we'll use the dummy data as a fallback
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isLoadingData = false);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _downloadResume() async {
    final url = widget.application?.resumeUrl;
    if (url == null || url.isEmpty) {
      AppScaffoldFeedback.show(
        context,
        message: 'Resume URL not available',
        type: ResponseType.error,
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppScaffoldFeedback.show(
        context,
        message: 'Could not launch resume URL',
        type: ResponseType.error,
      );
    }
  }

  void _navigateToJobDetails() {
    if (widget.application == null) return;

    final jobId = widget.application!.jobId.toString();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(jobId: jobId)),
    );
  }

  void _handleAction(String action) {
    if (widget.application == null) return;

    String backendStatus;
    String message;

    switch (action) {
      case 'shortlist':
        backendStatus = 'shortlisted';
        message = 'Applicant shortlisted successfully';
        break;
      case 'reject':
        backendStatus = 'rejected';
        message = 'Application rejected';
        break;
      case 'accept':
        backendStatus = 'accepted';
        message = 'Application accepted';
        break;
      case 'schedule':
        backendStatus = 'shortlisted';
        message = 'Interview scheduled';
        break;
      default:
        // Assume action is already a status value
        backendStatus = action;
        message =
            'Application status updated to ${_mapToDisplayStatus(action)}';
        break;
    }

    _updateApplicationStatus(backendStatus, message);
  }

  Future<void> _updateApplicationStatus(
    String status,
    String successMessage,
  ) async {
    if (widget.application == null) return;

    try {
      final success = await ref
          .read(jobsStateProvider.notifier)
          .updateApplicationStatus(widget.application!.id.toString(), status);

      if (success) {
        setState(() {
          _selectedStatus = status.toLowerCase();
        });

        AppScaffoldFeedback.show(
          context,
          message: successMessage,
          type: ResponseType.success,
        );

        // Refresh recruiter jobs to reflect the status change globally
        await ref.read(jobsStateProvider.notifier).loadRecruiterJobs();

        // Force rebuild of the widget to update the timeline section
        if (mounted) {
          setState(() {});
        }
      } else {
        AppScaffoldFeedback.show(
          context,
          message: 'Failed to update status',
          type: ResponseType.error,
        );
        // Reset the status to the original value if update failed
        setState(() {
          _selectedStatus = widget.application!.status.label.toLowerCase();
        });
      }
    } catch (e) {
      print('Error updating status: $e');
      AppScaffoldFeedback.show(
        context,
        message: 'Error: ${e.toString()}',
        type: ResponseType.error,
      );
      // Reset the status to the original value if update failed
      setState(() {
        _selectedStatus = widget.application!.status.label.toLowerCase();
      });
    }
  }

  // ── Job Details Card ────────────────────────────────────────────────────────
  Widget _buildJobDetailsSection(ThemeData theme) {
    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Applied For',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.application?.jobTitle ?? 'Job Title',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${widget.application?.jobType ?? "Full-time"} • ${widget.application?.location ?? "Location"}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _navigateToJobDetails,
              icon: Icon(Icons.info_outline, size: 16.sp),
              label: Text(
                'View Full Job Details',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
          if (widget.application?.coverLetter != null) ...[
            SizedBox(height: 12.h),
            _card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cover Letter',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.application?.coverLetter ??
                        'No cover letter provided',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () => _navigateToJobDetails(),
            icon: Icon(Icons.visibility_outlined, size: 16.sp),
            label: Text(
              'View Job Posting',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              minimumSize: Size(double.infinity, 40.h),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobsState = ref.watch(jobsStateProvider);
    final authState = ref.watch(authStateProvider);
    final recruiter = authState.value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        // forceMaterialTransparency: true,
        elevation: 1,
        shadowColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

        title: Text(
          'Applicant Review',
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Reload applications and jobs data from API
          await ref.read(jobsStateProvider.notifier).loadRecruiterJobs();
          await _loadApplicantData();
        },
        child: _isLoadingData
            ? _buildReviewShimmer(theme)
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      top: 16.h,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        spacing: 16.h,
                        children: [
                          _buildProfileSection(theme),
                          _buildApplicationTimelineSection(theme),
                          _buildJobDetailsSection(theme),
                          _buildContactSection(theme),
                          _buildBioSection(theme),
                          _buildQualificationSection(theme),
                          _buildSkillsSection(theme),
                          _buildResumeSection(theme),
                          _buildNotesSection(theme),
                          _buildActions(theme, recruiter),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Shimmer Loading Widget ─────────────────────────────────────────────
  Widget _buildReviewShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Profile shimmer
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                highlightColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                child: Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Timeline shimmer
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                highlightColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                child: Container(
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Job details shimmer
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                highlightColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                child: Container(
                  height: 180.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Contact section shimmer
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                highlightColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                child: Container(
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Qualification shimmer
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                highlightColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Skills shimmer
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                highlightColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Actions shimmer
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                highlightColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                child: Container(
                  height: 160.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ]),
          ),
        ),
      ],
    );
  }

  //── Profile Card ───────────────────────────────────────────────────────────
  Widget _buildProfileSection(ThemeData theme) {
    return _card(
      theme: theme,
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.05),
              ),
            ),
            child: ShimmerImage(
              imageUrl: widget.application?.jobseekerPhotoUrl ?? '',
              width: 100.w,
              height: 100.w,
              borderRadius: 50.r,
              errorWidget: CircleAvatar(
                radius: 50.r,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Icon(
                  Icons.person,
                  size: 48.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            widget.application?.jobseekerName ?? 'Applicant Name',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.application?.jobseekerCurrentRole ??
                'Applied for: ${widget.application?.jobTitle ?? "Position"}',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Application Timeline Section ──────────────────────────────────────────
  Widget _buildApplicationTimelineSection(ThemeData theme) {
    final app = widget.application;
    if (app == null) return const SizedBox.shrink();

    // Get the current status - either the selected status or the original status
    var currentStatus = app.status;
    // If the selected status is different from the original, use a temporary status
    if (_selectedStatus != app.status.label.toLowerCase()) {
      currentStatus = _getStatusFromString(_selectedStatus);
    }

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Application Timeline',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _timelineItem(
            icon: Icons.send_outlined,
            title: 'Application Submitted',
            dateTime: app.appliedAt,
            theme: theme,
            isCompleted: true,
          ),
          if (app.updatedAt != null && app.updatedAt != app.appliedAt) ...[
            SizedBox(height: 16.h),
            _timelineItem(
              icon: Icons.update_outlined,
              title: 'Last Updated',
              dateTime: app.updatedAt!,
              theme: theme,
              isCompleted: true,
            ),
          ],
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: currentStatus.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: currentStatus.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentStatus.icon,
                  color: currentStatus.color,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        currentStatus.label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: currentStatus.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required String title,
    required DateTime dateTime,
    required ThemeData theme,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: isCompleted
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isCompleted
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            icon,
            color: isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _formatDateTime(dateTime),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago at ${_formatTime(dateTime)}';
    } else {
      return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  // ── Contact Information Section ───────────────────────────────────────────
  Widget _buildContactSection(ThemeData theme) {
    final app = widget.application;
    if (app == null) return const SizedBox.shrink();

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          _contactInfoRow(
            Icons.email_outlined,
            'Email',
            app.jobseekerEmail ?? 'N/A',
            theme,
          ),
          SizedBox(height: 10.h),
          _contactInfoRow(
            Icons.phone_outlined,
            'Phone',
            app.jobseekerPhone ?? 'N/A',
            theme,
          ),
          SizedBox(height: 10.h),
          _contactInfoRow(
            Icons.location_on_outlined,
            'Location',
            app.location,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _contactInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bio Section ───────────────────────────────────────────────────────────
  Widget _buildBioSection(ThemeData theme) {
    final bio = widget.application?.jobseekerBio;
    if (bio == null || bio.isEmpty) return const SizedBox.shrink();

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Professional Bio',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            bio,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Qualification & Experience Section ───────────────────────────────────
  Widget _buildQualificationSection(ThemeData theme) {
    final app = widget.application;
    if (app == null) return const SizedBox.shrink();

    bool hasData =
        app.jobseekerQualification != null || app.jobseekerExperience != null;
    if (!hasData) return const SizedBox.shrink();

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Qualification & Experience',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (app.jobseekerQualification != null &&
              app.jobseekerQualification!.isNotEmpty) ...[
            _infoItem(
              icon: Icons.workspace_premium,
              label: 'Qualification',
              value: app.jobseekerQualification!,
              theme: theme,
            ),
            if (app.jobseekerExperience != null) SizedBox(height: 10.h),
          ],
          if (app.jobseekerExperience != null)
            _infoItem(
              icon: Icons.work_history,
              label: 'Experience',
              value: '${app.jobseekerExperience} years',
              theme: theme,
            ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Skills Section ────────────────────────────────────────────────────────
  Widget _buildSkillsSection(ThemeData theme) {
    final skills = widget.application?.jobseekerSkills;
    if (skills == null || skills.isEmpty) return const SizedBox.shrink();

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outline_rounded,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Skills',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: skills.map((skill) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  skill,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Resume Section ───────────────────────────────────────────────────────
  Widget _buildResumeSection(ThemeData theme) {
    final app = widget.application;
    if (app == null || app.resumeUrl.isEmpty) return const SizedBox.shrink();

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Resume',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _downloadResume,
              icon: Icon(Icons.download_outlined, size: 18.sp),
              label: Text(
                'Download Resume',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes Section ─────────────────────────────────────────────────────────
  Widget _buildNotesSection(ThemeData theme) {
    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Recruiter Notes',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Existing notes
          ..._savedNotes.asMap().entries.map(
            (e) => _noteItem(
              e.value,
              e.key < _noteAuthors.length ? _noteAuthors[e.key] : '— Recruiter',
            ),
          ),

          SizedBox(height: 12.h),

          // New note input
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Add a private note...',
              hintStyle: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.secondary),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: theme.colorScheme.onSurface,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: _saveNote,
              child: Text(
                'Save Note',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String label, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14.sp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteItem(String note, String author) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: const Border(
          left: BorderSide(color: AppColors.secondary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note,
            style: TextStyle(
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF334155),
              height: 1.5,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            author,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _saveNote() {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _savedNotes.add('"$text"');
      _noteAuthors.add('— You');
      _noteCtrl.clear();
    });

    AppScaffoldFeedback.show(
      context,
      message: 'Note saved successfully !',
      type: ResponseType.info,
    );
  }

  //── Action Bar ─────────────────────────────────────────────────────────────
  Widget _buildActions(ThemeData theme, Object? recruiter) {
    // Check if recruiter is a RecruiterModel
    bool canTakeAction = false;
    if (recruiter != null &&
        recruiter.runtimeType.toString().contains('RecruiterModel')) {
      canTakeAction = true;
    }

    // Get the current status from the application
    String currentStatus = widget.application?.status.label ?? 'Pending';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: canTakeAction ? _downloadResume : null,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(color: AppColors.textMuted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'Download Resume',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14.h,
                  horizontal: 12.w,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                  value: 'shortlisted',
                  child: Text('Shortlisted'),
                ),
                // DropdownMenuItem(value: 'interviewing', child: Text('Interviewing')),
                DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: canTakeAction
                  ? (String? newValue) {
                      if (newValue != null && newValue != _selectedStatus) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                        // Update the application status via API call
                        _updateApplicationStatus(
                          newValue,
                          'Application status updated to ${_mapToDisplayStatus(newValue)}',
                        );
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleInterview() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
              'Schedule Interview',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              '${widget.application?.jobseekerName ?? "Applicant"} • ${widget.application?.jobTitle ?? "Position"}',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 16.h),
            ...[
              ('Video Call — Tomorrow 10:00 AM', Icons.videocam_outlined),
              ('Phone Screen — Tomorrow 2:00 PM', Icons.phone_outlined),
              ('In-person — Friday 11:00 AM', Icons.location_on_outlined),
            ].map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(item.$2, color: AppColors.secondary, size: 18.sp),
                ),
                title: Text(item.$1, style: TextStyle(fontSize: 13.sp)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedStatus = 'shortlisted');

                  // Update application status in the backend
                  _updateApplicationStatus(
                    'shortlisted',
                    'Interview scheduled',
                  );

                  AppScaffoldFeedback.show(
                    context,
                    message: 'Interview scheduled: ${item.$1}',
                    type: ResponseType.info,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shortlistApplicant() {
    setState(() => _selectedStatus = 'shortlisted');

    // Update application status in the backend
    _updateApplicationStatus(
      'shortlisted',
      'Applicant shortlisted successfully',
    );

    AppScaffoldFeedback.show(
      context,
      message: 'Applicant shortlisted ✓',
      type: ResponseType.success,
    );
  }

  void _confirmReject() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          'Reject Applicant?',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to reject ${widget.application?.jobseekerName ?? "this applicant"}? This action cannot be undone.',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
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

              // Update application status in the backend
              _updateApplicationStatus('rejected', 'Applicant rejected');

              AppScaffoldFeedback.show(
                context,
                message: 'Applicant rejected',
                type: ResponseType.error,
              );
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  //── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({required Widget child, required ThemeData theme}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 1.h,
      color: theme.dividerColor.withValues(alpha: 0.1),
    );
  }
}

// ── Reusable icon button ──────────────────────────────────────────────────────
Widget _iconBtn(IconData icon, VoidCallback onTap, Color color) {
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

// ─── Status Options ───────────────────────────────────────────────────────────
final _statusOptions = [
  'Pending',
  'Shortlisted',
  'Interviewing',
  'Offer Extended',
  'Rejected',
];
