import 'dart:developer';
import 'dart:io';

import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import '../../../models/application_model.dart';

class ApplicationService {
  final DioClient _dioClient = DioClient();

  Future<Map<String, dynamic>> applyForJob({
    required String jobId,
    String? coverLetter,
    dynamic resumeFile,
  }) async {
    try {
      log('=============================================');
      log('ApplicationService.applyForJob: STARTED');
      log('Job ID: $jobId');
      log('Cover Letter: ${coverLetter ?? "(null)"}');
      log('Resume File: ${resumeFile ?? "(null)"}');
      log('=============================================');
      
      final FormData formData = FormData.fromMap({
        'job_id': jobId,
        if (coverLetter != null) 'cover_letter': coverLetter,
      });

      if (resumeFile != null && resumeFile is File) {
        log('ApplicationService: Attaching resume file: ${resumeFile.path.split('/').last}');
        formData.files.add(
          MapEntry(
            'resume',
            await MultipartFile.fromFile(
              resumeFile.path,
              filename: resumeFile.path.split('/').last,
            ),
          ),
        );
      }

      log('ApplicationService: Sending POST to /api/applications');
      log('FormData: job_id=$jobId, cover_letter=${coverLetter ?? "null"}');
      
      final response = await _dioClient.post('/api/applications', data: formData);
      final responseData = response.data;
      
      log('=============================================');
      log('ApplicationService: RESPONSE RECEIVED');
      log('Status Code: ${response.statusCode}');
      log('Response Data: $responseData');
      log('=============================================');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        log('ApplicationService: SUCCESS - Application submitted for job ID: $jobId');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Application submitted successfully',
          'application': responseData['application'] ?? responseData['data']?['application'],
        };
      } else {
        log('ApplicationService: FAILED - ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to apply for job',
        };
      }
    } on DioException catch (e) {
      log('=============================================');
      log('ApplicationService: DioException OCCURRED');
      log('Error Type: ${e.type}');
      log('Error Message: ${e.message}');
      log('Error Request: ${e.requestOptions.uri}');
      if (e.response != null) {
        log('Response Status: ${e.response!.statusCode}');
        log('Response Data: ${e.response!.data}');
      }
      log('=============================================');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred: ${e.message}',
      };
    } catch (e, stackTrace) {
      log('=============================================');
      log('ApplicationService: UNEXPECTED EXCEPTION');
      log('Error: $e');
      log('Stack Trace: $stackTrace');
      log('=============================================');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getMyApplications({int page = 1, int limit = 10, String? status}) async {
    try {
      print('ApplicationService: Fetching my applications - page: $page, limit: $limit, status: $status');
      
      final params = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await _dioClient.get('/api/applications/my', params: params);
      final responseData = response.data;
      print('ApplicationService: My applications response: $responseData');
      
      if (responseData.containsKey('applications')) {
        final data = responseData;
        final applications = (data['applications'] as List).map((app) => _applicationFromJson(app)).toList();
        print('ApplicationService: Successfully fetched ${applications.length} applications');
        return {
          'success': true,
          'applications': applications,
          'pagination': data['pagination'],
        };
      } else {
        print('ApplicationService: Failed to fetch applications: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch applications',
        };
      }
    } on DioException catch (e) {
      print('ApplicationService: Fetch applications failed with DioException: ${e.message}');
      if (e.response != null) {
        print('ApplicationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('ApplicationService: Fetch applications failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> getApplicationsForJob(String jobId, {int page = 1, int limit = 10, String? status}) async {
    try {
      print('ApplicationService: Fetching applications for job ID: $jobId - page: $page, limit: $limit, status: $status');
      
      final params = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await _dioClient.get('/api/applications/job/$jobId', params: params);
      final responseData = response.data;
      print('ApplicationService: Applications for job response: $responseData');
      
      if (responseData.containsKey('applications')) {
        final data = responseData;
        final applications = (data['applications'] as List).map((app) => _applicationFromJson(app)).toList();
        print('ApplicationService: Successfully fetched ${applications.length} applications for job ID: $jobId');
        return {
          'success': true,
          'applications': applications,
          'pagination': data['pagination'],
        };
      } else {
        print('ApplicationService: Failed to fetch applications for job: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch applications for job',
        };
      }
    } on DioException catch (e) {
      print('ApplicationService: Fetch applications for job failed with DioException: ${e.message}');
      if (e.response != null) {
        print('ApplicationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('ApplicationService: Fetch applications for job failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> updateApplicationStatus(String applicationId, String status) async {
    try {
      final response = await _dioClient.put('/api/applications/$applicationId/status', data: {
        'status': status,
      });
      final responseData = response.data;

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Application status updated successfully',
          'application': _applicationFromJson(responseData['application'] ?? responseData['data']?['application']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update application status',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> deleteApplication(String applicationId) async {
    try {
      final response = await _dioClient.delete('/api/applications/$applicationId');
      final responseData = response.data;

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Application deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete application',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // New endpoint for recruiters to get all their applications
  Future<Map<String, dynamic>> getApplicationsForRecruiter({int page = 1, int limit = 10, String? status}) async {
    try {
      print('ApplicationService: Fetching applications for recruiter - page: $page, limit: $limit, status: $status');
      
      final params = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await _dioClient.get('/api/applications/recruiter', params: params);
      final responseData = response.data;
      print('ApplicationService: Recruiter applications response: $responseData');
      
      if (responseData.containsKey('applications')) {
        final data = responseData;
        final applications = (data['applications'] as List).map((app) => _applicationFromJson(app)).toList();
        print('ApplicationService: Successfully fetched ${applications.length} applications for recruiter');
        return {
          'success': true,
          'applications': applications,
          'pagination': data['pagination'],
        };
      } else {
        print('ApplicationService: Failed to fetch applications for recruiter: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch applications for recruiter',
        };
      }
    } on DioException catch (e) {
      print('ApplicationService: Fetch recruiter applications failed with DioException: ${e.message}');
      if (e.response != null) {
        print('ApplicationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('ApplicationService: Fetch recruiter applications failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get application statistics
  Future<Map<String, dynamic>> getApplicationStats() async {
    try {
      print('ApplicationService: Fetching application statistics');
      final response = await _dioClient.get('/api/applications/stats');
      final responseData = response.data;
      print('ApplicationService: Application stats response: $responseData');
      
      if (responseData.containsKey('stats')) {
        return {
          'success': true,
          'stats': responseData['stats'],
          'user_type': responseData['user_type'],
        };
      } else {
        return {
          'success': false,
          'stats': null,
          'message': responseData['message'] ?? 'Failed to fetch application statistics',
        };
      }
    } on DioException catch (e) {
      print('ApplicationService: Fetch application stats failed with DioException: ${e.message}');
      if (e.response != null) {
        print('ApplicationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'stats': null,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('ApplicationService: Fetch application stats failed with general exception: $e');
      return {
        'success': false,
        'stats': null,
        'message': 'An unexpected error occurred',
      };
    }
  }

  ApplicationModel _applicationFromJson(Map<String, dynamic>? json) {
    if (json == null) return _getDefaultApplication();
    
    // Parse CTC values from backend
    double ctcMin = (json['ctc_min'] as num?)?.toDouble() ?? 0.0;
    double ctcMax = (json['ctc_max'] as num?)?.toDouble() ?? 0.0;
    
    // If ctc_min and ctc_max are not available, try to parse from ctc field
    if (ctcMin == 0.0 && ctcMax == 0.0 && json['ctc'] != null) {
      final ctcStr = json['ctc'].toString();
      final parts = ctcStr.split('-');
      if (parts.length == 2) {
        ctcMin = double.tryParse(parts[0].trim()) ?? 0;
        ctcMax = double.tryParse(parts[1].split(' ')[0].trim()) ?? 0;
      } else {
        ctcMin = double.tryParse(ctcStr.split(' ')[0].trim()) ?? 0;
        ctcMax = ctcMin;
      }
    }

    // Convert status string to enum
    ApplicationStatus status = ApplicationStatus.pending;
    if (json['status'] != null) {
      final statusStr = json['status'].toString().toLowerCase();
      if (statusStr.contains('short')) {
        status = ApplicationStatus.shortlisted;
      } else if (statusStr.contains('accept')) {
        status = ApplicationStatus.accepted;
      } else if (statusStr.contains('reject')) {
        status = ApplicationStatus.rejected;
      } else if (statusStr.contains('withdraw')) {
        status = ApplicationStatus.withdrawn;
      }
    }

    return ApplicationModel(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      jobTitle: json['designation'] as String? ?? json['job_title'] as String? ?? 'Unknown Position',
      company: json['company_name'] as String? ?? 'Unknown Company',
      companyLogoUrl: json['company_logo_url'] as String? ?? json['company_logo'] as String? ?? '',
      location: json['location'] as String? ?? 'Not specified',
      userId: json['jobseeker_user_id']?.toString() ?? json['user_id']?.toString() ?? '',
      resumeUrl: json['resume_url'] as String? ?? '',
      coverLetter: json['cover_letter'] as String?,
      status: status,
      timeline: [], // Timeline not provided by backend
      appliedAt: json['applied_at'] != null 
          ? DateTime.parse(json['applied_at'].toString()) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      ctcMin: ctcMin,
      ctcMax: ctcMax,
      jobType: json['job_type'] as String? ?? 'Full-time',
      jobseekerName: json['jobseeker_name'] as String? ?? json['name'] as String?,
      jobseekerEmail: json['jobseeker_email'] as String? ?? json['email'] as String?,
      jobseekerPhone: json['jobseeker_phone'] as String? ?? json['phone'] as String?,
      jobseekerPhotoUrl: json['jobseeker_photo_url'] as String? ?? json['photo_url'] as String? ?? json['profile_image_url'] as String?,
      jobseekerCurrentRole: json['jobseeker_current_role'] as String? ?? json['current_role'] as String? ?? json['jobseeker_bio'] as String? ?? json['bio'] as String?,
      jobseekerSkills: _parseSkillsField(json['jobseeker_skills'] ?? json['skills']),
      recruiterUserId: json['recruiter_user_id'] as int?,
      recruiterName: json['recruiter_name'] as String?,
      recruiterPhotoUrl: json['recruiter_photo_url'] as String?,
      companyWebsite: json['company_website'] as String?,
      companyUrl: json['company_url'] as String? ?? json['company_link'] as String?,
      category: json['category'] as String?,
    );
  }

  ApplicationModel _getDefaultApplication() {
    return ApplicationModel(
      id: '',
      jobId: '',
      jobTitle: 'Unknown Position',
      company: 'Unknown Company',
      companyLogoUrl: '',
      location: 'Not specified',
      userId: '',
      resumeUrl: '',
      coverLetter: null,
      status: ApplicationStatus.pending,
      timeline: [],
      appliedAt: DateTime.now(),
      updatedAt: null,
      ctcMin: 0,
      ctcMax: 0,
      jobType: 'Full-time',
      jobseekerName: null,
      jobseekerEmail: null,
      jobseekerPhone: null,
      jobseekerPhotoUrl: null,
      jobseekerCurrentRole: null,
      jobseekerSkills: null,
      recruiterUserId: null,
      recruiterName: null,
      companyWebsite: null,
      companyUrl: null,
      category: null,
    );
  }

  List<String>? _parseSkillsField(dynamic skillsData) {
    if (skillsData == null) return null;
    
    if (skillsData is List) {
      // If it's already a list, convert each item to string
      return skillsData.map((s) => s.toString()).toList();
    } else if (skillsData is String) {
      try {
        // Handle comma-separated format as fallback
        return skillsData.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } catch (e) {
        // If any error occurs, return null
        return skillsData.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }
    return null;
  }
}