import 'package:airigo_jobportal/models/job_model.dart';
import 'package:airigo_jobportal/screens/common/job_detail_body.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_savedjobs_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../core/providers/saved_jobs_provider.dart';
import '../core/providers/jobseeker_profile_provider.dart';
import '../screens/common/apply_job_modal.dart';

class JobCardWidget extends ConsumerWidget {
  final JobModel job;
  final bool isCompact;
  final bool isApplyNow;

  const JobCardWidget({
    required this.job,
    super.key,
    this.isCompact = false,
    this.isApplyNow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompact) {
      return _CompactJobCard(job: job);
    }

    // 🔥 Your EXISTING card (UNCHANGED)
    return _FullJobCard(job: job, isApplyNow: isApplyNow, isCompact: isCompact);
  }
}

class _FullJobCard extends ConsumerStatefulWidget {
  final JobModel job;
  final bool isApplyNow;
  final bool isCompact;

  const _FullJobCard({
    required this.job,
    required this.isApplyNow,
    this.isCompact = false,
  });

  @override
  ConsumerState createState() => _FullJobCardState();
}

class _FullJobCardState extends ConsumerState<_FullJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // Pre-fetch profile data to ensure resume details are available if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(jobseekerProfileProvider).profile == null) {
        ref.read(jobseekerProfileProvider.notifier).fetchProfile();
      }
    });
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailBody(job: job)),
        );
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: Logo + Company + Save ──────────────────
                    Row(
                      children: [
                        // Hero-tagged company logo
                        _CompanyLogo(url: job.companyLogoUrl ?? ''),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.companyName,
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                job.designation,
                                style: context.textTheme.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Save (heart) button with animation
                        Consumer(
                          builder: (context, ref, child) {
                            final savedJobsState = ref.watch(savedJobsProvider);
                            final isSaved =
                                savedJobsState.value?.contains(
                                  job.id.toString(),
                                ) ??
                                job.isInWishlist;

                            return _SaveButton(
                              isSaved: isSaved,
                              onTap: () async {
                                // Determine current state before toggle
                                final wasSaved =
                                    savedJobsState.value?.contains(
                                      job.id.toString(),
                                    ) ??
                                    job.isInWishlist;

                                await ref
                                    .read(savedJobsProvider.notifier)
                                    .toggle(job.id.toString(), jobModel: job);

                                // Show feedback message
                                if (!wasSaved) {
                                  // Job was added to bookmarks
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (context.mounted) {
                                      AppScaffoldFeedback.show(
                                        context,
                                        message: 'Job saved successfully!',
                                        type: ResponseType.success,
                                        duration: const Duration(seconds: 3),
                                        actionText: 'View',
                                        onAction: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SavedJobsScreen(),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  });
                                } else {
                                  // Job was removed from bookmarks
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (context.mounted) {
                                      AppScaffoldFeedback.show(
                                        context,
                                        message: 'Job removed from saved jobs',
                                        type: ResponseType.info,
                                        duration: const Duration(seconds: 3),
                                      );
                                    }
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // ── Row 2: Location + Job Type ────────────────────
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14.sp,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            job.location,
                            style: context.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _JobTypeBadge(jobType: job.jobTypeEnum),
                      ],
                    ),

                    SizedBox(height: 10.h),

                    // ── Row 3: CTC + Match % + Urgent ─────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // CTC range
                        Text(
                          job.ctcRange,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.isApplyNow)
                          ElevatedButton(
                            onPressed: () => _showApplyModal(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  context.theme.colorScheme.tertiary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 7.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Apply Now",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // ── Row 4: Skills ─────────────────────────────────
                    if (!widget.isCompact &&
                        (job.skillsRequired?.isNotEmpty ?? false))
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: job.skillsRequired!
                            .take(4)
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (e) =>
                                  _SkillChip(skill: e.value, colorIndex: e.key),
                            )
                            .toList(),
                      ),

                    SizedBox(height: 8.h),

                    // ── Row 5: Posted time + Applicants ───────────────
                    Row(
                      children: [
                        Text(
                          job.createdAt.timeAgo,
                          style: context.textTheme.labelSmall,
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${job.applicantsCount ?? 0} applicants',
                          style: context.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Urgent Badge
              if (job.isUrgentHiring)
                Positioned(
                  top: 0,
                  right: 0,
                  child: RepaintBoundary(child: _UrgentBadge()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyModal(BuildContext context, WidgetRef ref) {
    final profileState = ref.read(jobseekerProfileProvider);

    if (profileState.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading your profile details...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApplyJobModal(
        job: widget.job,
        jobseekerName: profileState.profile?.name,
        jobseekerSkills: profileState.profile?.skills.join(', '),
        resumeUrl: profileState.profile?.resumeUrl,
        resumeFilename: profileState.profile?.resumeFilename,
      ),
    );
  }
}

class _CompactJobCard extends StatelessWidget {
  final JobModel job;

  const _CompactJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailBody(job: job)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── Top Row ─────────────────────
            Row(
              children: [
                _CompanyLogo(url: job.companyLogoUrl ?? ''),
                const Spacer(),
                Consumer(
                  builder: (context, ref, child) {
                    final savedJobsState = ref.watch(savedJobsProvider);
                    final isSaved =
                        savedJobsState.value?.contains(job.id.toString()) ??
                        job.isInWishlist;

                    return GestureDetector(
                      onTap: () async {
                        // Determine current state before toggle
                        final wasSaved =
                            savedJobsState.value?.contains(job.id.toString()) ??
                            job.isInWishlist;

                        await ref
                            .read(savedJobsProvider.notifier)
                            .toggle(job.id.toString(), jobModel: job);

                        // Show feedback message
                        if (!wasSaved) {
                          // Job was added to bookmarks
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              AppScaffoldFeedback.show(
                                context,
                                message:
                                    '"${job.designation}" added to saved jobs',
                                type: ResponseType.success,
                                duration: const Duration(seconds: 3),
                                actionText: 'View',
                                onAction: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SavedJobsScreen(),
                                    ),
                                  );
                                },
                              );
                            }
                          });
                        } else {
                          // Job was removed from bookmarks
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              AppScaffoldFeedback.show(
                                context,
                                message:
                                    '"${job.designation}" removed from saved jobs',
                                type: ResponseType.info,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          });
                        }
                      },
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 18,
                        color: isSaved
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// ── Job Title ───────────────────
            Text(
              job.designation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            /// ── Company ─────────────────────
            Text(
              job.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),

            const Spacer(), // 🔥 THIS PREVENTS OVERFLOW
            /// ── Location ────────────────────
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// ── Salary ──────────────────────
            Text(
              '₹${job.ctcMin}-${job.ctcMax} LPA',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _CompanyLogo extends StatelessWidget {
  final String url;
  const _CompanyLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey.shade100,
            child: const Icon(
              Icons.business_rounded,
              color: AppColors.textLight,
              size: 24,
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey.shade100,
            child: const Icon(
              Icons.business_rounded,
              color: AppColors.textLight,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final bool isSaved;
  final VoidCallback onTap;
  const _SaveButton({required this.isSaved, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            widget.isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            // color: widget.isSaved
            //     ? AppColors.heartSaved
            //     : AppColors.heartUnsaved,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _JobTypeBadge extends StatelessWidget {
  final JobType jobType;
  const _JobTypeBadge({required this.jobType});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : jobType.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        jobType.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : jobType.color,
        ),
      ),
    );
  }
}

/// Red pulsing "Urgent" badge — draws attention to hot opportunities
class _UrgentBadge extends StatefulWidget {
  const _UrgentBadge();

  @override
  State<_UrgentBadge> createState() => _UrgentBadgeState();
}

class _UrgentBadgeState extends State<_UrgentBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.urgentBadge,
          // borderRadius: BorderRadius.circular(6.r),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15.r),
            bottomLeft: Radius.circular(15.r),
          ),
        ),
        child: Row(
          spacing: 4.w,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.flash5, color: Colors.white, size: 12.sp),
            const Text(
              'Urgent',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String skill;
  final int colorIndex;
  const _SkillChip({required this.skill, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final color = AppColors
        .skillChipColors[colorIndex % AppColors.skillChipColors.length];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
