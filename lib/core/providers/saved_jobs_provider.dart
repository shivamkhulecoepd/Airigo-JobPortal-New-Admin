// ============================================================
// core/providers/saved_jobs_provider.dart
// Single source of truth for saved/bookmarked job IDs + full job objects.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../services/api/wishlist_service.dart';

// ── ID-only provider (used by job cards everywhere for bookmark state) ──
final savedJobsProvider =
    AsyncNotifierProvider<SavedJobsNotifier, List<String>>(
      () => SavedJobsNotifier(),
    );

// ── Full job objects provider (used only by SavedJobsScreen list) ──
// Holds the full JobModel list in memory; updated optimistically on toggle.
final savedJobsFullProvider =
    NotifierProvider<SavedJobsFullNotifier, List<JobModel>>(
      () => SavedJobsFullNotifier(),
    );

// ─────────────────────────────────────────────────────────────

class SavedJobsNotifier extends AsyncNotifier<List<String>> {
  final WishlistService _wishlistService = WishlistService();

  @override
  Future<List<String>> build() async {
    return _loadIds();
  }

  Future<List<String>> _loadIds() async {
    try {
      final result = await _wishlistService.getWishlistIds();
      if (result['success'] == true) {
        return (result['job_ids'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      print('SavedJobsNotifier: Error loading IDs: $e');
    }
    return [];
  }

  /// Toggle bookmark — optimistic update, then sync with server.
  /// Also keeps savedJobsFullProvider in sync.
  Future<void> toggle(String jobId, {JobModel? jobModel}) async {
    final current = state.value ?? [];
    final isSaved = current.contains(jobId);

    // Optimistic update on IDs
    state = AsyncData(
      isSaved
          ? current.where((id) => id != jobId).toList()
          : [...current, jobId],
    );

    // Optimistic update on full list
    if (isSaved) {
      ref.read(savedJobsFullProvider.notifier).removeJob(jobId);
    } else if (jobModel != null) {
      ref.read(savedJobsFullProvider.notifier).addJob(jobModel);
    }

    try {
      if (isSaved) {
        await _wishlistService.removeFromWishlist(jobId);
      } else {
        await _wishlistService.addToWishlist(jobId);
      }
    } catch (e) {
      // Revert both on failure
      print('SavedJobsNotifier: Toggle failed, reverting: $e');
      state = AsyncData(current);
      if (isSaved && jobModel != null) {
        ref.read(savedJobsFullProvider.notifier).addJob(jobModel);
      } else {
        ref.read(savedJobsFullProvider.notifier).removeJob(jobId);
      }
    }
  }

  Future<void> add(String jobId, {JobModel? jobModel}) async {
    final current = state.value ?? [];
    if (current.contains(jobId)) return;
    state = AsyncData([...current, jobId]);
    if (jobModel != null) {
      ref.read(savedJobsFullProvider.notifier).addJob(jobModel);
    }
    try {
      await _wishlistService.addToWishlist(jobId);
    } catch (e) {
      state = AsyncData(current);
      ref.read(savedJobsFullProvider.notifier).removeJob(jobId);
    }
  }

  Future<void> remove(String jobId) async {
    final current = state.value ?? [];
    if (!current.contains(jobId)) return;
    state = AsyncData(current.where((id) => id != jobId).toList());
    ref.read(savedJobsFullProvider.notifier).removeJob(jobId);
    try {
      await _wishlistService.removeFromWishlist(jobId);
    } catch (e) {
      state = AsyncData(current);
    }
  }

  bool isSaved(String jobId) => state.value?.contains(jobId) ?? false;

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadIds);
    // Also refresh the full list
    await ref.read(savedJobsFullProvider.notifier).fetchFromApi();
  }
}

// ─────────────────────────────────────────────────────────────

class SavedJobsFullNotifier extends Notifier<List<JobModel>> {
  final WishlistService _wishlistService = WishlistService();

  @override
  List<JobModel> build() => [];

  Future<void> fetchFromApi() async {
    try {
      final result = await _wishlistService.getWishlist();
      if (result['success'] == true) {
        state = (result['jobs'] as List).cast<JobModel>();
      }
    } catch (e) {
      print('SavedJobsFullNotifier: Error fetching: $e');
    }
  }

  void addJob(JobModel job) {
    if (!state.any((j) => j.id == job.id)) {
      state = [job, ...state];
    }
  }

  void removeJob(String jobId) {
    state = state.where((j) => j.id.toString() != jobId).toList();
  }
}
