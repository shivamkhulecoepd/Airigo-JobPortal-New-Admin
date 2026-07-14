import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:airigo_jobportal/services/api/api_service.dart';
import 'package:airigo_jobportal/config/app_config.dart';

class AdminApiService {
  final ApiService _apiService = ApiService();

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.get('/api/admin/dashboard/full-stats');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  // User Management
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 10,
    String? userType,
    String? status,
    String? search,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/users',
        params: {
          'page': page,
          'limit': limit,
          if (userType != null) 'user_type': userType,
          if (status != null) 'status': status,
          if (search != null) 'search': search,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<Map<String, dynamic>> getJobseekers({
    int page = 1,
    int limit = 10,
    String? search,
    String? location,
    int? experience,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/jobseekers',
        params: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
          if (location != null) 'location': location,
          if (experience != null) 'experience': experience,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch jobseekers: $e');
    }
  }

  Future<Map<String, dynamic>> getRecruiters({
    int page = 1,
    int limit = 10,
    String? approvalStatus,
    String? search,
    String? location,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/recruiters',
        params: {
          'page': page,
          'limit': limit,
          if (approvalStatus != null) 'approval_status': approvalStatus,
          if (search != null) 'search': search,
          if (location != null) 'location': location,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch recruiters: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserStatus(int userId, String status) async {
    try {
      final response = await _apiService.put(
        '/api/admin/users/$userId/status',
        data: {'status': status},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  // Job Management
  Future<Map<String, dynamic>> getJobs({
    int page = 1,
    int limit = 10,
    String? status,
    String? approvalStatus,
    String? category,
    String? location,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/jobs',
        params: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (approvalStatus != null) 'approval_status': approvalStatus,
          if (category != null) 'category': category,
          if (location != null) 'location': location,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  Future<Map<String, dynamic>> getPendingJobs({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/jobs/pending',
        params: {'page': page, 'limit': limit},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch pending jobs: $e');
    }
  }

  Future<Map<String, dynamic>> approveJob(int jobId) async {
    try {
      final response = await _apiService.put('/api/admin/jobs/$jobId/approve');
      return response.data;
    } catch (e) {
      log('Failed to approve job: $e');
      throw Exception('Failed to approve job: $e');
    }
  }

  Future<Map<String, dynamic>> rejectJob(int jobId) async {
    try {
      final response = await _apiService.put('/api/admin/jobs/$jobId/reject');
      return response.data;
    } catch (e) {
      throw Exception('Failed to reject job: $e');
    }
  }

  Future<Map<String, dynamic>> updateJobStatus(int jobId, bool isActive) async {
    try {
      final response = await _apiService.put(
        '/api/admin/jobs/$jobId/status',
        data: {'is_active': isActive},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update job status: $e');
    }
  }

  Future<Map<String, dynamic>> deleteJob(int jobId) async {
    try {
      final response = await _apiService.delete('/api/admin/jobs/$jobId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }

  // Recruiter Approval
  Future<Map<String, dynamic>> approveRecruiter(int userId) async {
    try {
      final response = await _apiService.put('/api/admin/recruiters/$userId/approve');
      return response.data;
    } catch (e) {
      throw Exception('Failed to approve recruiter: $e');
    }
  }

  Future<Map<String, dynamic>> rejectRecruiter(int userId, String reason) async {
    try {
      final response = await _apiService.put(
        '/api/admin/recruiters/$userId/reject',
        data: {'rejection_reason': reason},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to reject recruiter: $e');
    }
  }

  // Application Management
  Future<Map<String, dynamic>> getApplications({
    int page = 1,
    int limit = 10,
    String? status,
    int? jobId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/applications',
        params: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (jobId != null) 'job_id': jobId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch applications: $e');
    }
  }

  Future<Map<String, dynamic>> updateApplicationStatus(
    int applicationId,
    String status,
  ) async {
    try {
      final response = await _apiService.put(
        '/api/admin/applications/$applicationId/status',
        data: {'status': status},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  // Issues & Reports
  Future<Map<String, dynamic>> getIssues({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
    String? userType,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/issues-reports',
        params: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (type != null) 'type': type,
          if (userType != null) 'user_type': userType,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch issues: $e');
    }
  }

  Future<Map<String, dynamic>> updateIssueStatus(
    int issueId,
    String status, {
    String? adminResponse,
  }) async {
    try {
      final data = {'status': status};
      if (adminResponse != null) {
        data['admin_response'] = adminResponse;
      }
      
      final response = await _apiService.put(
        '/api/admin/issues-reports/$issueId/status',
        data: data,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
    }
  }

  // Search
  Future<Map<String, dynamic>> globalSearch({
    required String query,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/search',
        params: {'q': query, 'limit': limit},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to perform search: $e');
    }
  }
}
