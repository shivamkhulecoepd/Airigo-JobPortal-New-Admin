import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import '../../config/app_config.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  static Dio? _dio;
  final LocalStorage _localStorage = LocalStorage();

  Dio get dio {
    if (_dio == null) {
      _dio = Dio();

      // Configure base options
      _dio!.options.baseUrl = AppConfig.apiUrl;
      _dio!.options.connectTimeout = const Duration(seconds: 30);
      _dio!.options.receiveTimeout = const Duration(seconds: 30);

      // Add interceptors
      _dio!.interceptors.add(LoggingInterceptor());
      _dio!.interceptors.add(AuthInterceptor(_localStorage));
      debugPrint('DioClient: Initialized with baseUrl: ${AppConfig.apiUrl}');
    }
    return _dio!;
  }

  // Public method to access localStorage for debugging
  LocalStorage get localStorage => _localStorage;

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    debugPrint('DioClient: Making GET request to path: $path with params: $params');
    final response = await dio.get(path, queryParameters: params);
    debugPrint('DioClient: GET request completed with status: ${response.statusCode}');
    return response;
  }

  Future<Response> post(String path, {dynamic data}) async {
    debugPrint('DioClient: Making POST request to path: $path with data: $data');
    final response = await dio.post(path, data: data);
    debugPrint('DioClient: POST request completed with status: ${response.statusCode}');
    return response;
  }

  Future<Response> put(String path, {dynamic data}) async {
    debugPrint('DioClient: Making PUT request to path: $path with data: $data');
    final response = await dio.put(path, data: data);
    debugPrint('DioClient: PUT request completed with status: ${response.statusCode}');
    return response;
  }

  Future<Response> delete(String path) async {
    debugPrint('DioClient: Making DELETE request to path: $path');
    final response = await dio.delete(path);
    debugPrint('DioClient: DELETE request completed with status: ${response.statusCode}');
    return response;
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('LoggingInterceptor: API CALL: ${options.method} ${options.uri}');
    debugPrint('LoggingInterceptor: Headers: ${options.headers}');
    debugPrint('LoggingInterceptor: Data: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('LoggingInterceptor: API RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    debugPrint('LoggingInterceptor: Response Data: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('LoggingInterceptor: API ERROR: ${err.type} ${err.requestOptions.path}');
    debugPrint('LoggingInterceptor: Error Message: ${err.message}');
    if (err.response != null) {
      debugPrint('LoggingInterceptor: Error Response: ${err.response!.data}');
    }
    super.onError(err, handler);
  }
}

class AuthInterceptor extends Interceptor {
  final LocalStorage _localStorage;

  AuthInterceptor(this._localStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    debugPrint('AuthInterceptor: Called for ${options.method} ${options.uri}');
    final token = await _localStorage.getToken();
    debugPrint('AuthInterceptor: Token from storage: ${token != null ? "exists" : "null"}');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('AuthInterceptor: Added Authorization header with Bearer token');
    } else {
      debugPrint('AuthInterceptor: No token found in storage');
    }
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }
    options.headers['Accept'] = 'application/json';
    debugPrint('AuthInterceptor: Final headers: ${options.headers}');
    debugPrint('AuthInterceptor: ${options.method} ${options.uri}');
    debugPrint('AuthInterceptor Data: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('AuthInterceptor Response: ${response.statusCode} ${response.requestOptions.path}');
    debugPrint('AuthInterceptor Response Data: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('AuthInterceptor Error: ${err.type} ${err.requestOptions.path}');
    debugPrint('AuthInterceptor Error Message: ${err.message}');
    if (err.response != null) {
      debugPrint('AuthInterceptor Error Response: ${err.response!.data}');
    }
    super.onError(err, handler);
  }
}