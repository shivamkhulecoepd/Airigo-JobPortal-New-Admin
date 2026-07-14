// ============================================================
// core/providers/latest_jobs_provider.dart
// Handles latest jobs state with Riverpod AsyncNotifier
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../services/api/job_service.dart';

class LatestJobsState {
  final List<JobModel> jobs;
  final List<JobModel> allFetchedJobs; // Store all fetched jobs for sorting/filtering
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;
  final String? sortOption; // Track current sort option

  const LatestJobsState({
    this.jobs = const [],
    this.allFetchedJobs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasReachedMax = false,
    this.sortOption,
  });

  LatestJobsState copyWith({
    List<JobModel>? jobs,
    List<JobModel>? allFetchedJobs,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool? hasReachedMax,
    String? sortOption,
  }) {
    return LatestJobsState(
      jobs: jobs ?? this.jobs,
      allFetchedJobs: allFetchedJobs ?? this.allFetchedJobs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

final latestJobsProvider =
    AsyncNotifierProvider<LatestJobsNotifier, LatestJobsState>(() => LatestJobsNotifier());

class LatestJobsNotifier extends AsyncNotifier<LatestJobsState> {
  final JobService _jobService = JobService();

  @override
  Future<LatestJobsState> build() async {
    await fetchLatestJobs();
    return state.hasValue ? state.value! : const LatestJobsState();
  }

  Future<void> fetchLatestJobs({
    String? location,
    String? category,
    String? jobType,
    String? sortBy,
  }) async {
    state = AsyncValue.data(const LatestJobsState(isLoading: true));
    
    try {
      final result = await _jobService.getLatestJobs(
        page: 1,
        limit: 10,
        location: location,
        category: category,
        jobType: jobType,
      );

      if (result['success']) {
        final jobs = result['jobs'] as List<JobModel>;
        final pagination = result['pagination'] as Map<String, dynamic>;
        
        // Apply sorting to fetched jobs
        List<JobModel> sortedJobs = _applySorting(jobs, sortBy ?? 'newest');
        
        state = AsyncValue.data(LatestJobsState(
          jobs: sortedJobs,
          allFetchedJobs: sortedJobs,
          isLoading: false,
          currentPage: 1,
          totalPages: (pagination['pages'] as num?)?.toInt() ?? 1,
          hasReachedMax: jobs.length < 10,
          sortOption: sortBy ?? 'newest',
        ));
      } else {
        state = AsyncValue.data(LatestJobsState(
          errorMessage: result['message'] ?? 'Failed to fetch latest jobs',
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(LatestJobsState(
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> loadMore() async {
    final currentState = state.hasValue ? state.value! : const LatestJobsState();
    
    if (currentState.isLoadingMore || currentState.hasReachedMax) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final result = await _jobService.getLatestJobs(
        page: nextPage,
        limit: 10,
      );

      if (result['success']) {
        final newJobs = result['jobs'] as List<JobModel>;
        final pagination = result['pagination'] as Map<String, dynamic>;
        
        // Combine with existing jobs and re-apply sorting
        final allJobs = [...currentState.allFetchedJobs, ...newJobs];
        List<JobModel> sortedJobs = _applySorting(allJobs, currentState.sortOption ?? 'newest');
        
        state = AsyncValue.data(currentState.copyWith(
          jobs: sortedJobs,
          allFetchedJobs: allJobs,
          isLoadingMore: false,
          currentPage: nextPage,
          totalPages: (pagination['pages'] as num?)?.toInt() ?? 1,
          hasReachedMax: newJobs.length < 10,
        ));
      } else {
        state = AsyncValue.data(currentState.copyWith(
          isLoadingMore: false,
          errorMessage: result['message'] ?? 'Failed to load more jobs',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refresh() async {
    final currentState = state.hasValue ? state.value! : const LatestJobsState();
    await fetchLatestJobs(
      sortBy: currentState.sortOption,
    );
  }

  // Apply sorting to jobs list
  List<JobModel> _applySorting(List<JobModel> jobs, String sortBy) {
    List<JobModel> sortedList = List.from(jobs);
    
    switch (sortBy) {
      case 'newest':
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sortedList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'salaryHigh':
        sortedList.sort((a, b) {
          final aMax = a.ctcMax ?? 0;
          final bMax = b.ctcMax ?? 0;
          return bMax.compareTo(aMax);
        });
        break;
      case 'salaryLow':
        sortedList.sort((a, b) {
          final aMin = a.ctcMin ?? 0;
          final bMin = b.ctcMin ?? 0;
          return aMin.compareTo(bMin);
        });
        break;
      default:
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return sortedList;
  }

  // Method to change sorting
  Future<void> changeSort(String sortBy) async {
    final currentState = state.hasValue ? state.value! : const LatestJobsState();
    
    // If we have jobs already, just re-sort them
    if (currentState.allFetchedJobs.isNotEmpty) {
      List<JobModel> sortedJobs = _applySorting(currentState.allFetchedJobs, sortBy);
      state = AsyncValue.data(currentState.copyWith(
        jobs: sortedJobs,
        sortOption: sortBy,
      ));
    } else {
      // Otherwise fetch with new sort
      await fetchLatestJobs(sortBy: sortBy);
    }
  }

  int get currentPage => state.hasValue ? state.value!.currentPage : 1;
}
