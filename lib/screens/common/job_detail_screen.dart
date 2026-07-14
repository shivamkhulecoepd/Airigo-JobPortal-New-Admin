import 'dart:ui';
import 'package:airigo_jobportal/core/providers/jobs_provider.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';
import '../../core/providers/saved_jobs_provider.dart';
import '../../core/providers/applications_provider.dart';
import '../../core/providers/jobseeker_profile_provider.dart';
import '../../widgets/app_scaffold_feedback.dart';
import 'apply_job_modal.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final JobModel? job;
  final String? jobId;

  const JobDetailScreen({super.key, this.job, this.jobId})
    : assert(
        job != null || jobId != null,
        'Either job or jobId must be provided',
      );

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  void _showApplyModal(BuildContext context, WidgetRef ref, JobModel job) {
    final profileState = ref.read(jobseekerProfileProvider);

    if (profileState.isLoading) {
      AppScaffoldFeedback.show(
        context,
        message: 'Loading your profile details...',
        type: ResponseType.info,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApplyJobModal(
        job: job,
        jobseekerName: profileState.profile?.name,
        jobseekerSkills: profileState.profile?.skills?.join(', '),
        resumeUrl: profileState.profile?.resumeUrl,
        resumeFilename: profileState.profile?.resumeFilename,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isSmall = mq.size.width < 360;
    final theme = Theme.of(context);

    // Determine the job to display
    JobModel? jobToShow = widget.job;

    final jobsState = ref.watch(jobsStateProvider);
    if (jobToShow == null && widget.jobId != null) {
      final state = jobsState.value;
      if (state != null) {
        jobToShow = [
          ...state.allJobs,
          ...state.recruiterJobs,
        ].where((j) => j.id.toString() == widget.jobId).firstOrNull;

        if (jobToShow == null && !state.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(jobsStateProvider.notifier).fetchJobById(widget.jobId!);
          });
        }
      }
    }

    if (jobToShow == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Job Details...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final job = jobToShow;

    // Watch providers for dynamic state
    final savedJobsState = ref.watch(savedJobsProvider);
    final isSaved =
        savedJobsState.value?.contains(job.id.toString()) ?? job.isInWishlist;

    final myApplications = ref.watch(applicationsStateProvider).value ?? [];
    final hasApplied = myApplications.any(
      (app) => app.jobId == job.id.toString(),
    );

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleIconButton(
                          theme,
                          Icons.arrow_back_ios_new_rounded,
                          () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            _circleIconButton(theme, Iconsax.share, () {
                              // Share logic
                            }),
                            SizedBox(width: 12.w),
                            _circleIconButton(
                              theme,
                              isSaved
                                  ? Iconsax.archive_add1
                                  : Iconsax.archive_add,
                              () async {
                                final wasSaved = isSaved;
                                await ref
                                    .read(savedJobsProvider.notifier)
                                    .toggle(job.id.toString(), jobModel: job);

                                if (mounted) {
                                  if (!wasSaved) {
                                    AppScaffoldFeedback.show(
                                      context,
                                      message: 'Job saved successfully!',
                                      type: ResponseType.success,
                                    );
                                  } else {
                                    AppScaffoldFeedback.show(
                                      context,
                                      message: 'Job removed from saved jobs',
                                      type: ResponseType.info,
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _heroSection(
                  context: context,
                  theme: theme,
                  imageUrl: job.companyLogoUrl ?? '',
                  company: job.companyName,
                  designation: job.designation,
                  location: job.location,
                  isUrgent: job.isUrgentHiring,
                  isSmall: isSmall,
                  postedTime: job.createdAt.timeAgo,
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.only(bottom: 100.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: 16.h),

                    _keyInfoChipsGrid(
                      theme: theme,
                      ctc: job.ctcRange,
                      jobType: job.jobType,
                      experience: job.experienceDisplay,
                      qualifications: job.category,
                      isSmall: isSmall,
                    ),

                    SizedBox(height: 24.h),

                    if (job.description != null &&
                        job.description!.isNotEmpty) ...[
                      _sectionTitle('Job Description'),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          job.description!,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    if (job.requirements != null &&
                        job.requirements!.isNotEmpty) ...[
                      _sectionTitle('Requirements'),
                      _bulletList(
                        theme: theme,
                        items: job.requirements!,
                        icon: Iconsax.personalcard,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 10.h),
                    ],

                    if (job.skillsRequired != null &&
                        job.skillsRequired!.isNotEmpty) ...[
                      _sectionTitle('Skills Required'),
                      _bulletList(
                        theme: theme,
                        items: job.skillsRequired!,
                        icon: Iconsax.activity,
                        color: theme.colorScheme.tertiary,
                      ),
                      SizedBox(height: 10.h),
                    ],

                    if (job.perksAndBenefits != null &&
                        job.perksAndBenefits!.isNotEmpty) ...[
                      _sectionTitle('Benefits & Perks'),
                      _bulletList(
                        theme: theme,
                        items: job.perksAndBenefits!,
                        icon: Iconsax.tag,
                        color: theme.colorScheme.tertiary,
                      ),
                    ],

                    SizedBox(height: 20.h),
                  ]),
                ),
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _applyBottomBar(theme, mq.padding.bottom, job, hasApplied),
          ),
        ],
      ),
    );
  }

  Widget _heroSection({
    required BuildContext context,
    required ThemeData theme,
    required String imageUrl,
    required String company,
    required String designation,
    required String location,
    required bool isUrgent,
    required bool isSmall,
    required String postedTime,
  }) {
    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: AspectRatio(
            aspectRatio: 11 / 10,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: theme.colorScheme.tertiary),
                  )
                : Container(color: theme.colorScheme.tertiary),
          ),
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ),

        if (isUrgent)
          Positioned(
            right: 10.w,
            top: 10.h,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Text(
                'URGENT HIRING',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 104.w,
                          height: 104.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 104.w,
                            height: 104.w,
                            color: Colors.white,
                            child: Icon(
                              Icons.business,
                              size: 48.sp,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        )
                      : Container(
                          width: 104.w,
                          height: 104.w,
                          color: Colors.white,
                          child: Icon(
                            Icons.business,
                            size: 48.sp,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                ),
                SizedBox(height: 12.h),
                Text(
                  designation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 26.sp : 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  company,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 20.sp : 22.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Posted $postedTime',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _keyInfoChipsGrid({
    required ThemeData theme,
    required String ctc,
    required String? jobType,
    required String? experience,
    required String? qualifications,
    required bool isSmall,
  }) {
    final items = [
      if (ctc.isNotEmpty) _ChipItem(Iconsax.moneys, ctc, 'Package'),
      if (jobType != null) _ChipItem(Iconsax.briefcase, jobType, 'Type'),
      if (experience != null)
        _ChipItem(Iconsax.clock, experience, 'Experience'),
      if (qualifications != null)
        _ChipItem(Iconsax.teacher, qualifications, 'Category'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 12.h,
        children: items.map((e) => _infoChip(theme, e, isSmall)).toList(),
      ),
    );
  }

  Widget _infoChip(ThemeData theme, _ChipItem item, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: theme.colorScheme.primary, size: 20.sp),
          SizedBox(width: 10.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 14.sp : 15.sp,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _bulletList({
    required ThemeData theme,
    required List<String> items,
    required IconData icon,
    Color? color,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: items
            .where((e) => e.trim().isNotEmpty)
            .map(
              (text) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20.sp, color: color ?? theme.primaryColor),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        text.trim(),
                        style: TextStyle(fontSize: 14.5.sp, height: 1.48),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _circleIconButton(ThemeData theme, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 20.sp),
      ),
    );
  }

  Widget _applyBottomBar(
    ThemeData theme,
    double bottomPadding,
    JobModel job,
    bool hasApplied,
  ) {
    final isActive = job.isActive;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h + bottomPadding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.tertiary, width: 1.2),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Iconsax.message_question,
              color: theme.colorScheme.tertiary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: SizedBox(
              height: 54.h,
              child: ElevatedButton(
                onPressed: (isActive && !hasApplied)
                    ? () => _showApplyModal(context, ref, job)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isActive && !hasApplied)
                      ? theme.colorScheme.tertiary
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  elevation: (isActive && !hasApplied) ? 3 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  hasApplied
                      ? 'Already Applied'
                      : (isActive ? 'Apply Now' : 'Position Closed'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipItem {
  final IconData icon;
  final String value;
  final String label;
  const _ChipItem(this.icon, this.value, this.label);
}
