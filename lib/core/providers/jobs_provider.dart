// ============================================================
// core/providers/jobs_provider.dart
// Handles jobs state with Riverpod AsyncNotifier
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../services/api/job_service.dart';
import '../providers/auth_provider.dart'; // Import auth provider
import '../../models/recruiter_model.dart'; // Import recruiter model
import '../../models/application_model.dart'; // Import application model
import '../storage/local_storage.dart'; // Import local storage

// Define a custom state class to hold both general jobs and recruiter jobs
class JobsState {
  final List<JobModel> allJobs;
  final List<JobModel> recruiterJobs;
  final List<ApplicationModel> recentApplications;
  final Map<String, dynamic>? applicantStats;
  final bool isLoading;
  final String? errorMessage;

  const JobsState({
    this.allJobs = const [],
    this.recruiterJobs = const [],
    this.recentApplications = const [],
    this.applicantStats,
    this.isLoading = false,
    this.errorMessage,
  });

  JobsState copyWith({
    List<JobModel>? allJobs,
    List<JobModel>? recruiterJobs,
    List<ApplicationModel>? recentApplications,
    Map<String, dynamic>? applicantStats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return JobsState(
      allJobs: allJobs ?? this.allJobs,
      recruiterJobs: recruiterJobs ?? this.recruiterJobs,
      recentApplications: recentApplications ?? this.recentApplications,
      applicantStats: applicantStats ?? this.applicantStats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final jobsStateProvider =
    AsyncNotifierProvider<JobsNotifier, JobsState>(() => JobsNotifier());

class JobsNotifier extends AsyncNotifier<JobsState> {
  final JobService _jobService = JobService();

  @override
  Future<JobsState> build() async {
    // Auto-load recruiter jobs on first build if user is a recruiter
    final authState = ref.read(authStateProvider);
    if (authState.hasValue && authState.value is RecruiterModel) {
      return _buildRecruiterState();
    }
    return const JobsState();
  }

  Future<JobsState> _buildRecruiterState() async {
    try {
      final authState = ref.read(authStateProvider);
      String? recruiterId;
      if (authState.hasValue && authState.value is RecruiterModel) {
        recruiterId = (authState.value as RecruiterModel).id.toString();
      }
      if (recruiterId == null) return const JobsState();

      final jobsResult = await getJobsByRecruiter(recruiterId);
      if (jobsResult == null) return const JobsState();

      final appsResult = await _jobService.getApplicationsForRecruiter();
      List<ApplicationModel> allApps = [];
      if (appsResult['success'] == true) {
        final rawApps = appsResult['applications'] as List;
        allApps = rawApps.map((a) => ApplicationModel.fromJson(a)).toList();
      }

      List<JobModel> updatedJobs = [];
      for (var job in jobsResult) {
        final jobApps = allApps
            .where((a) => a.jobId.toString() == job.id.toString())
            .toList();
        final recentPhotos = jobApps
            .where((a) => a.jobseekerPhotoUrl != null)
            .map((a) => a.jobseekerPhotoUrl!)
            .take(3)
            .toList();
        updatedJobs.add(job.copyWith(
          applicantsCount: jobApps.length,
          recentApplicantPhotos: recentPhotos,
        ));
      }
      allApps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

      return JobsState(
        recruiterJobs: updatedJobs,
        recentApplications: allApps,
      );
    } catch (e) {
      print('JobsNotifier: Error in build: $e');
      return const JobsState();
    }
  }

  Future<void> fetchJobs({
    int page = 1,
    int limit = 10,
    String? location,
    String? category,
    String? jobType,
    int? minCtc,
    int? maxCtc,
    bool? isUrgent,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _jobService.getAllJobs(
        page: page,
        limit: limit,
        location: location,
        category: category,
        jobType: jobType,
        minCtc: minCtc,
        maxCtc: maxCtc,
        isUrgent: isUrgent,
      );

      if (result['success']) {
        final currentState = state.hasValue ? state.value! : const JobsState();
        state = AsyncValue.data(currentState.copyWith(
          allJobs: result['jobs'] as List<JobModel>,
          isLoading: false,
        ));
      } else {
        final currentState = state.hasValue ? state.value! : const JobsState();
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: result['message'] ?? 'Failed to fetch jobs',
          isLoading: false,
        ));
      }
    } catch (e) {
      final currentState = state.hasValue ? state.value! : const JobsState();
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> fetchJobById(String id) async {
    try {
      final result = await _jobService.getJobById(id);

      if (result['success']) {
        final currentState = state.hasValue ? state.value! : const JobsState();
        final updatedJobs = [...currentState.allJobs];
        final existingIndex = updatedJobs.indexWhere((job) => job.id.toString() == id);

        if (existingIndex != -1) {
          updatedJobs[existingIndex] = result['job'] as JobModel;
        } else {
          updatedJobs.insert(0, result['job'] as JobModel);
        }

        state = AsyncValue.data(currentState.copyWith(allJobs: updatedJobs));
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> searchJobs({
    String? query,
    String? location,
    String? category,
    String? designation,
    String? companyName,
    String? jobType,
    int? minCtc,
    int? maxCtc,
    String? experienceRequired,
    bool? isUrgent,
    int page = 1,
    int limit = 10,
  }) async {
    final currentState = state.hasValue ? state.value! : const JobsState();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
    try {
      final result = await _jobService.searchJobs(
        query: query ?? '',
        location: location,
        category: category,
        designation: designation,
        companyName: companyName,
        jobType: jobType,
        minCtc: minCtc,
        maxCtc: maxCtc,
        experienceRequired: experienceRequired,
        isUrgent: isUrgent,
        page: page,
        limit: limit,
      );

      if (result['success']) {
        final currentState = state.hasValue ? state.value! : const JobsState();
        state = AsyncValue.data(currentState.copyWith(
          allJobs: result['jobs'] as List<JobModel>,
          isLoading: false,
        ));
      } else {
        final currentState = state.hasValue ? state.value! : const JobsState();
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: result['message'] ?? 'Failed to search jobs',
          isLoading: false,
        ));
      }
    } catch (e) {
      final currentState = state.hasValue ? state.value! : const JobsState();
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> createJob({
    required String companyName,
    String? companyLogoUrl,
    String? companyLogoPath, // Local file path for image upload
    String? companyUrl, // New field
    required String designation,
    required String ctc,
    required String location,
    required String category,
    required String description,
    List<String>? requirements,
    List<String>? skillsRequired,
    List<String>? perksAndBenefits,
    String? experienceRequired,  // Changed from int? to String?
    String jobType = 'Full-time',
    bool isUrgentHiring = false,
    bool isActive = true,
  }) async {
    try {
      final result = await _jobService.createJob(
        companyName: companyName,
        companyLogoUrl: companyLogoUrl,
        companyLogoPath: companyLogoPath, // Pass logo file path
        companyUrl: companyUrl, // Include new field
        designation: designation,
        ctc: ctc,
        location: location,
        category: category,
        description: description,
        requirements: requirements,
        skillsRequired: skillsRequired ?? [],
        perksAndBenefits: perksAndBenefits ?? [],
        experienceRequired: experienceRequired, // Now passes string
        jobType: jobType,
        isUrgentHiring: isUrgentHiring,
        isActive: isActive,
      );

      if (result['success']) {
        // Refresh recruiter jobs after creation to show the new job
        await loadRecruiterJobs();
      }
    } catch (e) {
      print('JobsNotifier: Error creating job: $e');
    }
  }

  Future<void> updateJob(String id, {
    String? companyName,
    String? companyLogoUrl,
    String? companyLogoPath, // Local file path for image upload
    String? companyUrl, // New field
    String? designation,
    String? ctc,
    String? location,
    String? category,
    String? description,
    List<String>? requirements,
    List<String>? skillsRequired,
    List<String>? perksAndBenefits,
    String? experienceRequired,  // Changed from int? to String?
    String? jobType,
    bool? isUrgentHiring,
    bool? isActive,
  }) async {
    try {
      final result = await _jobService.updateJob(
        jobId: int.parse(id), // Fix type conversion
        companyName: companyName,
        companyLogoUrl: companyLogoUrl,
        companyLogoPath: companyLogoPath, // Pass logo file path
        companyUrl: companyUrl, // Include new field
        designation: designation,
        ctc: ctc,
        location: location,
        category: category,
        description: description,
        requirements: requirements,
        skillsRequired: skillsRequired,
        perksAndBenefits: perksAndBenefits,
        experienceRequired: experienceRequired, // Now passes string
        jobType: jobType,
        isUrgentHiring: isUrgentHiring,
        isActive: isActive,
      );

      if (result['success']) {
        // Refresh recruiter jobs after update to show the updated job
        await loadRecruiterJobs();
      }
    } catch (e) {
      print('JobsNotifier: Error updating job: $e');
    }
  }

  Future<void> deleteJob(String id) async {
    try {
      print('JobsNotifier: Deleting job ID: $id');
      final result = await _jobService.deleteJob(id);

      if (result['success']) {
        print('JobsNotifier: Job deleted successfully, refreshing recruiter jobs...');
        // After successful deletion, refresh all recruiter jobs from API
        // This ensures the UI gets fresh data from the database
        await loadRecruiterJobs();
        print('JobsNotifier: Recruiter jobs refreshed after deletion');
      } else {
        print('JobsNotifier: Failed to delete job: ${result['message']}');
      }
    } catch (e) {
      print('JobsNotifier: Error deleting job: $e');
    }
  }

  Future<List<String>?> getJobCategories() async {
    try {
      final result = await _jobService.getJobCategories();
      if (result['success']) {
        return result['categories'] as List<String>;
      }
    } catch (e) {
      print('JobsNotifier: Error getting job categories: $e');
    }
    return null;
  }

  Future<List<String>?> getJobLocations() async {
    try {
      final result = await _jobService.getJobLocations();
      if (result['success']) {
        return result['locations'] as List<String>;
      }
    } catch (e) {
      print('JobsNotifier: Error getting job locations: $e');
    }
    return null;
  }

  Future<void> uploadCompanyLogo(String jobId, String imagePath) async {
    try {
      final result = await _jobService.uploadCompanyLogo(jobId, imagePath);
      
      if (result['success']) {
        // Update the job in the state with the new logo URL
        final currentState = state.hasValue ? state.value! : const JobsState();
        final updatedAllJobs = [...currentState.allJobs];
        final jobIndex = updatedAllJobs.indexWhere((job) => job.id.toString() == jobId);
        
        if (jobIndex != -1) {
          updatedAllJobs[jobIndex] = updatedAllJobs[jobIndex].copyWith(
            companyLogoUrl: result['logo_url'] as String?,
          );
        }
        
        // Also update in recruiter jobs if present
        final updatedRecruiterJobs = [...currentState.recruiterJobs];
        final recruiterJobIndex = updatedRecruiterJobs.indexWhere((job) => job.id.toString() == jobId);
        if (recruiterJobIndex != -1) {
          updatedRecruiterJobs[recruiterJobIndex] = updatedRecruiterJobs[recruiterJobIndex].copyWith(
            companyLogoUrl: result['logo_url'] as String?,
          );
        }
        
        state = AsyncValue.data(currentState.copyWith(
          allJobs: updatedAllJobs,
          recruiterJobs: updatedRecruiterJobs,
        ));
      }
    } catch (e) {
      print('JobsNotifier: Error uploading company logo: $e');
    }
  }

  Future<Map<String, dynamic>?> getApplicationsForJob(String jobId) async {
    try {
      final result = await _jobService.getApplicationsForJob(jobId);
      if (result['success']) {
        return result;
      }
    } catch (e) {
      print('JobsNotifier: Error getting applications for job $jobId: $e');
    }
    return null;
  }

  Future<bool> updateApplicationStatus(String applicationId, String status) async {
    try {
      final result = await _jobService.updateApplicationStatus(applicationId, status);
      return result['success'] ?? false;
    } catch (e) {
      print('JobsNotifier: Error updating application status for $applicationId: $e');
      return false;
    }
  }

  Future<List<JobModel>?> getJobsByRecruiter(String recruiterId) async {
    try {
      print('JobsNotifier: Calling getJobsByRecruiter with recruiterId: $recruiterId');
      final result = await _jobService.getJobsByRecruiter(recruiterId);
      print('JobsNotifier: getJobsByRecruiter result: $result');
      if (result['success']) {
        return result['jobs'] as List<JobModel>;
      }
    } catch (e) {
      print('JobsNotifier: Error getting jobs for recruiter $recruiterId: $e');
    }
    return null;
  }
  
  // New method to load recruiter's jobs
  Future<void> loadRecruiterJobs() async {
    final currentState = state.hasValue ? state.value! : const JobsState();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
    try {
      // Get the current recruiter from auth provider
      print('JobsNotifier: Loading recruiter jobs...');
      final authState = ref.read(authStateProvider);
      String? recruiterId;
      
      if (authState.hasValue && authState.value != null) {
        final profile = authState.value;
        // Check if user is a recruiter and get their ID
        if (profile is RecruiterModel) {
          recruiterId = profile.id.toString();
          print('JobsNotifier: Found recruiter from auth state: ID $recruiterId');
        } else {
          print('JobsNotifier: Auth state value is of unexpected type: ${profile.runtimeType}');
        }
      }
      
      if (recruiterId == null) {
        print('JobsNotifier: Recruiter ID not found in auth state, checking local storage...');
        final localRecruiter = LocalStorage().getRecruiter();
        if (localRecruiter != null) {
          recruiterId = localRecruiter.id.toString();
          print('JobsNotifier: Found recruiter in local storage: ID $recruiterId');
        }
      }
      
      List<JobModel>? jobsResult;
      
      if (recruiterId != null) {
        // Get jobs specifically for this recruiter
        print('JobsNotifier: Fetching jobs for recruiter ID: $recruiterId');
        jobsResult = await getJobsByRecruiter(recruiterId);
        print('JobsNotifier: getJobsByRecruiter returned: ${jobsResult?.length ?? 0} jobs');
      } else {
        print('JobsNotifier: No recruiter ID found, unable to fetch recruiter jobs');
        jobsResult = [];
      }
      
      if (jobsResult != null) {
        // Fetch all applications for this recruiter in one go to avoid N+1 queries
        final appsResult = await _jobService.getApplicationsForRecruiter();
        List<ApplicationModel> allApps = [];
        
        if (appsResult['success'] == true) {
          final rawApps = appsResult['applications'] as List;
          allApps = rawApps.map((a) => ApplicationModel.fromJson(a)).toList();
          print('JobsNotifier: Successfully fetched ${allApps.length} total applications for recruiter');
        }

        // Distribute applications to their respective jobs to update counts and photos
        List<JobModel> updatedJobs = [];
        for (var job in jobsResult) {
          final jobApps = allApps.where((a) => a.jobId.toString() == job.id.toString()).toList();
          final recentPhotos = jobApps
              .where((a) => a.jobseekerPhotoUrl != null)
              .map((a) => a.jobseekerPhotoUrl!)
              .take(3)
              .toList();
              
          updatedJobs.add(job.copyWith(
            applicantsCount: jobApps.length,
            recentApplicantPhotos: recentPhotos,
          ));
        }
        
        // Fetch application stats for counts
        final statsResult = await _jobService.getApplicationStats();
        Map<String, dynamic>? stats;
        if (statsResult['success'] == true) {
          stats = statsResult['stats'];
        }
        
        // Sort all applications by date (descending) to get the most recent ones
        allApps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
        
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          recruiterJobs: updatedJobs,
          recentApplications: allApps,
          applicantStats: stats,
          errorMessage: null,
        ));
      } else {
        print('JobsNotifier: jobsResult is null, setting error state');
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch recruiter jobs',
        ));
      }
    } catch (e) {
      final currentState = state.hasValue ? state.value! : const JobsState();
      print('JobsNotifier: Exception in loadRecruiterJobs: $e');
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }
}