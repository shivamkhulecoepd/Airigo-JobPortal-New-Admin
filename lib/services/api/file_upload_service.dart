import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class FileUploadService {
  final DioClient _dioClient = DioClient();

  /// Validate file before upload
  Map<String, dynamic> validateImageFile(String filePath, {int maxSizeMB = 2}) {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!file.existsSync()) {
        return {'valid': false, 'message': 'File does not exist'};
      }
      
      // Check file size
      final fileSize = file.lengthSync();
      final maxSizeBytes = maxSizeMB * 1024 * 1024;
      if (fileSize > maxSizeBytes) {
        return {
          'valid': false,
          'message': 'Image size exceeds ${maxSizeMB}MB limit (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)'
        };
      }
      
      // Check file extension
      final extension = filePath.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedExtensions.contains(extension)) {
        return {
          'valid': false,
          'message': 'Invalid image format. Allowed: JPG, PNG, GIF, WebP'
        };
      }
      
      return {'valid': true, 'message': 'File is valid'};
    } catch (e) {
      return {'valid': false, 'message': 'File validation failed: $e'};
    }
  }

  /// Validate resume file
  Map<String, dynamic> validateResumeFile(String filePath, {int maxSizeMB = 5}) {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!file.existsSync()) {
        return {'valid': false, 'message': 'File does not exist'};
      }
      
      // Check file size
      final fileSize = file.lengthSync();
      final maxSizeBytes = maxSizeMB * 1024 * 1024;
      if (fileSize > maxSizeBytes) {
        return {
          'valid': false,
          'message': 'Resume size exceeds ${maxSizeMB}MB limit (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)'
        };
      }
      
      // Check file extension
      final extension = filePath.split('.').last.toLowerCase();
      final allowedExtensions = ['pdf', 'doc', 'docx'];
      if (!allowedExtensions.contains(extension)) {
        return {
          'valid': false,
          'message': 'Invalid resume format. Allowed: PDF, DOC, DOCX'
        };
      }
      
      return {'valid': true, 'message': 'File is valid'};
    } catch (e) {
      return {'valid': false, 'message': 'File validation failed: $e'};
    }
  }

  // Upload profile image (works for both jobseekers and recruiters)
  Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    try {
      print('FileUploadService: Uploading profile image from path: $imagePath');
      
      // Validate file first
      final validation = validateImageFile(imagePath);
      if (validation['valid'] != true) {
        return {
          'success': false,
          'message': validation['message'] ?? 'Invalid image file',
        };
      }
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dioClient.dio.post('/api/users/upload-profile-image', data: formData);
      final responseData = response.data;
      print('FileUploadService: Profile image upload response: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile image uploaded successfully',
          'image_url': responseData['image_url'] ?? responseData['data']?['image_url'],
          'filename': responseData['filename'] ?? responseData['data']?['filename'],
          'old_file_deleted': responseData['old_file_deleted'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to upload profile image',
        };
      }
    } on DioException catch (e) {
      print('FileUploadService: Profile image upload failed with DioException: ${e.message}');
      if (e.response != null) {
        print('FileUploadService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('FileUploadService: Profile image upload failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Upload resume (for jobseekers)
  Future<Map<String, dynamic>> uploadResume(String filePath) async {
    try {
      print('FileUploadService: Uploading resume from path: $filePath');
      
      // Validate file first
      final validation = validateResumeFile(filePath);
      if (validation['valid'] != true) {
        return {
          'success': false,
          'message': validation['message'] ?? 'Invalid resume file',
        };
      }
      
      final formData = FormData.fromMap({
        'resume': await MultipartFile.fromFile(filePath),
      });

      final response = await _dioClient.dio.post('/api/users/upload-resume', data: formData);
      final responseData = response.data;
      print('FileUploadService: Resume upload response: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Resume uploaded successfully',
          'resume_url': responseData['resume_url'] ?? responseData['data']?['resume_url'],
          'filename': responseData['filename'] ?? responseData['data']?['filename'],
          'old_file_deleted': responseData['old_file_deleted'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to upload resume',
        };
      }
    } on DioException catch (e) {
      print('FileUploadService: Resume upload failed with DioException: ${e.message}');
      if (e.response != null) {
        print('FileUploadService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('FileUploadService: Resume upload failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Upload ID card (for recruiters)
  Future<Map<String, dynamic>> uploadIdCard(String imagePath) async {
    try {
      print('FileUploadService: Uploading ID card from path: $imagePath');
      
      final formData = FormData.fromMap({
        'id_card': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dioClient.post('/api/users/upload-id-card', data: formData);
      final responseData = response.data;
      print('FileUploadService: ID card upload response: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'ID card uploaded successfully',
          'id_card_url': responseData['id_card_url'] ?? responseData['data']?['id_card_url'],
          'filename': responseData['filename'] ?? responseData['data']?['filename'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to upload ID card',
        };
      }
    } on DioException catch (e) {
      print('FileUploadService: ID card upload failed with DioException: ${e.message}');
      if (e.response != null) {
        print('FileUploadService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('FileUploadService: ID card upload failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}