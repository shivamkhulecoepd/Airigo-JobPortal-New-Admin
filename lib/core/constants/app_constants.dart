// ============================================================
// core/constants/app_constants.dart
// App-wide constants: strings, dimensions, durations
// ============================================================

class AppConstants {
  AppConstants._();

  // ── App Info ─────────────────────────────────────────────────
  static const String appName = 'JobSphere';
  static const String appTagline = 'Your Dream Job Awaits';
  static const String appVersion = '1.0.0';

  // ── API Base (stub) ──────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.jobsphere.in/v1';

  // ── Firebase Placeholders ─────────────────────────────────────
  static const String fcmTokenPlaceholder = 'FCM_TOKEN_PLACEHOLDER';
  static const String firebaseStorageBase =
      'https://firebasestorage.googleapis.com/v0/b/jobsphere.appspot.com/o/';

  // ── Dimensions ───────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  static const double cardElevation = 0.5;
  static const double modalElevation = 16.0;

  // ── Animation Durations ───────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ── Pagination ────────────────────────────────────────────────
  static const int pageSize = 20;

  // ── SharedPrefs Keys ─────────────────────────────────────────
  static const String prefKeyTheme = 'theme_mode';
  static const String prefKeyUser = 'current_user';
  static const String prefKeyOnboarded = 'onboarded';
  static const String prefKeyNotif = 'notif_enabled';
  static const String prefKeyLang = 'language';

  // ── Job Types ─────────────────────────────────────────────────
  static const List<String> jobTypes = [
    'Full-time',
    'Part-time',
    'Remote',
    'Contract',
    'Internship',
    'Freelance',
  ];

  // ── Experience Levels ─────────────────────────────────────────
  static const List<String> experienceLevels = [
    'Fresher',
    '0-1 years',
    '1-3 years',
    '3-5 years',
    '5-10 years',
    '10+ years',
  ];

  // ── Categories ────────────────────────────────────────────────
  static const List<String> jobCategories = [
    'Airline',
    'Hospitality',
    'Cruise'
  ];

  // ── Popular Locations ─────────────────────────────────────────
  static const List<String> popularLocations = [
    'Pune',
    'Mumbai',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Delhi',
  ];
}
