// ============================================================
// features/search/screens/search_screen.dart
// Hero search bar, filter chips, grid/list toggle, map button
// ============================================================

import 'package:airigo_jobportal/core/providers/jobs_feed_provider.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/empty_state.dart';
import 'package:airigo_jobportal/widgets/job_card_widget.dart';
import 'package:airigo_jobportal/widgets/shimmer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:airigo_jobportal/core/providers/job_search_provider.dart';
import 'package:airigo_jobportal/core/providers/jobseeker_profile_provider.dart';
import '../../../core/constants/app_constants.dart';

// View mode toggle
enum _ViewMode { list, grid }

enum _SortOption { relevant, newest, highestCtc, mostApplicants }

extension SortOptionExtension on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.relevant:
        return 'Most Relevant';
      case _SortOption.newest:
        return 'Newest First';
      case _SortOption.highestCtc:
        return 'Highest CTC';
      case _SortOption.mostApplicants:
        return 'Most Applicants';
    }
  }
}

class SearchJobsScreen extends ConsumerStatefulWidget {
  final bool? isBackArrow;
  final String? initialQuery;
  const SearchJobsScreen({
    super.key,
    this.isBackArrow = false,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchJobsScreen> createState() => _SearchJobsScreenState();
}

class _SearchJobsScreenState extends ConsumerState<SearchJobsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _ViewMode _viewMode = _ViewMode.list;
  _SortOption _sortOption = _SortOption.relevant;
  String _selectedJobType = '';
  String _selectedLocation = '';
  String _selectedCategory = '';
  RangeValues _ctcRange = const RangeValues(0, 50);
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  static const List<String> _popularSearches = [
    'Flutter Developer',
    'Product Manager',
    'Data Scientist',
    'UI/UX Designer',
    'Backend Engineer',
    'DevOps',
    'React Native',
    'Full Stack',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchCtrl.text = widget.initialQuery!;
    }
    _searchCtrl.addListener(_onSearchChanged);
    _focusNode.addListener(() => setState(() {}));

    // Pre-fetch profile data to ensure resume details are available if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ref.read(jobseekerProfileProvider).profile == null) {
        ref.read(jobseekerProfileProvider.notifier).fetchProfile();
      }

      // If initial query exists, trigger search after a short delay to ensure
      // navigation transition is complete and provider is ready
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        debugPrint(
          '🚀 SearchJobsScreen: Initial query detected: ${widget.initialQuery}',
        );

        // Wait for the push transition to complete fully
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          debugPrint(
            '🚀 SearchJobsScreen: Executing auto-search for: ${widget.initialQuery}',
          );
          _search(widget.initialQuery);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _focusNode.dispose();

    // If this was a targeted search (e.g. from Top Companies),
    // reset the feed when leaving so the main Explore tab remains clean
    // for the user's next visit.
    if (widget.initialQuery != null) {
      Future.microtask(() {
        if (ref.exists(jobSearchProvider)) {
          ref.read(jobSearchProvider.notifier).clearSearch();
        }
      });
    }
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text;
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final filtered = _popularSearches
        .where((s) => s.toLowerCase().contains(q.toLowerCase()))
        .toList();
    setState(() {
      _suggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _search([String? override]) {
    final q = override ?? _searchCtrl.text;
    if (override != null) _searchCtrl.text = override;
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();

    // Convert CTC range from LPA to actual values (multiply by 1,00,000)
    // Only send CTC if it's not the default full range
    final minCtc = _ctcRange.start > 0
        ? (_ctcRange.start * 100000).toInt()
        : null;
    final maxCtc = _ctcRange.end < 50 ? (_ctcRange.end * 100000).toInt() : null;

    print('🔍 Searching with filters:');
    print('   Query: "$q"');
    print('   Location: $_selectedLocation');
    print('   JobType: $_selectedJobType');
    print('   Category: $_selectedCategory');
    print('   CTC: ${minCtc ?? "null"} - ${maxCtc ?? "null"}');

    ref
        .read(jobSearchProvider.notifier)
        .search(
          q,
          location: _selectedLocation.isEmpty ? null : _selectedLocation,
          jobType: _selectedJobType.isEmpty ? null : _selectedJobType,
          category: _selectedCategory.isEmpty ? null : _selectedCategory,
          minCtc: minCtc,
          maxCtc: maxCtc,
        );
  }

  List _getSortedJobs(List jobs) {
    // Create a modifiable copy to avoid "Cannot modify an unmodifiable list" error
    final sortedJobs = List.from(jobs);

    // Apply sorting to jobs list
    switch (_sortOption) {
      case _SortOption.relevant:
        // Already sorted by relevance from backend
        break;
      case _SortOption.newest:
        sortedJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.highestCtc:
        sortedJobs.sort((a, b) {
          final aMax = a.ctcMax ?? 0;
          final bMax = b.ctcMax ?? 0;
          return bMax.compareTo(aMax);
        });
        break;
      case _SortOption.mostApplicants:
        sortedJobs.sort((a, b) {
          final aCount = a.applicantsCount ?? 0;
          final bCount = b.applicantsCount ?? 0;
          return bCount.compareTo(aCount);
        });
        break;
    }
    return sortedJobs;
  }

  void _clearFilters() {
    print('🧹 Clearing all filters');
    setState(() {
      _selectedJobType = '';
      _selectedLocation = '';
      _selectedCategory = '';
      _ctcRange = const RangeValues(0, 50);
    });
    // Refresh to show all jobs
    ref.read(jobSearchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final jobsAsync = ref.watch(jobSearchProvider);
    final isDark = context.isDark;
    final hasFilters =
        _selectedJobType.isNotEmpty ||
        _selectedLocation.isNotEmpty ||
        _selectedCategory.isNotEmpty ||
        _ctcRange.start > 0 ||
        _ctcRange.end < 50;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (widget.isBackArrow!) ...[
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.arrow_back_ios_new_rounded),
                            ),
                            SizedBox(width: 10.w),
                          ],
                          Text(
                            'Explore Jobs',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // View Toggle Button
                          ToggleButtons(
                            isSelected: [
                              _viewMode == _ViewMode.list,
                              _viewMode == _ViewMode.grid,
                            ],
                            onPressed: (index) {
                              setState(() {
                                _viewMode = index == 0
                                    ? _ViewMode.list
                                    : _ViewMode.grid;
                              });
                            },
                            borderRadius: BorderRadius.circular(8.r),
                            selectedColor: AppColors.primary,
                            fillColor: AppColors.primary.withValues(alpha: 0.1),
                            color: isDark ? Colors.white : Colors.grey,
                            constraints: BoxConstraints(
                              minHeight: 36.h,
                              minWidth: 36.w,
                            ),
                            children: [
                              Icon(Icons.view_list_rounded, size: 20.sp),
                              Icon(Icons.grid_view_rounded, size: 20.sp),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },

          /// BODY - RefreshIndicator moved INSIDE NestedScrollView body
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(jobSearchProvider.notifier).clearSearch();
            },
            color: AppColors.primary,
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            child: Column(
              children: [
                // ── Search Bar ─────────────────────────────────────
                Container(
                  margin: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                  decoration: BoxDecoration(
                    // color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Job title, company, skills...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchCtrl.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(jobSearchProvider.notifier)
                                    .clearSearch();
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.mic_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () =>
                                context.showSnackBar('Voice search stub'),
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
                  ),
                ),

                // ── Search Suggestions Dropdown ────────────────────
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: _suggestions
                          .take(5)
                          .map(
                            (s) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              title: Text(
                                s,
                                style: context.textTheme.bodyMedium,
                              ),
                              onTap: () => _search(s),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                // ── Filter Chips (horizontal scroll) ──────────────
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    // vertical: 8.h,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      // Main Filters Button
                      Flexible(
                        child: _FilterChip(
                          label: hasFilters ? 'Filters Applied' : 'Filters',
                          icon: Icons.filter_alt_rounded,
                          isSelected: hasFilters,
                          onTap: () => _showFilterSheet(context),
                        ),
                      ),

                      // Clear All button (only when filters are active)
                      if (hasFilters)
                        Flexible(
                          // child: OutlinedButton.icon(
                          //   onPressed: _clearFilters,
                          //   icon: const Icon(Icons.clear_all_rounded, size: 16),
                          //   label: const Text('Clear All'),
                          //   style: OutlinedButton.styleFrom(
                          //     padding: EdgeInsets.symmetric(
                          //       horizontal: 12.w,
                          //       vertical: 8.h,
                          //     ),
                          //   ),
                          // ),
                          child: _FilterChip(
                            label: "Clear All",
                            isSelected: false,
                            onTap: _clearFilters,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Results count ─────────────────────────────────
                jobsAsync.whenOrNull(
                      data: (jobs) => Padding(
                        padding: EdgeInsets.only(left: 16.w, right: 4.w),
                        child: Row(
                          children: [
                            Text(
                              '${jobs.length} jobs found',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showSortSheet(context),
                              icon: Icon(
                                Icons.sort_rounded,
                                size: 16.sp,
                                color: context.isDark ? Colors.white : null,
                              ),
                              label: Text(
                                _sortOption.label,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.isDark
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ) ??
                    const SizedBox.shrink(),

                // ── Jobs List / Grid ──────────────────────────────
                Expanded(
                  child: jobsAsync.when(
                    loading: () => const ShimmerList(),
                    error: (e, _) {
                      print('❌ Jobs load error: $e');
                      return ErrorStateWidget(
                        message: e.toString().contains('Failed')
                            ? e.toString()
                            : 'Failed to load jobs',
                        onRetry: () =>
                            ref.read(jobsFeedProvider.notifier).refresh(),
                      );
                    },
                    data: (jobsList) {
                      if (jobsList.isEmpty) {
                        return EmptyStateWidget(
                          title: 'No Jobs Found',
                          subtitle: hasFilters
                              ? 'Try adjusting your filters or search terms'
                              : 'Try searching with different keywords',
                          icon: Icons.search_off_rounded,
                          actionLabel: hasFilters ? 'Clear Filters' : null,
                          onAction: hasFilters ? _clearFilters : null,
                        );
                      }

                      // Apply sorting to jobs before displaying
                      final jobs = _getSortedJobs(jobsList);

                      if (_viewMode == _ViewMode.grid) {
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: jobs.length,
                          itemBuilder: (_, i) =>
                              JobCardWidget(job: jobs[i], isCompact: true),
                        );
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: jobs.length,
                        itemBuilder: (_, i) => JobCardWidget(job: jobs[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        selectedJobType: _selectedJobType,
        selectedLocation: _selectedLocation,
        selectedCategory: _selectedCategory,
        ctcRange: _ctcRange,
        onApply: (jobType, location, category, ctc) {
          print('✅ Filter applied:');
          print('   JobType: $jobType');
          print('   Location: $location');
          print('   Category: $category');
          print('   CTC: $ctc');

          setState(() {
            _selectedJobType = jobType;
            _selectedLocation = location;
            _selectedCategory = category;
            _ctcRange = ctc;
          });

          // Trigger search with new filters
          _search();
        },
        onReset: () {
          print('🔄 Filters reset');
          setState(() {
            _selectedJobType = '';
            _selectedLocation = '';
            _selectedCategory = '';
            _ctcRange = const RangeValues(0, 50);
          });
          // Refresh to show all jobs
          ref.read(jobsFeedProvider.notifier).refresh();
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final option in _SortOption.values)
              RadioListTile<_SortOption>(
                title: Text(option.label, style: TextStyle(fontSize: 14.sp)),
                value: option,
                groupValue: _sortOption,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOption = value);
                    Navigator.pop(context);
                    // Re-search with updated sort to apply sorting
                    _search();
                  }
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip Widget ─────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (context.isDark
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.w,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Bottom Sheet ────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String selectedJobType;
  final String selectedLocation;
  final String selectedCategory;
  final RangeValues ctcRange;
  final Function(String, String, String, RangeValues) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.selectedJobType,
    required this.selectedLocation,
    required this.selectedCategory,
    required this.ctcRange,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _jobType;
  late String _location;
  late String _category;
  late RangeValues _ctcRange;

  @override
  void initState() {
    super.initState();
    _jobType = widget.selectedJobType;
    _location = widget.selectedLocation;
    _category = widget.selectedCategory;
    _ctcRange = widget.ctcRange;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onReset,
                  child: Text(
                    'Reset All',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // const SizedBox(height: 20),

            // Job Type
            Text(
              'Job Type',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.jobTypes
                  .map(
                    (t) => _SelectableChip(
                      label: t,
                      isSelected: _jobType == t,
                      onTap: () =>
                          setState(() => _jobType = _jobType == t ? '' : t),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Location
            Text(
              'Location',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.popularLocations
                  .map(
                    (l) => _SelectableChip(
                      label: l,
                      isSelected: _location == l,
                      onTap: () =>
                          setState(() => _location = _location == l ? '' : l),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Category Filter
            Text(
              'Category',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Airline', 'Hospitality', 'Cruise']
                  .map(
                    (c) => _SelectableChip(
                      label: c,
                      isSelected: _category == c,
                      onTap: () =>
                          setState(() => _category = _category == c ? '' : c),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 28),

            // CTC Range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CTC Range',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '₹${_ctcRange.start.toInt()} - ₹${_ctcRange.end.toInt()} LPA',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RangeSlider(
              values: _ctcRange,
              min: 0,
              max: 50,
              divisions: 50,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _ctcRange = v),
            ),

            const SizedBox(height: 32),

            // Apply button
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_jobType, _location, _category, _ctcRange);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
