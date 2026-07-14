// ============================================================
// core/service_locator.dart
// Service Locator for managing app-wide services
// ============================================================

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api/auth_service.dart';
import '../services/api/job_service.dart';
import '../services/api/application_service.dart';
import '../services/api/wishlist_service.dart';
import '../services/api/notification_service.dart';
import '../services/api/issue_report_service.dart';
import '../services/api/file_upload_service.dart';
import 'storage/local_storage.dart';
import 'network/dio_client.dart';

GetIt getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // Initialize shared preferences first
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    // Register secure storage
    getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

    // Initialize local storage
    await LocalStorage.init();
    getIt.registerSingleton<LocalStorage>(LocalStorage());

    // Register Dio client
    getIt.registerSingleton<DioClient>(DioClient());

    // Register all API services
    getIt.registerSingleton<AuthService>(AuthService());
    getIt.registerSingleton<JobService>(JobService());
    getIt.registerSingleton<ApplicationService>(ApplicationService());
    getIt.registerSingleton<WishlistService>(WishlistService());
    getIt.registerSingleton<NotificationService>(NotificationService());
    getIt.registerSingleton<IssueReportService>(IssueReportService());
    getIt.registerSingleton<FileUploadService>(FileUploadService());

    // Initialize other services
    await _initServices();
  }

  static Future<void> _initServices() async {
    // Any additional service initialization can go here
  }

  // Clear all services when user logs out
  static Future<void> clearServices() async {
    // Clear secure storage
    final secureStorage = getIt<FlutterSecureStorage>();
    await secureStorage.deleteAll();

    // Clear shared preferences
    final sharedPreferences = getIt<SharedPreferences>();
    await sharedPreferences.clear();

    // Reinitialize services after clearing
    await init();
  }
}