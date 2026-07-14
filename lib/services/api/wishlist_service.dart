import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:airigo_jobportal/models/job_model.dart';
import 'package:dio/dio.dart';

class WishlistService {
  final DioClient _dioClient = DioClient();

  // Get wishlist for current user
  Future<Map<String, dynamic>> getWishlist() async {
    try {
      print('WishlistService: Fetching wishlist');
      final response = await _dioClient.get('/api/wishlist');
      final responseData = response.data;
      print('WishlistService: Wishlist response: $responseData');
      
      if (responseData.containsKey('wishlist') || responseData.containsKey('jobs')) {
        final wishlistItems = responseData['wishlist'] ?? responseData['jobs'] ?? [];
        final jobs = wishlistItems.map((item) => JobModel.fromJson(item is Map ? item : item['job'])).toList();
        print('WishlistService: Successfully fetched ${jobs.length} wishlist items');
        return {
          'success': true,
          'jobs': jobs,
        };
      } else {
        print('WishlistService: Failed to fetch wishlist: ${responseData['message']}');
        return {
          'success': false,
          'jobs': [],
          'message': responseData['message'] ?? 'Failed to fetch wishlist',
        };
      }
    } on DioException catch (e) {
      print('WishlistService: Fetch wishlist failed with DioException: ${e.message}');
      if (e.response != null) {
        print('WishlistService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'jobs': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('WishlistService: Fetch wishlist failed with general exception: $e');
      return {
        'success': false,
        'jobs': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get wishlist IDs for current user
  Future<Map<String, dynamic>> getWishlistIds() async {
    try {
      print('WishlistService: Fetching wishlist IDs');
      final response = await _dioClient.get('/api/wishlist/ids');
      final responseData = response.data;
      print('WishlistService: Get wishlist IDs response: $responseData');
      
      if (responseData.containsKey('job_ids') || responseData.containsKey('ids')) {
        final rawIds = responseData['job_ids'] ?? responseData['ids'] ?? [];
        // Backend returns ints, normalize to strings for consistent comparison
        final jobIds = (rawIds as List).map((id) => id.toString()).toList();
        print('WishlistService: Successfully fetched ${jobIds.length} wishlist IDs');
        return {
          'success': true,
          'job_ids': jobIds,
        };
      } else {
        print('WishlistService: Failed to fetch wishlist IDs: ${responseData['message']}');
        return {
          'success': false,
          'job_ids': <String>[],
          'message': responseData['message'] ?? 'Failed to fetch wishlist',
        };
      }
    } on DioException catch (e) {
      print('WishlistService: Fetch wishlist IDs failed with DioException: ${e.message}');
      if (e.response != null) {
        print('WishlistService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'job_ids': <String>[],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('WishlistService: Fetch wishlist IDs failed with general exception: $e');
      return {
        'success': false,
        'job_ids': <String>[],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Add job to wishlist
  Future<Map<String, dynamic>> addToWishlist(String jobId) async {
    try {
      print('WishlistService: Adding job ID: $jobId to wishlist');
      final response = await _dioClient.post('/api/wishlist', data: {
        'job_id': jobId,
      });
      final responseData = response.data;
      print('WishlistService: Add to wishlist response: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        print('WishlistService: Successfully added job ID: $jobId to wishlist');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job added to wishlist',
        };
      } else {
        print('WishlistService: Failed to add job to wishlist: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add job to wishlist',
        };
      }
    } on DioException catch (e) {
      print('WishlistService: Add to wishlist failed with DioException: ${e.message}');
      if (e.response != null) {
        print('WishlistService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('WishlistService: Add to wishlist failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Remove job from wishlist
  Future<Map<String, dynamic>> removeFromWishlist(String jobId) async {
    try {
      print('WishlistService: Removing job ID: $jobId from wishlist');
      // Use DELETE request with query parameter as per backend route
      final response = await _dioClient.delete('/api/wishlist?jobId=$jobId');
      final responseData = response.data;
      print('WishlistService: Remove from wishlist response: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        print('WishlistService: Successfully removed job ID: $jobId from wishlist');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job removed from wishlist',
        };
      } else {
        print('WishlistService: Failed to remove job from wishlist: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to remove job from wishlist',
        };
      }
    } on DioException catch (e) {
      print('WishlistService: Remove from wishlist failed with DioException: ${e.message}');
      if (e.response != null) {
        print('WishlistService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('WishlistService: Remove from wishlist failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Toggle wishlist status
  Future<Map<String, dynamic>> toggleWishlist(String jobId) async {
    try {
      print('WishlistService: Toggling wishlist status for job ID: $jobId');
      final response = await _dioClient.post('/api/wishlist/toggle', data: {
        'job_id': jobId,
      });
      final responseData = response.data;
      print('WishlistService: Toggle wishlist response: $responseData');
      
      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        // Backend returns 'is_in_wishlist' after toggle
        final isInWishlist = responseData['is_in_wishlist'] ?? responseData['is_added'] ?? false;
        print('WishlistService: Successfully toggled wishlist for job ID: $jobId, is_in_wishlist: $isInWishlist');
        return {
          'success': true,
          'is_in_wishlist': isInWishlist,
          'message': responseData['message'] ?? 'Wishlist updated',
        };
      } else {
        print('WishlistService: Failed to toggle wishlist: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update wishlist',
        };
      }
    } on DioException catch (e) {
      print('WishlistService: Toggle wishlist failed with DioException: ${e.message}');
      if (e.response != null) {
        print('WishlistService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('WishlistService: Toggle wishlist failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Check if job is in wishlist
  Future<bool> isJobInWishlist(String jobId) async {
    try {
      print('WishlistService: Checking if job ID: $jobId is in wishlist');
      final response = await _dioClient.get('/api/wishlist/check/$jobId');
      final responseData = response.data;
      print('WishlistService: Check wishlist response: $responseData');
      
      if (responseData.containsKey('in_wishlist')) {
        final result = responseData['in_wishlist'] ?? false;
        print('WishlistService: Job ID $jobId is in wishlist: $result');
        return result;
      } else {
        // If the endpoint returns different structure, try alternative
        final result = responseData['is_in_wishlist'] ?? false;
        print('WishlistService: Job ID $jobId is in wishlist: $result');
        return result;
      }
    } catch (e) {
      print('WishlistService: Error checking wishlist for job ID $jobId: $e');
      return false;
    }
  }
}