class AppConfig {
  // Backend API Configuration
  // static const String apiUrl = 'http://localhost:8000'; // For local development with PHP backend
  static const String apiUrl = 'https://app.airigojobs.com/public'; // For production or remote server development with PHP backend
  // For production, you would use something like 'https://yourdomain.com/api'
  // For testing with remote server, use 'https://app.airigojobs.com/public'
  
  // Other configuration values
  static const String appName = 'AirigoJobs';
  static const String version = '1.0.6';
  static const int apiTimeout = 30; // seconds
  static const int cacheDuration = 3600; // seconds (1 hour)
  
  // Feature flags for production
  static const bool enableRealTimeUpdates = true;
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
}