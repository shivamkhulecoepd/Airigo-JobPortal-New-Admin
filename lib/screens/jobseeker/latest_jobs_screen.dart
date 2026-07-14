import 'package:airigo_jobportal/core/providers/jobseeker_profile_provider.dart';
import 'package:airigo_jobportal/core/providers/latest_jobs_provider.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/empty_state.dart';
import 'package:airigo_jobportal/widgets/job_card_widget.dart';
import 'package:airigo_jobportal/widgets/shimmer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

enum _SortOption { newest, oldest, salaryHigh, salaryLow }

extension SortOptionExtension on _SortOption {
  String get value {
    switch (this) {
      case _SortOption.newest:
        return 'newest';
      case _SortOption.oldest:
        return 'oldest';
      case _SortOption.salaryHigh:
        return 'salaryHigh';
      case _SortOption.salaryLow:
        return 'salaryLow';
    }
  }
  
  String get label {
    switch (this) {
      case _SortOption.newest:
        return 'Newest First';
      case _SortOption.oldest:
        return 'Oldest First';
      case _SortOption.salaryHigh:
        return 'Salary (High to Low)';
      case _SortOption.salaryLow:
        return 'Salary (Low to High)';
    }
  }
}

class LatestJobsScreen extends ConsumerStatefulWidget {
  const LatestJobsScreen({super.key});

  @override
  ConsumerState<LatestJobsScreen> createState() => _LatestJobsScreenState();
}

class _LatestJobsScreenState extends ConsumerState<LatestJobsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _selectedLocation = '';
  String _selectedCategory = '';
  String _selectedJobType = '';
  _SortOption _sortOption = _SortOption.newest;
  bool _showFilters = false;
  bool _remoteOnly = false;
  RangeValues _salaryRange = const RangeValues(0, 50);

  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(latestJobsProvider).hasValue) {
        ref.read(latestJobsProvider.notifier).fetchLatestJobs();
      }

      // Pre-fetch profile data to ensure resume details are available if needed
      if (ref.read(jobseekerProfileProvider).profile == null) {
        ref.read(jobseekerProfileProvider.notifier).fetchProfile();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(latestJobsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(latestJobsProvider.notifier).refresh();
  }

  void _applyFilters() {
    ref
        .read(latestJobsProvider.notifier)
        .fetchLatestJobs(
          location: _selectedLocation.isEmpty ? null : _selectedLocation,
          category: _selectedCategory.isEmpty ? null : _selectedCategory,
          jobType: _selectedJobType.isEmpty ? null : _selectedJobType,
          sortBy: _sortOption.value,
        );
    setState(() => _showFilters = false);
    _filterAnimationController.reverse();
  }

  void _clearFilters() {
    setState(() {
      _selectedLocation = '';
      _selectedCategory = '';
      _selectedJobType = '';
      _remoteOnly = false;
      _salaryRange = const RangeValues(0, 50);
    });
    _applyFilters();
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sort By',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SortTile(
              title: 'Newest First',
              value: _SortOption.newest,
              groupValue: _sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOption = value);
                  Navigator.pop(context);
                  // Apply sorting immediately
                  ref.read(latestJobsProvider.notifier).changeSort(value.value);
                }
              },
            ),
            _SortTile(
              title: 'Oldest First',
              value: _SortOption.oldest,
              groupValue: _sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOption = value);
                  Navigator.pop(context);
                  // Apply sorting immediately
                  ref.read(latestJobsProvider.notifier).changeSort(value.value);
                }
              },
            ),
            _SortTile(
              title: 'Salary (High to Low)',
              value: _SortOption.salaryHigh,
              groupValue: _sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOption = value);
                  Navigator.pop(context);
                  // Apply sorting immediately
                  ref.read(latestJobsProvider.notifier).changeSort(value.value);
                }
              },
            ),
            _SortTile(
              title: 'Salary (Low to High)',
              value: _SortOption.salaryLow,
              groupValue: _sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOption = value);
                  Navigator.pop(context);
                  // Apply sorting immediately
                  ref.read(latestJobsProvider.notifier).changeSort(value.value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(latestJobsProvider);
    final isDark = context.isDark;
    final theme = Theme.of(context);
    final hasActiveFilters =
        _selectedLocation.isNotEmpty ||
        _selectedCategory.isNotEmpty ||
        _selectedJobType.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          SliverAppBar(
            floating: true,
            // snap: true,
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
            title: Text(
              'Latest Jobs',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Sort Button
              IconButton(
                icon: Icon(
                  Iconsax.sort,
                  size: 22.sp,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: _showSortDialog,
                tooltip: 'Sort',
              ),
              // Filter Toggle
              IconButton(
                icon: Icon(
                  Iconsax.setting_4,
                  size: 20.sp,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() => _showFilters = !_showFilters);
                  if (_showFilters) {
                    _filterAnimationController.forward();
                  } else {
                    _filterAnimationController.reverse();
                  }
                },
                tooltip: 'Filters',
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            // Enhanced Header with Search
            Container(
              padding: EdgeInsets.fromLTRB(
                16.w,
                0.h,
                16.w,
                hasActiveFilters ? 0.h : 16.h,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 48.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      spacing: 8.w,
                      children: [
                        Icon(
                          Iconsax.search_normal,
                          color: Colors.grey,
                          size: 20.sp,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            decoration: InputDecoration(
                              hintText: 'Search jobs, companies, skills...',
                              hintStyle: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        size: 18.sp,
                                      ),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _refresh();
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _applyFilters(),
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Filters Indicator
                  if (hasActiveFilters)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 14.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              'Filters applied',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Expandable Filter Panel
            SizeTransition(
              sizeFactor: _filterAnimation,
              child: Container(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Location Filter
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _FilterChip(
                          label: 'Pune',
                          isSelected: _selectedLocation == 'Pune',
                          onTap: () => setState(
                            () => _selectedLocation =
                                _selectedLocation == 'Pune' ? '' : 'Pune',
                          ),
                        ),
                        _FilterChip(
                          label: 'Mumbai',
                          isSelected: _selectedLocation == 'Mumbai',
                          onTap: () => setState(
                            () => _selectedLocation =
                                _selectedLocation == 'Mumbai' ? '' : 'Mumbai',
                          ),
                        ),
                        _FilterChip(
                          label: 'Bangalore',
                          isSelected: _selectedLocation == 'Bangalore',
                          onTap: () => setState(
                            () => _selectedLocation =
                                _selectedLocation == 'Bangalore'
                                ? ''
                                : 'Bangalore',
                          ),
                        ),
                        _FilterChip(
                          label: 'Remote',
                          isSelected: _selectedLocation == 'Remote',
                          onTap: () => setState(
                            () => _selectedLocation =
                                _selectedLocation == 'Remote' ? '' : 'Remote',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Job Type Filter
                    Text(
                      'Job Type',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _FilterChip(
                          label: 'Full-time',
                          isSelected: _selectedJobType == 'Full-time',
                          onTap: () => setState(
                            () => _selectedJobType =
                                _selectedJobType == 'Full-time'
                                ? ''
                                : 'Full-time',
                          ),
                        ),
                        _FilterChip(
                          label: 'Part-time',
                          isSelected: _selectedJobType == 'Part-time',
                          onTap: () => setState(
                            () => _selectedJobType =
                                _selectedJobType == 'Part-time'
                                ? ''
                                : 'Part-time',
                          ),
                        ),
                        _FilterChip(
                          label: 'Contract',
                          isSelected: _selectedJobType == 'Contract',
                          onTap: () => setState(
                            () => _selectedJobType =
                                _selectedJobType == 'Contract'
                                ? ''
                                : 'Contract',
                          ),
                        ),
                        _FilterChip(
                          label: 'Internship',
                          isSelected: _selectedJobType == 'Internship',
                          onTap: () => setState(
                            () => _selectedJobType =
                                _selectedJobType == 'Internship'
                                ? ''
                                : 'Internship',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Apply/Clear Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text('Clear'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Jobs List
            Expanded(
              child: jobsState.when(
                loading: () => const ShimmerList(),
                error: (error, stackTrace) => Center(
                  child: ErrorStateWidget(
                    message: error.toString(),
                    onRetry: _refresh,
                  ),
                ),
                data: (state) {
                  if (state.jobs.isEmpty && !state.isLoading) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.primary,
                      backgroundColor: isDark
                          ? AppColors.cardDark
                          : Colors.white,
                      child: Center(
                        child: EmptyStateWidget(
                          title: 'No Jobs Found',
                          subtitle:
                              'Try adjusting your filters or search terms',
                          icon: Iconsax.search_normal,
                          actionLabel: 'Clear Filters',
                          onAction: _clearFilters,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Results count header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state.jobs.length} Jobs',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    _sortOption == _SortOption.newest
                                        ? 'Latest First'
                                        : _sortOption == _SortOption.oldest
                                        ? 'Oldest First'
                                        : _sortOption == _SortOption.salaryHigh
                                        ? 'Salary: High to Low'
                                        : 'Salary: Low to High',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Job Cards
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((ctx, i) {
                              final isLastItem = i == state.jobs.length - 1;
                              return Column(
                                children: [
                                  JobCardWidget(job: state.jobs[i]),
                                  if (isLastItem && state.isLoadingMore)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20.h,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20.w,
                                            height: 20.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Text(
                                            'Loading more jobs...',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }, childCount: state.jobs.length),
                          ),
                        ),

                        // Bottom padding
                        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
              ? Colors.grey.shade800
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : context.theme.dividerColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.white
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// Sort Tile Widget
class _SortTile extends StatelessWidget {
  final String title;
  final _SortOption value;
  final _SortOption groupValue;
  final ValueChanged<_SortOption?> onChanged;

  const _SortTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<_SortOption>(
      title: Text(title, style: TextStyle(fontSize: 14.sp)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
