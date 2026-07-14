import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:airigo_jobportal/core/providers/jobs_provider.dart';
import 'package:airigo_jobportal/models/job_model.dart';
import 'package:airigo_jobportal/screens/common/job_detail_screen.dart';

class RecruiterProfileInfo extends ConsumerStatefulWidget {
  final String user;
  final String name;
  final String designation;
  final String companyName;
  final String email;
  final String contact;
  final String location;
  final String photoUrl;
  final String? companyWebsite;
  final String? about;
  final String? approvalStatus;
  final String? joinedDate;
  final int? postedJobsCount;
  final String? recruiterUserId;

  const RecruiterProfileInfo({
    required this.user,
    required this.name,
    required this.designation,
    required this.companyName,
    required this.email,
    required this.contact,
    required this.location,
    required this.photoUrl,
    this.companyWebsite,
    this.about,
    this.approvalStatus,
    this.joinedDate,
    this.postedJobsCount,
    this.recruiterUserId,
    super.key,
  });

  @override
  ConsumerState<RecruiterProfileInfo> createState() =>
      _RecruiterProfileInfoState();
}

class _RecruiterProfileInfoState extends ConsumerState<RecruiterProfileInfo> {
  List<JobModel> _postedJobs = [];
  bool _isLoadingJobs = false;

  @override
  void initState() {
    super.initState();
    if (widget.recruiterUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fetchRecruiterJobs(),
      );
    }
  }

  Future<void> _fetchRecruiterJobs() async {
    if (widget.recruiterUserId == null) return;
    setState(() => _isLoadingJobs = true);
    try {
      final jobs = await ref
          .read(jobsStateProvider.notifier)
          .getJobsByRecruiter(widget.recruiterUserId!);
      if (mounted) {
        setState(() {
          _postedJobs = jobs ?? [];
          _isLoadingJobs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingJobs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────
          SliverAppBar(
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            // forceMaterialTransparency: true,
            elevation: 1,
            shadowColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

            title: Text(
              'Recruiter profile',
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

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                spacing: 12.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile hero card ─────────────────────────────
                  _sectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32.r,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: widget.photoUrl.isNotEmpty
                              ? NetworkImage(widget.photoUrl)
                              : null,
                          child: widget.photoUrl.isEmpty
                              ? Text(
                                  widget.name.isNotEmpty
                                      ? widget.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                widget.designation,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                widget.companyName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.companyWebsite != null &&
                                  widget.companyWebsite!.isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.link_rounded,
                                      size: 12.sp,
                                      color: theme.colorScheme.primary,
                                    ),
                                    SizedBox(width: 4.w),
                                    Flexible(
                                      child: Text(
                                        widget.companyWebsite!,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: theme.colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Stats ─────────────────────────────────────────
                  if (_postedJobs.length.toString() != null ||
                      widget.joinedDate != null)
                    _sectionCard(
                      child: Row(
                        spacing: 12.w,
                        children: [
                          if (_postedJobs.length.toString() != null)
                            Expanded(
                              child: _statBox(
                                Icons.work_outline_rounded,
                                'Posted jobs',
                                _postedJobs.length.toString(),
                              ),
                            ),
                          if (widget.postedJobsCount != null &&
                              widget.joinedDate != null)
                            SizedBox(width: 10.w),
                          if (widget.joinedDate != null)
                            Expanded(
                              child: _statBox(
                                Icons.calendar_today_outlined,
                                'Member since',
                                _formatJoinDate(widget.joinedDate!),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // ── About ─────────────────────────────────────────
                  if (widget.about != null && widget.about!.isNotEmpty)
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            Icons.info_outline_rounded,
                            'About',
                            null,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            widget.about!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Contact ───────────────────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          Icons.contact_page_outlined,
                          'Contact information',
                          null,
                        ),
                        SizedBox(height: 4.h),
                        _infoRow(Icons.email_outlined, 'Email', widget.email),
                        _divider(),
                        _infoRow(
                          Icons.phone_outlined,
                          'Contact',
                          widget.contact,
                        ),
                        _divider(),
                        _infoRow(
                          Icons.location_on_outlined,
                          'Location',
                          widget.location,
                        ),
                      ],
                    ),
                  ),

                  // ── Action buttons ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Call now',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Posted jobs ───────────────────────────────────
                  if (widget.recruiterUserId != null)
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            Icons.work_outline_rounded,
                            'Posted jobs',
                            _postedJobs.length,
                          ),
                          SizedBox(height: 12.h),
                          if (_isLoadingJobs)
                            Column(
                              children: List.generate(
                                5,
                                (_) => _shimmerJobCard(),
                              ),
                            )
                          else if (_postedJobs.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Center(
                                child: Text(
                                  'No jobs posted yet',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: _postedJobs
                                  .map((job) => _jobCard(job))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),

                  SizedBox(height: 28.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable section card wrapper ─────────────────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withValues(
              alpha: context.isDark ? 0.2 : 0.1,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Section header with green dot + count badge ───────────────────
  Widget _sectionHeader(IconData icon, String title, int? count) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.colorScheme.primary,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        if (count != null) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: context.theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11.sp,
                color: context.theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Stat box ──────────────────────────────────────────────────────
  Widget _statBox(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.07)
            : context.theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: context.isDark
                ? Colors.white
                : context.theme.colorScheme.primary,
            size: 20.sp,
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.isDark
                  ? Colors.white
                  : context.theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.isDark
                  ? Colors.white
                  : context.theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact info row ──────────────────────────────────────────────
  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? valueWidget,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: context.theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: context.theme.colorScheme.primary,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 2.h),
                valueWidget ??
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats an ISO date string → "Jan 2023"
  String _formatJoinDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      return DateFormat('MMM yyyy').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  Widget _divider() => Divider(
    height: 0,
    thickness: 0.5,
    color: Colors.grey.shade100.withValues(alpha: 0.2),
  );

  // ── Shimmer skeleton card ─────────────────────────────────────────
  Widget _shimmerJobCard() {
    return Shimmer.fromColors(
      baseColor: context.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: context.isDark
          ? Colors.grey.shade100
          : Colors.grey.shade200,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12.h,
                    width: double.infinity * 0.65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Container(
                    height: 10.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Row(
                    children: [
                      _shimmerPill(56.w),
                      SizedBox(width: 5.w),
                      _shimmerPill(48.w),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerPill(double width) {
    return Container(
      height: 20.h,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }

  // ── Job card ──────────────────────────────────────────────────────
  Widget _jobCard(JobModel job) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(job: job),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: context.theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: context.theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child:
                    job.companyLogoUrl != null &&
                        job.companyLogoUrl!.isNotEmpty &&
                        job.companyLogoUrl!.startsWith('http')
                    ? Image.network(
                        job.companyLogoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.work_outline_rounded,
                          color: context.theme.colorScheme.primary,
                          size: 18.sp,
                        ),
                      )
                    : Icon(
                        Icons.work_outline_rounded,
                        color: context.theme.colorScheme.primary,
                        size: 18.sp,
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (job.isUrgentHiring == true)
                        Container(
                          width: 6.w,
                          height: 6.h,
                          margin: EdgeInsets.only(right: 5.w, top: 2.h),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE24B4A),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          job.designation,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    job.companyName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 5.h,
                    children: [
                      if (job.location != null)
                        _pill(job.location, PillStyle.blue),
                      if (job.ctc != null)
                        _pill("₹ ${job.ctc}", PillStyle.green),
                      if (job.jobType != null)
                        _pill(job.jobType, PillStyle.neutral),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, PillStyle style) {
    Color bg, fg, border;
    switch (style) {
      case PillStyle.green:
        bg = AppColors.success.withOpacity(0.1);
        fg = AppColors.success.withOpacity(0.6);
        border = context.theme.dividerColor.withValues(alpha: 0.2);
        break;
      case PillStyle.blue:
        bg = AppColors.statusPending.withOpacity(0.1);
        fg = AppColors.statusPending.withOpacity(0.6);
        border = context.theme.dividerColor.withValues(alpha: 0.2);
        break;
      case PillStyle.neutral:
        bg = const Color.fromARGB(255, 12, 218, 233).withValues(alpha: 0.1);
        fg = const Color.fromARGB(255, 12, 218, 233).withValues(alpha: 0.6);
        border = const Color.fromARGB(255, 12, 218, 233).withValues(alpha: 0.2);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.sp, color: fg),
      ),
    );
  }
}

enum PillStyle { green, blue, neutral }
