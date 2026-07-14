import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class IssueReportService {
  final DioClient _dioClient = DioClient();

  // Create an issue report
  Future<Map<String, dynamic>> createIssueReport({
    required String type, // 'issue' or 'feedback'
    required String title,
    required String description,
  }) async {
    try {
      print('IssueReportService: Creating issue report - Type: $type, Title: $title');
      
      final response = await _dioClient.post('/api/issue-reports', data: {
        'type': type,
        'title': title,
        'description': description,
      });
      
      final responseData = response.data;
      print('IssueReportService: Create issue report response: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Issue report submitted successfully',
          'issue_report': responseData['issue_report'] ?? responseData['data']?['issue_report'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit issue report',
        };
      }
    } on DioException catch (e) {
      print('IssueReportService: Create issue report failed with DioException: ${e.message}');
      if (e.response != null) {
        print('IssueReportService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('IssueReportService: Create issue report failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get user's issue reports
  Future<Map<String, dynamic>> getMyIssueReports({
    int page = 1,
    int limit = 10,
    String? type,
    String? status,
  }) async {
    try {
      print('IssueReportService: Fetching my issue reports - page: $page, limit: $limit, type: $type, status: $status');
      
      final params = {
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
      };

      final response = await _dioClient.get('/api/issue-reports/my', params: params);
      final responseData = response.data;
      print('IssueReportService: My issue reports response: $responseData');
      
      if (responseData.containsKey('issue_reports')) {
        return {
          'success': true,
          'issue_reports': responseData['issue_reports'],
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'issue_reports': [],
          'message': responseData['message'] ?? 'Failed to fetch issue reports',
        };
      }
    } on DioException catch (e) {
      print('IssueReportService: Fetch my issue reports failed with DioException: ${e.message}');
      if (e.response != null) {
        print('IssueReportService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'issue_reports': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('IssueReportService: Fetch my issue reports failed with general exception: $e');
      return {
        'success': false,
        'issue_reports': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get issue report by ID
  Future<Map<String, dynamic>> getIssueReportById(String issueReportId) async {
    try {
      print('IssueReportService: Fetching issue report by ID: $issueReportId');
      
      final response = await _dioClient.get('/api/issue-reports/$issueReportId');
      final responseData = response.data;
      print('IssueReportService: Issue report by ID response: $responseData');
      
      if (responseData.containsKey('issue_report')) {
        return {
          'success': true,
          'issue_report': responseData['issue_report'],
        };
      } else {
        return {
          'success': false,
          'issue_report': null,
          'message': responseData['message'] ?? 'Failed to fetch issue report',
        };
      }
    } on DioException catch (e) {
      print('IssueReportService: Fetch issue report by ID failed with DioException: ${e.message}');
      if (e.response != null) {
        print('IssueReportService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'issue_report': null,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('IssueReportService: Fetch issue report by ID failed with general exception: $e');
      return {
        'success': false,
        'issue_report': null,
        'message': 'An unexpected error occurred',
      };
    }
  }
}