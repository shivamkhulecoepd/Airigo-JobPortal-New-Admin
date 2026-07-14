import 'dart:convert';
import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class AdminNotificationService {
  final DioClient _dioClient = DioClient();

  // Send notification to specific user
  Future<Map<String, dynamic>> sendNotificationToUser({
    required int userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/admin/notifications/user/$userId',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send notification to user response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send notification',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send notification to user failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send notification to user',
      };
    } catch (e) {
      print('AdminNotificationService: Send notification to user failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send notification to all users
  Future<Map<String, dynamic>> sendNotificationToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/admin/notifications/all',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send notification to all response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notifications sent successfully',
          'totalSent': responseData['total_sent'] ?? 0,
          'totalFailed': responseData['total_failed'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send notifications',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send notification to all failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send notifications to all users',
      };
    } catch (e) {
      print('AdminNotificationService: Send notification to all failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send notification to specific user role
  Future<Map<String, dynamic>> sendNotificationByRole({
    required String userType, // jobseeker, recruiter, admin
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/admin/notifications/role/$userType',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send notification by role response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notifications sent successfully',
          'totalSent': responseData['total_sent'] ?? 0,
          'totalFailed': responseData['total_failed'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send notifications',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send notification by role failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send notifications to users',
      };
    } catch (e) {
      print('AdminNotificationService: Send notification by role failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send job approval notification to recruiter
  Future<Map<String, dynamic>> sendJobApprovalNotification({
    required int jobId,
    required String jobTitle,
  }) async {
    try {
      final response = await _dioClient.put(
        '/api/admin/notifications/job/$jobId/approval',
        data: {
          'title': 'Job Approved',
          'body': 'Your job posting \'$jobTitle\' has been approved by admin.',
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send job approval notification response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job approval notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send job approval notification',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send job approval notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send job approval notification',
      };
    } catch (e) {
      print('AdminNotificationService: Send job approval notification failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send job rejection notification to recruiter
  Future<Map<String, dynamic>> sendJobRejectionNotification({
    required int jobId,
    required String jobTitle,
    String reason = 'Job posting does not meet platform guidelines',
  }) async {
    try {
      final response = await _dioClient.put(
        '/api/admin/notifications/job/$jobId/rejection',
        data: {
          'title': 'Job Rejected',
          'body': 'Your job posting \'$jobTitle\' has been rejected by admin. Reason: $reason',
          'reason': reason,
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send job rejection notification response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job rejection notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send job rejection notification',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send job rejection notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send job rejection notification',
      };
    } catch (e) {
      print('AdminNotificationService: Send job rejection notification failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send recruiter approval notification
  Future<Map<String, dynamic>> sendRecruiterApprovalNotification({
    required int userId,
  }) async {
    try {
      final response = await _dioClient.put(
        '/api/admin/notifications/recruiter/$userId/approval',
        data: {
          'title': 'Account Approved',
          'body': 'Your recruiter account has been approved by admin. You can now post jobs.',
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send recruiter approval notification response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Recruiter approval notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send recruiter approval notification',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send recruiter approval notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send recruiter approval notification',
      };
    } catch (e) {
      print('AdminNotificationService: Send recruiter approval notification failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send recruiter rejection notification
  Future<Map<String, dynamic>> sendRecruiterRejectionNotification({
    required int userId,
    String reason = 'Account does not meet platform guidelines',
  }) async {
    try {
      final response = await _dioClient.put(
        '/api/admin/notifications/recruiter/$userId/rejection',
        data: {
          'title': 'Account Rejected',
          'body': 'Your recruiter account has been rejected by admin. Reason: $reason',
          'reason': reason,
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send recruiter rejection notification response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Recruiter rejection notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send recruiter rejection notification',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send recruiter rejection notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send recruiter rejection notification',
      };
    } catch (e) {
      print('AdminNotificationService: Send recruiter rejection notification failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send system maintenance notification to all users
  Future<Map<String, dynamic>> sendSystemMaintenanceNotification({
    required String title,
    required String body,
    required String maintenanceStartTime,
    required String maintenanceDuration,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/admin/notifications/maintenance',
        data: {
          'title': title,
          'body': body,
          'maintenance_start_time': maintenanceStartTime,
          'maintenance_duration': maintenanceDuration,
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send system maintenance notification response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'System maintenance notifications sent successfully',
          'totalSent': responseData['total_sent'] ?? 0,
          'totalFailed': responseData['total_failed'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send system maintenance notifications',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send system maintenance notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send system maintenance notifications',
      };
    } catch (e) {
      print('AdminNotificationService: Send system maintenance notification failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send job status change notification to applicants
  Future<Map<String, dynamic>> sendJobStatusChangeNotification({
    required int jobId,
    required String jobTitle,
    required String status,
    required String message,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/admin/notifications/job/$jobId/status-change',
        data: {
          'title': 'Job Status Changed',
          'body': message,
          'status': status,
        },
      );
      
      final responseData = response.data;
      print('AdminNotificationService: Send job status change notification response: $responseData');

      if (responseData['success'] == true || 
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job status change notifications sent successfully',
          'totalSent': responseData['total_sent'] ?? 0,
          'totalFailed': responseData['total_failed'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send job status change notifications',
        };
      }
    } on DioException catch (e) {
      print('AdminNotificationService: Send job status change notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('AdminNotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send job status change notifications',
      };
    } catch (e) {
      print('AdminNotificationService: Send job status change notification failed with error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}