import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: AppConfig.apiTimeout),
      receiveTimeout: const Duration(seconds: AppConfig.apiTimeout),
      contentType: Headers.jsonContentType,
    ));
    
    // Add interceptors for authentication
    _dio.interceptors.add(AuthInterceptor(_secureStorage, this));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: params);
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: params);
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.delete(path, queryParameters: params);
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userType');
  }
  
  Dio get dio => _dio;
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final ApiService _apiService;

  AuthInterceptor(this._storage, this._apiService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final dio = Dio();
          final response = await dio.post(
            '${AppConfig.apiUrl}/api/auth/refresh-token',
            data: {'refresh_token': refreshToken},
          );
          
          if (response.statusCode == 200) {
            final newToken = response.data['tokens']['access_token'];
            await _storage.write(key: 'access_token', value: newToken);
            
            // Retry original request with new token
            final options = Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers..['Authorization'] = 'Bearer $newToken',
            );
            
            final newResponse = await _apiService.dio.request(
              err.requestOptions.path,
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
              options: options,
            );
            return handler.resolve(newResponse);
          }
        } catch (e) {
          // If refresh fails, clear stored tokens
          await _storage.deleteAll();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('isLoggedIn');
          await prefs.remove('userType');
        }
      }
    }
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    String message = 'An unknown error occurred';
    int? statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        statusCode = e.response?.statusCode;
        if (e.response?.data != null) {
          try {
            final responseData = jsonDecode(e.response!.data.toString());
            message = responseData['message'] ?? 'Bad response';
          } catch (decodeError) {
            message = e.response?.statusMessage ?? 'Bad response';
          }
        } else {
          message = 'Network error';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error';
        break;
      case DioExceptionType.badCertificate:
        message = 'SSL certificate error';
        break;
      default:
        message = e.message ?? 'An unknown error occurred';
    }

    return ApiException(message, statusCode: statusCode);
  }

  @override
  String toString() => 'ApiException: $message';
}