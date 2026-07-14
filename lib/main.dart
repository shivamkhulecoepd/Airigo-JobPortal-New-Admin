import 'package:airigo_jobportal/core/service_locator.dart';
import 'package:airigo_jobportal/screens/authentication/splash_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_main_screen.dart';
import 'package:airigo_jobportal/services/firebase_messaging_service.dart';
import 'package:airigo_jobportal/services/notification_manager.dart';
import 'package:airigo_jobportal/utils/theme.dart';
import 'package:airigo_jobportal/core/storage/local_storage.dart';
import 'package:airigo_jobportal/core/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Added for performance debugging
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'firebase_options.dart';

void main() async {
  // Enable performance overlay in debug mode fo  r monitoring
  debugPaintSizeEnabled = false; // Disable in production
  debugPaintBaselinesEnabled = false; // Disable in production

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ServiceLocator.init(); // Initialize service locator
  await LocalStorage.init(); // Initialize local storage

  // Initialize Firebase Messaging Service
  await FirebaseMessagingService.initialize();

  // Initialize Notification Manager to handle FCM token registration
  await NotificationManager().initialize();

  runApp(const ProviderScope(child: AirigoJobs()));
}

class AirigoJobs extends ConsumerStatefulWidget {
  const AirigoJobs({super.key});

  @override
  ConsumerState<AirigoJobs> createState() => _AirigoJobsState();
}

class _AirigoJobsState extends ConsumerState<AirigoJobs> {
  @override
  Widget build(BuildContext context) {
    // Check if last session was admin
    final localStorage = LocalStorage();
    final userType = localStorage.getUserType();
    final isAdmin = userType == 'admin';

    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 12 size as base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'AirigoJobs Onboarding',
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay:
              false, // Set to true temporarily to monitor performance
          checkerboardRasterCacheImages:
              false, // Set to true to visualize raster cache misses
          checkerboardOffscreenLayers:
              false, // Set to true to visualize layers rendered to offscreen surfaces
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: SplashScreen(isAdmin: true), // Force admin for testing
          // home: SplashScreen(), // Dynamic based on stored user type
        );
      },
    );
  }
}
