// ============================================================
// core/providers/jobs_feed_provider.dart
// Handles jobs feed state with Riverpod StateNotifier
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../services/api/job_service.dart';

final jobsFeedProvider =
    AsyncNotifierProvider<JobsFeedNotifier, List<JobModel>>(() => JobsFeedNotifier());

class JobsFeedNotifier extends AsyncNotifier<List<JobModel>> {
  final JobService _jobService = JobService();

  @override
  Future<List<JobModel>> build() async {
    return _fetchJobs();
  }

  Future<List<JobModel>> _fetchJobs() async {
    print('JobsFeedProvider: Fetching jobs...');
    final result = await _jobService.getAllJobs();
    print('JobsFeedProvider: Result success: ${result['success']}');
    if (result['success'] == true) {
      final jobs = (result['jobs'] as List).cast<JobModel>();
      print('JobsFeedProvider: Setting state with ${jobs.length} jobs');
      return jobs;
    } else {
      throw result['message'] ?? 'Failed to fetch jobs';
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final jobs = await _fetchJobs();
      state = AsyncValue.data(jobs);
    } catch (e, stackTrace) {
      print('JobsFeedProvider: Exception caught: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> search(String query, {
    String? location,
    String? jobType,
    String? category,
    int? minCtc,
    int? maxCtc,
    bool? isUrgent,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('JobsFeedProvider: Searching with - query: $query, location: $location, jobType: $jobType, category: $category, minCtc: $minCtc, maxCtc: $maxCtc');
      
      final result = await _jobService.searchJobs(
        query: query,
        location: location,
        jobType: jobType,
        category: category,
        minCtc: minCtc,
        maxCtc: maxCtc,
        isUrgent: isUrgent,
      );
      
      print('JobsFeedProvider: Search result - success: ${result['success']}, message: ${result['message']}, jobs count: ${result['jobs']?.length ?? 0}');
      
      if (result['success']) {
        state = AsyncValue.data(result['jobs'] as List<JobModel>);
      } else {
        final errorMsg = result['message'] ?? 'Failed to search jobs';
        print('JobsFeedProvider: Search failed with error: $errorMsg');
        state = AsyncValue.error(errorMsg, StackTrace.empty);
      }
    } catch (e, stackTrace) {
      print('JobsFeedProvider: Search caught exception: $e');
      print('JobsFeedProvider: Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMore() async {
    // Implementation for loading more jobs
  }
}