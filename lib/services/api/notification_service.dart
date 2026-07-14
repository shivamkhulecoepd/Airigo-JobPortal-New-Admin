import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class NotificationService {
  final DioClient _dioClient = DioClient();

  // Store FCM token for user
  Future<Map<String, dynamic>> storeFcmToken(String fcmToken, {String deviceType = 'mobile', Map<String, dynamic>? deviceInfo}) async {
    try {
      print('NotificationService: Storing FCM token: $fcmToken');
      final response = await _dioClient.post('/api/notifications/fcm-token', data: {
        'fcm_token': fcmToken,
        'device_type': deviceType,
        if (deviceInfo != null) 'device_info': deviceInfo,
      });
      final responseData = response.data;
      print('NotificationService: Store FCM token response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'FCM token stored successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to store FCM token',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Store FCM token failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Store FCM token failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Remove FCM token (logout/unregister device)
  Future<Map<String, dynamic>> removeFcmToken(String fcmToken) async {
    try {
      print('NotificationService: Removing FCM token: $fcmToken');
      // For DELETE requests with parameters, use query parameters
      final response = await _dioClient.dio.delete('/api/notifications/fcm-token', queryParameters: {
        'fcm_token': fcmToken,
      });
      final responseData = response.data;
      print('NotificationService: Remove FCM token response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'FCM token removed successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to remove FCM token',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Remove FCM token failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Remove FCM token failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send notification to a specific user
  Future<Map<String, dynamic>> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('NotificationService: Sending notification to user $recipientId');
      final response = await _dioClient.post('/api/notifications/send', data: {
        'user_id': recipientId,
        'title': title,
        'body': body,
        'type': type,
        if (data != null) 'data': data,
      });
      final responseData = response.data;
      print('NotificationService: Send notification response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notification sent successfully',
          'notification_id': responseData['notification_id'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send notification',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Send notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Send notification failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Send test notification
  Future<Map<String, dynamic>> sendTestNotification({String? title, String? body, Map<String, dynamic>? data}) async {
    try {
      print('NotificationService: Sending test notification');
      final requestData = <String, dynamic>{};
      if (title != null) requestData['title'] = title;
      if (body != null) requestData['body'] = body;
      if (data != null) requestData['data'] = data;

      final response = await _dioClient.post('/api/notifications/test', data: requestData);
      final responseData = response.data;
      print('NotificationService: Test notification response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Test notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send test notification',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Test notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Test notification failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get user's FCM tokens
  Future<Map<String, dynamic>> getUserTokens() async {
    try {
      print('NotificationService: Fetching user tokens');
      final response = await _dioClient.get('/api/notifications/tokens');
      final responseData = response.data;
      print('NotificationService: User tokens response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'tokens': responseData['tokens'] ?? [],
          'message': responseData['message'] ?? 'User tokens retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'tokens': [],
          'message': responseData['message'] ?? 'Failed to retrieve user tokens',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Get user tokens failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'tokens': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Get user tokens failed with general exception: $e');
      return {
        'success': false,
        'tokens': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get user notifications
  Future<Map<String, dynamic>> getUserNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) async {
    try {
      print('NotificationService: Fetching user notifications');
      final response = await _dioClient.dio.get('/api/notifications', queryParameters: {
        'page': page,
        'limit': limit,
        'unread_only': unreadOnly,
      });
      final responseData = response.data;
      print('NotificationService: User notifications raw response: $responseData');

      // Log the type of response data to debug
      print('NotificationService: Response data type: ${responseData.runtimeType}');

      // Check if the response has the expected structure
      if (responseData is Map<String, dynamic>) {
        print('NotificationService: Full response data: $responseData');
        print('NotificationService: Response keys: ${responseData.keys.toList()}');
        
        // Check if the response has the success flag and it's explicitly false
        if (responseData.containsKey('success') && responseData['success'] == false) {
          // Even if success is false, if there are notifications, we should return them
          if (responseData.containsKey('notifications') && (responseData['notifications'] as List?)?.isNotEmpty == true) {
            print('NotificationService: Found notifications despite success=false, count: ${responseData['notifications'].length}');
            return {
              'success': true,
              'notifications': responseData['notifications'] ?? [],
              'pagination': responseData['pagination'] ?? {},
              'message': responseData['message'] ?? 'Notifications retrieved successfully',
            };
          } else {
            // Handle explicit failure response
            print('NotificationService: API returned explicit failure: ${responseData['message']}');
            return {
              'success': false,
              'notifications': [],
              'message': responseData['message'] ?? 'Failed to retrieve notifications',
            };
          }
        } else if (responseData.containsKey('notifications')) {
          // Handle the case where the response directly contains the notifications array
          print('NotificationService: Found notifications in response, count: ${responseData['notifications'].length}');
          return {
            'success': true,
            'notifications': responseData['notifications'] ?? [],
            'pagination': responseData['pagination'] ?? {},
            'message': responseData['message'] ?? 'Notifications retrieved successfully',
          };
        } else {
          // If notifications key doesn't exist but it's not an explicit failure, log for debugging
          print('NotificationService: Unexpected response format - no notifications key found');
          print('NotificationService: Available keys: ${responseData.keys.toList()}');
          return {
            'success': false,
            'notifications': [],
            'message': 'Unexpected response format from server',
          };
        }
      } else if (responseData is List) {
        // Handle case where response is directly a list of notifications
        print('NotificationService: Response is a list with ${responseData.length} items');
        return {
          'success': true,
          'notifications': responseData,
          'pagination': {},
          'message': 'Notifications retrieved successfully',
        };
      } else {
        // If response is not a map or list, treat as failure
        print('NotificationService: Invalid response format - not Map or List');
        return {
          'success': false,
          'notifications': [],
          'message': 'Invalid response format from server',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Get user notifications failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'notifications': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Get user notifications failed with general exception: $e');
      return {
        'success': false,
        'notifications': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get user's archived notifications
  Future<Map<String, dynamic>> getUserArchivedNotifications({int page = 1, int limit = 20}) async {
    try {
      print('NotificationService: Fetching user archived notifications');
      final response = await _dioClient.dio.get('/api/notifications/archived', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final responseData = response.data;
      print('NotificationService: User archived notifications raw response: $responseData');

      // Check if the response has the expected structure
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('success') && responseData['success'] == false) {
          // Even if success is false, if there are notifications, we should return them
          if (responseData.containsKey('notifications') && (responseData['notifications'] as List?)?.isNotEmpty == true) {
            print('NotificationService: Found archived notifications despite success=false, count: ${responseData['notifications'].length}');
            return {
              'success': true,
              'notifications': responseData['notifications'] ?? [],
              'pagination': responseData['pagination'] ?? {},
              'message': responseData['message'] ?? 'Archived notifications retrieved successfully',
            };
          } else {
            print('NotificationService: API returned explicit failure for archived: ${responseData['message']}');
            return {
              'success': false,
              'notifications': [],
              'message': responseData['message'] ?? 'Failed to retrieve archived notifications',
            };
          }
        } else if (responseData.containsKey('notifications')) {
          print('NotificationService: Found archived notifications in response, count: ${responseData['notifications'].length}');
          return {
            'success': true,
            'notifications': responseData['notifications'] ?? [],
            'pagination': responseData['pagination'] ?? {},
            'message': responseData['message'] ?? 'Archived notifications retrieved successfully',
          };
        } else {
          print('NotificationService: Unexpected response format for archived notifications');
          return {
            'success': false,
            'notifications': [],
            'message': 'Unexpected response format from server',
          };
        }
      } else if (responseData is List) {
        print('NotificationService: Archived response is a list with ${responseData.length} items');
        return {
          'success': true,
          'notifications': responseData,
          'pagination': {},
          'message': 'Archived notifications retrieved successfully',
        };
      } else {
        print('NotificationService: Invalid response format for archived notifications - not Map or List');
        return {
          'success': false,
          'notifications': [],
          'message': 'Invalid response format from server',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Get user archived notifications failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'notifications': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Get user archived notifications failed with general exception: $e');
      return {
        'success': false,
        'notifications': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      print('NotificationService: Marking notification as read: $notificationId');
      final response = await _dioClient.put('/api/notifications/$notificationId/read');
      final responseData = response.data;
      print('NotificationService: Mark as read response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notification marked as read successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to mark notification as read',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Mark notification as read failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Mark notification as read failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      print('NotificationService: Marking all notifications as read');
      final response = await _dioClient.put('/api/notifications/mark-all-read');
      final responseData = response.data;
      print('NotificationService: Mark all as read response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'All notifications marked as read successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to mark all notifications as read',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Mark all notifications as read failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Mark all notifications as read failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get notification count
  Future<Map<String, dynamic>> getNotificationCount() async {
    try {
      print('NotificationService: Fetching notification count');
      final response = await _dioClient.get('/api/notifications/count');
      final responseData = response.data;
      print('NotificationService: Notification count response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'total': responseData['total'] ?? 0,
          'unread': responseData['unread'] ?? 0,
          'message': responseData['message'] ?? 'Notification count retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'total': 0,
          'unread': 0,
          'message': responseData['message'] ?? 'Failed to retrieve notification count',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Get notification count failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'total': 0,
        'unread': 0,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Get notification count failed with general exception: $e');
      return {
        'success': false,
        'total': 0,
        'unread': 0,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Archive notification
  Future<Map<String, dynamic>> archiveNotification(String notificationId) async {
    try {
      print('NotificationService: Archiving notification: $notificationId');
      final response = await _dioClient.put('/api/notifications/$notificationId/archive');
      final responseData = response.data;
      print('NotificationService: Archive notification response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notification archived successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to archive notification',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Archive notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Archive notification failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      print('NotificationService: Deleting notification: $notificationId');
      final response = await _dioClient.delete('/api/notifications/$notificationId');
      final responseData = response.data;
      print('NotificationService: Delete notification response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notification deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete notification',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Delete notification failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Delete notification failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Clear all notifications
  Future<Map<String, dynamic>> clearAllNotifications() async {
    try {
      print('NotificationService: Clearing all notifications');
      final response = await _dioClient.delete('/api/notifications/clear');
      final responseData = response.data;
      print('NotificationService: Clear all notifications response: $responseData');

      if (responseData['success'] == true || responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'All notifications cleared successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to clear notifications',
        };
      }
    } on DioException catch (e) {
      print('NotificationService: Clear all notifications failed with DioException: ${e.message}');
      if (e.response != null) {
        print('NotificationService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('NotificationService: Clear all notifications failed with general exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}