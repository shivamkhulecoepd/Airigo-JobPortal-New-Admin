// ============================================================
// core/providers/job_search_provider.dart
// Handles search-specific job results to avoid polluting main feed
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../services/api/job_service.dart';

final jobSearchProvider =
    AsyncNotifierProvider<JobSearchNotifier, List<JobModel>>(() => JobSearchNotifier());

class JobSearchNotifier extends AsyncNotifier<List<JobModel>> {
  final JobService _jobService = JobService();

  @override
  Future<List<JobModel>> build() async {
    // By default, show the main feed if no search is active
    final result = await _jobService.getAllJobs();
    if (result['success'] == true) {
      return (result['jobs'] as List).cast<JobModel>();
    }
    return [];
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
      final result = await _jobService.searchJobs(
        query: query,
        location: location,
        jobType: jobType,
        category: category,
        minCtc: minCtc,
        maxCtc: maxCtc,
        isUrgent: isUrgent,
      );
      
      if (result['success']) {
        state = AsyncValue.data(result['jobs'] as List<JobModel>);
      } else {
        state = AsyncValue.error(result['message'] ?? 'Search failed', StackTrace.empty);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> clearSearch() async {
    state = const AsyncValue.loading();
    try {
      final result = await _jobService.getAllJobs();
      if (result['success'] == true) {
        state = AsyncValue.data((result['jobs'] as List).cast<JobModel>());
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
