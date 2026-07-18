// ============================================================
// core/providers/auth_provider.dart
// Handles auth state with Riverpod AsyncNotifier
// ============================================================

import 'package:airigo_jobportal/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/jobseeker_model.dart';
import '../../../models/recruiter_model.dart';
import '../../services/api/auth_service.dart';
import '../../services/notification_manager.dart';

// Simulates authenticated user state
final authStateProvider = AsyncNotifierProvider<AuthNotifier, dynamic>(
  () => AuthNotifier(),
);

class AuthNotifier extends AsyncNotifier<dynamic> {
  final AuthService _authService = AuthService();

  @override
  Future<dynamic> build() async {
    print('AuthNotifier: Building auth state...');
    // Check if user is logged in
    final isLoggedIn = await _authService.isLoggedIn();
    print('AuthNotifier: Is logged in (token exists): $isLoggedIn');

    if (isLoggedIn) {
      try {
        // Get user type to determine which profile to fetch
        String? userType = await _authService.getCurrentUserTypeAsync();
        print('AuthNotifier: Retrieved user type: $userType');

        // If userType is missing but token exists, try to fetch it from profile
        if (userType == null || userType.isEmpty) {
          print(
            'AuthNotifier: userType missing, attempting to fetch profile to recover it...',
          );
          final result = await _authService.getProfile();
          if (result['success']) {
            userType = result['user_type'];
            print('AuthNotifier: Recovered user type: $userType');
          }
        }

        if (userType != null) {
          // Try to use locally stored data first for faster loading
          if (userType == 'jobseeker') {
            final localJobseeker = _authService
                .getLocalStorage()
                .getJobseeker();
            if (localJobseeker != null) {
              print('AuthNotifier: Using locally stored jobseeker data');
              return localJobseeker;
            }
          } else if (userType == 'recruiter') {
            final localRecruiter = _authService
                .getLocalStorage()
                .getRecruiter();
            if (localRecruiter != null) {
              print('AuthNotifier: Using locally stored recruiter data');
              return localRecruiter;
            }
          } else if (userType == 'admin') {
            final localAdmin = _authService.getLocalStorage().getAdminUser();
            if (localAdmin != null) {
              print('AuthNotifier: Using locally stored admin data');
              return localAdmin;
            }
          }

          // If no local data, fetch from API
          print('AuthNotifier: No local data found, fetching from API...');
          final result = await _authService.getProfile(userType: userType);
          if (result['success']) {
            print('AuthNotifier: Profile fetched successfully for $userType');
            return result['user'];
          } else {
            print('AuthNotifier: Profile fetch failed: ${result['message']}');
            return null;
          }
        }
      } catch (e) {
        print('AuthNotifier: Error during build: $e');
        return null;
      }
    }
    print('AuthNotifier: Not logged in or state recovery failed');
    return null;
  }

  // Allow manual refresh of auth state
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      String? userType = await _authService.getCurrentUserTypeAsync();

      // If userType is not available, try to recover it
      if (userType == null || userType.isEmpty) {
        final profileResult = await _authService.getProfile();
        if (profileResult['success']) {
          userType = profileResult['user_type'];
        }
      }

      if (userType != null) {
        // Force an API fetch to get the freshest database information
        final result = await _authService.getProfile(userType: userType);
        if (result['success']) {
          state = AsyncData(result['user']);

          // --- Initialize notifications after successful profile fetch ---
          await NotificationManager().initialize();
          final user = result['user'];
          if (user is RecruiterModel) {
            await NotificationManager().subscribeToRecruiterTopics(user.id);
          } else if (user is JobseekerModel) {
            await NotificationManager().subscribeToJobseekerTopics(user.id);
          }
          return;
        }
      }
    } catch (e) {
      print('AuthNotifier: Error refreshing from API: $e');
    }

    // Fallback to build() (which might use local cache) if API fails
    state = await AsyncValue.guard(() => build());
  }

  Future<void> loginAsJobseeker(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _authService.login(
        email: email,
        password: password,
        userType: 'jobseeker',
      );
      if (result['success']) {
        await refresh();
      } else {
        state = AsyncError(
          result['message'] ?? 'Login failed',
          StackTrace.empty,
        );
      }
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.empty);
    }
  }

  Future<void> loginAsRecruiter(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _authService.login(
        email: email,
        password: password,
        userType: 'recruiter', // This should match the backend API
      );
      if (result['success']) {
        await refresh();
      } else {
        state = AsyncError(
          result['message'] ?? 'Login failed',
          StackTrace.empty,
        );
      }
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.empty);
    }
  }

  Future<void> loginAsAdmin(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _authService.login(
        email: email,
        password: password,
        userType: 'admin',
      );
      if (result['success']) {
        await refresh();
      } else {
        state = AsyncError(
          result['message'] ?? 'Admin login failed',
          StackTrace.empty,
        );
      }
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.empty);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _authService.logout();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.empty);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    state = const AsyncLoading();
    try {
      final result = await _authService.updateProfile(
        name: profileData['name'],
        email: profileData['email'],
        phone: profileData['phone'],
        bio: profileData['bio'],
        location: profileData['location'],
        qualification: profileData['qualification'],
        experience: profileData['experience'],
        skills: profileData['skills'],
        companyName: profileData['company_name'],
        recruiterName: profileData['recruiter_name'],
        companyWebsite: profileData['company_website'],
        designation: profileData['designation'],
        avatarUrl: profileData['avatar_url'],
        idCardUrl: profileData['id_card_url'],
        resumeUrl: profileData['resume_url'],
        photoUrl: profileData['photo_url'],
      );

      if (result['success']) {
        // Force refresh from the backend to guarantee Riverpod matches exact schema
        await refresh();
      } else {
        state = AsyncError(
          result['message'] ?? 'Failed to update profile',
          StackTrace.empty,
        );
        // Ensure state drops back to valid state if there was an error
        await refresh();
      }
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.empty);
      await refresh();
    }
  }

  Future<void> updateProfileImage(String imagePath) async {
    state = const AsyncLoading();
    try {
      final result = await _authService.uploadProfileImage(imagePath);
      if (result['success']) {
        await refresh();
      } else {
        state = AsyncError(
          result['message'] ?? 'Failed to upload profile image',
          StackTrace.empty,
        );
        await refresh();
      }
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.empty);
      await refresh();
    }
  }

  Future<void> updateIdCard(String imagePath) async {
    state = const AsyncLoading();
    try {
      final result = await _authService.uploadIdCard(imagePath);
      if (result['success']) {
        await refresh();
      } else {
        state = AsyncError(
          result['message'] ?? 'Failed to upload ID card',
          StackTrace.empty,
        );
        await refresh();
      }
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.empty);
      await refresh();
    }
  }
}

// Convenience provider to check if user is recruiter
final isRecruiterProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user is RecruiterModel;
});

// Convenience provider to check if user is jobseeker
final isJobseekerProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user is JobseekerModel;
});

// Convenience provider to check if user is admin
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  // Admin users are stored as UserModel with role/user_type = 'admin'
  if (user == null) return false;
  // Check if user has admin role (could be UserModel with role='admin')
  if (user is Map) {
    return user['user_type'] == 'admin' || user['user_type'] == 'super_admin';
  }
  // For UserModel, we can check if it has admin-specific properties
  if (user is UserModel) {
    return user.role == 'admin' || user.role == 'super_admin';
  }
  return false;
});

// Current user shortcut for jobseeker
final currentJobseekerProvider = Provider<JobseekerModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user is JobseekerModel ? user : null;
});

// Current user shortcut for recruiter
final currentRecruiterProvider = Provider<RecruiterModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user is RecruiterModel ? user : null;
});

// Current user provider (returns whichever user type is logged in)
final currentUserProvider = Provider<dynamic>((ref) {
  return ref.watch(authStateProvider).value;
});
