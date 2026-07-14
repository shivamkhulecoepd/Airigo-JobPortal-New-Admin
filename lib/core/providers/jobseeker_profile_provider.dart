import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/jobseeker_model.dart';
import '../../services/api/jobseeker_profile_service.dart';
import '../../services/api/file_upload_service.dart';

/// State class for jobseeker profile
class JobseekerProfileState {
  final JobseekerModel? profile;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final String? successMessage;

  const JobseekerProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
    this.successMessage,
  });

  JobseekerProfileState copyWith({
    JobseekerModel? profile,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return JobseekerProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error,
      isUpdating: isUpdating ?? this.isUpdating,
      successMessage: clearSuccess ? null : successMessage,
    );
  }
}

/// Notifier for jobseeker profile state
class JobseekerProfileNotifier extends StateNotifier<JobseekerProfileState> {
  final JobseekerProfileService _profileService = JobseekerProfileService();
  final FileUploadService _fileUploadService = FileUploadService();

  JobseekerProfileNotifier() : super(const JobseekerProfileState());

  /// Fetch jobseeker profile from API
  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      log('JobseekerProfileNotifier: Fetching profile from API');
      final result = await _profileService.fetchProfile();

      if (result['success'] == true && result['profile'] != null) {
        final profile = JobseekerModel.fromJson(result['profile']);
        state = state.copyWith(
          profile: profile,
          isLoading: false,
        );
        log('JobseekerProfileNotifier: Profile fetched successfully: ${profile.name}');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Failed to fetch profile',
        );
        log('JobseekerProfileNotifier: Failed to fetch profile: ${result['message']}');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch profile: $e',
      );
      log('JobseekerProfileNotifier: Error fetching profile: $e');
    }
  }

  /// Update personal details section
  Future<bool> updatePersonalDetails({
    String? name,
    String? phone,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Updating personal details');
      final result = await _profileService.updatePersonalDetails(
        name: name,
        phone: phone,
      );

      if (result['success'] == true) {
        final updatedProfile = JobseekerModel.fromJson(result['profile']);
        
        // Preserve email and phone from existing profile if not in response
        // This prevents data loss when API doesn't return these fields
        if (state.profile != null) {
          final mergedProfile = updatedProfile.copyWith(
            email: updatedProfile.email.isNotEmpty ? updatedProfile.email : state.profile!.email,
            phone: updatedProfile.phone.isNotEmpty ? updatedProfile.phone : state.profile!.phone,
          );
          state = state.copyWith(
            profile: mergedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Personal details updated successfully',
          );
        } else {
          state = state.copyWith(
            profile: updatedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Personal details updated successfully',
          );
        }
        log('JobseekerProfileNotifier: Personal details updated successfully');
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update personal details',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update personal details: $e',
      );
      return false;
    }
  }

  /// Update education section
  Future<bool> updateEducation({
    String? qualification,
    String? dateOfBirth,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Updating education');
      final result = await _profileService.updateEducation(
        qualification: qualification,
        dateOfBirth: dateOfBirth,
      );

      if (result['success'] == true) {
        final updatedProfile = JobseekerModel.fromJson(result['profile']);
        
        // Preserve email and phone from existing profile if not in response
        if (state.profile != null) {
          final mergedProfile = updatedProfile.copyWith(
            email: updatedProfile.email.isNotEmpty ? updatedProfile.email : state.profile!.email,
            phone: updatedProfile.phone.isNotEmpty ? updatedProfile.phone : state.profile!.phone,
          );
          state = state.copyWith(
            profile: mergedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Education updated successfully',
          );
        } else {
          state = state.copyWith(
            profile: updatedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Education updated successfully',
          );
        }
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update education',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update education: $e',
      );
      return false;
    }
  }

  /// Update experience section
  Future<bool> updateExperience({required int experience}) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Updating experience');
      final result = await _profileService.updateExperience(experience: experience);

      if (result['success'] == true) {
        final updatedProfile = JobseekerModel.fromJson(result['profile']);
        
        // Preserve email and phone from existing profile if not in response
        if (state.profile != null) {
          final mergedProfile = updatedProfile.copyWith(
            email: updatedProfile.email.isNotEmpty ? updatedProfile.email : state.profile!.email,
            phone: updatedProfile.phone.isNotEmpty ? updatedProfile.phone : state.profile!.phone,
          );
          state = state.copyWith(
            profile: mergedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Experience updated successfully',
          );
        } else {
          state = state.copyWith(
            profile: updatedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Experience updated successfully',
          );
        }
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update experience',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update experience: $e',
      );
      return false;
    }
  }

  /// Update skills section
  Future<bool> updateSkills({required List<String> skills}) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Updating skills');
      final result = await _profileService.updateSkills(skills: skills);

      if (result['success'] == true) {
        final updatedProfile = JobseekerModel.fromJson(result['profile']);
        
        // Preserve email and phone from existing profile if not in response
        if (state.profile != null) {
          final mergedProfile = updatedProfile.copyWith(
            email: updatedProfile.email.isNotEmpty ? updatedProfile.email : state.profile!.email,
            phone: updatedProfile.phone.isNotEmpty ? updatedProfile.phone : state.profile!.phone,
          );
          state = state.copyWith(
            profile: mergedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Skills updated successfully',
          );
        } else {
          state = state.copyWith(
            profile: updatedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Skills updated successfully',
          );
        }
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update skills',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update skills: $e',
      );
      return false;
    }
  }

  /// Update location section
  Future<bool> updateLocation({required String location}) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Updating location');
      final result = await _profileService.updateLocation(location: location);

      if (result['success'] == true) {
        final updatedProfile = JobseekerModel.fromJson(result['profile']);
        
        // Preserve email and phone from existing profile if not in response
        if (state.profile != null) {
          final mergedProfile = updatedProfile.copyWith(
            email: updatedProfile.email.isNotEmpty ? updatedProfile.email : state.profile!.email,
            phone: updatedProfile.phone.isNotEmpty ? updatedProfile.phone : state.profile!.phone,
          );
          state = state.copyWith(
            profile: mergedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Location updated successfully',
          );
        } else {
          state = state.copyWith(
            profile: updatedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Location updated successfully',
          );
        }
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update location',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update location: $e',
      );
      return false;
    }
  }

  /// Update bio section
  Future<bool> updateBio({required String bio}) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Updating bio');
      final result = await _profileService.updateBio(bio: bio);

      if (result['success'] == true) {
        final updatedProfile = JobseekerModel.fromJson(result['profile']);
        
        // Preserve email and phone from existing profile if not in response
        if (state.profile != null) {
          final mergedProfile = updatedProfile.copyWith(
            email: updatedProfile.email.isNotEmpty ? updatedProfile.email : state.profile!.email,
            phone: updatedProfile.phone.isNotEmpty ? updatedProfile.phone : state.profile!.phone,
          );
          state = state.copyWith(
            profile: mergedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Bio updated successfully',
          );
        } else {
          state = state.copyWith(
            profile: updatedProfile,
            isUpdating: false,
            successMessage: result['message'] ?? 'Bio updated successfully',
          );
        }
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update bio',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update bio: $e',
      );
      return false;
    }
  }

  /// Update profile image
  Future<bool> updateProfileImage(String imagePath) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Uploading profile image');
      final result = await _fileUploadService.uploadProfileImage(imagePath);

      if (result['success'] == true) {
        // Refresh profile to get updated image URL
        await fetchProfile();
        state = state.copyWith(
          isUpdating: false,
          successMessage: result['message'] ?? 'Profile image updated successfully',
        );
        log('JobseekerProfileNotifier: Profile image updated successfully');
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update profile image',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update profile image: $e',
      );
      return false;
    }
  }

  /// Update resume
  Future<bool> updateResume(String filePath) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Uploading resume');
      final result = await _fileUploadService.uploadResume(filePath);

      if (result['success'] == true) {
        // Refresh profile to get updated resume URL
        await fetchProfile();
        state = state.copyWith(
          isUpdating: false,
          successMessage: result['message'] ?? 'Resume updated successfully',
        );
        log('JobseekerProfileNotifier: Resume updated successfully');
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update resume',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update resume: $e',
      );
      return false;
    }
  }

  /// Update full profile
  Future<bool> updateFullProfile({
    String? name,
    String? phone,
    String? qualification,
    String? dateOfBirth,
    int? experience,
    List<String>? skills,
    String? location,
    String? bio,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    try {
      log('JobseekerProfileNotifier: Updating full profile');
      final result = await _profileService.updateFullProfile(
        name: name,
        phone: phone,
        qualification: qualification,
        dateOfBirth: dateOfBirth,
        experience: experience,
        skills: skills,
        location: location,
        bio: bio,
      );

      if (result['success'] == true) {
        final updatedProfile = JobseekerModel.fromJson(result['profile']);
        state = state.copyWith(
          profile: updatedProfile,
          isUpdating: false,
          successMessage: result['message'] ?? 'Profile updated successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result['message'] ?? 'Failed to update profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update profile: $e',
      );
      return false;
    }
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Clear error message
  void clearErrorMessage() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for jobseeker profile state
final jobseekerProfileProvider = StateNotifierProvider<JobseekerProfileNotifier, JobseekerProfileState>(
  (ref) => JobseekerProfileNotifier(),
);

/// Provider to check if user is a jobseeker
final isJobseekerProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.hasValue && authState.value != null) {
    final user = authState.value;
    return user.runtimeType.toString().toLowerCase().contains('jobseeker');
  }
  return false;
});
