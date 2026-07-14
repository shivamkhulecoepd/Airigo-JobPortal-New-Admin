// ============================================================
// features/jobs/screens/job_detail_screen.dart
// Hero company logo, full job details, skills chips,
// accordion sections, Easy Apply FAB with modal bottom sheet
// ============================================================

import 'dart:developer';

import 'package:airigo_jobportal/core/providers/saved_jobs_provider.dart';
import 'package:airigo_jobportal/core/providers/applications_provider.dart';
import 'package:airigo_jobportal/core/providers/jobseeker_profile_provider.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import 'apply_job_modal.dart';

// ── JobDetailBody is now a ConsumerStatefulWidget so it can watch providers ──

class JobDetailBody extends ConsumerStatefulWidget {
  final JobModel job;
  const JobDetailBody({super.key, required this.job});

  @override
  ConsumerState<JobDetailBody> createState() => JobDetailBodyState();
}

class JobDetailBodyState extends ConsumerState<JobDetailBody> {
  bool _descExpanded = true;
  bool _reqExpanded = false;

  @override
  void initState() {
    super.initState();
    // Fetch profile if not already loaded to ensure resume details are ready for Apply modal
    Future.microtask(() {
      final profileState = ref.read(jobseekerProfileProvider);
      if (profileState.profile == null && !profileState.isLoading) {
        log('JobDetailBody: Profile not found, fetching...');
        ref.read(jobseekerProfileProvider.notifier).fetchProfile();
      } else {
        log('JobDetailBody: Profile already loaded or loading');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isDark = context.isDark;
    final theme = Theme.of(context);

    // ── Check if user has already applied for this job ──────────
    final applicationsState = ref.watch(applicationsStateProvider);
    final myApplications = applicationsState.value ?? <ApplicationModel>[];
    final hasApplied = myApplications.any(
      (app) => app.jobId == job.id.toString(),
    );
    log(
      'JobDetailBody: hasApplied=$hasApplied for jobId=${job.id}, total apps=${myApplications.length}',
    );

    return Scaffold(
      // ── Custom app bar with hero logo ──────────────────────
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.h,
            floating: false,
            pinned: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: iconWidget(theme, isDark, Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final savedJobsState = ref.watch(savedJobsProvider);
                  final isSaved =
                      savedJobsState.value?.contains(job.id.toString()) ??
                      job.isInWishlist;

                  return IconButton(
                    icon: iconWidget(
                      theme,
                      isDark,
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      isSaved,
                    ),
                    onPressed: () async {
                      await ref
                          .read(savedJobsProvider.notifier)
                          .toggle(job.id.toString(), jobModel: job);
                    },
                  );
                },
              ),
              IconButton(
                icon: iconWidget(theme, isDark, Icons.share_outlined),
                onPressed: () =>
                    context.showSnackBar('Share feature coming soon!'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(job.companyLogoUrl ?? ''),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 60.h),
                      // Hero-animated company logo
                      Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 16.r,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: CachedNetworkImage(
                            imageUrl: job.companyLogoUrl ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Icon(Icons.business_rounded, size: 40.w),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        job.companyName,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Job Details Content ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    job.designation,
                    style: context.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Key Info Row
                  _InfoRow(
                    items: [
                      _InfoItem(
                        icon: Icons.location_on_rounded,
                        label: job.location,
                      ),
                      _InfoItem(icon: Icons.work_rounded, label: job.jobType),
                      _InfoItem(
                        icon: Icons.access_time_rounded,
                        label: job.experienceDisplay,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // CTC + Posted
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salary Range',
                            style: context.textTheme.labelMedium,
                          ),
                          Text(
                            job.ctcRange,
                            style: context.textTheme.headlineSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Posted', style: context.textTheme.labelMedium),
                          Text(
                            job.createdAt.timeAgo,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // // Stats
                  // Container(
                  //   padding: EdgeInsets.all(12.r),
                  //   decoration: BoxDecoration(
                  //     color: isDark
                  //         ? Colors.white.withValues(alpha: 0.04)
                  //         : Colors.grey.shade50,
                  //     borderRadius: BorderRadius.circular(12.r),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //     children: [
                  //       _StatItem(
                  //         label: 'Applicants',
                  //         value: job.applicantsCount.toString(),
                  //       ),
                  //       _Divider(),
                  //       _StatItem(
                  //         label: 'Views',
                  //         value: job.viewsCount.toString(),
                  //       ),
                  //       _Divider(),
                  //       _StatItem(
                  //         label: 'Match',
                  //         value: '${job.matchPercentage ?? '--'}%',
                  //         valueColor: AppColors.success,
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // Urgent + Deadline badges
                  if (job.isUrgentHiring)
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Urgent Hiring',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 14.h),
                  const Divider(),
                  SizedBox(height: 16.h),

                  // ── Skills Required ──────────────────────
                  if (job.skillsRequired?.isNotEmpty ?? false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skills Required',
                          style: context.textTheme.titleLarge,
                        ),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.skillsRequired!
                              .asMap()
                              .entries
                              .map(
                                (e) => _SkillTag(
                                  skill: e.value,
                                  colorIndex: e.key,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  SizedBox(height: 16.h),

                  // ── Description Accordion ────────────────
                  if (job.description?.isNotEmpty ?? false)
                    _AccordionSection(
                      title: 'Job Description',
                      isExpanded: _descExpanded,
                      onToggle: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Text(
                        job.description!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          height: 1.7,
                        ),
                      ),
                    ),

                  SizedBox(height: 8.h),

                  // ── Requirements Accordion ───────────────
                  if (job.requirements?.isNotEmpty ?? false)
                    _AccordionSection(
                      title: 'Requirements',
                      isExpanded: _reqExpanded,
                      onToggle: () =>
                          setState(() => _reqExpanded = !_reqExpanded),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: job.requirements!
                            .map(
                              (r) => Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(
                                        top: 7.h,
                                        right: 8.w,
                                      ),
                                      width: 6.w,
                                      height: 6.h,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        r,
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  SizedBox(height: 8.h),

                  // ── About Company ────────────────────────
                  _AccordionSection(
                    title: 'About ${job.companyName}',
                    isExpanded: false,
                    onToggle: () {},
                    child: Text(
                      'Information about ${job.companyName} will be available soon. '
                      'Check back for updates on company culture and mission.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ),

                  SizedBox(height: 120.h),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Easy Apply FAB ─────────────────────────────────────
      floatingActionButton: hasApplied
          ? FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.success,
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                'Already Applied',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showApplyModal(context, job),
              backgroundColor: AppColors.success,
              icon: const Icon(Icons.bolt_rounded, color: Colors.white),
              label: Text(
                'Easy Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget iconWidget(
    ThemeData theme,
    bool isDark,
    IconData icon, [
    bool isSaved = false,
  ]) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8.r)],
      ),
      child: Icon(
        icon,
        size: 18.sp,
        color: isDark
            ? isSaved
                  ? theme.colorScheme.primary
                  : Colors.white
            : Colors.black,
      ),
    );
  }

  void _showApplyModal(BuildContext context, JobModel job) {
    debugPrint(
      '_showApplyModal: Opening apply modal for job ID: ${job.id}, designation: ${job.designation}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(
        builder: (ctx, ref, child) {
          final profileState = ref.watch(jobseekerProfileProvider);
          final profile = profileState.profile;

          debugPrint(
            '_showApplyModal: Profile state - isLoading: ${profileState.isLoading}, hasProfile: ${profile != null}',
          );

          if (profileState.isLoading && profile == null) {
            return Container(
              height: 300.h,
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          return ApplyJobModal(
            job: job,
            jobseekerName: profile?.name ?? 'Jobseeker',
            jobseekerSkills:
                profile?.skills.take(3).join(' • ') ?? 'Skills not specified',
            resumeUrl: profile?.resumeUrl,
            resumeFilename: profile?.resumeFilename,
            onSuccess: () {
              debugPrint(
                '_showApplyModal: Application submitted successfully, invalidating provider',
              );
              ref.invalidate(applicationsStateProvider);
              // Also refresh profile stats if needed
              ref.read(jobseekerProfileProvider.notifier).fetchProfile();
            },
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 14.sp, color: AppColors.textMuted),
                SizedBox(width: 4.w),
                Text(
                  item.label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  const _InfoItem({required this.icon, required this.label});
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30.h,
      width: 1.w,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String skill;
  final int colorIndex;
  const _SkillTag({required this.skill, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final color = AppColors
        .skillChipColors[colorIndex % AppColors.skillChipColors.length];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _AccordionSection({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Text(title, style: context.textTheme.titleLarge),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: child,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
        ),
        SizedBox(height: 8.h),
        const Divider(),
      ],
    );
  }
}
