import 'package:airigo_jobportal/core/providers/top_companies_provider.dart';
import 'package:airigo_jobportal/screens/jobseeker/search_jobs_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/empty_state.dart';
import 'package:airigo_jobportal/widgets/shimmer_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

enum _CompanySortOption { mostJobs, alphabetical, newest }

extension CompanySortOptionExtension on _CompanySortOption {
  String get label {
    switch (this) {
      case _CompanySortOption.mostJobs:
        return 'Most Open Positions';
      case _CompanySortOption.alphabetical:
        return 'Alphabetical (A-Z)';
      case _CompanySortOption.newest:
        return 'Recently Active';
    }
  }
}

class TopCompanyJobsScreen extends ConsumerStatefulWidget {
  const TopCompanyJobsScreen({super.key});

  @override
  ConsumerState<TopCompanyJobsScreen> createState() =>
      _TopCompanyJobsScreenState();
}

class _TopCompanyJobsScreenState extends ConsumerState<TopCompanyJobsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedIndustry = '';
  String _selectedLocation = '';
  _CompanySortOption _sortOption = _CompanySortOption.mostJobs;
  bool _showFilters = false;

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
      if (!ref.read(topCompaniesProvider).hasValue) {
        ref.read(topCompaniesProvider.notifier).fetchTopCompanies();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(topCompaniesProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(topCompaniesProvider.notifier).refresh();
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sort Companies By',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<_CompanySortOption>(
              title: Text(
                'Most Open Positions',
                style: TextStyle(fontSize: 14.sp),
              ),
              value: _CompanySortOption.mostJobs,
              groupValue: _sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOption = value);
                  Navigator.pop(context);
                }
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<_CompanySortOption>(
              title: Text(
                'Alphabetical (A-Z)',
                style: TextStyle(fontSize: 14.sp),
              ),
              value: _CompanySortOption.alphabetical,
              groupValue: _sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOption = value);
                  Navigator.pop(context);
                }
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<_CompanySortOption>(
              title: Text('Recently Active', style: TextStyle(fontSize: 14.sp)),
              value: _CompanySortOption.newest,
              groupValue: _sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOption = value);
                  Navigator.pop(context);
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  List<CompanyModel> _getFilteredCompanies(List<CompanyModel> companies) {
    // Create a modifiable copy of the list to avoid "Cannot modify an unmodifiable list" error during sorting
    var filtered = List<CompanyModel>.from(companies);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((company) {
        return company.companyName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (company.industry?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (company.location?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Apply industry filter
    if (_selectedIndustry.isNotEmpty) {
      filtered = filtered
          .where((c) => c.industry == _selectedIndustry)
          .toList();
    }

    // Apply location filter
    if (_selectedLocation.isNotEmpty) {
      filtered = filtered
          .where((c) => c.location == _selectedLocation)
          .toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case _CompanySortOption.mostJobs:
        filtered.sort((a, b) => b.openPositions.compareTo(a.openPositions));
        break;
      case _CompanySortOption.alphabetical:
        filtered.sort((a, b) => a.companyName.compareTo(b.companyName));
        break;
      case _CompanySortOption.newest:
        filtered.sort((a, b) {
          if (a.latestPost == null || b.latestPost == null) return 0;
          return DateTime.parse(
            b.latestPost!,
          ).compareTo(DateTime.parse(a.latestPost!));
        });
        break;
    }

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedIndustry = '';
      _selectedLocation = '';
      _sortOption = _CompanySortOption.mostJobs;
    });
    _searchCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final companiesState = ref.watch(topCompaniesProvider);
    final isDark = context.isDark;
    final theme = Theme.of(context);
    final hasActiveFilters =
        _selectedIndustry.isNotEmpty || _selectedLocation.isNotEmpty;

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
              'Top Company Jobs',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.fade,
              maxLines: 1,
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
            // Enhanced Header with Search & Filters
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
                            decoration: InputDecoration(
                              hintText: 'Search companies...',
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
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Filters Indicator
                  if (hasActiveFilters || _searchQuery.isNotEmpty)
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
                              '${_searchQuery.isNotEmpty ? 'Search: "$_searchQuery"' : ''}${_searchQuery.isNotEmpty && hasActiveFilters ? ' • ' : ''}${hasActiveFilters ? 'Filters applied' : ''}',
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
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  bottom: hasActiveFilters ? 0.h : 16.h,
                ),
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
                      'Filter by Industry & Location',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Industry Filter
                    Text(
                      'Industry',
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
                          label: 'Airline',
                          isSelected: _selectedIndustry == 'Airline',
                          onTap: () => setState(
                            () => _selectedIndustry =
                                _selectedIndustry == 'Airline' ? '' : 'Airline',
                          ),
                        ),
                        _FilterChip(
                          label: 'Hospitality',
                          isSelected: _selectedIndustry == 'Hospitality',
                          onTap: () => setState(
                            () => _selectedIndustry =
                                _selectedIndustry == 'Hospitality'
                                ? ''
                                : 'Hospitality',
                          ),
                        ),
                        _FilterChip(
                          label: 'Cruise',
                          isSelected: _selectedIndustry == 'Cruise',
                          onTap: () => setState(
                            () => _selectedIndustry =
                                _selectedIndustry == 'Cruise' ? '' : 'Cruise',
                          ),
                        ),
                      ],
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

                    // Clear Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text('Clear Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Companies List
            Expanded(
              child: companiesState.when(
                loading: () => const ShimmerCompanyList(),
                error: (error, stackTrace) => Center(
                  child: ErrorStateWidget(
                    message: error.toString(),
                    onRetry: _refresh,
                  ),
                ),
                data: (state) {
                  final filteredCompanies = _getFilteredCompanies(
                    state.companies,
                  );

                  if (filteredCompanies.isEmpty && !state.isLoading) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.primary,
                      backgroundColor: isDark
                          ? AppColors.cardDark
                          : Colors.white,
                      child: EmptyStateWidget(
                        title: _searchQuery.isNotEmpty || hasActiveFilters
                            ? 'No Companies Match Your Criteria'
                            : 'No Companies Found',
                        subtitle: _searchQuery.isNotEmpty || hasActiveFilters
                            ? 'Try adjusting your search or filters'
                            : 'Check back later for top employers',
                        icon: Iconsax.building_3,
                        actionLabel: _searchQuery.isNotEmpty || hasActiveFilters
                            ? 'Clear Filters'
                            : null,
                        onAction: _searchQuery.isNotEmpty || hasActiveFilters
                            ? _clearFilters
                            : null,
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
                                  '${filteredCompanies.length} Companies',
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
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.diagram,
                                        size: 12.sp,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        _sortOption ==
                                                _CompanySortOption.mostJobs
                                            ? 'Top Employers'
                                            : _sortOption ==
                                                  _CompanySortOption
                                                      .alphabetical
                                            ? 'A-Z'
                                            : 'Recently Active',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Company Cards
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((ctx, i) {
                              final company = filteredCompanies[i];
                              final isLastItem =
                                  i == filteredCompanies.length - 1;

                              return Column(
                                children: [
                                  _CompanyCard(company: company),
                                  SizedBox(height: 12.h),
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
                                            'Loading more companies...',
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
                            }, childCount: filteredCompanies.length),
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

class _CompanyCard extends StatelessWidget {
  final CompanyModel company;

  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Navigate to search screen filtered by company name
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchJobsScreen(
              isBackArrow: true,
              initialQuery: company.companyName,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              blurRadius: 12.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Company Logo
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11.r),
                child: company.companyLogoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: company.companyLogoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Iconsax.building_3,
                            color: AppColors.textMuted,
                            size: 32.sp,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Iconsax.building_3,
                            color: AppColors.textMuted,
                            size: 32.sp,
                          ),
                        ),
                      )
                    : Icon(
                        Iconsax.building_3,
                        color: AppColors.textMuted,
                        size: 32.sp,
                      ),
              ),
            ),

            SizedBox(width: 16.w),

            // Company Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.companyName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  if (company.industry != null)
                    Text(
                      company.industry!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  if (company.location != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 12.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              company.location!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Open Positions Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  Text(
                    '${company.openPositions}',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Jobs',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
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
