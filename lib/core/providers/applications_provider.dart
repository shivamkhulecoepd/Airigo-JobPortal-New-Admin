// ============================================================
// core/providers/applications_provider.dart
// Handles applications state with Riverpod StateNotifier
// ============================================================

import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/application_model.dart';
import '../../services/api/application_service.dart';
import '../../services/api/recruiter_service.dart';

final applicationsStateProvider =
    AsyncNotifierProvider<ApplicationsNotifier, List<ApplicationModel>>(
      () => ApplicationsNotifier(),
    );

class ApplicationsNotifier extends AsyncNotifier<List<ApplicationModel>> {
  final ApplicationService _applicationService = ApplicationService();
  final RecruiterService _recruiterService = RecruiterService();
  
  // Cache for recruiter profiles to avoid duplicate API calls
  final Map<int, Map<String, dynamic>> _recruiterProfilesCache = {};

  @override
  Future<List<ApplicationModel>> build() async {
    // Auto-fetch on first build so any screen that watches this
    // gets real data without needing to call fetchMyApplications() manually.
    return _fetchApplications();
  }

  Future<List<ApplicationModel>> _fetchApplications({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    try {
      final result = await _applicationService.getMyApplications(
        page: page,
        limit: limit,
        status: status,
      );
      if (result['success']) {
        final applications = result['applications'] as List<ApplicationModel>;
        _fetchRecruiterProfilesInBackground(applications);
        return applications;
      }
    } catch (e) {
      // fall through to return empty
    }
    return [];
  }

  Future<void> fetchMyApplications({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final applications = await _fetchApplications(
        page: page,
        limit: limit,
        status: status,
      );
      state = AsyncValue.data(applications);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }

  Future<void> fetchApplicationsForJob(
    String jobId, {
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _applicationService.getApplicationsForJob(
        jobId,
        page: page,
        limit: limit,
        status: status,
      );

      if (result['success']) {
        final applications = result['applications'] as List<ApplicationModel>;
        
        // Fetch recruiter profiles in the background after getting applications
        _fetchRecruiterProfilesInBackground(applications);
        
        state = AsyncValue.data(applications);
      } else {
        state = AsyncValue.error(
          result['message'] ?? 'Failed to fetch applications for job',
          StackTrace.empty,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }

  Future<void> applyForJob({
    required String jobId,
    String? coverLetter,
    dynamic resumeFile,
  }) async {
    try {
      final result = await _applicationService.applyForJob(
        jobId: jobId,
        coverLetter: coverLetter,
        resumeFile: resumeFile,
      );

      if (result['success']) {
        // Refresh applications list after applying
        await fetchMyApplications();
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      final result = await _applicationService.updateApplicationStatus(
        applicationId,
        status,
      );

      if (result['success']) {
        // Refresh applications list after status update
        await fetchMyApplications();
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> deleteApplication(String applicationId) async {
    try {
      final result = await _applicationService.deleteApplication(applicationId);

      if (result['success']) {
        // Remove application from state after deletion
        final currentState = state.value ?? [];
        final updatedApplications = [...currentState];
        updatedApplications.removeWhere((app) => app.id == applicationId);
        state = AsyncValue.data(updatedApplications);
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<Map<String, dynamic>?> getApplicationStats() async {
    try {
      final result = await _applicationService.getApplicationStats();
      if (result['success']) {
        return result['stats'] as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error silently or log it
    }
    return null;
  }

  // New method for recruiters to fetch all their applications
  Future<void> fetchApplicationsForRecruiter({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _applicationService.getApplicationsForRecruiter(
        page: page,
        limit: limit,
        status: status,
      );

      if (result['success']) {
        final applications = result['applications'] as List<ApplicationModel>;
        
        // Fetch recruiter profiles in the background after getting applications
        _fetchRecruiterProfilesInBackground(applications);
        
        state = AsyncValue.data(applications);
      } else {
        state = AsyncValue.error(
          result['message'] ?? 'Failed to fetch applications for recruiter',
          StackTrace.empty,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }
  
  // Method to fetch recruiter profiles in background
  Future<void> _fetchRecruiterProfilesInBackground(List<ApplicationModel> applications) async {
    try {
      // Extract unique recruiter user IDs from applications
      final Set<int> uniqueRecruiterIds = {};
      for (final application in applications) {
        if (application.recruiterUserId != null) {
          uniqueRecruiterIds.add(application.recruiterUserId!);
        }
      }
      
      if (uniqueRecruiterIds.isEmpty) return;
      
      log('Fetching recruiter profiles for IDs: $uniqueRecruiterIds');
      
      // Filter out recruiter IDs that are already cached
      final uncachedRecruiterIds = uniqueRecruiterIds.where((id) => !_recruiterProfilesCache.containsKey(id)).toList();
      
      if (uncachedRecruiterIds.isNotEmpty) {
        log('Uncached recruiter IDs: $uncachedRecruiterIds');
        // Fetch recruiter profiles for uncached IDs in batch
        final profilesMap = await _recruiterService.getMultipleRecruiterProfiles(uncachedRecruiterIds);
        
        if (profilesMap != null) {
          // Store the fetched profiles in cache
          _recruiterProfilesCache.addAll(profilesMap);
          log('Cached ${profilesMap.length} recruiter profiles');
          
          // Log photo URLs for debugging
          for (final entry in profilesMap.entries) {
            final photoUrl = entry.value['photo_url'] ?? entry.value['profile_image_url'];
            log('Cached recruiter ${entry.key} photo_url: $photoUrl');
          }
        }
      } else {
        log('All recruiter profiles already cached');
      }
    } catch (e) {
      log('Error fetching recruiter profiles in background: $e');
    }
  }
  
  // Method to get cached recruiter profile
  Map<String, dynamic>? getCachedRecruiterProfile(int recruiterUserId) {
    return _recruiterProfilesCache[recruiterUserId];
  }
  
  // Method to clear recruiter profiles cache
  void clearRecruiterProfilesCache() {
    _recruiterProfilesCache.clear();
  }
  
  // Method to prefetch recruiter profile (for immediate access)
  Future<Map<String, dynamic>?> prefetchRecruiterProfile(int recruiterUserId) async {
    // Check if already cached
    if (_recruiterProfilesCache.containsKey(recruiterUserId)) {
      return _recruiterProfilesCache[recruiterUserId];
    }
    
    // Fetch and cache the profile
    try {
      final profile = await _recruiterService.getRecruiterProfile(recruiterUserId);
      if (profile != null) {
        _recruiterProfilesCache[recruiterUserId] = profile;
      }
      return profile;
    } catch (e) {
      log('Error prefetching recruiter profile: $e');
      return null;
    }
  }
}