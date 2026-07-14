import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:airigo_jobportal/core/storage/local_storage.dart';
import 'package:airigo_jobportal/models/jobseeker_model.dart';
import 'package:airigo_jobportal/models/recruiter_model.dart';
import 'package:airigo_jobportal/models/user_model.dart';
import 'package:dio/dio.dart';

class AuthService {
  final DioClient _dioClient = DioClient();
  final LocalStorage _storage = LocalStorage();

  // Login method
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String userType, // 'jobseeker' or 'recruiter'
  }) async {
    try {
      print('AuthService: Initiating login for user: $email, type: $userType');
      final response = await _dioClient.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final responseData = response.data;
      print('AuthService: Login response received: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        // The backend response format is slightly different
        final tokens = responseData['tokens'] ?? responseData['data']?['tokens'];
        final user = responseData['user'] ?? responseData['data']?['user'];
        
        final token = tokens?['access_token'] ?? tokens?['token'];
        final refreshToken = tokens?['refresh_token'];

        // Store token first before fetching profile
        if (token == null || token.isEmpty) {
          print('AuthService: No token in response, login storage aborted');
          return {'success': false, 'message': 'No token received from server'};
        }
        await _storage.setToken(token);
        if (refreshToken != null) await _storage.setRefreshToken(refreshToken);
        await _storage.setUserType(userType);
        print('AuthService: Tokens and user type stored successfully');

        // Store user data based on user type
        if (userType == 'jobseeker') {
          try {
            // For jobseeker, fetch full profile data after login
            final profileResult = await getProfile(userType: 'jobseeker');
            if (profileResult['success'] && profileResult['user'] != null) {
              final jobseeker = profileResult['user'];
              await _storage.setJobseeker(jobseeker);
              print('AuthService: Stored jobseeker data: ${jobseeker.name}');
            } else {
              // If profile fetch fails, skip storing detailed user data for now
              // The app can fetch the profile later when needed
              print('AuthService: Profile fetch failed, will fetch later when needed');
            }
          } catch (e) {
            print('AuthService: Error in jobseeker profile processing: $e');
            // If there's an error, continue with login but skip detailed profile storage
          }
        } else if (userType == 'recruiter') {
          try {
            // For recruiter, fetch full profile data after login
            final profileResult = await getProfile(userType: 'recruiter');
            if (profileResult['success'] && profileResult['user'] != null) {
              final recruiter = profileResult['user'];
              await _storage.setRecruiter(recruiter);
              print('AuthService: Stored recruiter data: ${recruiter.name}');
            } else {
              // If profile fetch fails, skip storing detailed user data for now
              // The app can fetch the profile later when needed
              print('AuthService: Profile fetch failed, will fetch later when needed');
            }
          } catch (e) {
            print('AuthService: Error in recruiter profile processing: $e');
            // If there's an error, continue with login but skip detailed profile storage
          }
        } else if (userType == 'admin') {
          try {
            // For admin, fetch full profile data after login
            final profileResult = await getProfile(userType: 'admin');
            if (profileResult['success'] && profileResult['user'] != null) {
              final adminUser = profileResult['user'];
              await _storage.setAdminUser(adminUser);
              print('AuthService: Stored admin user data: ${adminUser.name ?? adminUser.email}');
            } else {
              print('AuthService: Admin profile fetch failed, will fetch later when needed');
            }
          } catch (e) {
            print('AuthService: Error in admin profile processing: $e');
            // If there's an error, continue with login but skip detailed profile storage
          }
        }

        // Don't return user model directly from login response as it may be incomplete
        // The caller should fetch the full profile separately
        return {
          'success': true,
          'message': 'Login successful',
          'token': token,
        };
      } else {
        print('AuthService: Login failed with message: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Login failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AuthService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('AuthService: Login failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Register method
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType, // 'jobseeker' or 'recruiter'
  }) async {
    try {
      print('AuthService: Initiating registration for user: $email, type: $userType');
      final response = await _dioClient.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'user_type': userType,
        'name': name,
        'phone': phone,
      });

      final responseData = response.data;
      print('AuthService: Registration response received: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        final tokens = responseData['tokens'] ?? responseData['data']?['tokens'];
        final user = responseData['user'] ?? responseData['data']?['user'];
        
        final token = tokens?['access_token'];
        final refreshToken = tokens?['refresh_token'];

        // Store user data based on user type
        if (userType == 'jobseeker') {
          // For jobseeker, fetch full profile data after registration
          final profileResult = await getProfile(userType: 'jobseeker');
          if (profileResult['success'] && profileResult['user'] != null) {
            final jobseeker = profileResult['user'];
            await _storage.setJobseeker(jobseeker);
            print('AuthService: Stored jobseeker data: ${jobseeker.name}');
          } else {
            // If profile fetch fails, create basic jobseeker from registration response
            final jobseeker = JobseekerModel.fromJson(user);
            await _storage.setJobseeker(jobseeker);
            print('AuthService: Stored basic jobseeker data from registration response: ${jobseeker.name}');
          }
        } else {
          // For recruiter, fetch full profile data after registration
          final profileResult = await getProfile(userType: 'recruiter');
          if (profileResult['success'] && profileResult['user'] != null) {
            final recruiter = profileResult['user'];
            await _storage.setRecruiter(recruiter);
            print('AuthService: Stored recruiter data: ${recruiter.name}');
          } else {
            // If profile fetch fails, create basic recruiter from registration response
            final recruiter = RecruiterModel.fromJson(user);
            await _storage.setRecruiter(recruiter);
            print('AuthService: Stored basic recruiter data from registration response: ${recruiter.name}');
          }
        }

        // Store token
        await _storage.setToken(token);
        await _storage.setRefreshToken(refreshToken);
        await _storage.setUserType(userType);
        print('AuthService: Tokens and user type stored successfully');

        // Don't return user model directly from registration response as it may be incomplete
        // The caller should fetch the full profile separately
        return {
          'success': true,
          'message': 'Registration successful',
          'token': token,
        };
      } else {
        print('AuthService: Registration failed with message: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'errors': responseData['errors'] ?? 'Invalid data provided',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Registration failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AuthService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
        'errors': e.response?.data['errors'] ?? 'Invalid data provided',
      };
    } catch (e) {
      print('AuthService: Registration failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile({String? userType}) async {
    try {
      print('AuthService: Fetching profile...');
      final response = await _dioClient.get('/api/auth/profile');
      final responseData = response.data;
      print('AuthService: Profile response received: $responseData');
      
      if (responseData['user'] != null) {
        final user = responseData['user'];
        final profileData = responseData['profile'];
        final returnedUserType = responseData['user_type'];
        
        // Handle case where profile is false (for admin users) or missing
        final profile = (profileData is Map) ? profileData : <String, dynamic>{};
        
        // The backend now merges user + profile, so we can use user directly
        // But we still merge to ensure all fields are available
        final merged = <String, dynamic>{...user, ...profile};
        
        print('AuthService: Merged profile data keys: ${merged.keys}');
        print('AuthService: User type from response: $returnedUserType');
        
        final finalUserType = userType ?? returnedUserType ?? user['user_type'];
        
        if (finalUserType == 'jobseeker') {
          try {
            final jobseeker = _createMinimalJobseeker(merged);
            await _storage.setJobseeker(jobseeker);
            await _storage.setUserType('jobseeker');
            print('AuthService: Updated jobseeker data: ${jobseeker.name}');
            return {
              'success': true,
              'user': jobseeker,
              'user_type': 'jobseeker',
            };
          } catch (e) {
            print('AuthService: Error creating jobseeker from profile: $e');
            return {
              'success': false,
              'message': 'Failed to parse profile data',
            };
          }
        } else if (finalUserType == 'recruiter') {
          try {
            final recruiter = _createMinimalRecruiter(merged);
            await _storage.setRecruiter(recruiter);
            await _storage.setUserType('recruiter');
            print('AuthService: Updated recruiter data: ${recruiter.name}');
            return {
              'success': true,
              'user': recruiter,
              'user_type': 'recruiter',
            };
          } catch (e) {
            print('AuthService: Error creating recruiter from profile: $e');
            return {
              'success': false,
              'message': 'Failed to parse profile data',
            };
          }
        } else if (finalUserType == 'admin') {
          try {
            // For admin users, create a basic UserModel from the merged data
            // Admin users don't have a separate profile table, so we use the user data directly
            final adminUser = UserModel.fromJson(merged);
            await _storage.setUserType('admin');
            await _storage.setAdminUser(adminUser);
            print('AuthService: Updated and stored admin data: ${adminUser.name}');
            return {
              'success': true,
              'user': adminUser,
              'user_type': 'admin',
            };
          } catch (e) {
            print('AuthService: Error creating admin user from profile: $e');
            return {
              'success': false,
              'message': 'Failed to parse admin profile data',
            };
          }
        } else {
            print('AuthService: Unknown user type: $finalUserType');
            return {
              'success': false,
              'message': 'Unknown user type in profile',
            };
        }
      } else {
        print('AuthService: Failed to fetch profile: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Profile fetch failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AuthService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('AuthService: Profile fetch failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? location,
    String? qualification,
    int? experience,
    List<String>? skills,
    String? companyName,
    String? recruiterName, // New field
    String? companyWebsite, // New field
    String? designation,
    String? avatarUrl,
    String? idCardUrl,
    String? resumeUrl,
    String? photoUrl, // For recruiter profile picture
  }) async {
    try {
      print('AuthService: Updating user profile');
      
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (bio != null) data['bio'] = bio;
      if (location != null) data['location'] = location;
      if (qualification != null) data['qualification'] = qualification;
      if (experience != null) data['experience'] = experience;
      if (skills != null) data['skills'] = skills;
      if (companyName != null) data['company_name'] = companyName;
      if (recruiterName != null) data['recruiter_name'] = recruiterName; // Include new field
      if (companyWebsite != null) data['company_website'] = companyWebsite; // Include new field
      if (designation != null) data['designation'] = designation;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (idCardUrl != null) data['id_card_url'] = idCardUrl;
      if (resumeUrl != null) data['resume_url'] = resumeUrl;
      if (photoUrl != null) data['photo_url'] = photoUrl; // For recruiter profile picture

      final response = await _dioClient.put('/api/users/profile', data: data);
      final responseData = response.data;
      print('AuthService: Update profile response: $responseData');
      
      if (responseData['success'] == true || (responseData['message'] != null && responseData['message'].toString().contains('success'))) {
        final user = UserModel.fromJson(responseData['user'] ?? responseData['data']?['user'] ?? responseData);
        final profile = responseData['profile'] ?? responseData['data']?['profile'];
        print('AuthService: Successfully updated profile for user ID: ${user.id}');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'user': user,
          'profile': profile,
        };
      } else {
        print('AuthService: Failed to update profile: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Update profile failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AuthService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('AuthService: Update profile failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
  
  // Upload Profile Image
  Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    try {
      print('AuthService: Uploading profile image from $imagePath');
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dioClient.post('/api/users/upload-profile-image', data: formData);
      final responseData = response.data;
      
      if (responseData['success'] == true || (responseData['message'] != null && responseData['message'].toString().contains('success'))) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Image uploaded successfully',
          'url': responseData['image_url'] ?? responseData['url'] ?? responseData['data']?['url'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to upload image',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Upload image failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('AuthService: Upload image error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Upload ID Card
  Future<Map<String, dynamic>> uploadIdCard(String imagePath) async {
    try {
      print('AuthService: Uploading ID card from $imagePath');
      final formData = FormData.fromMap({
        'id_card': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dioClient.post('/api/users/upload-id-card', data: formData);
      final responseData = response.data;
      
      if (responseData['success'] == true || (responseData['message'] != null && responseData['message'].toString().contains('success'))) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'ID Card uploaded successfully',
          'url': responseData['id_card_url'] ?? responseData['url'] ?? responseData['data']?['url'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to upload ID card',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Upload ID card failed: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('AuthService: Upload ID card error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      print('AuthService: Initiating logout');
      await _dioClient.post('/api/auth/logout');
      print('AuthService: Server logout completed');
    } catch (e) {
      print('AuthService: Server logout failed, clearing local storage anyway: $e');
      // Even if logout fails on the server, clear local storage
    }
    await _storage.clearAuthData();
    print('AuthService: Local storage cleared');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  // Get current user type
  String? getCurrentUserType() {
    return _storage.getUserType();
  }

  Future<String?> getCurrentUserTypeAsync() async {
    return await _storage.getUserTypeAsync();
  }

  LocalStorage getLocalStorage() {
    return _storage;
  }

  // Refresh token method
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      print('AuthService: Attempting token refresh, refresh token: ${refreshToken != null ? 'exists' : 'missing'}');
      if (refreshToken == null) return false;

      final response = await _dioClient.post('/api/auth/refresh-token', data: {
        'refresh_token': refreshToken,
      });

      final responseData = response.data;
      print('AuthService: Token refresh response: $responseData');
      
      if (responseData['success'] == true || (responseData['message'] != null && responseData['message'].contains('successful'))) {
        final newToken = responseData['tokens']?['access_token'] ?? responseData['data']?['token'];
        await _storage.setToken(newToken);
        print('AuthService: Token refresh successful, new token stored');
        return true;
      }
      print('AuthService: Token refresh failed');
      return false;
    } catch (e) {
      print('AuthService: Token refresh failed with exception: $e');
      return false;
    }
  }

  // Change user password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('AuthService: Changing password');
      
      final response = await _dioClient.post('/api/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      
      final responseData = response.data;
      print('AuthService: Change password response: $responseData');
      
      if (responseData['success'] == true || (responseData['message'] != null && responseData['message'].toString().contains('success'))) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to change password',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Change password failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AuthService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('AuthService: Change password failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Change user password with similarity check
  Future<Map<String, dynamic>> changePasswordWithValidation({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Check if current password is similar to new password
    if (currentPassword.toLowerCase() == newPassword.toLowerCase()) {
      return {
        'success': false,
        'message': 'New password must be different from current password',
      };
    }
    
    // Additional check for similarity - if they share more than 70% of characters
    int commonChars = 0;
    int minLength = currentPassword.length < newPassword.length ? currentPassword.length : newPassword.length;
    for (int i = 0; i < minLength; i++) {
      if (currentPassword[i].toLowerCase() == newPassword[i].toLowerCase()) {
        commonChars++;
      }
    }
    
    double similarityRatio = commonChars / minLength;
    if (similarityRatio > 0.7) {
      return {
        'success': false,
        'message': 'New password is too similar to current password',
      };
    }

    try {
      print('AuthService: Changing password');
      
      final response = await _dioClient.post('/api/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      
      final responseData = response.data;
      print('AuthService: Change password response: $responseData');
      
      if (responseData['success'] == true || (responseData['message'] != null && responseData['message'].toString().contains('success'))) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to change password',
        };
      }
    } on DioException catch (e) {
      print('AuthService: Change password failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AuthService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('AuthService: Change password failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Helper method to create a minimal jobseeker from basic user data
  JobseekerModel _createMinimalJobseeker(Map<String, dynamic> userData) {
    // Debug: Print the received data
    print('AuthService: Creating jobseeker from data: ${userData.keys}');
    
    return JobseekerModel(
      id: userData['user_id']?.toString() ?? userData['id']?.toString() ?? '',
      name: userData['name'] ?? userData['email']?.split('@')[0] ?? 'Job Seeker',
      email: userData['email'] ?? '',
      phone: userData['phone'] ?? '',
      location: userData['location'] ?? 'Not Mentioned',
      isVerified: userData['status'] == 'active',
      profileCompletion: 30, // Minimal profile completion
      createdAt: DateTime.tryParse(userData['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(userData['updated_at']?.toString() ?? '') ?? DateTime.now(),
      bio: userData['bio'],
      qualification: userData['qualification'],
      experienceYears: userData['experience'] ?? 0,
      avatarUrl: userData['profile_image_url'] ?? userData['avatar_url'],
      skills: List<String>.from(userData['skills'] ?? []),
      resumeUrl: userData['resume_url'],
      resumeFilename: userData['resume_filename'],
      dateOfBirth: userData['date_of_birth'],
    );
  }

  // Helper method to create a minimal recruiter from basic user data
  RecruiterModel _createMinimalRecruiter(Map<String, dynamic> userData) {
    // Debug: Print the received data
    print('AuthService: Creating recruiter from data: ${userData.keys}');
    
    return RecruiterModel(
      id: userData['user_id']?.toString() ?? userData['id']?.toString() ?? '',
      name: userData['recruiter_name'] ?? userData['company_name'] ?? userData['email']?.split('@')[0] ?? 'Recruiter',
      email: userData['email'] ?? '',
      phone: userData['phone'] ?? '',
      location: userData['location'] ?? 'Not Mentioned',
      isVerified: userData['status'] == 'active',
      approvalStatus: userData['approval_status'] ?? 'pending',
      profileCompletion: 30, // Minimal profile completion
      createdAt: DateTime.tryParse(userData['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(userData['updated_at']?.toString() ?? '') ?? DateTime.now(),
      company: userData['company_name'],
      designation: userData['designation'],
      avatarUrl: userData['photo_url'] ?? userData['avatar_url'],
      idCardUrl: userData['id_card_url'],
      recruiterName: userData['recruiter_name'],
      companyWebsite: userData['company_website'],
    );
  }
}