import 'package:airigo_jobportal/core/providers/feature_flags_provider.dart';
import 'package:airigo_jobportal/screens/authentication/onboarding_screen.dart';
import 'package:airigo_jobportal/screens/authentication/admin_auth_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_main_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_main_screen.dart';
import 'package:airigo_jobportal/screens/admin/admin_main_screen.dart';
import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/models/jobseeker_model.dart';
import 'package:airigo_jobportal/models/recruiter_model.dart';
import 'package:airigo_jobportal/models/user_model.dart';
import 'package:airigo_jobportal/services/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  const SplashScreen({this.isAdmin = false, super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Delay provider modifications until after the first build frame
    Future.microtask(() {
      _navigateToNextScreen();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    // Initialize feature flags
    try {
      await ref.read(featureFlagsProvider.notifier).refreshFlags();
    } catch (_) {
      // Non-critical, continue even if feature flags fail
    }
  }

  Future<void> _navigateToNextScreen() async {
    print('SplashScreen: Navigating...');
    
    // Start initializing services and auth concurrently
    final startTime = DateTime.now();
    
    // Wait for auth state to be fully resolved from API
    dynamic user;
    try {
      print('SplashScreen: Waiting for auth state to resolve...');
      user = await ref.read(authStateProvider.future);
      print('SplashScreen: Auth state resolved. User: ${user?.name ?? 'Anonymous'}');
    } catch (e) {
      print('SplashScreen: Error resolving auth state: $e');
    }

    await _initializeServices();

    // Ensure splash is visible for at least 2 seconds for branding
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < const Duration(seconds: 2)) {
      await Future.delayed(const Duration(seconds: 2) - elapsed);
    }

    if (!mounted) return;

    // Based on the resolved user, decide where to go
    if (user != null) {
      if (user is JobseekerModel) {
        print('SplashScreen: Navigating to JobseekerMainScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JobseekerMainScreen()),
        );
      } else if (user is RecruiterModel) {
        print('SplashScreen: Navigating to RecruiterMainScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RecruiterMainScreen()),
        );
      } else if (user is UserModel && user.role == 'admin') {
        print('SplashScreen: Admin user found, navigating to AdminMainScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      } else {
        // Fallback for unexpected user type
        print('SplashScreen: Unknown user type, going to onboarding');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      // Not logged in or fetch failed
      // If isAdmin flag is set, go to admin login, otherwise go to onboarding
      if (widget.isAdmin) {
        print('SplashScreen: No user found, admin mode detected, navigating to admin login');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminAuthScreen()),
        );
      } else {
        print('SplashScreen: User is null, navigating to Onboarding');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [      
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated App Logo/Icon
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 200.w,
                        padding: EdgeInsets.all(26.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 30.r,
                              spreadRadius: 1,
                              // offset: Offset(0, 8.h),
                            ),
                          ],
                        ),
                        child: Image.asset("assets/icons/Airigo-jobs-logo.png"),
                      ),
                    ),
                  ),
      
                  SizedBox(height: 40.h),
      
                  // Loading text with shimmer effect
                  Shimmer(
                    child: Text(
                      'Preparing your experience...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
      
                  SizedBox(height: 100.h),
                ],
              ),
            ),
      
            // Version info at bottom
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version 2.0.1',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Shimmer Widget for loading text
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({required this.child, super.key});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white,
                Colors.white.withValues(alpha: 0.3),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}