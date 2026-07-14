import 'package:airigo_jobportal/screens/authentication/choose_role_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingSlide> _slides = [
    // OnboardingSlide(
    //   imageUrl:
    //       'https://media.istockphoto.com/id/2188950024/photo/real-estate-agent-showing-couple-pictures-on-a-tablet-while-looking-at-a-house-for-sale.webp?a=1&b=1&s=612x612&w=0&k=20&c=UGE2LWN7gzfGcHMy5IOKGWEW6-BQfsoP05E5m2FaCcs=',
    //   title: 'Welcome to Airigo Job Portal',
    //   subtitle:
    //       'Explore breathtaking destinations,\nhidden gems, and top travel experiences.',
    // ),
    OnboardingSlide(
      imageUrl: 'assets/images/Onboarding-1.jpg',
      title: 'Discover Your Dream\nJob',
      subtitle:
          'Browse thousands of job opportunities from\ntop companies around the world.',
    ),
    OnboardingSlide(
      imageUrl: 'assets/images/Onboarding-2.jpg',
      title: 'Easy Application Process',
      subtitle:
          'Apply to multiple jobs with just one tap.\nSave time and track applications.',
    ),
    OnboardingSlide(
      title: 'Connect with Top\nEmployers',
      subtitle:
          'Get noticed by leading companies and receive\npersonalized job recommendations.',
      imageUrl: 'assets/images/Onboarding-3.jpg',
    ),
    OnboardingSlide(
      title: 'Start Your Career\nJourney',
      subtitle:
          'Join millions of professionals finding their\nperfect job match every day.',
      imageUrl: 'assets/images/Onboarding-4.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to login or home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
        (route) => false,
      );
    }
  }

  void _skip() {
    _pageController.jumpToPage(_slides.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      left: true,
      right: true,
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _fadeController.reset();
                _fadeController.forward();
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _buildSlide(_slides[index], index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, int index) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          bottom: MediaQuery.of(context).size.height / 2 - 30,
          child: Image.asset(slide.imageUrl, fit: BoxFit.cover),
        ),
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.colorScheme.surface,
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            spacing: 30.h,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(left: 16.w),
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 5.w,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                child: Text(
                  slide.title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  slide.subtitle,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 20.w),
                      child: _buildCustomPageIndicator(),
                    ),
                  ],
                ),
              ),
              // SizedBox(height: 40.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 7.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: TextButton.icon(
                  onPressed: _nextPage,
                  label: Text(
                    _currentPage == _slides.length - 1 ? 'Login' : 'Next',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomPageIndicator() {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        // Get the current scroll position (can be fractional during swipe)
        final double page = _pageController.hasClients
            ? _pageController.page ?? _currentPage.toDouble()
            : _currentPage.toDouble();

        return Row(
          spacing: 10.w,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final bool isActive = index == page.round();
            final double distance = (page - index).abs();

            // Size & color interpolation
            final double scale = 1.0 - (distance * 0.4).clamp(0.0, 0.6);
            final Color color = Color.lerp(
              Theme.of(context).colorScheme.onSurfaceVariant,
              Theme.of(context).colorScheme.primary,
              (1.0 - distance).clamp(0.0, 1.0),
            )!;

            return AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: Container(
                width: 10.w,
                height: 10.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : color,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 8.r,
                            spreadRadius: 2.r,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class OnboardingSlide {
  final String imageUrl;
  final String title;
  final String subtitle;

  OnboardingSlide({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });
}
