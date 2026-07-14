import 'dart:developer';

import 'package:airigo_jobportal/core/providers/saved_jobs_provider.dart';
import 'package:airigo_jobportal/core/providers/applications_provider.dart';
import 'package:airigo_jobportal/core/providers/jobseeker_profile_provider.dart';
import 'package:airigo_jobportal/models/application_model.dart';
import 'package:airigo_jobportal/screens/common/apply_job_modal.dart';
import 'package:airigo_jobportal/screens/jobseeker/search_jobs_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../../models/job_model.dart';
import '../../../widgets/empty_state.dart';

// ── Sort Enum ─────────────────────────────────────────────────
enum SavedJobSort {
  newest('Most Recent', Icons.schedule_rounded),
  salary('Highest Salary', Icons.attach_money_rounded),
  match('Best Match', Icons.bolt_rounded);

  const SavedJobSort(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ── Local Providers ───────────────────────────────────────────

/// Search query within saved jobs
final _savedSearchProvider = StateProvider<String>((ref) => '');

/// Active sort mode
final _savedSortProvider = StateProvider<SavedJobSort>(
  (ref) => SavedJobSort.newest,
);

/// Active category filter (empty = all)
final _savedCategoryProvider = StateProvider<String>((ref) => '');

/// Multi-select mode set of job IDs
final _selectedSavedProvider = StateProvider<Set<String>>((ref) => {});

// ── Main Screen ───────────────────────────────────────────────
class SavedJobsScreen extends ConsumerStatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  ConsumerState<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends ConsumerState<SavedJobsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late AnimationController _headerCtrl;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerCtrl.forward();

    // Load full job objects when screen opens (if not already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(savedJobsFullProvider).isEmpty) {
        ref.read(savedJobsFullProvider.notifier).fetchFromApi();
      }

      // Also ensure profile is loaded for Apply modal
      final profileState = ref.read(jobseekerProfileProvider);
      if (profileState.profile == null && !profileState.isLoading) {
        log('SavedJobsScreen: Profile not found, fetching...');
        ref.read(jobseekerProfileProvider.notifier).fetchProfile();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  // ── Remove a single saved job with undo snackbar ──────────
  void _removeSaved(BuildContext context, String jobId, String jobTitle) {
    // Grab the job object before removing (needed for undo)
    final job = ref
        .read(savedJobsFullProvider)
        .firstWhere(
          (j) => j.id.toString() == jobId,
          orElse: () => throw StateError('job not found'),
        );

    // Instant optimistic removal — no API wait, no invalidate
    ref.read(savedJobsProvider.notifier).toggle(jobId);
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Removed "$jobTitle" from saved',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.primary,
            onPressed: () {
              ref.read(savedJobsProvider.notifier).toggle(jobId, jobModel: job);
            },
          ),
        ),
      );
  }

  // ── Bulk remove selected ──────────────────────────────────
  void _bulkRemove(BuildContext context) {
    final selected = Set<String>.from(ref.read(_selectedSavedProvider));
    final count = selected.length;
    // Snapshot jobs for undo before removing
    final removedJobs = ref
        .read(savedJobsFullProvider)
        .where((j) => selected.contains(j.id.toString()))
        .toList();

    for (final id in selected) {
      ref.read(savedJobsProvider.notifier).toggle(id);
    }
    ref.read(_selectedSavedProvider.notifier).state = {};
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed $count saved job${count > 1 ? 's' : ''}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.primary,
            onPressed: () {
              for (final job in removedJobs) {
                ref
                    .read(savedJobsProvider.notifier)
                    .toggle(job.id.toString(), jobModel: job);
              }
            },
          ),
        ),
      );
  }

  // ── Sort bottom sheet ─────────────────────────────────────
  void _showSortSheet(BuildContext context) {
    final current = ref.read(_savedSortProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(current: current),
    );
  }

  List<JobModel> _applyFilters(List<JobModel> jobs, WidgetRef ref) {
    final searchQuery = ref.watch(_savedSearchProvider);
    final categoryFilter = ref.watch(_savedCategoryProvider);

    var filteredJobs = jobs;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filteredJobs = filteredJobs.where((job) {
        return job.designation.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            job.companyName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (job.skillsRequired?.any(
                  (skill) =>
                      skill.toLowerCase().contains(searchQuery.toLowerCase()),
                ) ??
                false);
      }).toList();
    }

    // Apply category filter
    if (categoryFilter.isNotEmpty && categoryFilter != 'All') {
      filteredJobs = filteredJobs.where((job) {
        return job.category.toLowerCase().contains(
          categoryFilter.toLowerCase(),
        );
      }).toList();
    }

    return filteredJobs;
  }

  @override
  Widget build(BuildContext context) {
    // Drive the list from savedJobsFullProvider — instant updates, no API wait
    final allJobs = ref.watch(savedJobsFullProvider);
    final savedJobsState = ref.watch(savedJobsProvider);
    final savedCount = allJobs.length;
    final selected = ref.watch(_selectedSavedProvider);
    final isDark = context.isDark;
    final theme = context.theme;

    return Scaffold(
      // backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        // Fix: use notificationPredicate to work with NestedScrollView
        notificationPredicate: (notification) => notification.depth == 2,
        onRefresh: () async {
          await ref.read(savedJobsProvider.notifier).refresh();
        },
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        child: NestedScrollView(
          controller: _scrollCtrl,
          headerSliverBuilder: (ctx, innerBoxScrolled) => [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20.sp,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              title: Row(
                spacing: 10.w,
                children: [
                  Text(
                    'Saved Jobs',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: savedCount > 0
                          ? AppColors.primary
                          : AppColors.textLight.withValues(alpha: 0.3),
                    ),
                    child: Text(
                      '$savedCount',
                      style: TextStyle(
                        color: savedCount > 0
                            ? Colors.white
                            : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (selected.isNotEmpty) ...[
                  IconButton(
                    tooltip: 'Remove selected',
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () => _bulkRemove(context),
                  ),
                  IconButton(
                    tooltip: 'Clear selection',
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () =>
                        ref.read(_selectedSavedProvider.notifier).state = {},
                  ),
                ] else ...[
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: _AnimatedIconButton(
                      icon: Icons.sort_rounded,
                      tooltip: 'Sort',
                      onTap: () => _showSortSheet(context),
                    ),
                  ),
                ],
              ],
            ),
          ],
          body: _buildBody(context, allJobs, selected, savedJobsState),
        ),
      ),
      floatingActionButton: selected.isNotEmpty
          ? _BulkActionFab(
              count: selected.length,
              onApply: () {
                ref.read(_selectedSavedProvider.notifier).state = {};
                context.showSnackBar(
                  'Applying to ${selected.length} jobs — feature coming soon!',
                );
              },
              onRemove: () => _bulkRemove(context),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<JobModel> jobs,
    Set<String> selected,
    AsyncValue<List<String>> savedJobsState,
  ) {
    // Check if there are any jobs after applying search/filter
    final filteredJobs = _applyFilters(
      jobs,
      ref,
    ); // Apply search and category filters

    if (filteredJobs.isEmpty && jobs.isNotEmpty) {
      // Jobs exist but none match the current filters
      return EmptyStateWidget(
        title: 'No matches found',
        subtitle: 'Try adjusting your search or filters to find saved jobs.',
        icon: Icons.search_off_rounded,
        actionLabel: 'Clear Filters',
        onAction: () {
          _searchCtrl.clear();
          ref.read(_savedSearchProvider.notifier).state = '';
          ref.read(_savedCategoryProvider.notifier).state = '';
        },
      );
    } else if (filteredJobs.isEmpty && jobs.isEmpty) {
      // No jobs at all (empty wishlist)
      return _EmptyState(
        // onBrowse: () => context.go(AppRoutes.search),
        onBrowse: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchJobsScreen(isBackArrow: true),
          ),
        ),
      );
    }

    // Continue with the normal rendering using filtered jobs
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Search bar ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchBar(
              controller: _searchCtrl,
              onChanged: (q) =>
                  ref.read(_savedSearchProvider.notifier).state = q,
              onClear: () {
                _searchCtrl.clear();
                ref.read(_savedSearchProvider.notifier).state = '';
              },
            ),
          ),

          const SizedBox(height: 10),
          // ── Category filter chips ─────────────
          const _CategoryFilterRow(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 120),
            itemCount: filteredJobs.length,
            itemBuilder: (ctx, index) {
              final job = filteredJobs[index];
              final isSelected = selected.contains(job.id.toString());

              // Staggered entrance animation per card
              return _StaggeredCard(
                index: index,
                child: _SavedJobCard(
                  job: job,
                  isSelected: isSelected,
                  isSelectionMode: selected.isNotEmpty,
                  onTap: () {
                    if (selected.isNotEmpty) {
                      // Toggle selection
                      final newSet = Set<String>.from(selected);
                      if (isSelected) {
                        newSet.remove(job.id.toString());
                      } else {
                        newSet.add(job.id.toString());
                      }
                      ref.read(_selectedSavedProvider.notifier).state = newSet;
                    } else {
                      // context.push('/job/${job.id}');
                    }
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    final newSet = Set<String>.from(selected);
                    newSet.add(job.id.toString());
                    ref.read(_selectedSavedProvider.notifier).state = newSet;
                  },
                  onRemove: () =>
                      _removeSaved(context, job.id.toString(), job.designation),
                  onApply: () {
                    log(
                      'SavedJobsScreen: Apply button clicked for job: ${job.designation}',
                    );
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => Consumer(
                        builder: (ctx, ref, child) {
                          final profileState = ref.watch(
                            jobseekerProfileProvider,
                          );
                          final profile = profileState.profile;

                          if (profileState.isLoading && profile == null) {
                            return Container(
                              height: 300.h,
                              decoration: BoxDecoration(
                                color: context.isDark
                                    ? AppColors.cardDark
                                    : Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          return ApplyJobModal(
                            job: job,
                            jobseekerName: profile?.name ?? 'Jobseeker',
                            jobseekerSkills:
                                profile?.skills.take(3).join(' • ') ??
                                'Skills not specified',
                            resumeUrl: profile?.resumeUrl,
                            resumeFilename: profile?.resumeFilename,
                            onSuccess: () {
                              ref.invalidate(applicationsStateProvider);
                              ref
                                  .read(jobseekerProfileProvider.notifier)
                                  .fetchProfile();
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Animated Icon Button ──────────────────────────────────────
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _AnimatedIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.82,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Icon(
            widget.icon,
            size: 22,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: context.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search in saved jobs...',
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 14,
          ),
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }
}

// ── Category Filter Chips Row ─────────────────────────────────
class _CategoryFilterRow extends ConsumerWidget {
  const _CategoryFilterRow();

  static const List<_Cat> _cats = [
    _Cat('All', Icons.apps_rounded),
    _Cat('Airline', Icons.flight_rounded),
    _Cat('Hospitality', Icons.hotel_rounded),
    _Cat('Cruise', Icons.directions_boat_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_savedCategoryProvider);

    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _cats.length,
        itemBuilder: (_, i) {
          final cat = _cats[i];
          final isActive =
              (cat.label == 'All' && selected.isEmpty) || selected == cat.label;
          return _FilterChipItem(
            cat: cat,
            isActive: isActive,
            onTap: () {
              ref.read(_savedCategoryProvider.notifier).state =
                  cat.label == 'All' ? '' : cat.label;
            },
          );
        },
      ),
    );
  }
}

class _Cat {
  final String label;
  final IconData icon;
  const _Cat(this.label, this.icon);
}

class _FilterChipItem extends StatefulWidget {
  final _Cat cat;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChipItem({
    required this.cat,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterChipItem> createState() => _FilterChipItemState();
}

class _FilterChipItemState extends State<_FilterChipItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary
                : isDark
                ? AppColors.cardDark
                : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.primary
                  : isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.cat.icon,
                size: 13,
                color: widget.isActive ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                widget.cat.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Staggered Card Entrance Animation ─────────────────────────
class _StaggeredCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredCard({required this.index, required this.child});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger per index
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ── Saved Job Card ────────────────────────────────────────────
/// The main card widget: swipe-to-remove via Dismissible,
/// long-press to enter multi-select, quick Apply button.
class _SavedJobCard extends ConsumerStatefulWidget {
  final JobModel job;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final VoidCallback onApply;

  const _SavedJobCard({
    required this.job,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    required this.onApply,
  });

  @override
  ConsumerState<_SavedJobCard> createState() => _SavedJobCardState();
}

class _SavedJobCardState extends ConsumerState<_SavedJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.975,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isDark = context.isDark;
    return Dismissible(
      key: ValueKey('saved_${job.id}'),
      direction: DismissDirection.endToStart,
      // ── Swipe background: red with trash icon ──────────
      background: Container(
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Unsave',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (dir) async {
        widget.onRemove();
        return false; // We handle removal ourselves (with undo)
      },
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        onLongPress: widget.onLongPress,
        child: ScaleTransition(
          scale: _pressScale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : isDark
                  ? AppColors.cardDark
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.primary
                    : isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.grey.shade100,
                width: widget.isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.25 : (widget.isSelected ? 0.08 : 0.05),
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (job.isUrgentHiring) ...[
                  Positioned(top: 0, right: 0, child: _UrgentPill()),
                ],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Row 1: Logo + Company + Select / Save ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selection checkbox or company logo
                          if (widget.isSelectionMode)
                            _SelectCircle(isSelected: widget.isSelected)
                          else
                            // Logo without Hero to avoid duplicate tag issues
                            _Logo(
                              url:
                                  job.companyLogoUrl != null &&
                                      job.companyLogoUrl!.isNotEmpty
                                  ? job.companyLogoUrl!
                                  : '',
                            ), // Using actual logo URL if available

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Company name
                                Text(
                                  job.companyName,
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 2),
                                // Job title
                                Text(
                                  job.designation,
                                  style: context.textTheme.titleLarge,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Unsave heart button
                          if (!widget.isSelectionMode)
                            _UnsaveButton(onTap: widget.onRemove),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Row 2: Location + Job type ─────────────
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              job.location,
                              style: context.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _JobTypePill(jobType: job.jobTypeEnum),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Row 3: Salary + Match + Urgent ─────────
                      Text(
                        job.ctcRange,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Row 4: Skills ───────────────────────────
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (job.skillsRequired ?? [])
                            .take(3)
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (e) => _SkillTag(skill: e.value, colorIdx: e.key),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 14),

                      // ── Row 5: Posted + Apply button ────────────
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.createdAt.timeAgo,
                            style: context.textTheme.labelSmall,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${job.applicantsCount ?? 0} applicants',
                            style: context.textTheme.labelSmall,
                          ),
                          const Spacer(),
                          // Apply / Applied button
                          _ApplyButton(onTap: widget.onApply),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final String url;
  const _Logo({required this.url});

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
        borderRadius: BorderRadius.circular(12.r),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
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

class _SelectCircle extends StatelessWidget {
  final bool isSelected;
  const _SelectCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.textLight,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
          : null,
    );
  }
}

class _UnsaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _UnsaveButton({required this.onTap});

  @override
  State<_UnsaveButton> createState() => _UnsaveButtonState();
}

class _UnsaveButtonState extends State<_UnsaveButton>
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
        child: Padding(
          padding: EdgeInsets.only(top: 16.h),
          child: Icon(
            Icons.bookmark_rounded,
            // color: AppColors.heartSaved,
            color: context.isDark ? Colors.white : AppColors.heartSaved,
            size: 22.sp,
          ),
        ),
      ),
    );
  }
}

class _JobTypePill extends StatelessWidget {
  final JobType jobType;
  const _JobTypePill({required this.jobType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: jobType.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        jobType.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: jobType.color,
        ),
      ),
    );
  }
}

class _UrgentPill extends StatefulWidget {
  @override
  State<_UrgentPill> createState() => _UrgentPillState();
}

class _UrgentPillState extends State<_UrgentPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.55, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16.w),
          bottomLeft: Radius.circular(16.w),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.flash5, color: Colors.white, size: 12.sp),
              Text(
                'URGENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SkillTag extends StatelessWidget {
  final String skill;
  final int colorIdx;
  const _SkillTag({required this.skill, required this.colorIdx});

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.skillChipColors[colorIdx % AppColors.skillChipColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _ApplyButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ApplyButton({required this.onTap});

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppliedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: AppColors.success, size: 13),
          SizedBox(width: 4),
          Text(
            'Applied',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sort Bottom Sheet ─────────────────────────────────────────
class _SortSheet extends ConsumerWidget {
  final SavedJobSort current;
  const _SortSheet({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Sort by',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...SavedJobSort.values.map((sort) {
            final isActive = sort == current;
            return _SortOptionTile(
              sort: sort,
              isActive: isActive,
              onTap: () {
                ref.read(_savedSortProvider.notifier).state = sort;
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final SavedJobSort sort;
  final bool isActive;
  final VoidCallback onTap;
  const _SortOptionTile({
    required this.sort,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                sort.icon,
                size: 18,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              sort.label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : null,
              ),
            ),
            const Spacer(),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bulk Action FAB ───────────────────────────────────────────
class _BulkActionFab extends StatelessWidget {
  final int count;
  final VoidCallback onApply;
  final VoidCallback onRemove;
  const _BulkActionFab({
    required this.count,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count selected',
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Text(
                'Apply All',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatefulWidget {
  final VoidCallback onBrowse;
  const _EmptyState({required this.onBrowse});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 56,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    Positioned(
                      top: 22,
                      right: 22,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No saved jobs yet',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Tap the ♥ on any job to save it here. Browse jobs and start building your wishlist!',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: widget.onBrowse,
                icon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text('Browse Jobs'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:airigo_jobportal/utils/app_colors.dart';
// import 'package:airigo_jobportal/utils/extensions.dart';
// import 'package:airigo_jobportal/widgets/job_card_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class JobseekerSavedJobsScreen extends StatefulWidget {
//   const JobseekerSavedJobsScreen({super.key});

//   @override
//   State<JobseekerSavedJobsScreen> createState() =>
//       _JobseekerSavedJobsScreenState();
// }

// class _JobseekerSavedJobsScreenState extends State<JobseekerSavedJobsScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = context.isDark;
//     final mq = MediaQuery.of(context);
//     return Scaffold(
//       backgroundColor: isDark ? AppColors.cardDark : Colors.white,
//       body: RefreshIndicator.adaptive(
//         onRefresh: () async {
//           await Future.delayed(Duration(seconds: 2));
//         },
//         child: CustomScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           slivers: [
//             SliverAppBar(
//               floating: true,
//               pinned: false,
//               surfaceTintColor: isDark ? AppColors.cardDark : Colors.white,
//               backgroundColor: isDark ? AppColors.cardDark : Colors.white,
//               leading: IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: Icon(
//                   Icons.arrow_back_ios_new_rounded,
//                   size: 20.sp,
//                   color: theme.colorScheme.onSurface,
//                 ),
//               ),
//               title: Text(
//                 'Saved Jobs',
//                 style: TextStyle(
//                   fontSize: 22.sp,
//                   fontWeight: FontWeight.w700,
//                   color: theme.colorScheme.onSurface,
//                 ),
//               ),
//             ),
//             SliverPadding(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               sliver: SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                   (context, index) => JobCardWidget(),
//                   childCount: 10,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
