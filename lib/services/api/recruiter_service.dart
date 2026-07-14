import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class RecruiterService {
  final DioClient _dioClient = DioClient();

  // Fetch a single recruiter profile by user ID
  Future<Map<String, dynamic>?> getRecruiterProfile(int userId) async {
    try {
      print('RecruiterService: Fetching recruiter profile for user ID: $userId');
      
      final response = await _dioClient.get('/api/jobs/recruiter/$userId');
      final responseData = response.data;
      
      print('RecruiterService: Recruiter profile response: $responseData');
      
      if (responseData != null && responseData['recruiter'] is Map) {
        return responseData['recruiter'];
      }
      
      print('RecruiterService: Failed to find recruiter profile for user ID: $userId');
      return null;
    } on DioException catch (e) {
      print('RecruiterService: Fetch recruiter profile failed with DioException: ${e.message}');
      if (e.response != null) {
        print('RecruiterService: Response data: ${e.response!.data}');
      }
      return null;
    } catch (e) {
      print('RecruiterService: Fetch recruiter profile failed with general exception: $e');
      return null;
    }
  }

  // Fetch multiple recruiter profiles efficiently
  Future<Map<int, Map<String, dynamic>>?> getMultipleRecruiterProfiles(List<int> userIds) async {
    try {
      print('RecruiterService: Fetching multiple recruiter profiles for user IDs: $userIds');
      
      // Create a map to store all recruiter profiles
      final Map<int, Map<String, dynamic>> result = {};
      
      // Fetch each recruiter profile individually using the new endpoint
      for (int userId in userIds) {
        try {
          final response = await _dioClient.get('/api/jobs/recruiter/$userId');
          final responseData = response.data;
          
          if (responseData != null && responseData['recruiter'] is Map) {
            result[userId] = responseData['recruiter'];
          }
        } catch (e) {
          print('RecruiterService: Failed to fetch profile for user ID $userId: $e');
          // Continue with other profiles even if one fails
        }
      }
      
      return result;
    } on DioException catch (e) {
      print('RecruiterService: Fetch multiple recruiter profiles failed with DioException: ${e.message}');
      if (e.response != null) {
        print('RecruiterService: Response data: ${e.response!.data}');
      }
      return null;
    } catch (e) {
      print('RecruiterService: Fetch multiple recruiter profiles failed with general exception: $e');
      return null;
    }
  }
}