import 'dart:developer';
import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:dio/dio.dart';

/// Service for managing jobseeker profile updates
/// Supports section-wise updates, full profile updates, and file uploads
class JobseekerProfileService {
  final DioClient _dioClient = DioClient();

  /// Fetch complete jobseeker profile
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      log('JobseekerProfileService: Fetching profile');
      final response = await _dioClient.dio.get('/api/users/profile');
      final responseData = response.data;
      log('JobseekerProfileService: Profile response: $responseData');

      // API returns 'message' and 'profile' without 'success' flag
      if (responseData['profile'] != null || responseData['message'] != null) {
        return {
          'success': true,
          'profile': responseData['profile'] ?? responseData['user'],
          'user': responseData['user'],
          'message': responseData['message'] ?? 'Profile fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Fetch profile failed: ${e.message}');
      if (e.response != null) {
        log('JobseekerProfileService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Fetch profile failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update personal details section (name, phone)
  Future<Map<String, dynamic>> updatePersonalDetails({
    String? name,
    String? phone,
  }) async {
    try {
      log('JobseekerProfileService: Updating personal details');
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;

      if (data.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      final response = await _dioClient.dio.patch('/api/users/profile/section/personal', data: data);
      final responseData = response.data;
      log('JobseekerProfileService: Personal details update response: $responseData');

      // API returns 'message' and 'profile' without 'success' flag
      if (responseData['profile'] != null) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Personal details updated successfully',
          'profile': responseData['profile'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update personal details',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Personal details update failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Personal details update failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update education section (qualification, date_of_birth)
  Future<Map<String, dynamic>> updateEducation({
    String? qualification,
    String? dateOfBirth,
  }) async {
    try {
      log('JobseekerProfileService: Updating education details');
      final data = <String, dynamic>{};
      if (qualification != null) data['qualification'] = qualification;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;

      if (data.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      final response = await _dioClient.dio.patch('/api/users/profile/section/education', data: data);
      final responseData = response.data;
      log('JobseekerProfileService: Education update response: $responseData');

      // API returns 'message' and 'profile' without 'success' flag
      if (responseData['profile'] != null) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Education details updated successfully',
          'profile': responseData['profile'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update education details',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Education update failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Education update failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update experience section
  Future<Map<String, dynamic>> updateExperience({
    required int experience,
  }) async {
    try {
      log('JobseekerProfileService: Updating experience: $experience');

      final response = await _dioClient.dio.patch('/api/users/profile/section/experience', data: {
        'experience': experience,
      });
      final responseData = response.data;
      log('JobseekerProfileService: Experience update response: $responseData');

      // API returns 'message' and 'profile' without 'success' flag
      if (responseData['profile'] != null) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Experience updated successfully',
          'profile': responseData['profile'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update experience',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Experience update failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Experience update failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update skills section
  Future<Map<String, dynamic>> updateSkills({
    required List<String> skills,
  }) async {
    try {
      log('JobseekerProfileService: Updating skills: $skills');

      final response = await _dioClient.dio.patch('/api/users/profile/section/skills', data: {
        'skills': skills,
      });
      final responseData = response.data;
      log('JobseekerProfileService: Skills update response: $responseData');

      // API returns 'message' and 'profile' without 'success' flag
      if (responseData['profile'] != null) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Skills updated successfully',
          'profile': responseData['profile'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update skills',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Skills update failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Skills update failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update location section
  Future<Map<String, dynamic>> updateLocation({
    required String location,
  }) async {
    try {
      log('JobseekerProfileService: Updating location: $location');

      final response = await _dioClient.dio.patch('/api/users/profile/section/location', data: {
        'location': location,
      });
      final responseData = response.data;
      log('JobseekerProfileService: Location update response: $responseData');

      // API returns 'message' and 'profile' without 'success' flag
      if (responseData['profile'] != null) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Location updated successfully',
          'profile': responseData['profile'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update location',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Location update failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Location update failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update bio section
  Future<Map<String, dynamic>> updateBio({
    required String bio,
  }) async {
    try {
      log('JobseekerProfileService: Updating bio');

      final response = await _dioClient.dio.patch('/api/users/profile/section/bio', data: {
        'bio': bio,
      });
      final responseData = response.data;
      log('JobseekerProfileService: Bio update response: $responseData');

      // API returns 'message' and 'profile' without 'success' flag
      if (responseData['profile'] != null) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Bio updated successfully',
          'profile': responseData['profile'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update bio',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Bio update failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Bio update failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update full profile (all sections at once)
  Future<Map<String, dynamic>> updateFullProfile({
    String? name,
    String? phone,
    String? qualification,
    String? dateOfBirth,
    int? experience,
    List<String>? skills,
    String? location,
    String? bio,
  }) async {
    try {
      log('JobseekerProfileService: Updating full profile');
      final data = <String, dynamic>{};
      
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (qualification != null) data['qualification'] = qualification;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
      if (experience != null) data['experience'] = experience;
      if (skills != null) data['skills'] = skills;
      if (location != null) data['location'] = location;
      if (bio != null) data['bio'] = bio;

      if (data.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      final response = await _dioClient.dio.put('/api/users/profile', data: data);
      final responseData = response.data;
      log('JobseekerProfileService: Full profile update response: $responseData');

      // API returns 'message', 'profile', and 'user' without 'success' flag
      if (responseData['profile'] != null) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'profile': responseData['profile'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } on DioException catch (e) {
      log('JobseekerProfileService: Full profile update failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      log('JobseekerProfileService: Full profile update failed: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
