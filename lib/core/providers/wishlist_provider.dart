// ============================================================
// core/providers/wishlist_provider.dart
// Handles wishlist state with Riverpod StateNotifier
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../services/api/wishlist_service.dart';

final wishlistStateProvider =
    AsyncNotifierProvider<WishlistNotifier, List<JobModel>>(() => WishlistNotifier());

class WishlistNotifier extends AsyncNotifier<List<JobModel>> {
  final WishlistService _wishlistService = WishlistService();

  @override
  Future<List<JobModel>> build() async {
    // Initially return empty list
    return [];
  }

  Future<void> fetchWishlist() async {
    state = const AsyncValue.loading();
    try {
      final result = await _wishlistService.getWishlist();

      if (result['success']) {
        state = AsyncValue.data(result['jobs'] as List<JobModel>);
      } else {
        state = AsyncValue.error(
          result['message'] ?? 'Failed to fetch wishlist',
          StackTrace.empty,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }

  Future<void> addToWishlist(String jobId) async {
    try {
      final result = await _wishlistService.addToWishlist(jobId);

      if (result['success']) {
        // Refresh wishlist after adding
        await fetchWishlist();
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> removeFromWishlist(String jobId) async {
    try {
      final result = await _wishlistService.removeFromWishlist(jobId);

      if (result['success']) {
        // Refresh wishlist after removing
        await fetchWishlist();
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> toggleWishlist(String jobId) async {
    try {
      final result = await _wishlistService.toggleWishlist(jobId);

      if (result['success']) {
        // Refresh wishlist after toggling
        await fetchWishlist();
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<bool> isJobInWishlist(String jobId) async {
    try {
      final result = await _wishlistService.isJobInWishlist(jobId);
      return result; // Directly return the boolean value
    } catch (e) {
      // Handle error silently or log it
      return false;
    }
  }

  Future<List<String>> getWishlistIds() async {
    try {
      final result = await _wishlistService.getWishlistIds();
      return result['job_ids'] as List<String>? ?? [];
    } catch (e) {
      // Handle error silently or log it
      return [];
    }
  }
}